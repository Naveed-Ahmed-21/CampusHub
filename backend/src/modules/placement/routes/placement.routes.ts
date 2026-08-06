import { Router } from 'express';
import { PlacementRepository } from '../placement.repository';
import { PlacementService } from '../placement.service';
import { PlacementController } from '../placement.controller';
import { authenticate } from '../../../shared/middlewares/auth.middleware';
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

placementRouter.use(authenticate);

// Dashboards
placementRouter.get('/dashboard/officer', placementController.getOfficerDashboard);
placementRouter.get('/dashboard/student', placementController.getStudentDashboard);

// Drives
placementRouter.get('/drives', placementController.getDrives);
placementRouter.post('/drives', validateRequest(createDriveSchema), placementController.createDrive);
placementRouter.get('/drives/:id', placementController.getDriveDetails);

// Applications & Eligibility
placementRouter.post('/apply', validateRequest(applyDriveSchema), placementController.applyForDrive);
placementRouter.patch('/applications/:applicationId/status', validateRequest(updateApplicationStatusSchema), placementController.updateApplicationStatus);

// Interviews & Offers
placementRouter.post('/interviews/schedule', validateRequest(scheduleInterviewSchema), placementController.scheduleInterview);
placementRouter.patch('/applications/:applicationId/offer-response', validateRequest(respondOfferSchema), placementController.respondToOffer);

export default placementRouter;
