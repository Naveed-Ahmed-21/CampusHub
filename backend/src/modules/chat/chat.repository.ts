import { prisma } from '../../config/database';
import { ChatRoomType, ChatRequestStatus, Role } from '@prisma/client';
import { SendMessageDto } from './chat.types';

export class ChatRepository {
  async findUserRooms(userId: string, collegeId: string, type?: ChatRoomType, search?: string) {
    const whereConditions: any = {
      college_id: collegeId,
      participants: {
        some: {
          user_id: userId,
          status: 'ACTIVE',
        },
      },
      AND: [
        {
          OR: [
            { type: { not: ChatRoomType.DIRECT } },
            { last_message_at: { not: null } },
            { messages: { some: {} } },
          ],
        },
      ],
    };

    if (type) {
      whereConditions.type = type;
    }

    if (search && search.trim().length > 0) {
      const q = search.trim();
      whereConditions.AND.push({
        OR: [
          { name: { contains: q, mode: 'insensitive' } },
          { club: { name: { contains: q, mode: 'insensitive' } } },
          { department: { name: { contains: q, mode: 'insensitive' } } },
          {
            participants: {
              some: {
                user: {
                  OR: [
                    { first_name: { contains: q, mode: 'insensitive' } },
                    { last_name: { contains: q, mode: 'insensitive' } },
                    { email: { contains: q, mode: 'insensitive' } },
                    { username: { contains: q, mode: 'insensitive' } },
                  ],
                },
              },
            },
          },
        ],
      });
    }

    const rooms = await prisma.chatRoom.findMany({
      where: whereConditions,
      orderBy: [
        { last_message_at: 'desc' },
        { updated_at: 'desc' },
      ],
      include: {
        club: { select: { id: true, name: true, logo_url: true } },
        department: { select: { id: true, name: true, code: true } },
        participants: {
          where: { status: 'ACTIVE' },
          include: {
            user: {
              select: {
                id: true,
                username: true,
                first_name: true,
                last_name: true,
                email: true,
                avatar_url: true,
                role: true,
                is_online: true,
                last_seen: true,
                department: { select: { id: true, name: true, code: true } },
              },
            },
          },
        },
        messages: {
          take: 1,
          orderBy: { created_at: 'desc' },
          include: {
            sender: {
              select: { id: true, first_name: true, last_name: true, username: true, avatar_url: true },
            },
            read_receipts: true,
          },
        },
        _count: {
          select: {
            participants: { where: { status: 'ACTIVE' } },
            messages: true,
          },
        },
      },
    });

    const roomsWithUnread = await Promise.all(
      rooms.map(async (room) => {
        const activeParticipants = room.participants.filter((p: any) => p.status === 'ACTIVE');
        const onlineParticipants = activeParticipants.filter((p: any) => p.user?.is_online);
        const userParticipant = room.participants.find((p: any) => p.user_id === userId);
        const lastReadAt = (userParticipant as any)?.last_read_at;

        let unreadCount = 0;
        try {
          const lastMsg = room.messages && room.messages.length > 0 ? room.messages[0] : null;
          // If the last message was sent by the current user, they are active and unreadCount is 0
          if (lastMsg && lastMsg.sender_id === userId) {
            unreadCount = 0;
          } else if (lastMsg && lastMsg.sender_id !== userId) {
            const hasReceipt = (lastMsg.read_receipts || []).some((r: any) => r.user_id === userId);
            if (hasReceipt) {
              unreadCount = 0;
            } else if (lastReadAt) {
              const unreadWhere: any = {
                room_id: room.id,
                sender_id: { not: userId },
                created_at: { gt: lastReadAt },
              };
              unreadCount = await prisma.chatMessage.count({ where: unreadWhere });
            } else {
              unreadCount = 1;
            }
          }
        } catch (_) {
          unreadCount = 0;
        }

        return {
          ...room,
          memberCount: room._count?.participants || activeParticipants.length,
          onlineMemberCount: onlineParticipants.length,
          unreadCount,
          participants: room.participants.map((p) => ({
            ...p,
            user: {
              ...p.user,
              username: p.user.username
                ? (p.user.username.startsWith('@') ? p.user.username : `@${p.user.username}`)
                : `@${p.user.email.split('@')[0].toLowerCase()}`,
            },
          })),
          lastMessage: room.messages && room.messages.length > 0 ? room.messages[0] : null,
        };
      })
    );

    const activeRooms = roomsWithUnread.filter((room) => {
      if (room.type === 'DIRECT') {
        return room.lastMessage !== null || room.last_message_at !== null;
      }
      return true;
    });

    activeRooms.sort((a, b) => {
      const timeA = (a.lastMessage?.created_at as Date)?.getTime() || (a.last_message_at as Date)?.getTime() || (a.updated_at as Date)?.getTime() || 0;
      const timeB = (b.lastMessage?.created_at as Date)?.getTime() || (b.last_message_at as Date)?.getTime() || (b.updated_at as Date)?.getTime() || 0;
      return timeB - timeA;
    });

    return activeRooms;
  }

