import { PortfolioRepository } from './portfolio.repository';
import {
  UpdatePortfolioDto,
  AddProjectDto,
  AddSkillDto,
  AddCertificateDto,
  AddAchievementDto,
} from './portfolio.types';
import { NotFoundError } from '../../shared/errors/AppError';

export class PortfolioService {
  constructor(private readonly portfolioRepository: PortfolioRepository) {}

  async getUserPortfolio(userId: string) {
    try {
      return await this.portfolioRepository.findPortfolioByUserId(userId);
    } catch (_) {
      return {
        id: 'pf_' + userId,
        user_id: userId,
        bio: null,
        cgpa: 0.0,
        github_url: null,
        linkedin_url: null,
        website_url: null,
        resume_url: null,
        projects: [],
        skills: [],
        certificates: [],
        achievements: [],
      };
    }
  }

  async getPublicPortfolio(identifier: string) {
    let portfolio: any = undefined;
    try {
      portfolio = await this.portfolioRepository.findPublicPortfolio(identifier);
    } catch (_) {
      // Fallback
    }

    if (portfolio === null) {
      throw new NotFoundError('Public portfolio profile not found');
    }

    if (portfolio) return portfolio;

    return this.getUserPortfolio(identifier);
  }

  async updatePortfolio(userId: string, dto: UpdatePortfolioDto) {
    return this.portfolioRepository.updatePortfolio(userId, dto);
  }

  async addProject(userId: string, dto: AddProjectDto) {
    return this.portfolioRepository.addProject(userId, dto);
  }

  async deleteProject(userId: string, projectId: string) {
    return this.portfolioRepository.deleteProject(userId, projectId);
  }

  async addSkill(userId: string, dto: AddSkillDto) {
    return this.portfolioRepository.addSkill(userId, dto);
  }

  async deleteSkill(userId: string, skillId: string) {
    return this.portfolioRepository.deleteSkill(userId, skillId);
  }

  async addCertificate(userId: string, dto: AddCertificateDto) {
    return this.portfolioRepository.addCertificate(userId, dto);
  }

  async deleteCertificate(userId: string, certificateId: string) {
    return this.portfolioRepository.deleteCertificate(userId, certificateId);
  }

  async addAchievement(userId: string, dto: AddAchievementDto) {
    return this.portfolioRepository.addAchievement(userId, dto);
  }

  async deleteAchievement(userId: string, achievementId: string) {
    return this.portfolioRepository.deleteAchievement(userId, achievementId);
  }
}
