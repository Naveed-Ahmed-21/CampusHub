import { prisma } from '../../config/database';
import { CreateEventDto, QueryEventsDto } from './events.types';
import crypto from 'crypto';

export class EventsRepository {
  async createEvent(organizerId: string, collegeId: string, dto: CreateEventDto) {
    return prisma.event.create({
      data: {
        college_id: collegeId,
        organizer_id: organizerId,
        scope: dto.scope,
        department_id: dto.department_id,
        club_id: dto.club_id,
        category: dto.category || 'General',
        title: dto.title,
        description: dto.description,
        venue: dto.venue,
        start_time: new Date(dto.start_time),
        end_time: new Date(dto.end_time),
        banner_url: dto.banner_url,
        max_capacity: dto.max_capacity,
        registration_deadline: dto.registration_deadline ? new Date(dto.registration_deadline) : null,
      },
      include: {
        organizer: {
          select: { id: true, first_name: true, last_name: true, role: true, avatar_url: true },
        },
        department: { select: { id: true, name: true, code: true } },
        club: { select: { id: true, name: true, logo_url: true } },
      },
    });
  }

  async findEvents(collegeId: string, query: QueryEventsDto) {
    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const where: Record<string, unknown> = { college_id: collegeId };

    if (query.scope) where.scope = query.scope;
    if (query.department_id) where.department_id = query.department_id;
    if (query.club_id) where.club_id = query.club_id;
    if (query.category) where.category = { equals: query.category, mode: 'insensitive' };
    if (query.search) {
      where.OR = [
        { title: { contains: query.search, mode: 'insensitive' } },
        { description: { contains: query.search, mode: 'insensitive' } },
        { venue: { contains: query.search, mode: 'insensitive' } },
      ];
    }

    const [total, events] = await Promise.all([
      prisma.event.count({ where: where as never }),
      prisma.event.findMany({
        where: where as never,
        skip,
        take: limit,
        orderBy: { start_time: 'asc' },
        include: {
          organizer: {
            select: { id: true, first_name: true, last_name: true, role: true, avatar_url: true },
          },
          department: { select: { id: true, name: true, code: true } },
          club: { select: { id: true, name: true, logo_url: true } },
          _count: { select: { registrations: true } },
        },
      }),
    ]);

    return { total, page, limit, events };
  }

  async findEventById(eventId: string) {
    return prisma.event.findUnique({
      where: { id: eventId },
      include: {
        organizer: {
          select: { id: true, first_name: true, last_name: true, role: true, avatar_url: true },
        },
        department: { select: { id: true, name: true, code: true } },
        club: { select: { id: true, name: true, logo_url: true } },
        _count: { select: { registrations: true } },
      },
    });
  }

  async getCalendarEvents(collegeId: string, month: number, year: number) {
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59);

    return prisma.event.findMany({
      where: {
        college_id: collegeId,
        start_time: {
          gte: startDate,
          lte: endDate,
        },
      },
      orderBy: { start_time: 'asc' },
      include: {
        department: { select: { id: true, name: true, code: true } },
        club: { select: { id: true, name: true, logo_url: true } },
      },
    });
  }

  async registerUserForEvent(userId: string, eventId: string) {
    const ticketCode = `TICK-${crypto.randomBytes(4).toString('hex').toUpperCase()}`;
    const qrToken = crypto.randomBytes(16).toString('hex');

    return prisma.eventRegistration.create({
      data: {
        event_id: eventId,
        user_id: userId,
        ticket_code: ticketCode,
        qr_code_token: qrToken,
      },
      include: {
        event: true,
        user: { select: { id: true, first_name: true, last_name: true, email: true } },
      },
    });
  }

  async getUserRegistration(userId: string, eventId: string) {
    return prisma.eventRegistration.findUnique({
      where: { event_id_user_id: { event_id: eventId, user_id: userId } },
    });
  }

  async getUserRegistrations(userId: string) {
    return prisma.eventRegistration.findMany({
      where: { user_id: userId },
      orderBy: { registered_at: 'desc' },
      include: {
        event: {
          include: {
            department: { select: { id: true, name: true, code: true } },
            club: { select: { id: true, name: true } },
          },
        },
      },
    });
  }

  async cancelUserRegistration(userId: string, eventId: string) {
    return prisma.eventRegistration.delete({
      where: { event_id_user_id: { event_id: eventId, user_id: userId } },
    });
  }

  async findRegistrationByTicketCode(ticketCode: string) {
    return prisma.eventRegistration.findFirst({
      where: { ticket_code: ticketCode },
      include: {
        event: true,
        user: { select: { id: true, first_name: true, last_name: true, email: true } },
      },
    });
  }

  async markAttendance(registrationId: string) {
    return prisma.eventRegistration.update({
      where: { id: registrationId },
      data: {
        attendance_status: 'ATTENDED',
        attended_at: new Date(),
      },
      include: {
        event: true,
        user: { select: { id: true, first_name: true, last_name: true, email: true } },
      },
    });
  }
}