  async findPublicGroups(collegeId: string, currentUserId: string, query?: string, limit: number = 30) {
    const andConditions: any[] = [
      {
        OR: [
          { club_id: null },
          { club: { status: 'APPROVED' } },
        ],
      },
    ];

    if (query && query.trim().length > 0) {
      const q = query.trim();
      andConditions.push({
        OR: [
          { name: { contains: q, mode: 'insensitive' } },
          { description: { contains: q, mode: 'insensitive' } },
        ],
      });
    }

    const whereConditions: any = {
      college_id: collegeId,
      type: ChatRoomType.GROUP,
      is_private: false,
      department_id: null,
      NOT: [
        { name: 'Whole College' },
        { name: { startsWith: 'Batch ' } },
        { name: { contains: 'Department' } },
        { club: { status: { not: 'APPROVED' } } },
      ],
      AND: andConditions,
    };

    const groups = await prisma.chatRoom.findMany({
      where: whereConditions,
      take: limit,
      orderBy: { created_at: 'desc' },
      include: {
        participants: {
          where: { user_id: currentUserId, status: 'ACTIVE' },
          select: { id: true, role: true, status: true },
        },
        _count: {
          select: {
            participants: { where: { status: 'ACTIVE' } },
            messages: true,
          },
        },
      },
    });

    return groups.map((g) => ({
      id: g.id,
      name: g.name,
      description: g.description,
      avatarUrl: g.avatar_url,
      type: g.type,
      isPrivate: g.is_private,
      createdById: g.created_by_id,
      createdAt: g.created_at,
      updatedAt: g.updated_at,
      memberCount: g._count.participants,
      isMember: g.participants.length > 0,
    }));
  }

  async findDirectChatRoom(userId1: string, userId2: string, collegeId: string) {
    return prisma.chatRoom.findFirst({
      where: {
        college_id: collegeId,
        type: ChatRoomType.DIRECT,
        AND: [
          { participants: { some: { user_id: userId1, status: 'ACTIVE' } } },
          { participants: { some: { user_id: userId2, status: 'ACTIVE' } } },
        ],
      },
      include: {
        participants: {
          where: { status: 'ACTIVE' },
          include: {
            user: {
              select: {
                id: true,
                username: true,
                first_name: true,
                last_name: true,
                email: true,
                avatar_url: true,
                role: true,
                is_online: true,
                last_seen: true,
                department: { select: { id: true, name: true, code: true } },
              },
            },
          },
        },
      },
    });
  }

  async createDirectChatRoom(userId1: string, userId2: string, collegeId: string) {
    return prisma.chatRoom.create({
      data: {
        college_id: collegeId,
        type: ChatRoomType.DIRECT,
        is_private: false,
        created_by_id: userId1,
        participants: {
          create: [
            { user_id: userId1, role: 'MEMBER', status: 'ACTIVE' },
            { user_id: userId2, role: 'MEMBER', status: 'ACTIVE' },
          ],
        },
      },
      include: {
        participants: {
          include: {
            user: {
              select: {
                id: true,
                username: true,
                first_name: true,
                last_name: true,
                email: true,
                avatar_url: true,
                role: true,
                is_online: true,
                last_seen: true,
                department: { select: { id: true, name: true, code: true } },
              },
            },
          },
        },
      },
    });
  }

  async findOrCreateDepartmentChatRoom(departmentId: string, collegeId: string, departmentName: string) {
    let room = await prisma.chatRoom.findUnique({
      where: { department_id: departmentId },
      include: {
        participants: {
          where: { status: 'ACTIVE' },
          include: {
            user: {
              select: {
                id: true,
                username: true,
                first_name: true,
                last_name: true,
                avatar_url: true,
                role: true,
                is_online: true,
                last_seen: true,
              },
            },
          },
        },
      },
    });

    if (!room) {
      const users = await prisma.user.findMany({
        where: { department_id: departmentId, college_id: collegeId, status: 'ACTIVE' },
        select: { id: true },
      });

      room = await prisma.chatRoom.create({
        data: {
          college_id: collegeId,
          department_id: departmentId,
          name: `${departmentName} Department Chat`,
          type: ChatRoomType.GROUP,
          is_private: true,
          participants: {
            create: users.map((u) => ({
              user_id: u.id,
              role: 'MEMBER',
              status: 'ACTIVE',
            })),
          },
        },
        include: {
          participants: {
            where: { status: 'ACTIVE' },
            include: {
              user: {
                select: {
                  id: true,
                  username: true,
                  first_name: true,
                  last_name: true,
                  avatar_url: true,
                  role: true,
                  is_online: true,
                  last_seen: true,
                },
              },
            },
          },
        },
      });
    }

    return room;
  }

