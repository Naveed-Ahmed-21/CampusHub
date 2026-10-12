import { Router } from 'express';
import { DeptAdminService } from './dept-admin.service';
import { DeptAdminController } from './dept-admin.controller';
import { requireAuth, requireRole } from '../../shared/middlewares/auth.middleware';

const service = new DeptAdminService();
const controller = new DeptAdminController(service);

export const deptAdminRouter = Router();

// Server-side authentication and role guard:
// Only DEPT_ADMIN and institutional ADMIN can access department admin endpoints.
deptAdminRouter.use(requireAuth());
deptAdminRouter.use(requireRole('DEPT_ADMIN', 'ADMIN'));

// 1. Dashboard
deptAdminRouter.get('/dashboard', controller.getDashboard);

// 2. Students & Profile
deptAdminRouter.get('/students', controller.getStudents);
deptAdminRouter.get('/students/:id', controller.getStudentById);

// 3. Faculty & Profile
deptAdminRouter.get('/faculty', controller.getFaculty);
deptAdminRouter.get('/faculty/:id', controller.getFacultyById);

// 4. Academics (Batches, Classes, Subjects)
deptAdminRouter.get('/academics', controller.getAcademics);

// 5. Timetable with Conflict Detection
deptAdminRouter.get('/timetable', controller.getTimetable);
deptAdminRouter.post('/timetable', controller.createTimetableSlot);

// 6. Attendance & Low Attendance
deptAdminRouter.get('/attendance', controller.getAttendance);
deptAdminRouter.get('/attendance/low', controller.getLowAttendanceStudents);

// 7. Academic Monitoring
deptAdminRouter.get('/assignments', controller.getAssignments);
deptAdminRouter.get('/assessments', controller.getAssessments);
deptAdminRouter.get('/resources', controller.getResources);

// 8. Placement Monitoring
deptAdminRouter.get('/placement', controller.getPlacementSummary);

// 9. Department Reports & Analytics
deptAdminRouter.get('/reports', controller.getReports);

// 10. Department-Targeted Announcement
deptAdminRouter.post('/announcements', controller.createAnnouncement);
