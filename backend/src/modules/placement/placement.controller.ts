import { Request, Response } from 'express';
import { PlacementService } from './placement.service';
import { asyncHandler } from '../../shared/utils/async-handler.util';
import { ResponseUtil } from '../../shared/utils/api-response.util';
import { DriveStatus } from '@prisma/client';

export class PlacementController {
  constructor(private readonly placementService: PlacementService) {}

  getOfficerDashboard = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const stats = await this.placementService.getOfficerDashboard(user.collegeId, user.role);
    ResponseUtil.success(res, stats, 'Placement officer dashboard metrics retrieved');
  });

  getStudentDashboard = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const stats = await this.placementService.getStudentDashboard(user.userId);
    ResponseUtil.success(res, stats, 'Student placement dashboard retrieved');
  });

  createDrive = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const drive = await this.placementService.createDrive(user.collegeId, user.role, req.body);
    ResponseUtil.success(res, drive, 'Placement drive created successfully', 201);
  });

  getDrives = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const query = {
      status: req.query.status as DriveStatus,
      search: req.query.search as string,
      page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 20,
    };
    const drives = await this.placementService.getDrives(user.collegeId, query);
    ResponseUtil.success(res, drives, 'Placement drives retrieved successfully');
  });

  getDriveDetails = asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params;
    const drive = await this.placementService.getDriveDetails(id);
    ResponseUtil.success(res, drive, 'Placement drive details retrieved');
  });

  applyForDrive = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const application = await this.placementService.applyForDrive(user.userId, user.collegeId, req.body);
    ResponseUtil.success(res, application, 'Applied for placement drive successfully', 201);
  });

  updateApplicationStatus = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { applicationId } = req.params;
    const application = await this.placementService.updateApplicationStatus(applicationId, user.role, req.body);
    ResponseUtil.success(res, application, 'Application status updated');
  });

  scheduleInterview = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const interview = await this.placementService.scheduleInterview(user.role, req.body);
    ResponseUtil.success(res, interview, 'Interview scheduled successfully', 201);
  });

  respondToOffer = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { applicationId } = req.params;
    const application = await this.placementService.respondToOffer(applicationId, user.userId, req.body);
    ResponseUtil.success(res, application, 'Offer response updated successfully');
  });
}
