import { Router } from 'express';
import { FacultyController } from './faculty.controller';
import { requireAuth, requireRole } from '../../shared/middlewares/auth.middleware';
import { validateRequest } from '../../shared/middlewares/validate.middleware';
import {
  createSubjectSchema,
  createSubjectResourceSchema,
  createSubjectAnnouncementSchema,
} from './faculty.validation';

export const facultyRouter: Router = Router();
const controller = new FacultyController();

// Global RBAC: Faculty and Admin privileges required
facultyRouter.use(requireAuth());
facultyRouter.use(requireRole('FACULTY', 'ADMIN', 'COLLEGE_ADMIN', 'SUPER_ADMIN'));

// Dashboard & Overview
facultyRouter.get('/dashboard', controller.getDashboard);

// Subject / Course Management
facultyRouter.get('/subjects', controller.getSubjects);
facultyRouter.post('/subjects', validateRequest(createSubjectSchema), controller.createSubject);
facultyRouter.get('/subjects/:id', controller.getSubjectDetails);

// Subject Resources & Materials (ImageKit upload link metadata)
facultyRouter.post('/subjects/:id/resources', validateRequest(createSubjectResourceSchema), controller.addSubjectResource);
facultyRouter.delete('/subjects/:id/resources/:resourceId', controller.deleteSubjectResource);

// Subject Announcements
facultyRouter.post('/subjects/:id/announcements', validateRequest(createSubjectAnnouncementSchema), controller.addSubjectAnnouncement);

// Today's Timetable / Schedule
facultyRouter.get('/classes/today', controller.getTodaySchedule);

// Student Mentoring Roster
facultyRouter.get('/mentees', controller.getMentees);
