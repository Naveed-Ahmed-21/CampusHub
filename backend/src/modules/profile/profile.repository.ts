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
        club_members: {
          include: {
            club: {
              select: {
                id: true,
                name: true,
                category: true,
                logo_url: true,
                status: true,
              },
            },
          },
        },
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

  async addSkill(portfolioId: string, skillName: string, proficiency?: string | null): Promise<PortfolioSkill> {
    return prisma.portfolioSkill.create({
      data: {
        portfolio_id: portfolioId,
        skill_name: skillName.trim(),
        proficiency: proficiency && proficiency.trim().length > 0 ? proficiency.trim() : null,
      },
    });
  }

  async removeSkill(skillId: string): Promise<void> {
    await prisma.portfolioSkill.delete({
      where: { id: skillId },
    });
  }

  async addProject(
    portfolioId: string,
    title: string,
    description?: string | null,
    projectUrl?: string | null,
    repoUrl?: string | null,
  ): Promise<PortfolioProject> {
    return prisma.portfolioProject.create({
      data: {
        portfolio_id: portfolioId,
        title: title.trim(),
        description: description && description.trim().length > 0 ? description.trim() : null,
        project_url: projectUrl && projectUrl.trim().length > 0 ? projectUrl.trim() : null,
        repo_url: repoUrl && repoUrl.trim().length > 0 ? repoUrl.trim() : null,
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

  async getDetailedStudentProfile(userId: string) {
    return prisma.user.findUnique({
      where: { id: userId },
      include: {
        department: { select: { id: true, name: true, code: true } },
        academic_profile: {
          include: {
            program: { select: { id: true, name: true, code: true } },
          },
        },
        student_profile: true,
        portfolio: {
          include: {
            skills: true,
            projects: true,
          },
        },
        change_requests_sent: {
          orderBy: { submitted_at: 'desc' },
          take: 20,
        },
      },
    });
  }

  async getOnboardingContext(userId: string) {
    return prisma.user.findUnique({
      where: { id: userId },
      include: {
        department: { select: { id: true, name: true, code: true } },
        academic_profile: {
          include: {
            program: { select: { id: true, name: true, code: true } },
          },
        },
        student_profile: true,
      },
    });
  }

  async submitStudentOnboarding(userId: string, data: any) {
    return prisma.$transaction(async (tx) => {
      const user = await tx.user.update({
        where: { id: userId },
        data: {
          ...(data.firstName && { first_name: data.firstName }),
          ...(data.lastName && { last_name: data.lastName }),
          phone: data.phone,
          ...(data.rollNumber && { roll_number: data.rollNumber }),
          is_profile_completed: true,
          first_login_completed: true,
          status: 'ACTIVE',
        },
      });

      const dobDate = data.dob ? new Date(data.dob) : null;
      const studentProfile = await tx.studentProfile.upsert({
        where: { user_id: userId },
        create: {
          user_id: userId,
          dob: dobDate,
          blood_group: data.bloodGroup,
          father_name: data.fatherName,
          father_phone: data.fatherPhone,
          mother_name: data.motherName,
          mother_phone: data.motherPhone,
          guardian_name: data.guardianName,
          guardian_phone: data.guardianPhone,
          emergency_contact_name: data.emergencyContactName,
          emergency_contact_relation: data.emergencyContactRelation,
          emergency_contact_phone: data.emergencyContactPhone,
          permanent_address: data.permanentAddress,
          permanent_city: data.permanentCity,
          permanent_state: data.permanentState,
          permanent_pincode: data.permanentPincode,
          current_address: data.currentAddress || data.permanentAddress,
          current_city: data.currentCity || data.permanentCity,
          current_state: data.currentState || data.permanentState,
          current_pincode: data.currentPincode || data.permanentPincode,
          tenth_percentage: data.tenthPercentage,
          twelfth_percentage: data.twelfthPercentage,
          registration_number: data.registrationNumber,
        },
        update: {
          dob: dobDate,
          blood_group: data.bloodGroup,
          father_name: data.fatherName,
          father_phone: data.fatherPhone,
          mother_name: data.motherName,
          mother_phone: data.motherPhone,
          guardian_name: data.guardianName,
          guardian_phone: data.guardianPhone,
          emergency_contact_name: data.emergencyContactName,
          emergency_contact_relation: data.emergencyContactRelation,
          emergency_contact_phone: data.emergencyContactPhone,
          permanent_address: data.permanentAddress,
          permanent_city: data.permanentCity,
          permanent_state: data.permanentState,
          permanent_pincode: data.permanentPincode,
          current_address: data.currentAddress || data.permanentAddress,
          current_city: data.currentCity || data.permanentCity,
          current_state: data.currentState || data.permanentState,
          current_pincode: data.currentPincode || data.permanentPincode,
          tenth_percentage: data.tenthPercentage,
          twelfth_percentage: data.twelfthPercentage,
          ...(data.registrationNumber && { registration_number: data.registrationNumber }),
        },
      });

      return { user, studentProfile };
    });
  }

  async updateCareerProfile(userId: string, data: any) {
    const portfolio = await prisma.portfolio.upsert({
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

    if (data.skills && Array.isArray(data.skills)) {
      await prisma.portfolioSkill.deleteMany({ where: { portfolio_id: portfolio.id } });
      if (data.skills.length > 0) {
        await prisma.portfolioSkill.createMany({
          data: data.skills.map((s: string) => ({
            portfolio_id: portfolio.id,
            skill_name: s,
          })),
        });
      }
    }

    return prisma.portfolio.findUnique({
      where: { id: portfolio.id },
      include: { skills: true, projects: true },
    });
  }

  async findPendingChangeRequestByField(studentId: string, field: string) {
    return prisma.profileChangeRequest.findFirst({
      where: {
        student_id: studentId,
        field,
        status: 'PENDING',
      },
    });
  }

  async createProfileChangeRequest(data: {
    college_id: string;
    student_id: string;
    field: string;
    category: any;
    current_value: string;
    requested_value: string;
    reason: string;
    supporting_document?: string;
  }) {
    return prisma.profileChangeRequest.create({
      data: {
        college_id: data.college_id,
        student_id: data.student_id,
        field: data.field,
        category: data.category,
        current_value: data.current_value,
        requested_value: data.requested_value,
        reason: data.reason,
        supporting_document: data.supporting_document,
        status: 'PENDING',
      },
    });
  }

  async getStudentChangeRequests(studentId: string) {
    return prisma.profileChangeRequest.findMany({
      where: { student_id: studentId },
      orderBy: { submitted_at: 'desc' },
      include: {
        reviewer: {
          select: {
            id: true,
            first_name: true,
            last_name: true,
            email: true,
          },
        },
      },
    });
  }

  async cancelChangeRequest(requestId: string, studentId: string) {
    return prisma.profileChangeRequest.update({
      where: { id: requestId, student_id: studentId, status: 'PENDING' },
      data: { status: 'CANCELLED' },
    });
  }
}

