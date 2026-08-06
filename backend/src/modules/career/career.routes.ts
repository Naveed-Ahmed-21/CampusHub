import { Router } from 'express';
import { CareerRepository } from './career.repository';
import { CareerService } from './career.service';
import { CareerController } from './career.controller';
import { authenticate } from '../../shared/middlewares/auth.middleware';
import { validateRequest } from '../../shared/middlewares/validate.middleware';
import {
  createWeeklyGoalSchema,
  toggleGoalSchema,
  toggleNodeProgressSchema,
  submitMiniProjectSchema,
} from './career.validation';

const careerRepository = new CareerRepository();
const careerService = new CareerService(careerRepository);
const careerController = new CareerController(careerService);

export const careerRouter = Router();

careerRouter.use(authenticate);

// Roadmaps & Node Progress
careerRouter.get('/roadmaps', careerController.getRoadmaps);
careerRouter.get('/roadmaps/:id', careerController.getRoadmapDetails);
careerRouter.get('/progress', careerController.getUserProgress);
careerRouter.post('/nodes/progress', validateRequest(toggleNodeProgressSchema), careerController.toggleNodeProgress);

// Weekly Goals
careerRouter.get('/goals', careerController.getWeeklyGoals);
careerRouter.post('/goals', validateRequest(createWeeklyGoalSchema), careerController.createWeeklyGoal);
careerRouter.patch('/goals/:goalId', validateRequest(toggleGoalSchema), careerController.toggleWeeklyGoal);

// Resume Tips
careerRouter.get('/resume-tips', careerController.getResumeTips);

// Placement Prep
careerRouter.get('/placement-prep', careerController.getPlacementPrep);

// Mini Projects
careerRouter.get('/mini-projects', careerController.getMiniProjects);
careerRouter.post('/mini-projects/submit', validateRequest(submitMiniProjectSchema), careerController.submitMiniProject);

export default careerRouter;
