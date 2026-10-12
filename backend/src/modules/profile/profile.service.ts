import { ProfileRepository } from './profile.repository';
import { NotFoundError, ConflictError, BadRequestError } from '../../shared/errors/AppError';
import {
  UpdateProfileDTO,
  AddSkillDTO,
  AddProjectDTO,
  ProfileResponseDTO,
  SubmitOnboardingDTO,
  UpdateCareerProfileDTO,
  CreateChangeRequestDTO,
  OnboardingContextDTO,
  DetailedStudentProfileDTO,
} from './profile.types';
import { NotificationsRepository } from '../notifications/notifications.repository';
import { NotificationsService } from '../notifications/notifications.service';


export class ProfileService {
  private readonly notificationsService: NotificationsService;

  constructor(
    private readonly profileRepo: ProfileRepository,
    notificationsService?: NotificationsService,
  ) {
    this.notificationsService = notificationsService ?? new NotificationsService(new NotificationsRepository());
  }

  async getProfile(userId: string, currentUserId?: string): Promise<ProfileResponseDTO> {
    const user = await this.profileRepo.getProfileByUserId(userId);
    if (!user) {
      throw new NotFoundError('User not found');
    }

    const stats = await this.profileRepo.getUserFollowStats(user.id, currentUserId);

    const handle = user.username
      ? (user.username.startsWith('@') ? user.username : `@${user.username}`)
      : `@${user.email.split('@')[0].toLowerCase()}`;

    return {
      id: user.id,
      email: user.email,
      username: handle,
      firstName: user.first_name,
      lastName: user.last_name,
      role: user.role,
      department: user.department ? { id: user.department.id, name: user.department.name } : null,
      rollNumber: user.roll_number,
      phone: user.phone,
      avatarUrl: user.avatar_url,
      bio: user.portfolio?.bio,
      githubUrl: user.portfolio?.github_url,
      linkedinUrl: user.portfolio?.linkedin_url,
      websiteUrl: user.portfolio?.website_url,
      resumeUrl: user.portfolio?.resume_url,
      followersCount: stats.followersCount,
      followingCount: stats.followingCount,
      postsCount: stats.postsCount ?? 0,
      isFollowing: stats.isFollowing,
      status: user.status,
      createdAt: user.created_at,
      updatedAt: user.updated_at,
      lastSeen: user.last_seen,
      skills: (user.portfolio?.skills || []).map((s) => ({
        id: s.id,
        skillName: s.skill_name,
        proficiency: s.proficiency,
      })),
      projects: (user.portfolio?.projects || []).map((p) => ({
        id: p.id,
        title: p.title,
        description: p.description,
        projectUrl: p.project_url,
        repoUrl: p.repo_url,
      })),
      clubs: ((user as any).club_members || []).map((cm: any) => ({
        id: cm.id,
        clubId: cm.club?.id ?? cm.club_id,
        name: cm.club?.name ?? 'Club',
        category: cm.club?.category ?? 'General',
        logoUrl: cm.club?.logo_url,
        role: cm.role,
      })),
    };
  }

  async getFollowers(userId: string, currentUserId?: string) {
    return this.profileRepo.getFollowers(userId, currentUserId);
  }

  async getFollowing(userId: string, currentUserId?: string) {
    return this.profileRepo.getFollowing(userId, currentUserId);
  }

  async toggleFollow(followerId: string, followingId: string) {
    const result = await this.profileRepo.toggleFollow(followerId, followingId);
    if (result && result.isFollowing) {
      try {
        const follower = await this.profileRepo.getProfileByUserId(followerId);
        const name = follower ? `${follower.first_name} ${follower.last_name}`.trim() : 'Someone';
        await this.notificationsService.sendNotification({
          user_id: followingId,
          title: 'New Follower',
          body: `${name} started following your campus profile`,
          type: 'SYSTEM',
          category: 'Social',
          deep_link: `/profile/user/${followerId}`,
        });
      } catch (_) {}
    }
    return result;
  }

  async updateProfile(userId: string, dto: UpdateProfileDTO): Promise<ProfileResponseDTO> {
    const avatar = dto.avatarUrl ?? (dto as any).avatar_url;
    if (dto.firstName || dto.lastName || dto.phone || avatar !== undefined) {
      await this.profileRepo.updateUser(userId, {
        firstName: dto.firstName ?? undefined,
        lastName: dto.lastName ?? undefined,
        phone: dto.phone ?? undefined,
        avatarUrl: avatar ?? undefined,
      });
    }

    if (dto.bio !== undefined || dto.githubUrl !== undefined || dto.linkedinUrl !== undefined || dto.websiteUrl !== undefined) {
      await this.profileRepo.upsertPortfolio(userId, {
        bio: dto.bio ?? undefined,
        githubUrl: dto.githubUrl ?? undefined,
        linkedinUrl: dto.linkedinUrl ?? undefined,
        websiteUrl: dto.websiteUrl ?? undefined,
      });
    }

    return this.getProfile(userId);
  }

