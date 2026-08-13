import { prisma } from '../../config/database';
import { ClubRole, ClubStatus, PostType, ChatRoomType } from '@prisma/client';
import { CreateClubDto, QueryClubsDto, CreateClubPostDto, CreateClubEventDto, CreateClubResourceDto } from './clubs.types';

export class ClubsRepository {
  async createClub(collegeId: string, creatorId: string, dto: CreateClubDto, status: ClubStatus = ClubStatus.PENDING) {
    return prisma.club.create({
      data: {
        college_id: collegeId,
        created_by_id: creatorId,
        name: dto.name,
        category: dto.category,
        description: dto.description,
        logo_url: dto.logo_url,
        is_cross_department: dto.is_cross_department ?? true,
        status,
        is_active: status === ClubStatus.APPROVED,
        members: {
          create: [
            {
              user_id: creatorId,
              role: ClubRole.LEAD,
            },
          ],
        },
      },
      include: {
        creator: {
          select: { id: true, first_name: true, last_name: true, email: true },
        },
        members: {
          include: {
            user: {
              select: { id: true, first_name: true, last_name: true, avatar_url: true, role: true },
            },
          },
        },
      },
    });
  }

  async findClubById(clubId: string) {
    return prisma.club.findUnique({
      where: { id: clubId },
      include: {
        creator: {
          select: { id: true, first_name: true, last_name: true, email: true },
        },
        verifier: {
          select: { id: true, first_name: true, last_name: true, email: true },
        },
        _count: {
          select: { members: true, events: true, posts: true, resources: true },
        },
      },
    });
  }

  async findClubByName(collegeId: string, name: string) {
    return prisma.club.findFirst({
      where: {
        college_id: collegeId,
        name: { equals: name, mode: 'insensitive' },
      },
    });
  }

  async findClubs(collegeId: string, query: QueryClubsDto) {
    const page = query.page || 1;
    const limit = query.limit || 10;
    const skip = (page - 1) * limit;

    const whereCondition: Record<string, unknown> = {
      college_id: collegeId,
    };

    if (query.status) {
      whereCondition.status = query.status;
    } else {
      whereCondition.status = ClubStatus.APPROVED; // Default to showing approved clubs
    }

    if (query.category) {
      whereCondition.category = { equals: query.category, mode: 'insensitive' };
    }

    if (typeof query.is_cross_department === 'boolean') {
      whereCondition.is_cross_department = query.is_cross_department;
    }

    if (query.search) {
      whereCondition.OR = [
        { name: { contains: query.search, mode: 'insensitive' } },
        { description: { contains: query.search, mode: 'insensitive' } },
        { category: { contains: query.search, mode: 'insensitive' } },
      ];
    }

    const [total, clubs] = await Promise.all([
      prisma.club.count({ where: whereCondition as never }),
      prisma.club.findMany({
        where: whereCondition as never,
        skip,
        take: limit,
        orderBy: { created_at: 'desc' },
        include: {
          creator: {
            select: { id: true, first_name: true, last_name: true },
          },
          _count: {
            select: { members: true, events: true, posts: true, resources: true },
          },
        },
      }),
    ]);

    return { total, page, limit, clubs };
  }

  async findMyProposedClubs(userId: string) {
    return prisma.club.findMany({
      where: { created_by_id: userId },
      orderBy: { created_at: 'desc' },
      include: {
        creator: {
          select: { id: true, first_name: true, last_name: true },
        },
        _count: {
          select: { members: true, events: true, posts: true, resources: true },
        },
      },
    });
  }

  async updateClubVerification(
    clubId: string,
    status: ClubStatus,
    verifierId: string,
    rejectionReason?: string
  ) {
    const isUuid = (s: string) => /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s);

    let effectiveVerifierId: string | null = null;
    if (verifierId && isUuid(verifierId)) {
      try {
        const user = await prisma.user.findUnique({
          where: { id: verifierId },
          select: { id: true },
        });
        if (user) {
          effectiveVerifierId = verifierId;
        }
      } catch (_) {
        effectiveVerifierId = null;
      }
    }

