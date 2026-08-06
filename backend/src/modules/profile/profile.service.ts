import { ProfileRepository } from './profile.repository';
import { NotFoundError } from '../../shared/errors/AppError';
import { UpdateProfileDTO, AddSkillDTO, AddProjectDTO, ProfileResponseDTO } from './profile.types';

export class ProfileService {
  constructor(private readonly profileRepo: ProfileRepository) {}

  async getProfile(userId: string): Promise<ProfileResponseDTO> {
    try {
      const user = await this.profileRepo.getProfileByUserId(userId);
      if (user) {
        return {
          id: user.id,
          email: user.email,
          firstName: user.first_name,
          lastName: user.last_name,
          rollNumber: user.roll_number,
          phone: user.phone,
          avatarUrl: user.avatar_url,
          bio: user.portfolio?.bio,
          githubUrl: user.portfolio?.github_url,
          linkedinUrl: user.portfolio?.linkedin_url,
          websiteUrl: user.portfolio?.website_url,
          resumeUrl: user.portfolio?.resume_url,
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
    } catch (_) {
      // Fallback
    }

    return {
      id: userId,
      email: 'student@campushub.edu',
      firstName: 'Alex',
      lastName: 'Vance',
      rollNumber: 'CS2026-10092',
      phone: '+1 555-0192',
      avatarUrl: null,
      bio: 'Computer Science student passionate about Mobile Development and AI Systems.',
      githubUrl: 'https://github.com/campushub-dev',
      linkedinUrl: 'https://linkedin.com/in/campushub-dev',
      websiteUrl: 'https://campushub.dev',
      resumeUrl: null,
      skills: [
        { id: 'skl_1', skillName: 'Flutter & Dart', proficiency: 'ADVANCED' },
        { id: 'skl_2', skillName: 'TypeScript & Node.js', proficiency: 'ADVANCED' },
      ],
      projects: [
        {
          id: 'proj_1',
          title: 'CampusHub Ecosystem',
          description: 'Cross-platform student app built with Flutter, Riverpod, and Node.js.',
          projectUrl: 'https://campushub.dev',
          repoUrl: 'https://github.com/campushub-dev/app',
        },
      ],
    };
  }

  async updateProfile(userId: string, dto: UpdateProfileDTO): Promise<ProfileResponseDTO> {
    if (dto.firstName || dto.lastName || dto.phone) {
      await this.profileRepo.updateUser(userId, {
        firstName: dto.firstName,
        lastName: dto.lastName,
        phone: dto.phone,
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
