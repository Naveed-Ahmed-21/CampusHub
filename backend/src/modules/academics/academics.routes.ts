import { Router } from 'express';
import { AcademicsController } from './academics.controller';
import { requireAuth } from '../../shared/middlewares/auth.middleware';

export const academicsRouter: Router = Router();
const controller = new AcademicsController();

// Global Auth required for all academic actions
academicsRouter.use(requireAuth());

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
