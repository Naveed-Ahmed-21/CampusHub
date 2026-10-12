import { Router } from 'express';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { AdminRepository } from './admin.repository';
import { requireAuth, requireRole } from '../../shared/middlewares/auth.middleware';

const adminRepo = new AdminRepository();
const adminService = new AdminService(adminRepo);
const adminController = new AdminController(adminService);

export const adminRouter = Router();

// Protect Admin endpoints with Authentication & Administrative Role Authorization
// Permits institutional ADMIN and department-scoped DEPT_ADMIN
adminRouter.use(requireAuth());
adminRouter.use(requireRole('ADMIN', 'DEPT_ADMIN'));

// Dashboard & Analytics
adminRouter.get('/metrics', adminController.getMetrics);
adminRouter.get('/analytics', adminController.getAnalytics);
adminRouter.get('/reports', adminController.getAuditReports);
adminRouter.get('/reports/csv', adminController.getAuditReportsCsv);

// Institutional Settings & College Profile (Institutional ADMIN Only)
adminRouter.get('/college', adminController.getCollegeSettings);
adminRouter.patch('/college', requireRole('ADMIN'), adminController.updateCollegeSettings);

// User Management
adminRouter.get('/users', adminController.getUsers);
adminRouter.get('/users/bin', adminController.getDeletedUsers);
adminRouter.delete('/users/bin/purge', requireRole('ADMIN'), adminController.purgeExpiredDeletedUsers);
adminRouter.post('/users/:id/restore', adminController.restoreUser);
adminRouter.delete('/users/:id/permanent', requireRole('ADMIN'), adminController.permanentlyDeleteUser);
adminRouter.post('/users', adminController.createUser);
adminRouter.get('/users/:id', adminController.getUserById);
adminRouter.patch('/users/:id', adminController.updateUser);
adminRouter.patch('/users/role', adminController.updateUserRole);
adminRouter.patch('/users/:id/role', adminController.updateUserRole);
adminRouter.patch('/users/status', adminController.updateUserStatus);
adminRouter.patch('/users/:id/status', adminController.updateUserStatus);
adminRouter.delete('/users/:id', adminController.deleteUser);
adminRouter.post('/users/:id/temporary-password', adminController.setTemporaryPassword);

// Department Management
adminRouter.get('/departments', adminController.getDepartments);
adminRouter.post('/departments', requireRole('ADMIN'), adminController.createDepartment);
adminRouter.get('/departments/:id/overview', adminController.getDepartmentOverview);
adminRouter.get('/departments/:id/students', adminController.getDepartmentStudents);
adminRouter.get('/departments/:id/faculty', adminController.getDepartmentFaculty);
adminRouter.get('/departments/:id', adminController.getDepartmentById);
adminRouter.patch('/departments/:id', adminController.updateDepartment);
adminRouter.patch('/departments/:id/status', adminController.updateDepartmentStatus);
adminRouter.delete('/departments/:id', requireRole('ADMIN'), adminController.deleteDepartment);

// Academic Years
adminRouter.get('/academic-years', adminController.getAcademicYears);
adminRouter.post('/academic-years', adminController.createAcademicYear);
adminRouter.get('/academic-years/:id', adminController.getAcademicYearById);
adminRouter.patch('/academic-years/:id', adminController.updateAcademicYear);
adminRouter.patch('/academic-years/:id/active', adminController.setActiveAcademicYear);
adminRouter.post('/academic-years/:id/transition', requireRole('ADMIN'), adminController.processAcademicTransition);

// Academic Terms
adminRouter.get('/academic-terms', adminController.getAcademicTerms);
adminRouter.post('/academic-terms', adminController.createAcademicTerm);
adminRouter.get('/academic-terms/:id', adminController.getAcademicTermById);
adminRouter.patch('/academic-terms/:id', adminController.updateAcademicTerm);

