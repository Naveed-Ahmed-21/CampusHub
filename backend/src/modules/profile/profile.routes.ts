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
profileRouter.get('/followers', profileController.getFollowers);
profileRouter.get('/following', profileController.getFollowing);
profileRouter.get('/user/:userId/followers', profileController.getFollowers);
profileRouter.get('/user/:userId/following', profileController.getFollowing);
profileRouter.get('/:userId/followers', profileController.getFollowers);
profileRouter.get('/:userId/following', profileController.getFollowing);
profileRouter.get('/user/:userId', profileController.getUserProfileById);
profileRouter.get('/:userId', profileController.getUserProfileById);
profileRouter.post('/follow/:targetUserId', profileController.toggleFollow);
profileRouter.post('/user/:userId/follow', profileController.toggleFollow);
profileRouter.post('/:userId/follow', profileController.toggleFollow);
profileRouter.patch('/', validateRequest(updateProfileSchema), profileController.updateProfile);
profileRouter.post('/avatar', profileController.uploadAvatar);
profileRouter.post('/resume', profileController.uploadResume);

profileRouter.post('/skills', validateRequest(addSkillSchema), profileController.addSkill);
profileRouter.delete('/skills/:skillId', profileController.removeSkill);

profileRouter.post('/projects', validateRequest(addProjectSchema), profileController.addProject);
profileRouter.delete('/projects/:projectId', profileController.removeProject);
