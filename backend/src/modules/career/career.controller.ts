import { Request, Response } from 'express';
import { CareerService } from './career.service';
import { asyncHandler } from '../../shared/utils/async-handler.util';
import { ResponseUtil } from '../../shared/utils/api-response.util';

export class CareerController {
  constructor(private readonly careerService: CareerService) {}

  getRoadmaps = asyncHandler(async (req: Request, res: Response) => {
    const query = {
      category: req.query.category as string,
      level: req.query.level as string,
      search: req.query.search as string,
    };
    const roadmaps = await this.careerService.getRoadmaps(query);
    ResponseUtil.success(res, roadmaps, 'Career roadmaps retrieved successfully');
  });

  getRoadmapDetails = asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params;
    const roadmap = await this.careerService.getRoadmapDetails(id);
    ResponseUtil.success(res, roadmap, 'Roadmap details retrieved');
  });

  getUserProgress = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const progress = await this.careerService.getUserProgress(user.userId);
    ResponseUtil.success(res, progress, 'User progress retrieved successfully');
  });

  toggleNodeProgress = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { node_id, is_completed } = req.body;
    const result = await this.careerService.toggleNodeProgress(user.userId, node_id, is_completed);
    ResponseUtil.success(res, result, 'Roadmap node progress updated');
  });

  getWeeklyGoals = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const goals = await this.careerService.getWeeklyGoals(user.userId);
    ResponseUtil.success(res, goals, 'Weekly goals retrieved');
  });

  createWeeklyGoal = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const goal = await this.careerService.createWeeklyGoal(user.userId, req.body);
    ResponseUtil.success(res, goal, 'Weekly goal created', 201);
  });

  toggleWeeklyGoal = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { goalId } = req.params;
    const { is_completed } = req.body;
    const goal = await this.careerService.toggleWeeklyGoal(goalId, user.userId, is_completed);
    ResponseUtil.success(res, goal, 'Weekly goal updated');
  });

  getResumeTips = asyncHandler(async (_req: Request, res: Response) => {
    const tips = await this.careerService.getResumeTips();
    ResponseUtil.success(res, tips, 'Resume tips retrieved');
  });

  getPlacementPrep = asyncHandler(async (_req: Request, res: Response) => {
    const modules = await this.careerService.getPlacementPrepModules();
    ResponseUtil.success(res, modules, 'Placement preparation modules retrieved');
  });

  getMiniProjects = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const projects = await this.careerService.getMiniProjects(user.userId);
    ResponseUtil.success(res, projects, 'Mini projects retrieved');
  });

  submitMiniProject = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const submission = await this.careerService.submitMiniProject(user.userId, req.body);
    ResponseUtil.success(res, submission, 'Mini project submitted successfully', 201);
  });
}
