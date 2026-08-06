import { Router } from 'express';
import { ProfileRepository } from './profile.repository';
import { ProfileService } from './profile.service';
import { ProfileController } from './profile.controller';
import { authenticate } from '../../shared/middlewares/auth.middleware';
import { validateRequest } from '../../shared/middlewares/validate.middleware';
import { updateProfileSchema, addSkillSchema, addProjectSchema } from './profile.validation';

const profileRepository = new ProfileRepository();
const profileService = new ProfileService(profileRepository);
const profileController = new ProfileController(profileService);

export const profileRouter = Router();

profileRouter.use(authenticate);

profileRouter.get('/', profileController.getProfile);
profileRouter.patch('/', validateRequest(updateProfileSchema), profileController.updateProfile);
profileRouter.post('/avatar', profileController.uploadAvatar);
profileRouter.post('/resume', profileController.uploadResume);

profileRouter.post('/skills', validateRequest(addSkillSchema), profileController.addSkill);
profileRouter.delete('/skills/:skillId', profileController.removeSkill);

profileRouter.post('/projects', validateRequest(addProjectSchema), profileController.addProject);
profileRouter.delete('/projects/:projectId', profileController.removeProject);
