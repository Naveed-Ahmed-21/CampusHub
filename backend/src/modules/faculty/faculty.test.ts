import request from 'supertest';
import { createApp } from '../../app';
import { generateAccessToken } from '../../shared/utils/jwt.util';
import { FacultyService } from './faculty.service';
import { FacultyRepository } from './faculty.repository';
import { prisma } from '../../config/database';

describe('Faculty Module Tests', () => {
  let facultyToken: string;
  let studentToken: string;
  let collegeId: string = '10000000-0000-4000-8000-000000000001';
  let facultyUserId: string = '10000000-0000-4000-8000-000000000002';
  let studentUserId: string = '10000000-0000-4000-8000-000000000101';
  let createdSubjectId: string | null = null;
  const app = createApp();

  beforeAll(async () => {
    try {
      const college = await prisma.college.findFirst();
      if (college) {
        collegeId = college.id;
      }
      const facultyUser = await prisma.user.findFirst({ where: { role: 'FACULTY' } });
      if (facultyUser) {
        facultyUserId = facultyUser.id;
        collegeId = facultyUser.college_id;
      }
      const studentUser = await prisma.user.findFirst({ where: { role: 'STUDENT' } });
      if (studentUser) {
        studentUserId = studentUser.id;
      }
    } catch (_) {}

    facultyToken = generateAccessToken({
      userId: facultyUserId,
      collegeId: collegeId,
      role: 'FACULTY',
      email: 'faculty@campushub.edu',
    });

    studentToken = generateAccessToken({
      userId: studentUserId,
      collegeId: collegeId,
      role: 'STUDENT',
      email: 'student@campushub.edu',
    });
  });

  describe('FacultyService Unit Tests', () => {
    let mockRepo: jest.Mocked<FacultyRepository>;
    let service: FacultyService;

    beforeEach(() => {
      mockRepo = {
        getFacultyUserInfo: jest.fn().mockResolvedValue({
          id: 'fac_1',
          name: 'Dr. Robert Taylor',
          email: 'faculty@campushub.edu',
          designation: 'Associate Professor',
          department: 'Computer Science & Engineering',
          avatarUrl: null,
        }),
        findSubjectsByFaculty: jest.fn().mockResolvedValue([
          {
            id: 'sbj_1',
            code: 'CS301',
            name: 'Data Structures',
            department: 'CSE',
            semester: 'Semester 5',
            section: 'A',
            credits: 4,
            resourcesCount: 2,
            announcementsCount: 1,
            studentsCount: 40,
            createdAt: new Date(),
          },
        ]),
        findSubjectById: jest.fn().mockResolvedValue({
          id: 'sbj_1',
          facultyId: 'fac_1',
          code: 'CS301',
          name: 'Data Structures',
          department: 'CSE',
          semester: 'Semester 5',
          section: 'A',
          credits: 4,
          resourcesCount: 1,
          announcementsCount: 0,
          studentsCount: 40,
          createdAt: new Date(),
          resources: [],
          announcements: [],
        }),
        createSubject: jest.fn().mockImplementation((facId, colId, dto) =>
          Promise.resolve({
            id: 'sbj_new',
            code: dto.code,
            name: dto.name,
            department: 'CSE',
            semester: dto.semester,
            section: 'A',
            credits: 3,
            resourcesCount: 0,
            announcementsCount: 0,
            studentsCount: 0,
            createdAt: new Date(),
          })
        ),
        createSubjectResource: jest.fn().mockResolvedValue({
          id: 'res_1',
          subjectId: 'sbj_1',
          title: 'Notes.pdf',
          fileUrl: 'https://ik.imagekit.io/notes.pdf',
          fileType: 'PDF',
          uploadedById: 'fac_1',
          uploadedByName: 'Dr. Robert Taylor',
          createdAt: new Date(),
        }),
        deleteSubjectResource: jest.fn().mockResolvedValue(true),
        createSubjectAnnouncement: jest.fn().mockResolvedValue({
          id: 'anc_1',
          subjectId: 'sbj_1',
          title: 'Exam info',
          content: 'Midterms on Monday',
          authorId: 'fac_1',
          authorName: 'Dr. Robert Taylor',
          createdAt: new Date(),
        }),
        getMentees: jest.fn().mockResolvedValue([
          {
            id: 'std_1',
            name: 'Alex Vance',
            rollNumber: '21CS001',
            department: 'CSE',
            semester: 'Semester 7',
            cgpa: 9.0,
            email: 'alex@campushub.edu',
            avatarUrl: null,
            hasPortfolio: true,
          },
        ]),
        getRecentAnnouncements: jest.fn().mockResolvedValue([]),
      } as unknown as jest.Mocked<FacultyRepository>;

      service = new FacultyService(mockRepo);
    });

    it('should aggregate faculty dashboard metrics', async () => {
      const dashboard = await service.getDashboard('fac_1', 'col_1');
      expect(dashboard.faculty.name).toBe('Dr. Robert Taylor');
      expect(dashboard.stats.totalSubjects).toBe(1);
      expect(dashboard.stats.totalMentees).toBe(1);
    });

    it('should create and assign a subject', async () => {
      const subject = await service.createSubject('fac_1', 'col_1', {
        code: 'CS401',
        name: 'Cloud Computing',
        semester: 'Semester 7',
      });
      expect(subject.code).toBe('CS401');
      expect(mockRepo.createSubject).toHaveBeenCalled();
    });

    it('should allow resource creation when faculty is the subject owner', async () => {
      const resource = await service.addSubjectResource(
        'fac_1',
        'sbj_1',
        {
          title: 'Slides.pdf',
          fileUrl: 'https://ik.imagekit.io/slides.pdf',
          fileType: 'PDF',
        },
        'FACULTY'
      );
      expect(resource.title).toBe('Notes.pdf');
    });

    it('should block resource upload when requesting faculty is not the subject owner', async () => {
      await expect(
        service.addSubjectResource(
          'different_fac_id',
          'sbj_1',
          {
            title: 'HackedNotes.pdf',
            fileUrl: 'https://evil.com',
            fileType: 'PDF',
          },
          'FACULTY'
        )
      ).rejects.toThrow('You are not authorized to upload resources to this subject');
    });
  });

  describe('Faculty HTTP Endpoints & RBAC Guards', () => {
    it('should return 401 Unauthorized when requesting without token', async () => {
      const res = await request(app).get('/api/v1/faculty/dashboard');
      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });

    it('should return 403 Forbidden when accessed by a STUDENT', async () => {
      const res = await request(app)
        .get('/api/v1/faculty/dashboard')
        .set('Authorization', `Bearer ${studentToken}`);
      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });

    it('should return 200 OK for FACULTY requesting dashboard', async () => {
      const res = await request(app)
        .get('/api/v1/faculty/dashboard')
        .set('Authorization', `Bearer ${facultyToken}`);
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('faculty');
      expect(res.body.data).toHaveProperty('stats');
    });

    it('should return 200 OK for FACULTY requesting subjects', async () => {
      const res = await request(app)
        .get('/api/v1/faculty/subjects')
        .set('Authorization', `Bearer ${facultyToken}`);
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
    });

    it('should return 200 OK for today class schedule', async () => {
      const res = await request(app)
        .get('/api/v1/faculty/classes/today')
        .set('Authorization', `Bearer ${facultyToken}`);
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
    });

    it('should return 200 OK for mentee students roster', async () => {
      const res = await request(app)
        .get('/api/v1/faculty/mentees')
        .set('Authorization', `Bearer ${facultyToken}`);
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
    });

    it('should return 201 Created when creating a new subject', async () => {
      const subjectCode = `CS${Math.floor(100 + Math.random() * 899)}`;
      const res = await request(app)
        .post('/api/v1/faculty/subjects')
        .set('Authorization', `Bearer ${facultyToken}`)
        .send({
          code: subjectCode,
          name: 'Advanced Machine Learning',
          semester: 'Semester 7',
          section: 'A',
          credits: 4,
          departmentName: 'Computer Science and Engineering',
        });
      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.code).toBe(subjectCode);
      createdSubjectId = res.body.data.id;
    });

    it('should return 200 OK when fetching subject details', async () => {
      if (!createdSubjectId) return;
      const res = await request(app)
        .get(`/api/v1/faculty/subjects/${createdSubjectId}`)
        .set('Authorization', `Bearer ${facultyToken}`);
      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.id).toBe(createdSubjectId);
    });

    it('should return 201 Created when uploading subject study material', async () => {
      if (!createdSubjectId) return;
      const res = await request(app)
        .post(`/api/v1/faculty/subjects/${createdSubjectId}/resources`)
        .set('Authorization', `Bearer ${facultyToken}`)
        .send({
          title: 'Unit 3 Graph Theory & Trees.pdf',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/unit3.pdf',
          fileType: 'PDF',
        });
      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.title).toBe('Unit 3 Graph Theory & Trees.pdf');
    });

    it('should return 201 Created when publishing a subject announcement', async () => {
      if (!createdSubjectId) return;
      const res = await request(app)
        .post(`/api/v1/faculty/subjects/${createdSubjectId}/announcements`)
        .set('Authorization', `Bearer ${facultyToken}`)
        .send({
          title: 'Assignment 2 Deadline Extended',
          content: 'The deadline for Assignment 2 is extended until Sunday midnight.',
        });
      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.title).toBe('Assignment 2 Deadline Extended');
    });
  });
});
