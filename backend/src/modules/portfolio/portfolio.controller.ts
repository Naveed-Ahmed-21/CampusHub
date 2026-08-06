import { Request, Response } from 'express';
import { PortfolioService } from './portfolio.service';
import { asyncHandler } from '../../shared/utils/async-handler.util';
import { ResponseUtil } from '../../shared/utils/api-response.util';

export class PortfolioController {
  constructor(private readonly portfolioService: PortfolioService) {}

  getUserPortfolio = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const portfolio = await this.portfolioService.getUserPortfolio(user.userId);
    ResponseUtil.success(res, portfolio, 'User portfolio retrieved successfully');
  });

  getPublicPortfolio = asyncHandler(async (req: Request, res: Response) => {
    const { identifier } = req.params;
    const portfolio = await this.portfolioService.getPublicPortfolio(identifier);
    ResponseUtil.success(res, portfolio, 'Public portfolio profile retrieved');
  });

  updatePortfolio = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const portfolio = await this.portfolioService.updatePortfolio(user.userId, req.body);
    ResponseUtil.success(res, portfolio, 'Portfolio updated successfully');
  });

  addProject = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const project = await this.portfolioService.addProject(user.userId, req.body);
    ResponseUtil.success(res, project, 'Project added to portfolio', 201);
  });

  deleteProject = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { id } = req.params;
    await this.portfolioService.deleteProject(user.userId, id);
    ResponseUtil.success(res, null, 'Project deleted');
  });

  addSkill = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const skill = await this.portfolioService.addSkill(user.userId, req.body);
    ResponseUtil.success(res, skill, 'Skill added to portfolio', 201);
  });

  deleteSkill = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { id } = req.params;
    await this.portfolioService.deleteSkill(user.userId, id);
    ResponseUtil.success(res, null, 'Skill deleted');
  });

  addCertificate = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const cert = await this.portfolioService.addCertificate(user.userId, req.body);
    ResponseUtil.success(res, cert, 'Certificate added to portfolio', 201);
  });

  deleteCertificate = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { id } = req.params;
    await this.portfolioService.deleteCertificate(user.userId, id);
    ResponseUtil.success(res, null, 'Certificate deleted');
  });

  addAchievement = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const achievement = await this.portfolioService.addAchievement(user.userId, req.body);
    ResponseUtil.success(res, achievement, 'Achievement added to portfolio', 201);
  });

  deleteAchievement = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { id } = req.params;
    await this.portfolioService.deleteAchievement(user.userId, id);
    ResponseUtil.success(res, null, 'Achievement deleted');
  });
}
