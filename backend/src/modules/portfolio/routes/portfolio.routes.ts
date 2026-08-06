import { Router } from 'express';
import { PortfolioRepository } from '../portfolio.repository';
import { PortfolioService } from '../portfolio.service';
import { PortfolioController } from '../portfolio.controller';
import { authenticate } from '../../../shared/middlewares/auth.middleware';
import { validateRequest } from '../../../shared/middlewares/validate.middleware';
import {
  updatePortfolioSchema,
  addProjectSchema,
  addSkillSchema,
  addCertificateSchema,
  addAchievementSchema,
} from '../portfolio.validation';

const portfolioRepository = new PortfolioRepository();
const portfolioService = new PortfolioService(portfolioRepository);
const portfolioController = new PortfolioController(portfolioService);

export const portfolioRouter = Router();

// Public Portfolio Profile Endpoint (No authentication required)
portfolioRouter.get('/public/:identifier', portfolioController.getPublicPortfolio);

// Authenticated Routes
portfolioRouter.use(authenticate);

portfolioRouter.get('/me', portfolioController.getUserPortfolio);
portfolioRouter.patch('/me', validateRequest(updatePortfolioSchema), portfolioController.updatePortfolio);

// Projects
portfolioRouter.post('/projects', validateRequest(addProjectSchema), portfolioController.addProject);
portfolioRouter.delete('/projects/:id', portfolioController.deleteProject);

// Skills
portfolioRouter.post('/skills', validateRequest(addSkillSchema), portfolioController.addSkill);
portfolioRouter.delete('/skills/:id', portfolioController.deleteSkill);

// Certificates
portfolioRouter.post('/certificates', validateRequest(addCertificateSchema), portfolioController.addCertificate);
portfolioRouter.delete('/certificates/:id', portfolioController.deleteCertificate);

// Achievements
portfolioRouter.post('/achievements', validateRequest(addAchievementSchema), portfolioController.addAchievement);
portfolioRouter.delete('/achievements/:id', portfolioController.deleteAchievement);

export default portfolioRouter;