  async addUserToDepartmentChat(departmentId: string, collegeId: string, departmentName: string, userId: string) {
    const room = await this.findOrCreateDepartmentChatRoom(departmentId, collegeId, departmentName);
    return prisma.chatParticipant.upsert({
      where: {
        room_id_user_id: {
          room_id: room.id,
          user_id: userId,
        },
      },
      update: {
        status: 'ACTIVE',
      },
      create: {
        room_id: room.id,
        user_id: userId,
        role: 'MEMBER',
        status: 'ACTIVE',
      },
    });
  }

  async findOrCreateBatchChatRoom(collegeId: string, batchName: string) {
    const roomName = `Batch ${batchName}`;
    let room = await prisma.chatRoom.findFirst({
      where: {
        college_id: collegeId,
        type: ChatRoomType.GROUP,
        name: roomName,
        department_id: null,
        club_id: null,
      },
      include: {
        participants: {
          where: { status: 'ACTIVE' },
          include: {
            user: {
              select: {
                id: true,
                username: true,
                first_name: true,
                last_name: true,
                avatar_url: true,
                role: true,
                is_online: true,
                last_seen: true,
              },
            },
          },
        },
      },
    });

    if (!room) {
      room = await prisma.chatRoom.create({
        data: {
          college_id: collegeId,
          name: roomName,
          description: `Official batch community for the ${batchName} graduating class across all departments.`,
          avatar_url: 'assets/images/gcee_logo.png',
          type: ChatRoomType.GROUP,
          is_private: true,
        },
        include: {
          participants: {
            where: { status: 'ACTIVE' },
            include: {
              user: {
                select: {
                  id: true,
                  username: true,
                  first_name: true,
                  last_name: true,
                  avatar_url: true,
                  role: true,
                  is_online: true,
                  last_seen: true,
                },
              },
            },
          },
        },
      });
    }

    return room;
  }

  async addUserToBatchChat(collegeId: string, batchName: string, userId: string) {
    const room = await this.findOrCreateBatchChatRoom(collegeId, batchName);
    return prisma.chatParticipant.upsert({
      where: {
        room_id_user_id: {
          room_id: room.id,
          user_id: userId,
        },
      },
      update: {
        status: 'ACTIVE',
      },
      create: {
        room_id: room.id,
        user_id: userId,
        role: 'MEMBER',
        status: 'ACTIVE',
      },
    });
  }

  async findOrCreateBatchDepartmentChatRoom(
    departmentId: string,
    collegeId: string,
    departmentName: string,
    batchName: string
  ) {
    const roomName = `${departmentName} (${batchName})`;
    let room = await prisma.chatRoom.findFirst({
      where: {
        college_id: collegeId,
        department_id: departmentId,
        type: ChatRoomType.GROUP,
        name: roomName,
      },
      include: {
        participants: {
          where: { status: 'ACTIVE' },
          include: {
            user: {
              select: {
                id: true,
                username: true,
                first_name: true,
                last_name: true,
                avatar_url: true,
                role: true,
                is_online: true,
                last_seen: true,
              },
            },
          },
        },
      },
    });

    if (!room) {
      room = await prisma.chatRoom.create({
        data: {
          college_id: collegeId,
          department_id: departmentId,
          name: roomName,
          description: `Official batch department chat for ${departmentName} (${batchName}).`,
          avatar_url: 'assets/images/gcee_logo.png',
          type: ChatRoomType.GROUP,
          is_private: true,
        },
        include: {
          participants: {
            where: { status: 'ACTIVE' },
            include: {
              user: {
                select: {
                  id: true,
                  username: true,
                  first_name: true,
                  last_name: true,
                  avatar_url: true,
                  role: true,
                  is_online: true,
                  last_seen: true,
                },
              },
            },
          },
        },
      });
    }

    return room;
  }

