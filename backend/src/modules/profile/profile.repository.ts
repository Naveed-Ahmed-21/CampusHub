import { prisma } from '../../config/database';
import { Portfolio, PortfolioSkill, PortfolioProject, User } from '@prisma/client';

export class ProfileRepository {
  async getProfileByUserId(userId: string) {
    const cleanHandle = userId.startsWith('@') ? userId.slice(1) : userId;
    return prisma.user.findFirst({
      where: {
        OR: [
          { id: userId },
          { username: userId },
          { username: cleanHandle },
          { username: `@${cleanHandle}` },
        ],
      },
      include: {
        department: { select: { id: true, name: true, code: true } },
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

  async toggleFollow(followerId: string, followingId: string): Promise<{ isFollowing: boolean; followersCount: number; followingCount?: number }> {
    if (followerId === followingId) {
      throw new Error('You cannot follow yourself');
    }

    const existing = await prisma.userFollow.findUnique({
      where: {
        follower_id_following_id: {
          follower_id: followerId,
          following_id: followingId,
        },
      },
    });

    if (existing) {
      await prisma.userFollow.delete({
        where: { id: existing.id },
      });
    } else {
      await prisma.userFollow.create({
        data: {
          follower_id: followerId,
          following_id: followingId,
        },
      });
    }

    const followersCount = await prisma.userFollow.count({
      where: { following_id: followingId },
    });

    const followingCount = await prisma.userFollow.count({
      where: { follower_id: followerId },
    });

    return { isFollowing: !existing, followersCount, followingCount };
  }

  async getUserFollowStats(userId: string, currentUserId?: string) {
    const [followersCount, followingCount, isFollowing, postsCount] = await Promise.all([
      prisma.userFollow.count({ where: { following_id: userId } }),
      prisma.userFollow.count({ where: { follower_id: userId } }),
      currentUserId && currentUserId !== userId
        ? prisma.userFollow.findUnique({
            where: {
              follower_id_following_id: {
                follower_id: currentUserId,
                following_id: userId,
              },
            },
          }).then((r) => !!r)
        : Promise.resolve(false),
      prisma.post.count({
        where: { author_id: userId },
      }),
    ]);

    return { followersCount, followingCount, isFollowing, postsCount };
  }

  async getFollowers(userId: string, currentUserId?: string) {
    const followerSelect: any = {
      id: true,
      username: true,
      first_name: true,
      last_name: true,
      email: true,
      avatar_url: true,
      role: true,
      department: { select: { id: true, name: true, code: true } },
    };

    if (currentUserId) {
      followerSelect.followers = {
        where: { follower_id: currentUserId },
        select: { id: true },
      };
    }

    const follows = await prisma.userFollow.findMany({
      where: {
        following_id: userId,
        follower: { status: 'ACTIVE' },
      },
      include: {
        follower: {
          select: followerSelect,
        },
      },
      orderBy: { created_at: 'desc' },
    });

    return follows.map((f: any) => {
      const u: any = f.follower;
      const handle = u.username
        ? (u.username.startsWith('@') ? u.username : `@${u.username}`)
        : `@${u.email.split('@')[0].toLowerCase()}`;

      return {
        id: u.id,
        username: handle,
        firstName: u.first_name,
        lastName: u.last_name,
        fullName: `${u.first_name} ${u.last_name}`.trim(),
        email: u.email,
        avatarUrl: u.avatar_url,
        role: u.role,
        department: u.department ? { id: u.department.id, name: u.department.name, code: u.department.code } : null,
        isFollowing: Array.isArray(u.followers) && u.followers.length > 0,
      };
    });
  }

  async getFollowing(userId: string, currentUserId?: string) {
    const followingSelect: any = {
      id: true,
      username: true,
      first_name: true,
      last_name: true,
      email: true,
      avatar_url: true,
      role: true,
      department: { select: { id: true, name: true, code: true } },
    };

    if (currentUserId) {
      followingSelect.followers = {
        where: { follower_id: currentUserId },
        select: { id: true },
      };
    }

    const follows = await prisma.userFollow.findMany({
      where: {
        follower_id: userId,
        following: { status: 'ACTIVE' },
      },
      include: {
        following: {
          select: followingSelect,
        },
      },
      orderBy: { created_at: 'desc' },
    });

    return follows.map((f: any) => {
      const u: any = f.following;
      const handle = u.username
        ? (u.username.startsWith('@') ? u.username : `@${u.username}`)
        : `@${u.email.split('@')[0].toLowerCase()}`;

      return {
        id: u.id,
        username: handle,
        firstName: u.first_name,
        lastName: u.last_name,
        fullName: `${u.first_name} ${u.last_name}`.trim(),
        email: u.email,
        avatarUrl: u.avatar_url,
        role: u.role,
        department: u.department ? { id: u.department.id, name: u.department.name, code: u.department.code } : null,
        isFollowing: Array.isArray(u.followers) && u.followers.length > 0,
      };
    });
  }
}
