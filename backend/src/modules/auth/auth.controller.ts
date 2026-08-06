import { Request, Response } from 'express';
import { AuthService } from './auth.service';
import { asyncHandler } from '../../shared/utils/async-handler.util';

export class AuthController {
  constructor(private readonly authService: AuthService) {}

  register = asyncHandler(async (req: Request, res: Response) => {
    const result = await this.authService.register(req.body);
    res.status(201).json({ success: true, data: result });
  });

  login = asyncHandler(async (req: Request, res: Response) => {
    const result = await this.authService.login(req.body);
    res.status(200).json({ success: true, data: result });
  });

  refresh = asyncHandler(async (req: Request, res: Response) => {
    const token = req.body.refreshToken || req.body.refresh_token;
    const tokens = await this.authService.refreshTokens(token);
    res.status(200).json({ success: true, data: tokens });
  });

  logout = asyncHandler(async (req: Request, res: Response) => {
    await this.authService.logout(req.user!.userId);
    res.status(200).json({ success: true, message: 'Logged out successfully' });
  });

  forgotPassword = asyncHandler(async (req: Request, res: Response) => {
    const result = await this.authService.forgotPassword(req.body);
    res.status(200).json({ success: true, ...result });
  });

  resetPassword = asyncHandler(async (req: Request, res: Response) => {
    const result = await this.authService.resetPassword(req.body);
    res.status(200).json({ success: true, ...result });
  });

  getMe = asyncHandler(async (req: Request, res: Response) => {
    const user = await this.authService.getMe(req.user!.userId);
    res.status(200).json({ success: true, data: user });
  });
}
