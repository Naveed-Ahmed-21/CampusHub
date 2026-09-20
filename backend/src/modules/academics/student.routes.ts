import { Router } from 'express';
import { AcademicsController } from './academics.controller';
import { requireAuth } from '../../shared/middlewares/auth.middleware';

export const studentRouter: Router = Router();
const controller = new AcademicsController();

studentRouter.use(requireAuth());

// Student Academic Context & Auto-Derived Progression
studentRouter.get('/academic-context', controller.getStudentAcademicContext);
studentRouter.get('/subjects', controller.getMySubjects);
studentRouter.get('/timetable', controller.getTimetable);
studentRouter.get('/timetable/today', controller.getTodayTimetable);
studentRouter.get('/attendance', controller.getOverallAttendanceSummary);
studentRouter.get('/assessments', controller.getAssessmentsSummary);
studentRouter.get('/assignments/pending', controller.getPendingAssignments);
