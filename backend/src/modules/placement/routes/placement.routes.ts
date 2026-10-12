import { Router } from 'express';
import { PlacementRepository } from '../placement.repository';
import { PlacementService } from '../placement.service';
import { PlacementController } from '../placement.controller';
import { requireAuth, requireRole } from '../../../shared/middlewares/auth.middleware';
import { validateRequest } from '../../../shared/middlewares/validate.middleware';
import {
  createDriveSchema,
  updateDriveSchema,
  applyDriveSchema,
  updateApplicationStatusSchema,
  bulkUpdateStatusSchema,
  scheduleInterviewSchema,
  respondOfferSchema,
  createCompanySchema,
  updateCompanySchema,
  createResourceSchema,
} from '../placement.validation';

const placementRepository = new PlacementRepository();
const placementService = new PlacementService(placementRepository);
const placementController = new PlacementController(placementService);

export const placementRouter = Router();

placementRouter.use(requireAuth());

// ==========================================
// Dashboards & Analytics
// ==========================================
placementRouter.get(
  '/dashboard/officer',
  requireRole('PLACEMENT', 'ADMIN'),
  placementController.getOfficerDashboard
);
placementRouter.get(
  '/dashboard/department',
  requireRole('DEPT_ADMIN', 'ADMIN'),
  placementController.getDepartmentPlacementStats
);
placementRouter.get(
  '/dashboard/student',
  requireRole('STUDENT', 'ADMIN', 'DEPT_ADMIN', 'PLACEMENT', 'FACULTY'),
  placementController.getStudentDashboard
);

// ==========================================
// Drives
// ==========================================
placementRouter.get('/drives', placementController.getDrives);
placementRouter.post(
  '/drives',
  requireRole('PLACEMENT', 'ADMIN'),
  validateRequest(createDriveSchema),
  placementController.createDrive
);
placementRouter.get('/drives/:id', placementController.getDriveDetails);
placementRouter.patch(
  '/drives/:id',
  requireRole('PLACEMENT', 'ADMIN'),
  validateRequest(updateDriveSchema),
  placementController.updateDrive
);

// ==========================================
// Applications
// ==========================================
placementRouter.post(
  '/apply',
  requireRole('STUDENT', 'ADMIN'),
  validateRequest(applyDriveSchema),
  placementController.applyForDrive
);
placementRouter.get(
  '/applications',
  requireRole('PLACEMENT', 'ADMIN', 'DEPT_ADMIN'),
  placementController.getApplications
);
placementRouter.get(
  '/applications/:id',
  placementController.getApplicationById
);
placementRouter.post(
  '/applications/bulk-status',
  requireRole('PLACEMENT', 'ADMIN'),
  validateRequest(bulkUpdateStatusSchema),
  placementController.bulkUpdateApplicationStatus
);
placementRouter.patch(
  '/applications/:applicationId/status',
  requireRole('PLACEMENT', 'ADMIN'),
  validateRequest(updateApplicationStatusSchema),
  placementController.updateApplicationStatus
);
placementRouter.patch(
  '/applications/:applicationId/offer-response',
  requireRole('STUDENT', 'ADMIN'),
  validateRequest(respondOfferSchema),
  placementController.respondToOffer
);

// ==========================================
// Interviews
// ==========================================
placementRouter.get(
  '/interviews',
  placementController.getInterviews
);
placementRouter.post(
  '/interviews/schedule',
  requireRole('PLACEMENT', 'ADMIN'),
  validateRequest(scheduleInterviewSchema),
  placementController.scheduleInterview
);

// ==========================================
// Companies
// ==========================================
placementRouter.get(
  '/companies',
  placementController.getCompanies
);
placementRouter.get(
  '/companies/lookup',
  placementController.lookupCompany
);
placementRouter.post(
  '/companies',
  requireRole('PLACEMENT', 'ADMIN'),
  validateRequest(createCompanySchema),
  placementController.createCompany
);
placementRouter.get(
  '/companies/:id',
  placementController.getCompanyDetails
);
placementRouter.patch(
  '/companies/:id',
  requireRole('PLACEMENT', 'ADMIN'),
  validateRequest(updateCompanySchema),
  placementController.updateCompany
);

// ==========================================
// Preparation Resources
// ==========================================
placementRouter.get(
  '/resources',
  placementController.getResources
);
placementRouter.post(
  '/resources',
  requireRole('PLACEMENT', 'ADMIN', 'FACULTY'),
  validateRequest(createResourceSchema),
  placementController.createResource
);
placementRouter.get(
  '/resources/:id',
  placementController.getResourceDetails
);
placementRouter.delete(
  '/resources/:id',
  requireRole('PLACEMENT', 'ADMIN'),
  placementController.deleteResource
);

// ==========================================
// Students Directory & Placement Profile
// ==========================================
placementRouter.get(
  '/students',
  requireRole('PLACEMENT', 'ADMIN', 'DEPT_ADMIN', 'FACULTY'),
  placementController.getStudents
);
placementRouter.get(
  '/students/:id',
  placementController.getStudentProfile
);

export default placementRouter;