  async updateAvatar(userId: string, avatarUrl: string): Promise<ProfileResponseDTO> {
    await this.profileRepo.updateUser(userId, { avatarUrl });
    return this.getProfile(userId);
  }

  async updateResume(userId: string, resumeUrl: string): Promise<ProfileResponseDTO> {
    await this.profileRepo.upsertPortfolio(userId, { resumeUrl });
    return this.getProfile(userId);
  }

  async addSkill(userId: string, dto: AddSkillDTO): Promise<ProfileResponseDTO> {
    const portfolio = await this.profileRepo.upsertPortfolio(userId, {});
    await this.profileRepo.addSkill(portfolio.id, dto.skillName, dto.proficiency);
    return this.getProfile(userId);
  }

  async removeSkill(userId: string, skillId: string): Promise<ProfileResponseDTO> {
    await this.profileRepo.removeSkill(skillId);
    return this.getProfile(userId);
  }

  async addProject(userId: string, dto: AddProjectDTO): Promise<ProfileResponseDTO> {
    const portfolio = await this.profileRepo.upsertPortfolio(userId, {});
    await this.profileRepo.addProject(portfolio.id, dto.title, dto.description, dto.projectUrl, dto.repoUrl);
    return this.getProfile(userId);
  }

  async removeProject(userId: string, projectId: string): Promise<ProfileResponseDTO> {
    await this.profileRepo.removeProject(projectId);
    return this.getProfile(userId);
  }

  async getOnboardingContext(userId: string): Promise<OnboardingContextDTO> {
    const user = await this.profileRepo.getOnboardingContext(userId);
    if (!user) {
      throw new NotFoundError('User not found');
    }

    return {
      userId: user.id,
      email: user.email,
      firstName: user.first_name,
      lastName: user.last_name,
      departmentId: user.department_id,
      departmentName: user.department?.name,
      programId: user.academic_profile?.program_id,
      programName: user.academic_profile?.program?.name,
      batchName: user.academic_profile?.batch_name,
      section: user.academic_profile?.section,
      rollNumber: user.roll_number,
      registrationNumber: user.student_profile?.registration_number,
    };
  }

  async submitOnboarding(userId: string, dto: SubmitOnboardingDTO) {
    if (dto.phone === dto.fatherPhone || dto.phone === dto.motherPhone || dto.fatherPhone === dto.motherPhone) {
      throw new BadRequestError('Student mobile, father mobile, and mother mobile must be distinct telephone numbers.');
    }

    const birthDate = new Date(dto.dob);
    if (isNaN(birthDate.getTime()) || birthDate > new Date()) {
      throw new BadRequestError('Invalid date of birth');
    }

    const age = calculateAge(birthDate);
    if (age !== null && age < 15) {
      throw new BadRequestError('Student must be at least 15 years of age');
    }

    return this.profileRepo.submitStudentOnboarding(userId, dto);
  }

