import { PrismaClient } from '@prisma/client';

export class SearchRepository {
  constructor(private prisma: PrismaClient) {}

  async searchStudents(collegeId: string, query: string, limit: number = 10) {
    return this.prisma.user.findMany({
      where: {
        college_id: collegeId,
        role: 'STUDENT',
        status: 'ACTIVE',
        OR: [
          { first_name: { contains: query, mode: 'insensitive' } },
          { last_name: { contains: query, mode: 'insensitive' } },
          { email: { contains: query, mode: 'insensitive' } },
          { roll_number: { contains: query, mode: 'insensitive' } },
        ],
      },
      select: {
        id: true,
        first_name: true,
        last_name: true,
        email: true,
        avatar_url: true,
        roll_number: true,
        department: { select: { id: true, name: true, code: true } },
      },
      take: limit,
    });
  }

  async searchFaculty(collegeId: string, query: string, limit: number = 10) {
    return this.prisma.user.findMany({
      where: {
        college_id: collegeId,
        role: 'FACULTY',
        status: 'ACTIVE',
        OR: [
          { first_name: { contains: query, mode: 'insensitive' } },
          { last_name: { contains: query, mode: 'insensitive' } },
          { email: { contains: query, mode: 'insensitive' } },
        ],
      },
      select: {
        id: true,
        first_name: true,
        last_name: true,
        email: true,
        avatar_url: true,
        department: { select: { id: true, name: true, code: true } },
      },
      take: limit,
    });
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