// Academic Programs
adminRouter.get('/programs', adminController.getAcademicPrograms);
adminRouter.post('/programs', adminController.createAcademicProgram);
adminRouter.get('/programs/:id', adminController.getAcademicProgramById);
adminRouter.patch('/programs/:id', adminController.updateAcademicProgram);

// Batches
adminRouter.get('/batches', adminController.getBatches);
adminRouter.post('/batches', adminController.createBatch);
adminRouter.get('/batches/:id', adminController.getBatchById);
adminRouter.patch('/batches/:id', adminController.updateBatch);

// Subjects & Course Offerings
adminRouter.get('/subjects', adminController.getSubjects);
adminRouter.post('/subjects', adminController.createSubject);
adminRouter.get('/subjects/:id', adminController.getSubjectById);
adminRouter.patch('/subjects/:id', adminController.updateSubject);

// Curriculum Mapping
adminRouter.get('/curriculum', adminController.getCurriculumSubjects);
adminRouter.post('/curriculum', adminController.createCurriculumSubject);
adminRouter.delete('/curriculum/:id', adminController.deleteCurriculumSubject);

// Academic Classes & Sections
adminRouter.get('/classes', adminController.getAcademicClasses);
adminRouter.post('/classes', adminController.createAcademicClass);
adminRouter.get('/classes/:id', adminController.getAcademicClassById);
adminRouter.patch('/classes/:id', adminController.updateAcademicClass);

// Rooms & Physical Facilities
adminRouter.get('/rooms', adminController.getRooms);
adminRouter.post('/rooms', adminController.createRoom);
adminRouter.get('/rooms/:id', adminController.getRoomById);
adminRouter.patch('/rooms/:id', adminController.updateRoom);

// Faculty Subject Assignments
adminRouter.get('/faculty-assignments', adminController.getFacultyAssignments);
adminRouter.post('/faculty-assignments', adminController.createFacultyAssignment);
adminRouter.delete('/faculty-assignments/:id', adminController.deleteFacultyAssignment);

// Faculty Schedules & Timetable with Conflict Detection
adminRouter.get('/schedules', adminController.getSchedules);
adminRouter.post('/schedules', adminController.createSchedule);
adminRouter.get('/schedules/:id', adminController.getScheduleById);
adminRouter.patch('/schedules/:id', adminController.updateSchedule);
adminRouter.delete('/schedules/:id', adminController.deleteSchedule);

// Academic Monitoring (Phase 6: Attendance, Assignments, Assessments)
adminRouter.get('/monitoring/metrics', adminController.getMonitoringMetrics);
adminRouter.get('/monitoring/attendance', adminController.getAttendanceSessions);
adminRouter.get('/monitoring/attendance/:id', adminController.getAttendanceSessionById);
adminRouter.get('/monitoring/assignments', adminController.getSubjectAssignments);
adminRouter.get('/monitoring/assignments/:id', adminController.getSubjectAssignmentById);
adminRouter.get('/monitoring/assessments', adminController.getSubjectAssessments);
adminRouter.get('/monitoring/assessments/:id', adminController.getSubjectAssessmentById);

// Campus Moderation & Broadcast Notifications (Phase 7)
adminRouter.post('/broadcast-notification', adminController.sendBroadcastNotification);
adminRouter.get('/moderation/events', adminController.getModerationEvents);
adminRouter.delete('/moderation/events/:id', adminController.deleteModerationEvent);
adminRouter.get('/moderation/posts', adminController.getModerationPosts);
adminRouter.delete('/moderation/posts/:id', adminController.deleteModerationPost);

// Profile Change Requests (Institutional Admin Workflow)
adminRouter.get('/change-requests', adminController.getChangeRequests);
adminRouter.get('/change-requests/:id', adminController.getChangeRequestById);
adminRouter.post('/change-requests/:id/approve', requireRole('ADMIN'), adminController.approveChangeRequest);
adminRouter.post('/change-requests/:id/reject', requireRole('ADMIN'), adminController.rejectChangeRequest);



