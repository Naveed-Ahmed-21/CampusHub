import { SearchRepository } from './search.repository';
import { BadRequestError } from '../../shared/errors/AppError';

export class SearchService {
  constructor(private searchRepo: SearchRepository) {}

  async search(collegeId: string, query: string, type: string = 'all', page: number = 1, limit: number = 10) {
    const q = query ? query.trim() : '';
    if (!q) {
      return {
        students: [],
        faculty: [],
        clubs: [],
        posts: [],
        events: [],
        career_resources: [],
      };
    }

    const safeLimit = Math.min(Math.max(limit, 1), 50);
    const validTypes = ['all', 'students', 'faculty', 'clubs', 'posts', 'events', 'career_resources'];
    
    if (!validTypes.includes(type)) {
      throw new BadRequestError(`Invalid search type: '${type}'. Supported types: ${validTypes.join(', ')}`);
    }

    const results: Record<string, unknown[]> = {
      students: [],
      faculty: [],
      clubs: [],
      posts: [],
      events: [],
      career_resources: [],
    };

    if (type === 'all' || type === 'students') {
      results.students = await this.searchRepo.searchStudents(collegeId, q, safeLimit);
    }
    if (type === 'all' || type === 'faculty') {
      results.faculty = await this.searchRepo.searchFaculty(collegeId, q, safeLimit);
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