  async getDetailedStudentProfile(userId: string): Promise<DetailedStudentProfileDTO> {
    const user = await this.profileRepo.getDetailedStudentProfile(userId);
    if (!user) {
      throw new NotFoundError('Student profile not found');
    }

    const completionPercentage = calculateProfileCompletion({
      user,
      studentProfile: user.student_profile,
      portfolio: user.portfolio,
    });

    const age = calculateAge(user.student_profile?.dob);

    const badges = ['STUDENT'];
    if (user.status === 'ACTIVE') badges.push('ENROLLED');
    if (completionPercentage === 100) badges.push('VERIFIED_PROFILE');

    return {
      overview: {
        userId: user.id,
        email: user.email,
        fullName: `${user.first_name} ${user.last_name}`.trim(),
        avatarUrl: user.avatar_url,
        role: user.role,
        status: user.status,
        isProfileCompleted: user.is_profile_completed,
        completionPercentage,
        badges,
      },
      officialIdentity: {
        rollNumber: user.roll_number,
        registrationNumber: user.student_profile?.registration_number,
        departmentId: user.department?.id,
        departmentName: user.department?.name,
        departmentCode: user.department?.code,
        programId: user.academic_profile?.program?.id,
        programName: user.academic_profile?.program?.name,
        batchName: user.academic_profile?.batch_name,
        section: user.academic_profile?.section,
        currentStatus: user.academic_profile?.current_status ?? user.status,
        admissionYear: user.academic_profile?.admission_year,
      },
      personal: {
        firstName: user.first_name,
        lastName: user.last_name,
        dob: user.student_profile?.dob ? user.student_profile.dob.toISOString().split('T')[0] : null,
        age,
        bloodGroup: user.student_profile?.blood_group,
        phone: user.phone,
        email: user.email,
      },
      family: {
        fatherName: user.student_profile?.father_name,
        fatherPhone: user.student_profile?.father_phone,
        motherName: user.student_profile?.mother_name,
        motherPhone: user.student_profile?.mother_phone,
        guardianName: user.student_profile?.guardian_name,
        guardianPhone: user.student_profile?.guardian_phone,
      },
      address: {
        permanentAddress: user.student_profile?.permanent_address,
        permanentCity: user.student_profile?.permanent_city,
        permanentState: user.student_profile?.permanent_state,
        permanentCountry: user.student_profile?.permanent_country,
        permanentPincode: user.student_profile?.permanent_pincode,
        currentAddress: user.student_profile?.current_address,
        currentCity: user.student_profile?.current_city,
        currentState: user.student_profile?.current_state,
        currentCountry: user.student_profile?.current_country,
        currentPincode: user.student_profile?.current_pincode,
      },
      emergency: {
        contactName: user.student_profile?.emergency_contact_name,
        contactRelation: user.student_profile?.emergency_contact_relation,
        contactPhone: user.student_profile?.emergency_contact_phone,
      },
      education: {
        tenthPercentage: user.student_profile?.tenth_percentage,
        twelfthPercentage: user.student_profile?.twelfth_percentage,
      },
      career: {
        bio: user.portfolio?.bio,
        skills: (user.portfolio?.skills || []).map((s) => ({
          id: s.id,
          skillName: s.skill_name,
          proficiency: s.proficiency,
        })),
        projects: (user.portfolio?.projects || []).map((p) => ({
          id: p.id,
          title: p.title,
          description: p.description,
          projectUrl: p.project_url,
          repoUrl: p.repo_url,
        })),
        githubUrl: user.portfolio?.github_url,
        linkedinUrl: user.portfolio?.linkedin_url,
        websiteUrl: user.portfolio?.website_url,
        resumeUrl: user.portfolio?.resume_url,
      },
      fieldPolicies: {
        rollNumber: 'LOCKED',
        registrationNumber: 'LOCKED',
        department: 'LOCKED',
        program: 'LOCKED',
        batchName: 'LOCKED',
        section: 'LOCKED',
        firstName: 'APPROVAL_REQUIRED',
        lastName: 'APPROVAL_REQUIRED',
        dob: 'APPROVAL_REQUIRED',
        phone: 'APPROVAL_REQUIRED',
        bloodGroup: 'APPROVAL_REQUIRED',
        fatherName: 'APPROVAL_REQUIRED',
        fatherPhone: 'APPROVAL_REQUIRED',
        motherName: 'APPROVAL_REQUIRED',
        motherPhone: 'APPROVAL_REQUIRED',
        guardianName: 'APPROVAL_REQUIRED',
        guardianPhone: 'APPROVAL_REQUIRED',
        permanentAddress: 'APPROVAL_REQUIRED',
        emergencyContactPhone: 'APPROVAL_REQUIRED',
        tenthPercentage: 'APPROVAL_REQUIRED',
        twelfthPercentage: 'APPROVAL_REQUIRED',
        bio: 'EDITABLE',
        skills: 'EDITABLE',
        projects: 'EDITABLE',
        githubUrl: 'EDITABLE',
        linkedinUrl: 'EDITABLE',
        websiteUrl: 'EDITABLE',
        resumeUrl: 'EDITABLE',
        avatarUrl: 'EDITABLE',
      },
    };
  }

  async updateCareerProfile(userId: string, dto: UpdateCareerProfileDTO) {
    return this.profileRepo.updateCareerProfile(userId, dto);
  }

