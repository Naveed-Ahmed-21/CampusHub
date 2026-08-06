import { Router } from 'express';
import { authController } from '../controllers/auth.controller.js';
import { validateRequest } from '../../../shared/middlewares/validation.middleware.js';
import { registerSchema, loginSchema } from '../dtos/auth.dto.js';
import { authenticateJwt } from '../../../shared/middlewares/auth.middleware.js';

const router = Router();

router.post('/register', validateRequest(registerSchema), authController.register);
router.post('/login', validateRequest(loginSchema), authController.login);
router.get('/me', authenticateJwt, authController.getProfile);

export default router;
