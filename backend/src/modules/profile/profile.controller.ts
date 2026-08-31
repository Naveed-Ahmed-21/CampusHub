import { Request, Response } from 'express';
import { ProfileService } from './profile.service';
import { asyncHandler } from '../../shared/utils/async-handler.util';

export class ProfileController {
  constructor(private readonly profileService: ProfileService) {}

  getProfile = asyncHandler(async (req: Request, res: Response) => {
    const profile = await this.profileService.getProfile(req.user!.userId, req.user!.userId);
    res.status(200).json({ success: true, data: profile });
  });

  getUserProfileById = asyncHandler(async (req: Request, res: Response) => {
    const targetUserId = req.params.userId;
    const profile = await this.profileService.getProfile(targetUserId, req.user!.userId);
    res.status(200).json({ success: true, data: profile });
  });

  getFollowers = asyncHandler(async (req: Request, res: Response) => {
    const targetUserId = req.params.userId || req.user!.userId;
    const followers = await this.profileService.getFollowers(targetUserId, req.user!.userId);
    res.status(200).json({ success: true, data: followers });
  });

  getFollowing = asyncHandler(async (req: Request, res: Response) => {
    const targetUserId = req.params.userId || req.user!.userId;
    const following = await this.profileService.getFollowing(targetUserId, req.user!.userId);
    res.status(200).json({ success: true, data: following });
  });

  toggleFollow = asyncHandler(async (req: Request, res: Response) => {
    const targetUserId = req.params.targetUserId || req.params.userId;
    const result = await this.profileService.toggleFollow(req.user!.userId, targetUserId);
    res.status(200).json({ success: true, data: result });
  });

  updateProfile = asyncHandler(async (req: Request, res: Response) => {
    const profile = await this.profileService.updateProfile(req.user!.userId, req.body);
    res.status(200).json({ success: true, data: profile });
  });

  uploadAvatar = asyncHandler(async (req: Request, res: Response) => {
    const avatarUrl = req.body?.avatarUrl || req.body?.avatar_url || req.body?.url || '';
    const profile = await this.profileService.updateAvatar(req.user!.userId, avatarUrl);
    res.status(200).json({ success: true, data: profile });
  });

  uploadResume = asyncHandler(async (req: Request, res: Response) => {
    const resumeUrl = req.body?.resumeUrl || req.body?.resume_url || req.body?.url || '';
    const profile = await this.profileService.updateResume(req.user!.userId, resumeUrl);
    res.status(200).json({ success: true, data: profile });
  });

  addSkill = asyncHandler(async (req: Request, res: Response) => {
    const profile = await this.profileService.addSkill(req.user!.userId, req.body);
    res.status(201).json({ success: true, data: profile });
  });

  removeSkill = asyncHandler(async (req: Request, res: Response) => {
    const skillId = req.params.skillId;
    const profile = await this.profileService.removeSkill(req.user!.userId, skillId);
    res.status(200).json({ success: true, data: profile });
  });

  addProject = asyncHandler(async (req: Request, res: Response) => {
    const profile = await this.profileService.addProject(req.user!.userId, req.body);
    res.status(201).json({ success: true, data: profile });
  });

  removeProject = asyncHandler(async (req: Request, res: Response) => {
    const projectId = req.params.projectId;
    const profile = await this.profileService.removeProject(req.user!.userId, projectId);
    res.status(200).json({ success: true, data: profile });
  });
}
