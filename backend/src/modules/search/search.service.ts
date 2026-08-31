import { SearchRepository } from './search.repository';
import { BadRequestError } from '../../shared/errors/AppError';

export class SearchService {
  constructor(private searchRepo: SearchRepository) {}

  async search(collegeId: string, query: string, type: string = 'all', page: number = 1, limit: number = 10, currentUserId?: string) {
    const q = query ? query.trim() : '';
    const safeLimit = Math.min(Math.max(limit, 1), 50);
    const validTypes = ['all', 'users', 'students', 'faculty', 'clubs', 'posts', 'events', 'career_resources'];
    
    if (!validTypes.includes(type)) {
      throw new BadRequestError(`Invalid search type: '${type}'. Supported types: ${validTypes.join(', ')}`);
    }

    const results: Record<string, unknown[]> = {
      users: [],
      students: [],
      faculty: [],
      clubs: [],
      posts: [],
      events: [],
      career_resources: [],
    };

    if (type === 'all' || type === 'users') {
      if (typeof this.searchRepo.searchUsers === 'function') {
        results.users = await this.searchRepo.searchUsers(collegeId, q, safeLimit, currentUserId);
      }
    }

    if (!q) {
      return results;
    }

    if (type === 'all' || type === 'students') {
      results.students = currentUserId
        ? await this.searchRepo.searchStudents(collegeId, q, safeLimit, currentUserId)
        : await this.searchRepo.searchStudents(collegeId, q, safeLimit);
    }
    if (type === 'all' || type === 'faculty') {
      results.faculty = currentUserId
        ? await this.searchRepo.searchFaculty(collegeId, q, safeLimit, currentUserId)
        : await this.searchRepo.searchFaculty(collegeId, q, safeLimit);
    }
    if (type === 'all' || type === 'clubs') {
      results.clubs = await this.searchRepo.searchClubs(collegeId, q, safeLimit);
    }
    if (type === 'all' || type === 'posts') {
      results.posts = await this.searchRepo.searchPosts(collegeId, q, safeLimit);
    }
    if (type === 'all' || type === 'events') {
      results.events = await this.searchRepo.searchEvents(collegeId, q, safeLimit);
    }
    if (type === 'all' || type === 'career_resources') {
      results.career_resources = await this.searchRepo.searchCareerResources(q, safeLimit);
    }

    return results;
  }
}
