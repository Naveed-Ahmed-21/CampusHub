import { ProfileService } from './profile.service';
import { ProfileRepository } from './profile.repository';
import { ConflictError, BadRequestError } from '../../shared/errors/AppError';

describe('ProfileService', () => {
  let profileService: ProfileService;
  let profileRepo: jest.Mocked<ProfileRepository>;

  beforeEach(() => {
    profileRepo = {
      getProfileByUserId: jest.fn(),
      updateUser: jest.fn(),
      upsertPortfolio: jest.fn(),
      addSkill: jest.fn(),
      removeSkill: jest.fn(),
      addProject: jest.fn(),
      removeProject: jest.fn(),
      toggleFollow: jest.fn(),
      getUserFollowStats: jest.fn(),
      getFollowers: jest.fn(),
      getFollowing: jest.fn(),
      getDetailedStudentProfile: jest.fn(),
      getOnboardingContext: jest.fn(),
      submitStudentOnboarding: jest.fn(),
      updateCareerProfile: jest.fn(),
      findPendingChangeRequestByField: jest.fn(),
      createProfileChangeRequest: jest.fn(),
      getStudentChangeRequests: jest.fn(),
      cancelChangeRequest: jest.fn(),
    } as unknown as jest.Mocked<ProfileRepository>;

    profileService = new ProfileService(profileRepo);
  });

  describe('submitOnboarding', () => {
    it('should throw BadRequestError if student phone equals father phone', async () => {
      await expect(
        profileService.submitOnboarding('user-1', {
          phone: '9876543210',
          dob: '2004-05-15',
          fatherName: 'Father Name',
          fatherPhone: '9876543210',
          motherName: 'Mother Name',
          motherPhone: '9876543211',
          emergencyContactName: 'Contact',
          emergencyContactRelation: 'Uncle',
          emergencyContactPhone: '9876543212',
          permanentAddress: '123 Main St',
          permanentCity: 'City',
          permanentState: 'State',
          permanentPincode: '560001',
          tenthPercentage: 88.5,
        }),
      ).rejects.toThrow(BadRequestError);
    });

    it('should throw BadRequestError if father phone equals mother phone', async () => {
      await expect(
        profileService.submitOnboarding('user-1', {
          phone: '9876543210',
          dob: '2004-05-15',
          fatherName: 'Father Name',
          fatherPhone: '9876543211',
          motherName: 'Mother Name',
          motherPhone: '9876543211',
          emergencyContactName: 'Contact',
          emergencyContactRelation: 'Uncle',
          emergencyContactPhone: '9876543212',
          permanentAddress: '123 Main St',
          permanentCity: 'City',
          permanentState: 'State',
          permanentPincode: '560001',
          tenthPercentage: 88.5,
        }),
      ).rejects.toThrow(BadRequestError);
    });

    it('should pass and call repository on distinct phone numbers and valid age', async () => {
      profileRepo.submitStudentOnboarding.mockResolvedValue({ user: {} as any, studentProfile: {} as any });

      await profileService.submitOnboarding('user-1', {
        phone: '9876543210',
        dob: '2004-05-15',
        fatherName: 'Father Name',
        fatherPhone: '9876543211',
        motherName: 'Mother Name',
        motherPhone: '9876543212',
        emergencyContactName: 'Contact',
        emergencyContactRelation: 'Uncle',
        emergencyContactPhone: '9876543213',
        permanentAddress: '123 Main St',
        permanentCity: 'City',
        permanentState: 'State',
        permanentPincode: '560001',
        tenthPercentage: 88.5,
      });

      expect(profileRepo.submitStudentOnboarding).toHaveBeenCalledTimes(1);
    });
  });

  describe('getDetailedStudentProfile', () => {
    it('should compute completion percentage and map field policies', async () => {
      profileRepo.getDetailedStudentProfile.mockResolvedValue({
        id: 'usr-1',
        email: 'student@campushub.edu',
        first_name: 'Alex',
        last_name: 'Vance',
        phone: '9876543210',
        roll_number: 'CS202301',
        department_id: 'dept-1',
        status: 'ACTIVE',
        is_profile_completed: true,
        department: { id: 'dept-1', name: 'Computer Science', code: 'CSE' },
        academic_profile: {
          program: { id: 'prog-1', name: 'B.Tech CSE', code: 'BT-CSE' },
          batch_name: '2023-2027',
          section: 'A',
          admission_year: 2023,
          current_status: 'ACTIVE',
        },
        student_profile: {
          dob: new Date('2004-05-15'),
          father_name: 'Father',
          father_phone: '9876543211',
          mother_name: 'Mother',
          mother_phone: '9876543212',
          emergency_contact_phone: '9876543213',
          permanent_address: '123 Campus Rd',
          tenth_percentage: 92.4,
          registration_number: 'REG12345',
        },
        portfolio: {
          bio: 'CS Student & Flutter enthusiast',
          skills: [{ id: 's1', skill_name: 'Flutter', proficiency: 'ADVANCED' }],
          projects: [],
          resume_url: 'https://storage/resume.pdf',
        },
        change_requests_sent: [],
      } as any);

      const result = await profileService.getDetailedStudentProfile('usr-1');
      expect(result.overview.completionPercentage).toBe(100);
      expect(result.fieldPolicies.rollNumber).toBe('LOCKED');
      expect(result.fieldPolicies.department).toBe('LOCKED');
      expect(result.fieldPolicies.firstName).toBe('APPROVAL_REQUIRED');
      expect(result.fieldPolicies.bio).toBe('EDITABLE');
      expect(result.personal.age).toBeGreaterThanOrEqual(20);
    });
  });

  describe('createProfileChangeRequest', () => {
    it('should reject request when a pending request already exists for the same field', async () => {
      profileRepo.findPendingChangeRequestByField.mockResolvedValue({
        id: 'req-1',
        field: 'phone',
        status: 'PENDING',
      } as any);

      await expect(
        profileService.createProfileChangeRequest('usr-1', 'clg-1', {
          field: 'phone',
          category: 'PERSONAL_CHANGE',
          requestedValue: '9999999999',
          reason: 'Lost old SIM card',
        }),
      ).rejects.toThrow(ConflictError);
    });

    it('should create request with resolved current value when no pending request exists', async () => {
      profileRepo.findPendingChangeRequestByField.mockResolvedValue(null);
      profileRepo.getDetailedStudentProfile.mockResolvedValue({
        id: 'usr-1',
        first_name: 'Alex',
        last_name: 'Vance',
        phone: '9876543210',
        student_profile: {
          father_name: 'Old Father Name',
        },
      } as any);
      profileRepo.createProfileChangeRequest.mockResolvedValue({
        id: 'req-2',
        field: 'father_name',
        status: 'PENDING',
      } as any);

      const res = await profileService.createProfileChangeRequest('usr-1', 'clg-1', {
        field: 'father_name',
        category: 'PERSONAL_CHANGE',
        requestedValue: 'Corrected Father Name',
        reason: 'Spelling mistake in official certificate',
      });

      expect(res.id).toBe('req-2');
      expect(profileRepo.createProfileChangeRequest).toHaveBeenCalledWith(
        expect.objectContaining({
          current_value: 'Old Father Name',
          requested_value: 'Corrected Father Name',
          field: 'father_name',
        }),
      );
    });
  });

  describe('addSkill and addProject', () => {
    it('should add skill with optional/null proficiency', async () => {
      profileRepo.upsertPortfolio.mockResolvedValue({ id: 'port-1' } as any);
      profileRepo.addSkill.mockResolvedValue({ id: 's1', skill_name: 'Flutter', proficiency: null } as any);
      jest.spyOn(profileService, 'getProfile').mockResolvedValue({ id: 'usr-1', skills: [{ id: 's1', skillName: 'Flutter', proficiency: null }] } as any);

      const res = await profileService.addSkill('usr-1', { skillName: 'Flutter', proficiency: null });
      expect(profileRepo.upsertPortfolio).toHaveBeenCalledWith('usr-1', {});
      expect(profileRepo.addSkill).toHaveBeenCalledWith('port-1', 'Flutter', null);
      expect(res.skills).toHaveLength(1);
    });

    it('should add project with optional/null URLs and description', async () => {
      profileRepo.upsertPortfolio.mockResolvedValue({ id: 'port-1' } as any);
      profileRepo.addProject.mockResolvedValue({ id: 'p1', title: 'CampusHub' } as any);
      jest.spyOn(profileService, 'getProfile').mockResolvedValue({ id: 'usr-1', projects: [{ id: 'p1', title: 'CampusHub' }] } as any);

      const res = await profileService.addProject('usr-1', {
        title: 'CampusHub',
        description: null,
        projectUrl: null,
        repoUrl: null,
      });
      expect(profileRepo.upsertPortfolio).toHaveBeenCalledWith('usr-1', {});
      expect(profileRepo.addProject).toHaveBeenCalledWith('port-1', 'CampusHub', null, null, null);
      expect(res.projects).toHaveLength(1);
    });
  });
});

