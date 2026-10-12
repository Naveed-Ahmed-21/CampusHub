import { Router } from 'express';
import { AuthRepository } from './auth.repository';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { validateRequest } from '../../shared/middlewares/validate.middleware';
import { authenticate } from '../../shared/middlewares/auth.middleware';
import {
  registerSchema,
  loginSchema,
  refreshTokenSchema,
  forgotPasswordSchema,
  resetPasswordSchema,
  checkStatusSchema,
  setupPasswordSchema,
  sendFirstLoginOtpSchema,
  verifyFirstLoginOtpSchema,
  verifyForgotPasswordOtpSchema,
  changePasswordSchema,
} from './auth.validation';

const authRepository = new AuthRepository();
const authService = new AuthService(authRepository);
const authController = new AuthController(authService);

export const authRouter = Router();

authRouter.post('/register', validateRequest(registerSchema), authController.register);
authRouter.post('/login', validateRequest(loginSchema), authController.login);
authRouter.post('/check-status', validateRequest(checkStatusSchema), authController.checkStatus);
authRouter.post('/setup-password', validateRequest(setupPasswordSchema), authController.setupPassword);
authRouter.post('/send-first-login-otp', validateRequest(sendFirstLoginOtpSchema), authController.sendFirstLoginOtp);
authRouter.post('/verify-first-login-otp', validateRequest(verifyFirstLoginOtpSchema), authController.verifyFirstLoginOtp);
authRouter.post('/refresh', validateRequest(refreshTokenSchema), authController.refresh);
authRouter.post('/forgot-password', validateRequest(forgotPasswordSchema), authController.forgotPassword);
authRouter.post('/forgot-password-otp', validateRequest(forgotPasswordSchema), authController.forgotPassword);
authRouter.post('/verify-forgot-password-otp', validateRequest(verifyForgotPasswordOtpSchema), authController.verifyForgotPasswordOtp);
authRouter.post('/reset-password', validateRequest(resetPasswordSchema), authController.resetPassword);


// Protected routes
authRouter.post('/logout', authenticate, authController.logout);
authRouter.get('/me', authenticate, authController.getMe);
authRouter.post('/change-password', authenticate, validateRequest(changePasswordSchema), authController.changePassword);