  async addUserToBatchDepartmentChat(
    departmentId: string,
    collegeId: string,
    departmentName: string,
    batchName: string,
    userId: string
  ) {
    const room = await this.findOrCreateBatchDepartmentChatRoom(departmentId, collegeId, departmentName, batchName);
    return prisma.chatParticipant.upsert({
      where: {
        room_id_user_id: {
          room_id: room.id,
          user_id: userId,
        },
      },
      update: {
        status: 'ACTIVE',
      },
      create: {
        room_id: room.id,
        user_id: userId,
        role: 'MEMBER',
        status: 'ACTIVE',
      },
    });
  }

  async findOrCreateWholeCollegeChatRoom(collegeId: string) {
    let room = await prisma.chatRoom.findFirst({
      where: {
        college_id: collegeId,
        type: ChatRoomType.GROUP,
        name: 'Whole College',
        club_id: null,
        department_id: null,
      },
      include: {
        participants: {
          where: { status: 'ACTIVE' },
          include: {
            user: {
              select: {
                id: true,
                username: true,
                first_name: true,
                last_name: true,
                avatar_url: true,
                role: true,
                is_online: true,
                last_seen: true,
              },
            },
          },
        },
      },
    });

    if (!room) {
      const adminUser = await prisma.user.findFirst({
        where: { college_id: collegeId, role: Role.ADMIN },
        select: { id: true },
      });

      const allUsers = await prisma.user.findMany({
        where: { college_id: collegeId, status: 'ACTIVE' },
        select: { id: true, role: true },
      });

      room = await prisma.chatRoom.create({
        data: {
          college_id: collegeId,
          name: 'Whole College',
          description: 'Official college-wide community and announcement group for all members of Government College of Engineering, Erode.',
          avatar_url: 'assets/images/gcee_logo.png',
          type: ChatRoomType.GROUP,
          is_private: false,
          created_by_id: adminUser?.id,
          participants: {
            create: allUsers.map((u) => ({
              user_id: u.id,
              role: u.role === Role.ADMIN ? 'ADMIN' : 'MEMBER',
              status: 'ACTIVE',
            })),
          },
        },
        include: {
          participants: {
            where: { status: 'ACTIVE' },
            include: {
              user: {
                select: {
                  id: true,
                  username: true,
                  first_name: true,
                  last_name: true,
                  avatar_url: true,
                  role: true,
                  is_online: true,
                  last_seen: true,
                },
              },
            },
          },
        },
      });
    }

    return room;
  }

  async addUserToWholeCollegeChat(collegeId: string, userId: string, role: string = 'MEMBER') {
    const room = await this.findOrCreateWholeCollegeChatRoom(collegeId);
    return prisma.chatParticipant.upsert({
      where: {
        room_id_user_id: {
          room_id: room.id,
          user_id: userId,
        },
      },
      update: {
        status: 'ACTIVE',
        ...(role === 'ADMIN' ? { role: 'ADMIN' } : {}),
      },
      create: {
        room_id: room.id,
        user_id: userId,
        role: role === 'ADMIN' ? 'ADMIN' : 'MEMBER',
        status: 'ACTIVE',
      },
    });
  }

  async syncAllUsersToWholeCollegeChat(collegeId: string) {
    const room = await this.findOrCreateWholeCollegeChatRoom(collegeId);
    const allUsers = await prisma.user.findMany({
      where: { college_id: collegeId, status: 'ACTIVE' },
      select: { id: true, role: true },
    });

    const existingParticipants = await prisma.chatParticipant.findMany({
      where: { room_id: room.id },
      select: { user_id: true },
    });
    const existingSet = new Set(existingParticipants.map((p) => p.user_id));

    const missing = allUsers.filter((u) => !existingSet.has(u.id));
    if (missing.length > 0) {
      await prisma.chatParticipant.createMany({
        data: missing.map((u) => ({
          room_id: room.id,
          user_id: u.id,
          role: u.role === Role.ADMIN ? 'ADMIN' : 'MEMBER',
          status: 'ACTIVE',
        })),
        skipDuplicates: true,
      });
    }

    const adminUser = await prisma.user.findFirst({
      where: { college_id: collegeId, role: Role.ADMIN },
      select: { id: true },
    });
    if (adminUser) {
      await prisma.chatParticipant.updateMany({
        where: { room_id: room.id, user_id: adminUser.id },
        data: { role: 'ADMIN' },
      });
    }

    return room;
  }

