import request from 'supertest';
import { createApp } from '../../app';
import { generateAccessToken } from '../../shared/utils/jwt.util';
import { Role } from '@prisma/client';
import { prisma } from '../../infrastructure/prisma/prisma.service';
import { DeptAdminService } from './dept-admin.service';
import { ForbiddenError, ConflictError } from '../../shared/errors/AppError';

const app = createApp();

describe('DEPT_ADMIN Module Test Suite', () => {
  let collegeId = '';
  let itDeptId = '';
  let cseDeptId = '';
  let deptAdminUserId = '';
  let deptAdminToken = '';
  let studentToken = '';
  let facultyToken = '';

  let service: DeptAdminService;

  beforeAll(async () => {
    service = new DeptAdminService();

    const college = await prisma.college.findFirst();
    if (college) {
      collegeId = college.id;
    }

    const itDept = await prisma.department.findFirst({ where: { code: 'IT' } });
    if (itDept) {
      itDeptId = itDept.id;
    }

    const cseDept = await prisma.department.findFirst({ where: { code: 'CSE' } });
    if (cseDept) {
      cseDeptId = cseDept.id;
    }

    const deptAdminUser = await prisma.user.findFirst({
      where: { role: Role.DEPT_ADMIN },
    });
    if (deptAdminUser) {
      deptAdminUserId = deptAdminUser.id;
    }

    deptAdminToken = generateAccessToken({
      sub: deptAdminUserId || 'dept-admin-id',
      userId: deptAdminUserId || 'dept-admin-id',
      collegeId,
      departmentId: itDeptId,
      role: Role.DEPT_ADMIN,
      email: 'deptadmin.it@gcee.ac.in',
    });

    studentToken = generateAccessToken({
      sub: 'student-id',
      userId: 'student-id',
      collegeId,
      departmentId: itDeptId,
      role: Role.STUDENT,
      email: 'student@gcee.ac.in',
    });

    facultyToken = generateAccessToken({
      sub: 'faculty-id',
      userId: 'faculty-id',
      collegeId,
      departmentId: itDeptId,
      role: Role.FACULTY,
      email: 'faculty@gcee.ac.in',
    });
  });

  describe('1. Department Scope & RBAC Boundary (Server-Side)', () => {
    it('resolveDeptId: MUST reject if DEPT_ADMIN attempts to access another department', () => {
      const user = {
        role: Role.DEPT_ADMIN,
        departmentId: itDeptId,
      };

      // Frontend attempts to supply CSE departmentId
      expect(() => {
        service.resolveDeptId(user, cseDeptId);
      }).toThrow(ForbiddenError);
    });

    it('resolveDeptId: MUST reject DEPT_ADMIN without assigned department', () => {
      const unassignedUser = {
        role: Role.DEPT_ADMIN,
        departmentId: undefined,
      };

      expect(() => {
        service.resolveDeptId(unassignedUser);
      }).toThrow(ForbiddenError);
    });

    it('resolveDeptId: Allows college ADMIN to inspect specific department', () => {
      const adminUser = {
        role: Role.ADMIN,
        departmentId: undefined,
      };

      const resolved = service.resolveDeptId(adminUser, cseDeptId);
      expect(resolved).toBe(cseDeptId);
    });
  });

  describe('2. Cross-Department Isolation', () => {
    it('getStudentById: MUST throw 403 Forbidden when accessing student in another department', async () => {
      // Find a student not in IT
      const foreignStudent = await prisma.user.findFirst({
        where: {
          role: Role.STUDENT,
          department_id: { not: itDeptId },
        },
      });

      if (foreignStudent) {
        await expect(
          service.getStudentById(
            collegeId,
            { role: Role.DEPT_ADMIN, departmentId: itDeptId },
            foreignStudent.id
          )
        ).rejects.toThrow(ForbiddenError);
      }
    });

    it('getFacultyById: MUST throw 403 Forbidden when accessing faculty in another department', async () => {
      // Find a faculty not in IT
      const foreignFaculty = await prisma.user.findFirst({
        where: {
          role: Role.FACULTY,
          department_id: { not: itDeptId },
        },
      });

      if (foreignFaculty) {
        await expect(
          service.getFacultyById(
            collegeId,
            { role: Role.DEPT_ADMIN, departmentId: itDeptId },
            foreignFaculty.id
          )
        ).rejects.toThrow(ForbiddenError);
      }
    });
  });

  describe('3. Timetable Conflict Detection', () => {
    it('MUST detect faculty time overlap on the same day', async () => {
      const testFaculty = await prisma.user.findFirst({
        where: { role: Role.FACULTY, department_id: itDeptId },
      });
      const testClass = await prisma.academicClass.findFirst({
        where: { department_id: itDeptId },
      });
      const testSubject = await prisma.subject.findFirst({
        where: { department_id: itDeptId },
      });

      if (testFaculty && testClass && testSubject) {
        // Create an existing schedule
        const existingSchedule = await prisma.facultySchedule.create({
          data: {
            faculty_id: testFaculty.id,
            class_id: testClass.id,
            subject_id: testSubject.id,
            day_of_week: 'MONDAY',
            start_time: '09:00 AM',
            end_time: '10:00 AM',
            subject_name: 'Database Management Systems',
            room_or_venue: 'IT Lab 1',
          },
        });

        // Attempt to create a colliding slot for the same faculty at the same time
        await expect(
          service.createTimetableSlot(
            collegeId,
            { role: Role.DEPT_ADMIN, departmentId: itDeptId },
            {
              facultyId: testFaculty.id,
              classId: testClass.id,
              subjectId: testSubject.id,
              dayOfWeek: 'Monday',
              startTime: '09:00 AM',
              endTime: '10:00 AM',
            }
          )
        ).rejects.toThrow(ConflictError);

        // Clean up test schedule
        await prisma.facultySchedule.delete({ where: { id: existingSchedule.id } });
      }
    });
  });

  describe('4. HTTP API Endpoints & Role Guard Verification', () => {
    it('GET /api/v1/dept-admin/dashboard returns 401 when unauthenticated', async () => {
      const res = await request(app).get('/api/v1/dept-admin/dashboard');
      expect(res.status).toBe(401);
    });

    it('GET /api/v1/dept-admin/dashboard returns 403 for STUDENT role', async () => {
      const res = await request(app)
        .get('/api/v1/dept-admin/dashboard')
        .set('Authorization', `Bearer ${studentToken}`);
      expect(res.status).toBe(403);
    });

    it('GET /api/v1/dept-admin/dashboard returns 403 for FACULTY role', async () => {
      const res = await request(app)
        .get('/api/v1/dept-admin/dashboard')
        .set('Authorization', `Bearer ${facultyToken}`);
      expect(res.status).toBe(403);
    });

    it('GET /api/v1/dept-admin/dashboard returns 200 with complete dashboard data for DEPT_ADMIN', async () => {
      const res = await request(app)
        .get('/api/v1/dept-admin/dashboard')
        .set('Authorization', `Bearer ${deptAdminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.department).toBeDefined();
      expect(res.body.data.department.code).toBe('IT');
      expect(res.body.data.department.degree).toBe('B.Tech');
      expect(res.body.data.kpis).toBeDefined();
      expect(res.body.data.alerts).toBeDefined();
    });

    it('GET /api/v1/dept-admin/students returns 200 with department students', async () => {
      const res = await request(app)
        .get('/api/v1/dept-admin/students')
        .set('Authorization', `Bearer ${deptAdminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data.students)).toBe(true);
    });

    it('GET /api/v1/dept-admin/academics returns 200 with batches and classes', async () => {
      const res = await request(app)
        .get('/api/v1/dept-admin/academics')
        .set('Authorization', `Bearer ${deptAdminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.batches).toBeDefined();
      expect(res.body.data.classes).toBeDefined();
      expect(res.body.data.subjects).toBeDefined();
    });

    it('GET /api/v1/dept-admin/placement returns 200 with placement stats and active drives', async () => {
      const res = await request(app)
        .get('/api/v1/dept-admin/placement')
        .set('Authorization', `Bearer ${deptAdminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.activeDrives).toBeDefined();
      expect(res.body.data.eligibleStudents).toBeDefined();
      expect(Array.isArray(res.body.data.recentDrives)).toBe(true);
    });

    it('GET /api/v1/dept-admin/reports returns 200 with analytics metrics', async () => {
      const res = await request(app)
        .get('/api/v1/dept-admin/reports')
        .set('Authorization', `Bearer ${deptAdminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.metrics).toBeDefined();
      expect(res.body.data.studentsByYear).toBeDefined();
    });

    it('GET /api/v1/dept-admin/attendance returns 200 with real attendance metrics and subject distributions', async () => {
      const res = await request(app)
        .get('/api/v1/dept-admin/attendance')
        .set('Authorization', `Bearer ${deptAdminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(typeof res.body.data.averageAttendance).toBe('number');
      expect(res.body.data.breakdown).toBeDefined();
      expect(typeof res.body.data.lowAttendanceCount).toBe('number');
      expect(Array.isArray(res.body.data.subjectAttendance)).toBe(true);
    });

    it('GET /api/v1/dept-admin/attendance/low returns 200 with low attendance student records', async () => {
      const res = await request(app)
        .get('/api/v1/dept-admin/attendance/low')
        .set('Authorization', `Bearer ${deptAdminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
    });

    it('GET /api/v1/dept-admin/assignments returns 200 with assignments list', async () => {
      const res = await request(app)
        .get('/api/v1/dept-admin/assignments')
        .set('Authorization', `Bearer ${deptAdminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
    });

    it('GET /api/v1/dept-admin/assessments returns 200 with assessments list', async () => {
      const res = await request(app)
        .get('/api/v1/dept-admin/assessments')
        .set('Authorization', `Bearer ${deptAdminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
    });

    it('GET /api/v1/dept-admin/resources returns 200 with uploaded resources list', async () => {
      const res = await request(app)
        .get('/api/v1/dept-admin/resources')
        .set('Authorization', `Bearer ${deptAdminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
    });
  });
});
