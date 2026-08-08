import { Router } from 'express';
import { PlacementRepository } from '../placement.repository';
import { PlacementService } from '../placement.service';
import { PlacementController } from '../placement.controller';
import { requireAuth, requireRole } from '../../../shared/middlewares/auth.middleware';
import { validateRequest } from '../../../shared/middlewares/validate.middleware';
import {
  createDriveSchema,
  applyDriveSchema,
  updateApplicationStatusSchema,
  scheduleInterviewSchema,
  respondOfferSchema,
} from '../placement.validation';

const placementRepository = new PlacementRepository();
const placementService = new PlacementService(placementRepository);
const placementController = new PlacementController(placementService);

export const placementRouter = Router();

placementRouter.use(requireAuth());

// Dashboards
placementRouter.get('/dashboard/officer', requireRole('PLACEMENT_OFFICER', 'ADMIN'), placementController.getOfficerDashboard);
placementRouter.get('/dashboard/student', requireRole('STUDENT', 'ADMIN'), placementController.getStudentDashboard);

// Drives
placementRouter.get('/drives', placementController.getDrives);
placementRouter.post('/drives', requireRole('PLACEMENT_OFFICER', 'ADMIN'), validateRequest(createDriveSchema), placementController.createDrive);
placementRouter.get('/drives/:id', placementController.getDriveDetails);

// Applications & Eligibility
placementRouter.post('/apply', requireRole('STUDENT', 'ADMIN'), validateRequest(applyDriveSchema), placementController.applyForDrive);
placementRouter.patch('/applications/:applicationId/status', requireRole('PLACEMENT_OFFICER', 'ADMIN'), validateRequest(updateApplicationStatusSchema), placementController.updateApplicationStatus);

// Interviews & Offers
placementRouter.post('/interviews/schedule', requireRole('PLACEMENT_OFFICER', 'ADMIN'), validateRequest(scheduleInterviewSchema), placementController.scheduleInterview);
placementRouter.patch('/applications/:applicationId/offer-response', requireRole('STUDENT', 'ADMIN'), validateRequest(respondOfferSchema), placementController.respondToOffer);

export default placementRouter;
