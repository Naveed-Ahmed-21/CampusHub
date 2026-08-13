import { ClubsService } from './clubs.service';
import { ClubsRepository } from './clubs.repository';
import { ClubRole, ClubStatus, Role } from '@prisma/client';
import { ForbiddenError, NotFoundError, ConflictError } from '../../shared/errors/AppError';

describe('ClubsService', () => {
  let clubsRepository: jest.Mocked<ClubsRepository>;
  let clubsService: ClubsService;

  const mockCollegeId = 'college-123';
  const mockStudentId = 'student-123';
  const mockAdminId = 'admin-123';
  const mockClubId = 'club-123';

  beforeEach(() => {
    clubsRepository = {
      createClub: jest.fn(),
      findClubById: jest.fn(),
      findClubByName: jest.fn(),
      findClubs: jest.fn(),
      updateClubVerification: jest.fn(),
      findMember: jest.fn(),
      addMember: jest.fn(),
      removeMember: jest.fn(),
      updateMemberRole: jest.fn(),
      getMembers: jest.fn(),
      createClubPost: jest.fn(),
      getClubFeed: jest.fn(),
      createClubEvent: jest.fn(),
      getClubEvents: jest.fn(),
      createClubResource: jest.fn(),
      getClubResources: jest.fn(),
      deleteClubResource: jest.fn(),
      findOrCreateClubChatRoom: jest.fn(),
      addChatParticipant: jest.fn(),
      removeChatParticipant: jest.fn(),
      getChatMessages: jest.fn(),
      sendChatMessage: jest.fn(),
    } as unknown as jest.Mocked<ClubsRepository>;

    clubsService = new ClubsService(clubsRepository);
  });

  describe('createClub', () => {
    it('should create a PENDING club when created by a student', async () => {
      clubsRepository.findClubByName.mockResolvedValue(null);
      clubsRepository.createClub.mockResolvedValue({
        id: mockClubId,
        name: 'Robotics Club',
        category: 'Tech',
        status: ClubStatus.PENDING,
        college_id: mockCollegeId,
        created_by_id: mockStudentId,
        is_cross_department: true,
        is_active: false,
        verified_by_id: null,
        description: null,
        logo_url: null,
        rejection_reason: null,
        verified_at: null,
        created_at: new Date(),
        updated_at: new Date(),
      } as never);

      const result = await clubsService.createClub(mockStudentId, mockCollegeId, Role.STUDENT, {
        name: 'Robotics Club',
        category: 'Tech',
      });

      expect(clubsRepository.findClubByName).toHaveBeenCalledWith(mockCollegeId, 'Robotics Club');
      expect(clubsRepository.createClub).toHaveBeenCalledWith(
        mockCollegeId,
        mockStudentId,
        { name: 'Robotics Club', category: 'Tech' },
        ClubStatus.PENDING
      );
      expect(result.status).toBe(ClubStatus.PENDING);
    });

    it('should throw ConflictError if club name already exists in college', async () => {
      clubsRepository.findClubByName.mockResolvedValue({ id: 'existing-id' } as never);

      await expect(
        clubsService.createClub(mockStudentId, mockCollegeId, Role.STUDENT, {
          name: 'Robotics Club',
          category: 'Tech',
        })
      ).rejects.toThrow(ConflictError);
    });
  });

  describe('verifyClub', () => {
    it('should allow admin to approve club and initialize chat room', async () => {
      clubsRepository.findClubById.mockResolvedValue({
        id: mockClubId,
        name: 'Robotics Club',
        college_id: mockCollegeId,
        created_by_id: mockStudentId,
      } as never);

      clubsRepository.updateClubVerification.mockResolvedValue({
        id: mockClubId,
        name: 'Robotics Club',
        status: ClubStatus.APPROVED,
        is_active: true,
      } as never);

      clubsRepository.findOrCreateClubChatRoom.mockResolvedValue({ id: 'room-123' } as never);

      const result = await clubsService.verifyClub(mockClubId, mockCollegeId, mockAdminId, Role.COLLEGE_ADMIN, {
        status: ClubStatus.APPROVED,
      });

      expect(clubsRepository.updateClubVerification).toHaveBeenCalledWith(
        mockClubId,
        ClubStatus.APPROVED,
        mockAdminId,
        undefined
      );
      expect(clubsRepository.findOrCreateClubChatRoom).toHaveBeenCalledWith(mockClubId, mockCollegeId, 'Robotics Club');
      expect(result.status).toBe(ClubStatus.APPROVED);
    });

    it('should throw ForbiddenError if non-admin tries to verify club', async () => {
      await expect(
        clubsService.verifyClub(mockClubId, mockCollegeId, mockStudentId, Role.STUDENT, {
          status: ClubStatus.APPROVED,
        })
      ).rejects.toThrow(ForbiddenError);
    });
  });

  describe('joinClub', () => {
    it('should add student to club members and chat room', async () => {
      clubsRepository.findClubById.mockResolvedValue({
        id: mockClubId,
        name: 'Robotics Club',
        college_id: mockCollegeId,
        status: ClubStatus.APPROVED,
        is_active: true,
      } as never);

      clubsRepository.findMember.mockResolvedValue(null);
      clubsRepository.addMember.mockResolvedValue({ id: 'mem-1', role: ClubRole.MEMBER } as never);
      clubsRepository.findOrCreateClubChatRoom.mockResolvedValue({ id: 'room-123' } as never);

      const member = await clubsService.joinClub(mockClubId, mockStudentId, mockCollegeId);

      expect(clubsRepository.addMember).toHaveBeenCalledWith(mockClubId, mockStudentId, ClubRole.MEMBER);
      expect(clubsRepository.addChatParticipant).toHaveBeenCalledWith('room-123', mockStudentId);
      expect(member.role).toBe(ClubRole.MEMBER);
    });
  });

  describe('createClubResource', () => {
    it('should throw ForbiddenError if non-member tries to upload resource', async () => {
      clubsRepository.findClubById.mockResolvedValue({ id: mockClubId, college_id: mockCollegeId } as never);
      clubsRepository.findMember.mockResolvedValue(null);

      await expect(
        clubsService.createClubResource(mockClubId, mockStudentId, mockCollegeId, Role.STUDENT, {
          title: 'Notes',
          file_url: 'https://file.pdf',
          file_name: 'notes.pdf',
          file_type: 'pdf',
        })
      ).rejects.toThrow(ForbiddenError);
    });

    it('should throw ForbiddenError if regular MEMBER tries to upload resource', async () => {
      clubsRepository.findClubById.mockResolvedValue({ id: mockClubId, college_id: mockCollegeId } as never);
      clubsRepository.findMember.mockResolvedValue({ id: 'mem-1', role: ClubRole.MEMBER } as never);

      await expect(
        clubsService.createClubResource(mockClubId, mockStudentId, mockCollegeId, Role.STUDENT, {
          title: 'Notes',
          file_url: 'https://file.pdf',
          file_name: 'notes.pdf',
          file_type: 'pdf',
        })
      ).rejects.toThrow(ForbiddenError);
    });

    it('should allow Club LEAD to upload resource', async () => {
      clubsRepository.findClubById.mockResolvedValue({ id: mockClubId, college_id: mockCollegeId } as never);
      clubsRepository.findMember.mockResolvedValue({ id: 'mem-1', role: ClubRole.LEAD } as never);
      clubsRepository.createClubResource.mockResolvedValue({ id: 'res-1', title: 'Notes' } as never);

      const res = await clubsService.createClubResource(mockClubId, mockStudentId, mockCollegeId, Role.STUDENT, {
        title: 'Notes',
        file_url: 'https://file.pdf',
        file_name: 'notes.pdf',
        file_type: 'pdf',
      });

      expect(res.title).toBe('Notes');
    });

    it('should allow COLLEGE_ADMIN to upload resource', async () => {
      clubsRepository.findClubById.mockResolvedValue({ id: mockClubId, college_id: mockCollegeId } as never);
      clubsRepository.findMember.mockResolvedValue(null);
      clubsRepository.createClubResource.mockResolvedValue({ id: 'res-2', title: 'Admin Doc' } as never);

      const res = await clubsService.createClubResource(mockClubId, mockAdminId, mockCollegeId, Role.COLLEGE_ADMIN, {
        title: 'Admin Doc',
        file_url: 'https://file.pdf',
        file_name: 'doc.pdf',
        file_type: 'pdf',
      });

      expect(res.title).toBe('Admin Doc');
    });
  });
});
