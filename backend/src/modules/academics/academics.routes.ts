import { Router } from 'express';
import { AcademicsController } from './academics.controller';
import { requireAuth } from '../../shared/middlewares/auth.middleware';

export const academicsRouter: Router = Router();
const controller = new AcademicsController();

// Global Auth required for all academic actions
academicsRouter.use(requireAuth());

// Term-Driven Academic Context
academicsRouter.get('/current-term', controller.getCurrentTerm);
academicsRouter.get('/student/academic-context', controller.getStudentAcademicContext);
academicsRouter.get('/me', controller.getStudentAcademicContext);

// Subject Discovery & Search
academicsRouter.get('/subjects', controller.getSubjects);
academicsRouter.get('/subjects/enrolled', controller.getMySubjects);
academicsRouter.get('/subjects/:id', controller.getSubjectDetails);
academicsRouter.post('/subjects/:id/enroll', controller.enrollSubject);
academicsRouter.delete('/subjects/:id/enroll', controller.unenrollSubject);

// Academic Resource Discovery & Metrics
academicsRouter.get('/resources/search', controller.searchResources);
academicsRouter.post('/resources/:id/view', controller.viewResource);
academicsRouter.post('/resources/:id/download', controller.downloadResource);

// Faculty Academic Directory & Public Profile
academicsRouter.get('/faculty', controller.getFacultyDirectory);
academicsRouter.get('/faculty/:id', controller.getFacultyProfile);

// Student Assignments
academicsRouter.get('/subjects/:id/assignments', controller.getSubjectAssignments);
academicsRouter.get('/assignments/pending', controller.getPendingAssignments);
academicsRouter.post('/assignments/:id/submit', controller.submitAssignment);

// Student Attendance
academicsRouter.get('/subjects/:id/attendance', controller.getSubjectAttendance);
academicsRouter.get('/attendance/summary', controller.getOverallAttendanceSummary);

// Student Timetable
academicsRouter.get('/timetable', controller.getTimetable);
academicsRouter.get('/timetable/today', controller.getTodayTimetable);

// Student Assessments
academicsRouter.get('/subjects/:id/assessments', controller.getSubjectAssessments);
academicsRouter.get('/assessments/summary', controller.getAssessmentsSummary);


