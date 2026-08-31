import { ProfileRepository } from './profile.repository';
import { NotFoundError } from '../../shared/errors/AppError';
import { UpdateProfileDTO, AddSkillDTO, AddProjectDTO, ProfileResponseDTO } from './profile.types';

export class ProfileService {
  constructor(private readonly profileRepo: ProfileRepository) {}

  async getProfile(userId: string, currentUserId?: string): Promise<ProfileResponseDTO> {
    const user = await this.profileRepo.getProfileByUserId(userId);
    if (!user) {
      throw new NotFoundError('User not found');
    }

    const stats = await this.profileRepo.getUserFollowStats(user.id, currentUserId);

    const handle = user.username
      ? (user.username.startsWith('@') ? user.username : `@${user.username}`)
      : `@${user.email.split('@')[0].toLowerCase()}`;

    return {
      id: user.id,
      email: user.email,
      username: handle,
      firstName: user.first_name,
      lastName: user.last_name,
      role: user.role,
      department: user.department ? { id: user.department.id, name: user.department.name } : null,
      rollNumber: user.roll_number,
      phone: user.phone,
      avatarUrl: user.avatar_url,
      bio: user.portfolio?.bio,
      githubUrl: user.portfolio?.github_url,
      linkedinUrl: user.portfolio?.linkedin_url,
      websiteUrl: user.portfolio?.website_url,
      resumeUrl: user.portfolio?.resume_url,
      followersCount: stats.followersCount,
      followingCount: stats.followingCount,
      postsCount: stats.postsCount ?? 0,
      isFollowing: stats.isFollowing,
      skills: (user.portfolio?.skills || []).map((s) => ({
        id: s.id,
        skillName: s.skill_name,
        proficiency: s.proficiency,
      })),
      projects: (user.portfolio?.projects || []).map((p) => ({
        id: p.id,
        title: p.title,
        description: p.description,
        projectUrl: p.project_url,
        repoUrl: p.repo_url,
      })),
    };
  }

  async getFollowers(userId: string, currentUserId?: string) {
    return this.profileRepo.getFollowers(userId, currentUserId);
  }

  async getFollowing(userId: string, currentUserId?: string) {
    return this.profileRepo.getFollowing(userId, currentUserId);
  }

  async toggleFollow(followerId: string, followingId: string) {
    return this.profileRepo.toggleFollow(followerId, followingId);
  }

  async updateProfile(userId: string, dto: UpdateProfileDTO): Promise<ProfileResponseDTO> {
    const avatar = dto.avatarUrl ?? (dto as any).avatar_url;
    if (dto.firstName || dto.lastName || dto.phone || avatar !== undefined) {
      await this.profileRepo.updateUser(userId, {
        firstName: dto.firstName,
        lastName: dto.lastName,
        phone: dto.phone,
        avatarUrl: avatar,
      });
    }

    if (dto.bio !== undefined || dto.githubUrl !== undefined || dto.linkedinUrl !== undefined || dto.websiteUrl !== undefined) {
      await this.profileRepo.upsertPortfolio(userId, {
        bio: dto.bio,
        githubUrl: dto.githubUrl,
        linkedinUrl: dto.linkedinUrl,
        websiteUrl: dto.websiteUrl,
      });
    }

    return this.getProfile(userId);
  }

  async updateAvatar(userId: string, avatarUrl: string): Promise<ProfileResponseDTO> {
    await this.profileRepo.updateUser(userId, { avatarUrl });
    return this.getProfile(userId);
  }

  async updateResume(userId: string, resumeUrl: string): Promise<ProfileResponseDTO> {
    await this.profileRepo.upsertPortfolio(userId, { resumeUrl });
    return this.getProfile(userId);
  }

  async addSkill(userId: string, dto: AddSkillDTO): Promise<ProfileResponseDTO> {
    const portfolio = await this.profileRepo.upsertPortfolio(userId, {});
    await this.profileRepo.addSkill(portfolio.id, dto.skillName, dto.proficiency);
    return this.getProfile(userId);
  }

  async removeSkill(userId: string, skillId: string): Promise<ProfileResponseDTO> {
    await this.profileRepo.removeSkill(skillId);
    return this.getProfile(userId);
  }

  async addProject(userId: string, dto: AddProjectDTO): Promise<ProfileResponseDTO> {
    const portfolio = await this.profileRepo.upsertPortfolio(userId, {});
    await this.profileRepo.addProject(portfolio.id, dto.title, dto.description, dto.projectUrl, dto.repoUrl);
    return this.getProfile(userId);
  }

  async removeProject(userId: string, projectId: string): Promise<ProfileResponseDTO> {
    await this.profileRepo.removeProject(projectId);
    return this.getProfile(userId);
  }
}
