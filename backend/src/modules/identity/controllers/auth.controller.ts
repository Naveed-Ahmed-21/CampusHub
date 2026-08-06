import { Request, Response, NextFunction } from 'express';
import { authService, AuthService } from '../services/auth.service.js';
import { ResponseUtil } from '../../../shared/utils/api-response.util.js';

export class AuthController {
  constructor(private service: AuthService = authService) {}

  register = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const result = await this.service.register(req.body);
      ResponseUtil.success(res, result, 'User registered successfully', 201);
    } catch (error) {
      next(error);
    }
  };

  login = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const result = await this.service.login(req.body);
      ResponseUtil.success(res, result, 'User authenticated successfully', 200);
    } catch (error) {
      next(error);
    }
  };

  getProfile = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      ResponseUtil.success(res, { user: req.user }, 'Profile retrieved successfully', 200);
    } catch (error) {
      next(error);
    }
  };
}

export const authController = new AuthController();
