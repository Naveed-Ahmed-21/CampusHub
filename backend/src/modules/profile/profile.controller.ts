import { Request, Response } from 'express';
import { ProfileService } from './profile.service';
import { asyncHandler } from '../../shared/utils/async-handler.util';

export class ProfileController {
  constructor(private readonly profileService: ProfileService) {}

  getProfile = asyncHandler(async (req: Request, res: Response) => {
    const profile = await this.profileService.getProfile(req.user!.userId);
    res.status(200).json({ success: true, data: profile });
  });

  updateProfile = asyncHandler(async (req: Request, res: Response) => {
    const profile = await this.profileService.updateProfile(req.user!.userId, req.body);
    res.status(200).json({ success: true, data: profile });
  });

  uploadAvatar = asyncHandler(async (req: Request, res: Response) => {
    const { avatarUrl } = req.body;
    const profile = await this.profileService.updateAvatar(req.user!.userId, avatarUrl || 'https://images.unsplash.com/photo-1534528741775-53994a69daeb');
    res.status(200).json({ success: true, data: profile });
  });

  uploadResume = asyncHandler(async (req: Request, res: Response) => {
    const { resumeUrl } = req.body;
    const profile = await this.profileService.updateResume(req.user!.userId, resumeUrl || 'https://campushub.edu/resumes/sample_resume.pdf');
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
