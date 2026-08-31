import { PrismaClient } from '@prisma/client';

export class SearchRepository {
  constructor(private prisma: PrismaClient) {}

  async searchUsers(collegeId: string, query: string, limit: number = 20, currentUserId?: string) {
    const trimmed = query ? query.trim().replace(/^@/, '') : '';
    const words = trimmed.split(/\s+/).filter(Boolean);

    const userSelect: any = {
      id: true,
      username: true,
      first_name: true,
      last_name: true,
      email: true,
      avatar_url: true,
      roll_number: true,
      role: true,
      department: { select: { id: true, name: true, code: true } },
    };

    if (currentUserId) {
      userSelect.followers = {
        where: { follower_id: currentUserId },
        select: { id: true },
      };
    }

    // 1. Discovery Mode (No search query entered)
    // Exclude current logged in user and all users currently followed by the current user
    // Return a maximum of 20 randomized eligible users
    if (trimmed.length === 0) {
      let excludedUserIds: string[] = [];
      if (currentUserId) {
        excludedUserIds.push(currentUserId);
        const followed = await this.prisma.userFollow.findMany({
          where: { follower_id: currentUserId },
          select: { following_id: true },
        });
        for (const f of followed) {
          excludedUserIds.push(f.following_id);
        }
      }

      const discoverWhere: any = {
        status: 'ACTIVE',
      };
      if (collegeId) {
        discoverWhere.college_id = collegeId;
      }
      if (excludedUserIds.length > 0) {
        discoverWhere.id = { notIn: excludedUserIds };
      }

      const eligibleUsers = await this.prisma.user.findMany({
        where: discoverWhere,
        select: userSelect,
        take: 100,
      });

      // Fisher-Yates random shuffle
      const shuffled = [...eligibleUsers];
      for (let i = shuffled.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
      }

      const selectedUsers = shuffled.slice(0, Math.min(limit, 20));

      return selectedUsers.map((u: any) => {
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
          rollNumber: u.roll_number,
          role: u.role,
          department: u.department ? { id: u.department.id, name: u.department.name, code: u.department.code } : null,
          isFollowing: false,
        };
      });
    }

    // 2. Active Search Mode
    // Include ALL users (both followed and unfollowed), matching query, excluding self
    const whereClause: any = {
      status: 'ACTIVE',
    };

    if (collegeId) {
      whereClause.college_id = collegeId;
    }

    if (currentUserId) {
      whereClause.id = { not: currentUserId };
    }

    const orConditions: any[] = [
      { first_name: { contains: trimmed, mode: 'insensitive' } },
      { last_name: { contains: trimmed, mode: 'insensitive' } },
      { username: { contains: trimmed, mode: 'insensitive' } },
      { email: { contains: trimmed, mode: 'insensitive' } },
      { roll_number: { contains: trimmed, mode: 'insensitive' } },
      { department: { name: { contains: trimmed, mode: 'insensitive' } } },
      { department: { code: { contains: trimmed, mode: 'insensitive' } } },
    ];

    if (words.length > 1) {
      orConditions.push({
        AND: [
          { first_name: { contains: words[0], mode: 'insensitive' } },
          { last_name: { contains: words[words.length - 1], mode: 'insensitive' } },
        ],
      });
    }

    whereClause.OR = orConditions;

    const users = await this.prisma.user.findMany({
      where: whereClause,
      select: userSelect,
      take: limit,
      orderBy: [{ first_name: 'asc' }],
    });

    return users.map((u: any) => {
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
        rollNumber: u.roll_number,
        role: u.role,
        department: u.department ? { id: u.department.id, name: u.department.name, code: u.department.code } : null,
        isFollowing: Array.isArray(u.followers) && u.followers.length > 0,
      };
    });
  }

  async searchStudents(collegeId: string, query: string, limit: number = 10, currentUserId?: string) {
    const trimmed = query.trim();
    return this.searchUsers(collegeId, trimmed, limit, currentUserId);
  }

  async searchFaculty(collegeId: string, query: string, limit: number = 10, currentUserId?: string) {
    const whereClause: any = {
      role: 'FACULTY',
      status: 'ACTIVE',
      OR: [
        { first_name: { contains: query, mode: 'insensitive' } },
        { last_name: { contains: query, mode: 'insensitive' } },
        { email: { contains: query, mode: 'insensitive' } },
      ],
    };

    if (collegeId) {
      whereClause.college_id = collegeId;
    }

    const facultySelect: any = {
      id: true,
      first_name: true,
      last_name: true,
      email: true,
      avatar_url: true,
      role: true,
      department: { select: { id: true, name: true, code: true } },
    };

    if (currentUserId) {
      facultySelect.followers = {
        where: { follower_id: currentUserId },
        select: { id: true },
      };
    }

    const users = await this.prisma.user.findMany({
      where: whereClause,
      select: facultySelect,
      take: limit,
    });

    return users.map((u: any) => ({
      id: u.id,
      firstName: u.first_name,
      lastName: u.last_name,
      fullName: `${u.first_name} ${u.last_name}`.trim(),
      email: u.email,
      avatarUrl: u.avatar_url,
      role: u.role,
      department: u.department ? { id: u.department.id, name: u.department.name, code: u.department.code } : null,
      isFollowing: Array.isArray(u.followers) && u.followers.length > 0,
    }));
  }

  async searchClubs(collegeId: string, query: string, limit: number = 10) {
    return this.prisma.club.findMany({
      where: {
        college_id: collegeId,
        status: 'APPROVED',
        is_active: true,
        OR: [
          { name: { contains: query, mode: 'insensitive' } },
          { category: { contains: query, mode: 'insensitive' } },
          { description: { contains: query, mode: 'insensitive' } },
        ],
      },
      select: {
        id: true,
        name: true,
        category: true,
        logo_url: true,
        description: true,
        _count: { select: { members: true } },
      },
      take: limit,
    });
  }

  async searchPosts(collegeId: string, query: string, limit: number = 10) {
    return this.prisma.post.findMany({
      where: {
        college_id: collegeId,
        OR: [
          { title: { contains: query, mode: 'insensitive' } },
          { content: { contains: query, mode: 'insensitive' } },
        ],
      },
      select: {
        id: true,
        title: true,
        content: true,
        type: true,
        created_at: true,
        author: { select: { id: true, first_name: true, last_name: true } },
        _count: { select: { likes: true, comments: true } },
      },
      take: limit,
    });
  }

  async searchEvents(collegeId: string, query: string, limit: number = 10) {
    return this.prisma.event.findMany({
      where: {
        college_id: collegeId,
        OR: [
          { title: { contains: query, mode: 'insensitive' } },
          { description: { contains: query, mode: 'insensitive' } },
          { venue: { contains: query, mode: 'insensitive' } },
        ],
      },
      select: {
        id: true,
        title: true,
        description: true,
        venue: true,
        start_time: true,
        category: true,
        scope: true,
      },
      take: limit,
    });
  }

  async searchCareerResources(query: string, limit: number = 10) {
    return this.prisma.learningResource.findMany({
      where: {
        OR: [
          { title: { contains: query, mode: 'insensitive' } },
          { type: { contains: query, mode: 'insensitive' } },
        ],
      },
      select: {
        id: true,
        title: true,
        type: true,
        url: true,
        duration_mins: true,
        is_free: true,
      },
      take: limit,
    });
  }
}
