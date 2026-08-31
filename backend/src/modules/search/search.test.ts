import { SearchService } from './search.service';
import { SearchRepository } from './search.repository';
import { BadRequestError } from '../../shared/errors/AppError';

describe('SearchService', () => {
  let searchRepo: jest.Mocked<SearchRepository>;
  let searchService: SearchService;
  const mockCollegeId = 'college-123';

  beforeEach(() => {
    searchRepo = {
      searchUsers: jest.fn().mockResolvedValue([{ id: 'usr-1', first_name: 'Alex' }]),
      searchStudents: jest.fn().mockResolvedValue([{ id: 'std-1', first_name: 'Alex' }]),
      searchFaculty: jest.fn().mockResolvedValue([{ id: 'fac-1', first_name: 'Dr. Smith' }]),
      searchClubs: jest.fn().mockResolvedValue([{ id: 'clb-1', name: 'DevSync' }]),
      searchPosts: jest.fn().mockResolvedValue([{ id: 'post-1', title: 'Tech Talk' }]),
      searchEvents: jest.fn().mockResolvedValue([{ id: 'evt-1', title: 'Hackathon' }]),
      searchCareerResources: jest.fn().mockResolvedValue([{ id: 'res-1', title: 'Flutter Guide' }]),
    } as unknown as jest.Mocked<SearchRepository>;

    searchService = new SearchService(searchRepo);
  });

  it('should return empty lists when query string is empty', async () => {
    const res = await searchService.search(mockCollegeId, '');
    expect(res.students).toEqual([]);
    expect(res.clubs).toEqual([]);
    expect(searchRepo.searchStudents).not.toHaveBeenCalled();
  });

  it('should query all entities when type is all', async () => {
    const res = await searchService.search(mockCollegeId, 'tech', 'all');
    expect(searchRepo.searchStudents).toHaveBeenCalledWith(mockCollegeId, 'tech', 10);
    expect(searchRepo.searchFaculty).toHaveBeenCalledWith(mockCollegeId, 'tech', 10);
    expect(searchRepo.searchClubs).toHaveBeenCalledWith(mockCollegeId, 'tech', 10);
    expect(searchRepo.searchPosts).toHaveBeenCalledWith(mockCollegeId, 'tech', 10);
    expect(searchRepo.searchEvents).toHaveBeenCalledWith(mockCollegeId, 'tech', 10);
    expect(searchRepo.searchCareerResources).toHaveBeenCalledWith('tech', 10);

    expect(res.students.length).toBe(1);
    expect(res.clubs.length).toBe(1);
  });

  it('should query only students when type is students', async () => {
    const res = await searchService.search(mockCollegeId, 'Alex', 'students');
    expect(searchRepo.searchStudents).toHaveBeenCalledWith(mockCollegeId, 'Alex', 10);
    expect(searchRepo.searchClubs).not.toHaveBeenCalled();
    expect(res.students.length).toBe(1);
    expect(res.clubs.length).toBe(0);
  });

  it('should throw BadRequestError on invalid search type', async () => {
    await expect(searchService.search(mockCollegeId, 'test', 'invalid_type')).rejects.toThrow(BadRequestError);
  });
});
