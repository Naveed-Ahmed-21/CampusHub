import { prisma } from '../../config/database';
import { Portfolio, PortfolioSkill, PortfolioProject, User } from '@prisma/client';

export class ProfileRepository {
  async getProfileByUserId(userId: string) {
    return prisma.user.findUnique({
      where: { id: userId },
      include: {
        portfolio: {
          include: {
            skills: true,
            projects: true,
          },
        },
      },
    });
  }

  async updateUser(userId: string, data: { firstName?: string; lastName?: string; phone?: string; avatarUrl?: string }) {
    return prisma.user.update({
      where: { id: userId },
      data: {
        ...(data.firstName && { first_name: data.firstName }),
        ...(data.lastName && { last_name: data.lastName }),
        ...(data.phone !== undefined && { phone: data.phone }),
        ...(data.avatarUrl !== undefined && { avatar_url: data.avatarUrl }),
      },
    });
  }

  async upsertPortfolio(userId: string, data: { bio?: string; githubUrl?: string; linkedinUrl?: string; websiteUrl?: string; resumeUrl?: string }): Promise<Portfolio> {
    return prisma.portfolio.upsert({
      where: { user_id: userId },
      create: {
        user_id: userId,
        bio: data.bio,
        github_url: data.githubUrl,
        linkedin_url: data.linkedinUrl,
        website_url: data.websiteUrl,
        resume_url: data.resumeUrl,
      },
      update: {
        ...(data.bio !== undefined && { bio: data.bio }),
        ...(data.githubUrl !== undefined && { github_url: data.githubUrl }),
        ...(data.linkedinUrl !== undefined && { linkedin_url: data.linkedinUrl }),
        ...(data.websiteUrl !== undefined && { website_url: data.websiteUrl }),
        ...(data.resumeUrl !== undefined && { resume_url: data.resumeUrl }),
      },
    });
  }

  async addSkill(portfolioId: string, skillName: string, proficiency?: string): Promise<PortfolioSkill> {
    return prisma.portfolioSkill.create({
      data: {
        portfolio_id: portfolioId,
        skill_name: skillName,
        proficiency,
      },
    });
  }

  async removeSkill(skillId: string): Promise<void> {
    await prisma.portfolioSkill.delete({
      where: { id: skillId },
    });
  }

  async addProject(portfolioId: string, title: string, description?: string, projectUrl?: string, repoUrl?: string): Promise<PortfolioProject> {
    return prisma.portfolioProject.create({
      data: {
        portfolio_id: portfolioId,
        title,
        description,
        project_url: projectUrl,
        repo_url: repoUrl,
      },
    });
  }

  async removeProject(projectId: string): Promise<void> {
    await prisma.portfolioProject.delete({
      where: { id: projectId },
    });
  }
}
