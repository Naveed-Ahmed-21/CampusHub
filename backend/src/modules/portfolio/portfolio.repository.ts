import { prisma } from '../../config/database';
import {
  UpdatePortfolioDto,
  AddProjectDto,
  AddSkillDto,
  AddCertificateDto,
  AddAchievementDto,
} from './portfolio.types';

export class PortfolioRepository {
  async findPortfolioByUserId(userId: string) {
    let portfolio = await prisma.portfolio.findUnique({
      where: { user_id: userId },
      include: {
        user: {
          select: {
            id: true,
            first_name: true,
            last_name: true,
            email: true,
            avatar_url: true,
            role: true,
            department: { select: { id: true, name: true, code: true } },
          },
        },
        projects: { orderBy: { created_at: 'desc' } },
        skills: true,
        certificates: { orderBy: { created_at: 'desc' } },
        achievements: { orderBy: { created_at: 'desc' } },
      },
    });

    if (!portfolio) {
      portfolio = await prisma.portfolio.create({
        data: { user_id: userId },
        include: {
          user: {
            select: {
              id: true,
              first_name: true,
              last_name: true,
              email: true,
              avatar_url: true,
              role: true,
              department: { select: { id: true, name: true, code: true } },
            },
          },
          projects: true,
          skills: true,
          certificates: true,
          achievements: true,
        },
      });
    }

    return portfolio;
  }

  async findPublicPortfolio(identifier: string) {
    return prisma.portfolio.findFirst({
      where: {
        is_public: true,
        OR: [{ user_id: identifier }, { custom_username: identifier }],
      },
      include: {
        user: {
          select: {
            id: true,
            first_name: true,
            last_name: true,
            email: true,
            avatar_url: true,
            role: true,
            department: { select: { id: true, name: true, code: true } },
          },
        },
        projects: { orderBy: { created_at: 'desc' } },
        skills: true,
        certificates: { orderBy: { created_at: 'desc' } },
        achievements: { orderBy: { created_at: 'desc' } },
      },
    });
  }

  async updatePortfolio(userId: string, dto: UpdatePortfolioDto) {
    const portfolio = await this.findPortfolioByUserId(userId);

    return prisma.portfolio.update({
      where: { id: portfolio.id },
      data: {
        bio: dto.bio,
        github_url: dto.github_url,
        linkedin_url: dto.linkedin_url,
        website_url: dto.website_url,
        resume_url: dto.resume_url,
        cgpa: dto.cgpa,
        custom_username: dto.custom_username,
        is_public: dto.is_public,
      },
      include: {
        projects: true,
        skills: true,
        certificates: true,
        achievements: true,
      },
    });
  }

  async addProject(userId: string, dto: AddProjectDto) {
    const portfolio = await this.findPortfolioByUserId(userId);

    return prisma.portfolioProject.create({
      data: {
        portfolio_id: portfolio.id,
        title: dto.title,
        description: dto.description,
        tech_stack: dto.tech_stack || [],
        project_url: dto.project_url,
        repo_url: dto.repo_url,
        image_url: dto.image_url,
      },
    });
  }

  async deleteProject(userId: string, projectId: string) {
    const portfolio = await this.findPortfolioByUserId(userId);
    return prisma.portfolioProject.deleteMany({
      where: { id: projectId, portfolio_id: portfolio.id },
    });
  }

  async addSkill(userId: string, dto: AddSkillDto) {
    const portfolio = await this.findPortfolioByUserId(userId);

    return prisma.portfolioSkill.create({
      data: {
        portfolio_id: portfolio.id,
        skill_name: dto.skill_name,
        category: dto.category || 'General',
        proficiency: dto.proficiency || 'Intermediate',
      },
    });
  }

  async deleteSkill(userId: string, skillId: string) {
    const portfolio = await this.findPortfolioByUserId(userId);
    return prisma.portfolioSkill.deleteMany({
      where: { id: skillId, portfolio_id: portfolio.id },
    });
  }

  async addCertificate(userId: string, dto: AddCertificateDto) {
    const portfolio = await this.findPortfolioByUserId(userId);

    return prisma.portfolioCertificate.create({
      data: {
        portfolio_id: portfolio.id,
        title: dto.title,
        issuer: dto.issuer,
        issue_date: dto.issue_date ? new Date(dto.issue_date) : null,
        credential_url: dto.credential_url,
        credential_id: dto.credential_id,
      },
    });
  }

  async deleteCertificate(userId: string, certificateId: string) {
    const portfolio = await this.findPortfolioByUserId(userId);
    return prisma.portfolioCertificate.deleteMany({
      where: { id: certificateId, portfolio_id: portfolio.id },
    });
  }

  async addAchievement(userId: string, dto: AddAchievementDto) {
    const portfolio = await this.findPortfolioByUserId(userId);

    return prisma.portfolioAchievement.create({
      data: {
        portfolio_id: portfolio.id,
        title: dto.title,
        category: dto.category || 'General',
        description: dto.description,
        date_achieved: dto.date_achieved ? new Date(dto.date_achieved) : null,
        proof_url: dto.proof_url,
      },
    });
  }

  async deleteAchievement(userId: string, achievementId: string) {
    const portfolio = await this.findPortfolioByUserId(userId);
    return prisma.portfolioAchievement.deleteMany({
      where: { id: achievementId, portfolio_id: portfolio.id },
    });
  }
}