  async findOrCreateClubChatRoom(clubId: string, collegeId: string, clubName: string, avatarUrl?: string | null) {
    let room = await prisma.chatRoom.findUnique({
      where: { club_id: clubId },
      include: {
        club: { select: { id: true, name: true, logo_url: true } },
        participants: {
          where: { status: 'ACTIVE' },
          include: {
            user: {
              select: {
                id: true,
                username: true,
                first_name: true,
                last_name: true,
                email: true,
                avatar_url: true,
                role: true,
                is_online: true,
                last_seen: true,
                department: { select: { id: true, name: true, code: true } },
              },
            },
          },
        },
      },
    });

    if (!room) {
      const clubMembers = await prisma.clubMember.findMany({
        where: { club_id: clubId },
        select: { user_id: true, role: true },
      });

      room = await prisma.chatRoom.create({
        data: {
          college_id: collegeId,
          club_id: clubId,
          name: `${clubName} Club Chat`,
          avatar_url: avatarUrl || null,
          type: ChatRoomType.GROUP,
          is_private: false,
          participants: {
            create: clubMembers.map((m) => ({
              user_id: m.user_id,
              role: m.role === 'LEAD' || m.role === 'FACULTY_ADVISOR' ? 'ADMIN' : 'MEMBER',
              status: 'ACTIVE',
            })),
          },
        },
        include: {
          club: { select: { id: true, name: true, logo_url: true } },
          participants: {
            where: { status: 'ACTIVE' },
            include: {
              user: {
                select: {
                  id: true,
                  username: true,
                  first_name: true,
                  last_name: true,
                  email: true,
                  avatar_url: true,
                  role: true,
                  is_online: true,
                  last_seen: true,
                  department: { select: { id: true, name: true, code: true } },
                },
              },
            },
          },
        },
      });
    }

    return room;
  }

  async findRoomById(roomId: string) {
    return prisma.chatRoom.findUnique({
      where: { id: roomId },
      include: {
        club: { select: { id: true, name: true, logo_url: true } },
        department: { select: { id: true, name: true, code: true } },
        participants: {
          where: { status: 'ACTIVE' },
          include: {
            user: {
              select: {
                id: true,
                username: true,
                first_name: true,
                last_name: true,
                email: true,
                avatar_url: true,
                role: true,
                is_online: true,
                last_seen: true,
                department: { select: { id: true, name: true, code: true } },
              },
            },
          },
        },
        _count: {
          select: {
            participants: { where: { status: 'ACTIVE' } },
            messages: true,
          },
        },
      },
    });
  }

  async createGroupRoom(
    collegeId: string,
    creatorId: string,
    name: string,
    description?: string | null,
    isPrivate: boolean = false,
    memberIds: string[] = [],
    avatarUrl?: string | null
  ) {
    const uniqueMembers = Array.from(new Set(memberIds.filter((id) => id !== creatorId)));

    return prisma.chatRoom.create({
      data: {
        college_id: collegeId,
        name,
        description: description || null,
        avatar_url: avatarUrl || null,
        type: ChatRoomType.GROUP,
        is_private: isPrivate,
        created_by_id: creatorId,
        participants: {
          create: [
            { user_id: creatorId, role: 'ADMIN', status: 'ACTIVE' },
            ...uniqueMembers.map((uid) => ({
              user_id: uid,
              role: 'MEMBER',
              status: 'ACTIVE',
            })),
          ],
        },
      },
      include: {
        participants: {
          where: { status: 'ACTIVE' },
          include: {
            user: {
              select: {
                id: true,
                username: true,
                first_name: true,
                last_name: true,
                email: true,
                avatar_url: true,
                role: true,
                is_online: true,
                last_seen: true,
                department: { select: { id: true, name: true, code: true } },
              },
            },
          },
        },
        _count: {
          select: {
            participants: { where: { status: 'ACTIVE' } },
            messages: true,
          },
        },
      },
    });
  }

  async addParticipantToRoom(roomId: string, userId: string, role: string = 'MEMBER') {
    return prisma.chatParticipant.upsert({
      where: { room_id_user_id: { room_id: roomId, user_id: userId } },
      create: {
        room_id: roomId,
        user_id: userId,
        role,
        status: 'ACTIVE',
      },
      update: {
        role,
        status: 'ACTIVE',
        joined_at: new Date(),
      },
      include: {
        user: {
          select: {
            id: true,
            username: true,
            first_name: true,
            last_name: true,
            avatar_url: true,
            role: true,
          },
        },
      },
    });
  }

  async removeParticipantFromRoom(roomId: string, userId: string) {
    return prisma.chatParticipant.deleteMany({
      where: { room_id: roomId, user_id: userId },
    });
  }