  async createProfileChangeRequest(studentId: string, collegeId: string, dto: CreateChangeRequestDTO) {
    const existingPending = await this.profileRepo.findPendingChangeRequestByField(studentId, dto.field);
    if (existingPending) {
      throw new ConflictError(`A change request for "${dto.field}" is already pending approval.`);
    }

    const user = await this.profileRepo.getDetailedStudentProfile(studentId);
    if (!user) {
      throw new NotFoundError('Student not found');
    }

    const currentValue = resolveCurrentFieldValue(dto.field, user);

    return this.profileRepo.createProfileChangeRequest({
      college_id: collegeId,
      student_id: studentId,
      field: dto.field,
      category: dto.category,
      current_value: currentValue || 'Not Set',
      requested_value: dto.requestedValue,
      reason: dto.reason,
      supporting_document: dto.supportingDocument,
    });
  }

  async getStudentChangeRequests(studentId: string) {
    return this.profileRepo.getStudentChangeRequests(studentId);
  }

  async cancelChangeRequest(requestId: string, studentId: string) {
    return this.profileRepo.cancelChangeRequest(requestId, studentId);
  }
}

function calculateProfileCompletion(data: {
  user: any;
  studentProfile?: any;
  portfolio?: any;
}): number {
  const checks = [
    Boolean(data.user?.first_name),
    Boolean(data.user?.last_name),
    Boolean(data.user?.phone),
    Boolean(data.user?.roll_number || data.studentProfile?.registration_number),
    Boolean(data.user?.department_id),
    Boolean(data.studentProfile?.dob),
    Boolean(data.studentProfile?.father_name),
    Boolean(data.studentProfile?.father_phone),
    Boolean(data.studentProfile?.mother_name),
    Boolean(data.studentProfile?.mother_phone),
    Boolean(data.studentProfile?.emergency_contact_phone),
    Boolean(data.studentProfile?.permanent_address),
    Boolean(data.studentProfile?.tenth_percentage),
    Boolean(data.portfolio?.bio),
    Boolean(data.portfolio?.skills && data.portfolio.skills.length > 0),
    Boolean(data.portfolio?.resume_url),
  ];

  const completed = checks.filter(Boolean).length;
  return Math.round((completed / checks.length) * 100);
}

function calculateAge(dob?: Date | null): number | null {
  if (!dob) return null;
  const birthDate = new Date(dob);
  if (isNaN(birthDate.getTime())) return null;
  const diffMs = Date.now() - birthDate.getTime();
  const ageDt = new Date(diffMs);
  return Math.abs(ageDt.getUTCFullYear() - 1970);
}

function resolveCurrentFieldValue(field: string, user: any): string {
  const normField = field.toLowerCase().replace(/_/g, '');
  if (normField === 'firstname') return user.first_name || '';
  if (normField === 'lastname') return user.last_name || '';
  if (normField === 'phone') return user.phone || '';
  if (normField === 'rollnumber') return user.roll_number || '';
  if (normField === 'batchname') return user.academic_profile?.batch_name || '';
  if (normField === 'section') return user.academic_profile?.section || '';
  if (normField === 'program') return user.academic_profile?.program?.name || '';
  if (normField === 'department') return user.department?.name || '';

  const sp = user.student_profile;
  if (!sp) return '';
  if (normField === 'dob') return sp.dob ? new Date(sp.dob).toISOString().split('T')[0] : '';
  if (normField === 'fathername') return sp.father_name || '';
  if (normField === 'fatherphone') return sp.father_phone || '';
  if (normField === 'mothername') return sp.mother_name || '';
  if (normField === 'motherphone') return sp.mother_phone || '';
  if (normField === 'guardianname') return sp.guardian_name || '';
  if (normField === 'guardianphone') return sp.guardian_phone || '';
  if (normField === 'bloodgroup') return sp.blood_group || '';
  if (normField === 'emergencycontactname') return sp.emergency_contact_name || '';
  if (normField === 'emergencycontactrelation') return sp.emergency_contact_relation || '';
  if (normField === 'emergencycontactphone') return sp.emergency_contact_phone || '';
  if (normField === 'permanentaddress') return sp.permanent_address || '';
  if (normField === 'permanentcity') return sp.permanent_city || '';
  if (normField === 'permanentstate') return sp.permanent_state || '';
  if (normField === 'permanentpincode') return sp.permanent_pincode || '';
  if (normField === 'currentaddress') return sp.current_address || '';
  if (normField === 'currentcity') return sp.current_city || '';
  if (normField === 'currentstate') return sp.current_state || '';
  if (normField === 'currentpincode') return sp.current_pincode || '';
  if (normField === 'tenthpercentage') return sp.tenth_percentage != null ? `${sp.tenth_percentage}%` : '';
  if (normField === 'twelfthpercentage') return sp.twelfth_percentage != null ? `${sp.twelfth_percentage}%` : '';
  if (normField === 'registrationnumber') return sp.registration_number || '';

  return '';
}

