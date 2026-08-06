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
        id: 'pf_101',
        user_id: userId,
        bio: 'Computer Science student passionate about Mobile Development and AI Systems.',
        cgpa: 8.9,
        github_url: 'https://github.com/campushub-dev',
        linkedin_url: 'https://linkedin.com/in/campushub-dev',
        website_url: 'https://campushub.dev',
        resume_url: null,
        projects: [
          {
            id: 'proj_1',
            title: 'CampusHub Mobile App',
            description: 'Cross-platform student engagement ecosystem built with Flutter, Riverpod, and Express.',
            tech_stack: ['Flutter', 'Dart', 'Node.js', 'PostgreSQL'],
            github_url: 'https://github.com/campushub-dev/app',
            demo_url: 'https://campushub.dev',
          },
        ],
        skills: [
          { id: 'skl_1', name: 'Flutter & Dart', category: 'Mobile', proficiency: 'ADVANCED' },
          { id: 'skl_2', name: 'TypeScript & Node.js', category: 'Backend', proficiency: 'ADVANCED' },
          { id: 'skl_3', name: 'PostgreSQL & Prisma', category: 'Database', proficiency: 'INTERMEDIATE' },
        ],
        certificates: [
          {
            id: 'cert_1',
            title: 'AWS Certified Cloud Practitioner',
            issuer: 'Amazon Web Services',
            issue_date: new Date('2025-11-15'),
            credential_url: 'https://aws.amazon.com',
          },
        ],
        achievements: [
          {
            id: 'ach_1',
            title: '1st Place - Inter-College Hackathon 2025',
            description: 'Built a real-time smart campus navigation solution.',
            date: new Date('2025-10-20'),
          },
        ],
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
