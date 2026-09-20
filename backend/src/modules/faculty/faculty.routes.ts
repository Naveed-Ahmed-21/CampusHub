import { Router } from 'express';
import { FacultyController } from './faculty.controller';
import { requireAuth, requireRole } from '../../shared/middlewares/auth.middleware';
import { validateRequest } from '../../shared/middlewares/validate.middleware';
import {
  createSubjectSchema,
  updateSubjectSchema,
  createSubjectResourceSchema,
  updateSubjectResourceSchema,
  createSubjectAnnouncementSchema,
  updateFacultyProfileSchema,
} from './faculty.validation';

export const facultyRouter: Router = Router();
const controller = new FacultyController();

// Global RBAC: Faculty and Admin privileges required
facultyRouter.use(requireAuth());
facultyRouter.use(requireRole('FACULTY', 'ADMIN', 'COLLEGE_ADMIN', 'SUPER_ADMIN'));

// Dashboard & Overview
facultyRouter.get('/dashboard', controller.getDashboard);
facultyRouter.get('/academic-context', controller.getAcademicContext);

// Subject / Course Management
facultyRouter.get('/subjects', controller.getSubjects);
facultyRouter.post('/subjects', validateRequest(createSubjectSchema), controller.createSubject);
facultyRouter.get('/subjects/:id', controller.getSubjectDetails);
facultyRouter.put('/subjects/:id', validateRequest(updateSubjectSchema), controller.updateSubject);
facultyRouter.delete('/subjects/:id', controller.deleteSubject);

// Subject Resources & Materials
facultyRouter.post('/subjects/:id/resources', validateRequest(createSubjectResourceSchema), controller.addSubjectResource);
facultyRouter.put('/subjects/:id/resources/:resourceId', validateRequest(updateSubjectResourceSchema), controller.updateSubjectResource);
facultyRouter.delete('/subjects/:id/resources/:resourceId', controller.deleteSubjectResource);

// Subject Announcements
facultyRouter.post('/subjects/:id/announcements', validateRequest(createSubjectAnnouncementSchema), controller.addSubjectAnnouncement);

// Faculty Profile Management
facultyRouter.get('/profile', controller.getProfile);
facultyRouter.put('/profile', validateRequest(updateFacultyProfileSchema), controller.updateProfile);

// Today's Timetable / Schedule
facultyRouter.get('/classes/today', controller.getTodaySchedule);
facultyRouter.post('/classes/schedule', controller.createScheduleSlot);
facultyRouter.put('/classes/schedule/:id', controller.updateScheduleSlot);
facultyRouter.delete('/classes/schedule/:id', controller.deleteScheduleSlot);

// Student Mentoring Roster
facultyRouter.get('/mentees', controller.getMentees);

// Assignments Management
facultyRouter.post('/subjects/:id/assignments', controller.createAssignment);
facultyRouter.get('/subjects/:id/assignments', controller.getSubjectAssignments);
facultyRouter.get('/assignments/:id/submissions', controller.getAssignmentSubmissions);
facultyRouter.post('/assignments/:id/submissions/:submissionId/grade', controller.gradeSubmission);

// Attendance Sessions
facultyRouter.post('/subjects/:id/attendance', controller.recordAttendance);
facultyRouter.get('/subjects/:id/attendance', controller.getAttendanceSessions);
facultyRouter.get('/sessions/:sessionId/attendance', controller.getSessionAttendance);
facultyRouter.post('/attendance/bulk', controller.bulkRecordAttendance);
facultyRouter.patch('/attendance/:recordId', controller.updateAttendanceRecord);
facultyRouter.patch('/sessions/:sessionId/lock', controller.toggleSessionLock);

// Assessments & Continuous Evaluation
facultyRouter.post('/subjects/:id/assessments', controller.createAssessment);
facultyRouter.get('/subjects/:id/assessments', controller.getSubjectAssessments);
facultyRouter.get('/assessments/:id/results', controller.getAssessmentResults);
facultyRouter.post('/assessments/:id/results', controller.recordAssessmentMarks);