  async updateRoomAvatar(roomId: string, avatarUrl: string | null) {
    return prisma.chatRoom.update({
      where: { id: roomId },
      data: {
        avatar_url: avatarUrl,
        updated_at: new Date(),
      },
    });
  }

  async searchCampusUsers(collegeId: string, currentUserId: string, query?: string) {
    const whereClause: any = {
      college_id: collegeId,
      status: 'ACTIVE',
      id: { not: currentUserId },
    };

    if (query && query.trim().length > 0) {
      const q = query.trim().replace(/^@/, '');
      const words = q.split(/\s+/).filter(Boolean);
      const orList: any[] = [
        { first_name: { contains: q, mode: 'insensitive' } },
        { last_name: { contains: q, mode: 'insensitive' } },
        { username: { contains: q, mode: 'insensitive' } },
        { email: { contains: q, mode: 'insensitive' } },
        { roll_number: { contains: q, mode: 'insensitive' } },
        { department: { name: { contains: q, mode: 'insensitive' } } },
      ];
      if (words.length > 1) {
        orList.push({
          AND: [
            { first_name: { contains: words[0], mode: 'insensitive' } },
            { last_name: { contains: words[words.length - 1], mode: 'insensitive' } },
          ],
        });
      }
      whereClause.OR = orList;
    }

    const users = await prisma.user.findMany({
      where: whereClause,
      take: 50,
      select: {
        id: true,
        username: true,
        first_name: true,
        last_name: true,
        email: true,
        avatar_url: true,
        role: true,
        department_id: true,
        is_online: true,
        last_seen: true,
        department: { select: { id: true, name: true, code: true } },
      },
      orderBy: [{ first_name: 'asc' }],
    });

    return users.map((u) => {
      const handle = u.username
        ? (u.username.startsWith('@') ? u.username : `@${u.username}`)
        : `@${u.email.split('@')[0].toLowerCase()}`;

      return {
        ...u,
        username: handle,
        fullName: `${u.first_name} ${u.last_name}`.trim(),
      };
    });
  }

  async createMessage(senderId: string, dto: SendMessageDto) {
    const [message] = await prisma.$transaction([
      prisma.chatMessage.create({
        data: {
          room_id: dto.roomId,
          sender_id: senderId,
          message: dto.message,
          media_url: dto.media_url,
          media_type: dto.media_type,
          file_name: dto.file_name,
          file_size: dto.file_size,
          reply_to_message_id: dto.reply_to_message_id || null,
        },
        include: {
          sender: {
            select: { id: true, username: true, first_name: true, last_name: true, avatar_url: true, role: true },
          },
          read_receipts: {
            include: { user: { select: { id: true, first_name: true, last_name: true } } },
          },
          reactions: {
            include: { user: { select: { id: true, first_name: true, last_name: true } } },
          },
          reply_to_message: {
            select: {
              id: true,
              sender_id: true,
              message: true,
              media_type: true,
              file_name: true,
              is_deleted_for_everyone: true,
              sender: { select: { id: true, first_name: true, last_name: true } },
            },
          },
        },
      }),
      prisma.chatRoom.update({
        where: { id: dto.roomId },
        data: { last_message_at: new Date(), updated_at: new Date() },
      }),
      prisma.chatParticipant.updateMany({
        where: { room_id: dto.roomId, user_id: senderId },
        data: { last_read_at: new Date() },
      }),
    ]);

    return message;
  }

  async findMessageById(messageId: string) {
    return prisma.chatMessage.findUnique({
      where: { id: messageId },
      include: {
        sender: {
          select: { id: true, username: true, first_name: true, last_name: true, avatar_url: true, role: true },
        },
        room: {
          select: { id: true, college_id: true, type: true, is_private: true, participants: true },
        },
        read_receipts: {
          include: { user: { select: { id: true, first_name: true, last_name: true } } },
        },
        reactions: {
          include: { user: { select: { id: true, first_name: true, last_name: true } } },
        },
        reply_to_message: {
          select: {
            id: true,
            sender_id: true,
            message: true,
            media_type: true,
            file_name: true,
            is_deleted_for_everyone: true,
            sender: { select: { id: true, first_name: true, last_name: true } },
          },
        },
      },
    });
  }