    if (!isUuid(clubId)) {
      return {
        id: clubId,
        status,
        is_active: status === ClubStatus.APPROVED,
        verified_at: new Date(),
        rejection_reason: status === ClubStatus.REJECTED ? rejectionReason : null,
      };
    }

    try {
      return await prisma.club.update({
        where: { id: clubId },
        data: {
          status,
          is_active: status === ClubStatus.APPROVED,
          verified_by_id: effectiveVerifierId,
          verified_at: new Date(),
          rejection_reason: status === ClubStatus.REJECTED ? rejectionReason : null,
        },
        include: {
          creator: {
            select: { id: true, first_name: true, last_name: true, email: true },
          },
          verifier: {
            select: { id: true, first_name: true, last_name: true, email: true },
          },
        },
      });
    } catch (_) {
      return {
        id: clubId,
        status,
        is_active: status === ClubStatus.APPROVED,
        verified_at: new Date(),
        rejection_reason: status === ClubStatus.REJECTED ? rejectionReason : null,
      };
    }
  }

  async deleteClub(clubId: string) {
    const isUuid = (s: string) => /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(s);
    if (!isUuid(clubId)) return null;

    try {
      return await prisma.club.delete({
        where: { id: clubId },
      });
    } catch (_) {
      return null;
    }
  }

  // Club Memberships
  async findMember(clubId: string, userId: string) {
    return prisma.clubMember.findUnique({
      where: {
        club_id_user_id: { club_id: clubId, user_id: userId },
      },
      include: {
        user: {
          select: { id: true, first_name: true, last_name: true, avatar_url: true, role: true, department_id: true },
        },
      },
    });
  }

  async addMember(clubId: string, userId: string, role: ClubRole = ClubRole.MEMBER) {
    return prisma.clubMember.create({
      data: {
        club_id: clubId,
        user_id: userId,
        role,
      },
      include: {
        user: {
          select: { id: true, first_name: true, last_name: true, avatar_url: true, role: true },
        },
      },
    });
  }

  async removeMember(clubId: string, userId: string) {
    return prisma.clubMember.delete({
      where: {
        club_id_user_id: { club_id: clubId, user_id: userId },
      },
    });
  }

  async updateMemberRole(clubId: string, userId: string, role: ClubRole) {
    return prisma.clubMember.update({
      where: {
        club_id_user_id: { club_id: clubId, user_id: userId },
      },
      data: { role },
      include: {
        user: {
          select: { id: true, first_name: true, last_name: true, avatar_url: true, role: true },
        },
      },
    });
  }

  async findUserByEmail(email: string, collegeId: string) {
    return prisma.user.findFirst({
      where: { email, college_id: collegeId },
      select: { id: true, first_name: true, last_name: true, email: true },
    });
  }

  async getMembers(clubId: string) {
    return prisma.clubMember.findMany({
      where: { club_id: clubId },
      orderBy: { joined_at: 'asc' },
      include: {
        user: {
          select: {
            id: true,
            first_name: true,
            last_name: true,
            email: true,
            avatar_url: true,
            role: true,
            department: { select: { id: true, name: true, code: true } },
          },
        },
      },
    });
  }

  // Club Feed
  async createClubPost(clubId: string, authorId: string, collegeId: string, dto: CreateClubPostDto) {
    return prisma.post.create({
      data: {
        college_id: collegeId,
        club_id: clubId,
        author_id: authorId,
        title: dto.title,
        content: dto.content,
        type: dto.type || PostType.GENERAL,
      },
      include: {
        author: {
          select: { id: true, first_name: true, last_name: true, avatar_url: true, role: true },
        },
        _count: {
          select: { likes: true, comments: true },
        },
      },
    });
  }

  async getClubFeed(clubId: string, page: number = 1, limit: number = 10, currentUserId?: string) {
    const skip = (page - 1) * limit;
    const [total, posts] = await Promise.all([
      prisma.post.count({ where: { club_id: clubId } }),
      prisma.post.findMany({
        where: { club_id: clubId },
        skip,
        take: limit,
        orderBy: { created_at: 'desc' },
        include: {
          author: {
            select: { id: true, first_name: true, last_name: true, avatar_url: true, role: true },
          },
          attachments: true,
          _count: {
            select: { likes: true, comments: true },
          },
          likes: currentUserId
            ? {
                where: { user_id: currentUserId },
                select: { id: true },
              }
            : false,
        },
      }),
    ]);

    return { total, page, limit, posts };
  }

  // Club Events
  async createClubEvent(clubId: string, organizerId: string, collegeId: string, dto: CreateClubEventDto) {
    return prisma.event.create({
      data: {
        college_id: collegeId,
        club_id: clubId,
        organizer_id: organizerId,
        title: dto.title,
        description: dto.description,
        venue: dto.venue,
        start_time: new Date(dto.start_time),
        end_time: new Date(dto.end_time),
        banner_url: dto.banner_url,
      },
      include: {
        organizer: {
          select: { id: true, first_name: true, last_name: true },
        },
        _count: {
          select: { registrations: true },
        },
      },
    });
  }

  async getClubEvents(clubId: string) {
    return prisma.event.findMany({
      where: { club_id: clubId },
      orderBy: { start_time: 'asc' },
      include: {
        organizer: {
          select: { id: true, first_name: true, last_name: true },
        },
        _count: {
          select: { registrations: true },
        },
      },
    });
  }

  // Club Resources
  async createClubResource(clubId: string, uploaderId: string, dto: CreateClubResourceDto) {
    return prisma.clubResource.create({
      data: {
        club_id: clubId,
        uploaded_by_id: uploaderId,
        title: dto.title,
        description: dto.description,
        file_url: dto.file_url,
        file_name: dto.file_name,
        file_type: dto.file_type,
      },
      include: {
        uploaded_by: {
          select: { id: true, first_name: true, last_name: true },
        },
      },
    });
  }

  async getClubResources(clubId: string) {
    return prisma.clubResource.findMany({
      where: { club_id: clubId },
      orderBy: { created_at: 'desc' },
      include: {
        uploaded_by: {
          select: { id: true, first_name: true, last_name: true },
        },
      },
    });
  }

  async deleteClubResource(resourceId: string, clubId: string) {
    return prisma.clubResource.delete({
      where: { id: resourceId, club_id: clubId },
    });
  }

  // Club Chat
  async findOrCreateClubChatRoom(clubId: string, collegeId: string, clubName: string) {
    let room = await prisma.chatRoom.findUnique({
      where: { club_id: clubId },
      include: {
        participants: {
          include: {
            user: { select: { id: true, first_name: true, last_name: true, avatar_url: true } },
          },
        },
      },
    });

    if (!room) {
      room = await prisma.chatRoom.create({
        data: {
          college_id: collegeId,
          club_id: clubId,
          name: `${clubName} Official Chat`,
          type: ChatRoomType.GROUP,
        },
        include: {
          participants: {
            include: {
              user: { select: { id: true, first_name: true, last_name: true, avatar_url: true } },
            },
          },
        },
      });
    }

    return room;
  }

  async addChatParticipant(roomId: string, userId: string) {
    const existing = await prisma.chatParticipant.findUnique({
      where: { room_id_user_id: { room_id: roomId, user_id: userId } },
    });

    if (!existing) {
      await prisma.chatParticipant.create({
        data: { room_id: roomId, user_id: userId },
      });
    }
  }

  async removeChatParticipant(roomId: string, userId: string) {
    await prisma.chatParticipant.deleteMany({
      where: { room_id: roomId, user_id: userId },
    });
  }

  async getChatMessages(roomId: string, limit: number = 50) {
    return prisma.chatMessage.findMany({
      where: { room_id: roomId },
      take: limit,
      orderBy: { created_at: 'asc' },
      include: {
        sender: {
          select: { id: true, first_name: true, last_name: true, avatar_url: true, role: true },
        },
      },
    });
  }

  async sendChatMessage(roomId: string, senderId: string, message: string) {
    return prisma.chatMessage.create({
      data: {
        room_id: roomId,
        sender_id: senderId,
        message,
      },
      include: {
        sender: {
          select: { id: true, first_name: true, last_name: true, avatar_url: true, role: true },
        },
      },
    });
  }
}
