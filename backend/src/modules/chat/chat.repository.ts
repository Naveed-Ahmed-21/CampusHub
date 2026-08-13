import { prisma } from '../../config/database';
import { ChatRoomType } from '@prisma/client';
import { SendMessageDto } from './chat.types';

export class ChatRepository {
  async findUserRooms(userId: string, collegeId: string) {
    return prisma.chatRoom.findMany({
      where: {
        college_id: collegeId,
        participants: {
          some: { user_id: userId },
        },
      },
      orderBy: { updated_at: 'desc' },
      include: {
        club: { select: { id: true, name: true, logo_url: true } },
        department: { select: { id: true, name: true, code: true } },
        participants: {
          include: {
            user: {
              select: {
                id: true,
                first_name: true,
                last_name: true,
                email: true,
                avatar_url: true,
                role: true,
                is_online: true,
                last_seen: true,
              },
            },
          },
        },
        messages: {
          take: 1,
          orderBy: { created_at: 'desc' },
          include: {
            sender: {
              select: { id: true, first_name: true, last_name: true },
            },
            read_receipts: true,
          },
        },
      },
    });
  }

  async findDirectChatRoom(userId1: string, userId2: string, collegeId: string) {
    const room = await prisma.chatRoom.findFirst({
      where: {
        college_id: collegeId,
        type: ChatRoomType.DIRECT,
        AND: [
          { participants: { some: { user_id: userId1 } } },
          { participants: { some: { user_id: userId2 } } },
        ],
      },
      include: {
        participants: {
          include: {
            user: {
              select: {
                id: true,
                first_name: true,
                last_name: true,
                email: true,
                avatar_url: true,
                is_online: true,
                last_seen: true,
              },
            },
          },
        },
      },
    });
    return room;
  }

  async createDirectChatRoom(userId1: string, userId2: string, collegeId: string) {
    return prisma.chatRoom.create({
      data: {
        college_id: collegeId,
        type: ChatRoomType.DIRECT,
        participants: {
          create: [{ user_id: userId1 }, { user_id: userId2 }],
        },
      },
      include: {
        participants: {
          include: {
            user: {
              select: {
                id: true,
                first_name: true,
                last_name: true,
                email: true,
                avatar_url: true,
                is_online: true,
                last_seen: true,
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
          include: {
            user: {
              select: {
                id: true,
                first_name: true,
                last_name: true,
                avatar_url: true,
                is_online: true,
                last_seen: true,
              },
            },
          },
        },
      },
    });

    if (!room) {
      // Find all department members
      const users = await prisma.user.findMany({
        where: { department_id: departmentId, college_id: collegeId },
        select: { id: true },
      });

      room = await prisma.chatRoom.create({
        data: {
          college_id: collegeId,
          department_id: departmentId,
          name: `${departmentName} Department Chat`,
          type: ChatRoomType.GROUP,
          participants: {
            create: users.map((u) => ({ user_id: u.id })),
          },
        },
        include: {
          participants: {
            include: {
              user: {
                select: {
                  id: true,
                  first_name: true,
                  last_name: true,
                  avatar_url: true,
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

  async findRoomById(roomId: string) {
    return prisma.chatRoom.findUnique({
      where: { id: roomId },
      include: {
        participants: {
          include: {
            user: {
              select: {
                id: true,
                first_name: true,
                last_name: true,
                avatar_url: true,
                is_online: true,
                last_seen: true,
              },
            },
          },
        },
      },
    });
  }

  async createGroupRoom(name: string, creatorId: string, memberIds: string[], collegeId: string) {
    const allParticipantIds = Array.from(new Set([creatorId, ...memberIds]));
    return prisma.chatRoom.create({
      data: {
        college_id: collegeId,
        name,
        type: ChatRoomType.GROUP,
        participants: {
          create: allParticipantIds.map((uid) => ({ user_id: uid })),
        },
      },
      include: {
        participants: {
          include: {
            user: {
              select: {
                id: true,
                first_name: true,
                last_name: true,
                email: true,
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

  async removeParticipantFromRoom(roomId: string, userId: string) {
    return prisma.chatParticipant.deleteMany({
      where: { room_id: roomId, user_id: userId },
    });
  }

  async searchCampusUsers(collegeId: string, query?: string) {
    const whereClause: any = { college_id: collegeId };
    if (query && query.trim().length > 0) {
      const q = query.trim();
      whereClause.OR = [
        { first_name: { contains: q, mode: 'insensitive' } },
        { last_name: { contains: q, mode: 'insensitive' } },
        { email: { contains: q, mode: 'insensitive' } },
      ];
    }

    return prisma.user.findMany({
      where: whereClause,
      take: 50,
      select: {
        id: true,
        first_name: true,
        last_name: true,
        email: true,
        avatar_url: true,
        role: true,
        department_id: true,
        is_online: true,
        last_seen: true,
        department: { select: { id: true, name: true } },
      },
      orderBy: { first_name: 'asc' },
    });
  }

  async addParticipantToRoom(roomId: string, userId: string) {
    const existing = await prisma.chatParticipant.findUnique({
      where: { room_id_user_id: { room_id: roomId, user_id: userId } },
    });

    if (!existing) {
      return prisma.chatParticipant.create({
        data: { room_id: roomId, user_id: userId },
      });
    }
    return existing;
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
        },
        include: {
          sender: {
            select: { id: true, first_name: true, last_name: true, avatar_url: true, role: true },
          },
          read_receipts: {
            include: { user: { select: { id: true, first_name: true, last_name: true } } },
          },
        },
      }),
      prisma.chatRoom.update({
        where: { id: dto.roomId },
        data: { last_message_at: new Date(), updated_at: new Date() },
      }),
    ]);

    return message;
  }

  async getRoomMessages(roomId: string, page: number = 1, limit: number = 50) {
    const skip = (page - 1) * limit;

    const [total, messages] = await Promise.all([
      prisma.chatMessage.count({ where: { room_id: roomId } }),
      prisma.chatMessage.findMany({
        where: { room_id: roomId },
        skip,
        take: limit,
        orderBy: { created_at: 'asc' },
        include: {
          sender: {
            select: { id: true, first_name: true, last_name: true, avatar_url: true, role: true },
          },
          read_receipts: {
            include: {
              user: { select: { id: true, first_name: true, last_name: true } },
            },
          },
        },
      }),
    ]);

    return { total, page, limit, messages };
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
}