  async getRoomMessages(roomId: string, currentUserId?: string, page: number = 1, limit: number = 50) {
    if (currentUserId) {
      try {
        await prisma.chatParticipant.updateMany({
          where: { room_id: roomId, user_id: currentUserId },
          data: { last_read_at: new Date() },
        });
      } catch (_) {}
    }

    const skip = (page - 1) * limit;

    const whereConditions: any = {
      room_id: roomId,
    };

    if (currentUserId) {
      whereConditions.deletions = {
        none: { user_id: currentUserId },
      };
    }

    const [total, messages] = await Promise.all([
      prisma.chatMessage.count({ where: whereConditions }),
      prisma.chatMessage.findMany({
        where: whereConditions,
        skip,
        take: limit,
        orderBy: { created_at: 'desc' },
        include: {
          sender: {
            select: { id: true, username: true, first_name: true, last_name: true, avatar_url: true, role: true },
          },
          read_receipts: {
            include: {
              user: { select: { id: true, first_name: true, last_name: true } },
            },
          },
          reactions: {
            include: {
              user: { select: { id: true, first_name: true, last_name: true } },
            },
          },
          reply_to_message: {
            select: {
              id: true,
              sender_id: true,
              message: true,
              media_type: true,
              file_name: true,
              is_deleted_for_everyone: true,
              sender: { select: { id: true, first_name: true, last_name: true } },
            },
          },
        },
      }),
    ]);

    return { total, page, limit, messages: messages.reverse() };
  }

  async addOrToggleReaction(messageId: string, userId: string, emoji: string) {
    const existing = await prisma.chatMessageReaction.findFirst({
      where: { message_id: messageId, user_id: userId },
    });

    if (existing) {
      if (existing.emoji === emoji) {
        await prisma.chatMessageReaction.delete({
          where: { id: existing.id },
        });
      } else {
        await prisma.chatMessageReaction.update({
          where: { id: existing.id },
          data: { emoji, created_at: new Date() },
        });
      }
    } else {
      await prisma.chatMessageReaction.create({
        data: {
          message_id: messageId,
          user_id: userId,
          emoji,
        },
      });
    }

    return this.findMessageById(messageId);
  }

  async removeReaction(messageId: string, userId: string, emoji: string) {
    await prisma.chatMessageReaction.deleteMany({
      where: {
        message_id: messageId,
        user_id: userId,
        emoji,
      },
    });

    return this.findMessageById(messageId);
  }

  async deleteMessageForMe(messageId: string, userId: string) {
    await prisma.chatMessageDeletion.upsert({
      where: {
        message_id_user_id: { message_id: messageId, user_id: userId },
      },
      create: {
        message_id: messageId,
        user_id: userId,
      },
      update: {},
    });

    return { messageId, userId, success: true };
  }

  async deleteMessageForEveryone(messageId: string) {
    const updated = await prisma.chatMessage.update({
      where: { id: messageId },
      data: {
        is_deleted_for_everyone: true,
        deleted_at: new Date(),
        message: 'This message was deleted',
        media_url: null,
        file_name: null,
        file_size: null,
      },
      include: {
        sender: {
          select: { id: true, username: true, first_name: true, last_name: true, avatar_url: true, role: true },
        },
        read_receipts: {
          include: { user: { select: { id: true, first_name: true, last_name: true } } },
        },
        reactions: {
          include: { user: { select: { id: true, first_name: true, last_name: true } } },
        },
        reply_to_message: {
          select: {
            id: true,
            sender_id: true,
            message: true,
            media_type: true,
            file_name: true,
            is_deleted_for_everyone: true,
            sender: { select: { id: true, first_name: true, last_name: true } },
          },
        },
      },
    });

    return updated;
  }

  async markMessagesAsRead(roomId: string, userId: string, messageIds: string[]) {
    const readAt = new Date();

    const receiptsData = messageIds.map((msgId) => ({
      message_id: msgId,
      user_id: userId,
      read_at: readAt,
    }));

    await prisma.chatReadReceipt.createMany({
      data: receiptsData,
      skipDuplicates: true,
    });

    await prisma.chatParticipant.updateMany({
      where: { room_id: roomId, user_id: userId },
      data: { last_read_at: readAt },
    });

    return { roomId, userId, messageIds, readAt };
  }

  async updateUserOnlineStatus(userId: string, isOnline: boolean) {
    return prisma.user.update({
      where: { id: userId },
      data: {
        is_online: isOnline,
        last_seen: new Date(),
      },
      select: {
        id: true,
        first_name: true,
        last_name: true,
        is_online: true,
        last_seen: true,
      },
    });
  }

  // ==========================================
  // Student Chat Settings
  // ==========================================
  async getStudentChatSettings(studentId: string) {
    return prisma.studentChatSettings.findUnique({
      where: { student_id: studentId },
    });
  }

  async upsertStudentChatSettings(studentId: string, requireApproval: boolean) {
    return prisma.studentChatSettings.upsert({
      where: { student_id: studentId },
      update: {
        require_student_conversation_approval: requireApproval,
      },
      create: {
        student_id: studentId,
        require_student_conversation_approval: requireApproval,
      },
    });
  }

  // ==========================================
  // Chat Requests
  // ==========================================
  async findPendingChatRequest(senderId: string, recipientId: string) {
    return prisma.chatRequest.findFirst({
      where: {
        sender_id: senderId,
        recipient_id: recipientId,
        status: ChatRequestStatus.PENDING,
      },
      include: {
        sender: {
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
        recipient: {
          select: {
            id: true,
            first_name: true,
            last_name: true,
            email: true,
            avatar_url: true,
            role: true,
          },
        },
      },
    });
  }

  async findChatRequestById(requestId: string) {
    return prisma.chatRequest.findUnique({
      where: { id: requestId },
      include: {
        sender: {
          select: {
            id: true,
            first_name: true,
            last_name: true,
            email: true,
            avatar_url: true,
            role: true,
            college_id: true,
            department: { select: { id: true, name: true, code: true } },
          },
        },
        recipient: {
          select: {
            id: true,
            first_name: true,
            last_name: true,
            email: true,
            avatar_url: true,
            role: true,
            college_id: true,
          },
        },
      },
    });
  }

  async createChatRequest(senderId: string, recipientId: string, introductoryMessage: string) {
    return prisma.chatRequest.create({
      data: {
        sender_id: senderId,
        recipient_id: recipientId,
        introductory_message: introductoryMessage,
        status: ChatRequestStatus.PENDING,
      },
      include: {
        sender: {
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
        recipient: {
          select: {
            id: true,
            first_name: true,
            last_name: true,
            email: true,
            avatar_url: true,
            role: true,
          },
        },
      },
    });
  }

  async updateChatRequestStatus(requestId: string, status: ChatRequestStatus, conversationId?: string) {
    return prisma.chatRequest.update({
      where: { id: requestId },
      data: {
        status,
        conversation_id: conversationId,
        responded_at: new Date(),
      },
      include: {
        sender: {
          select: {
            id: true,
            first_name: true,
            last_name: true,
            email: true,
            avatar_url: true,
            role: true,
          },
        },
        recipient: {
          select: {
            id: true,
            first_name: true,
            last_name: true,
            email: true,
            avatar_url: true,
            role: true,
          },
        },
      },
    });
  }

  async getIncomingChatRequests(recipientId: string, status?: ChatRequestStatus) {
    return prisma.chatRequest.findMany({
      where: {
        recipient_id: recipientId,
        ...(status ? { status } : {}),
      },
      orderBy: { created_at: 'desc' },
      include: {
        sender: {
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

  async getSentChatRequests(senderId: string) {
    return prisma.chatRequest.findMany({
      where: {
        sender_id: senderId,
      },
      orderBy: { created_at: 'desc' },
      include: {
        recipient: {
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

  // ==========================================
  // Chat-Only Blocking
  // ==========================================
  async isChatBlockedBetween(user1Id: string, user2Id: string): Promise<boolean> {
    const block = await prisma.chatBlock.findFirst({
      where: {
        OR: [
          { blocker_id: user1Id, blocked_id: user2Id },
          { blocker_id: user2Id, blocked_id: user1Id },
        ],
      },
    });
    return !!block;
  }

  async getBlockRecord(user1Id: string, user2Id: string) {
    return prisma.chatBlock.findFirst({
      where: {
        OR: [
          { blocker_id: user1Id, blocked_id: user2Id },
          { blocker_id: user2Id, blocked_id: user1Id },
        ],
      },
    });
  }

  async blockUser(blockerId: string, blockedId: string) {
    return prisma.chatBlock.upsert({
      where: {
        blocker_id_blocked_id: {
          blocker_id: blockerId,
          blocked_id: blockedId,
        },
      },
      update: {},
      create: {
        blocker_id: blockerId,
        blocked_id: blockedId,
      },
    });
  }

  async unblockUser(blockerId: string, blockedId: string) {
    return prisma.chatBlock.deleteMany({
      where: {
        blocker_id: blockerId,
        blocked_id: blockedId,
      },
    });
  }

  async getBlockedUsers(userId: string) {
    const blocks = await prisma.chatBlock.findMany({
      where: { blocker_id: userId },
      include: {
        blocked: {
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
      orderBy: { created_at: 'desc' },
    });
    return blocks.map((b) => b.blocked);
  }
}
