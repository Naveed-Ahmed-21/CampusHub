import { EventsService } from './events.service';
import { EventsRepository } from './events.repository';
import { BadRequestError, NotFoundError } from '../../shared/errors/AppError';

describe('EventsService', () => {
  let eventsRepository: jest.Mocked<EventsRepository>;
  let eventsService: EventsService;

  const mockCollegeId = 'college-123';
  const mockUserId = 'user-123';
  const mockEventId = 'event-123';

  beforeEach(() => {
    eventsRepository = {
      createEvent: jest.fn(),
      findEvents: jest.fn(),
      findEventById: jest.fn(),
      getCalendarEvents: jest.fn(),
      registerUserForEvent: jest.fn(),
      getUserRegistration: jest.fn(),
      getUserRegistrations: jest.fn(),
      cancelUserRegistration: jest.fn(),
      findRegistrationByTicketCode: jest.fn(),
      markAttendance: jest.fn(),
    } as unknown as jest.Mocked<EventsRepository>;

    eventsService = new EventsService(eventsRepository);
  });

  describe('createEvent', () => {
    it('should throw BadRequestError if end_time is before or equal to start_time', async () => {
      await expect(
        eventsService.createEvent(mockUserId, mockCollegeId, {
          title: 'Tech Fest',
          scope: 'COLLEGE',
          start_time: '2026-09-10T10:00:00Z',
          end_time: '2026-09-10T09:00:00Z',
        })
      ).rejects.toThrow(BadRequestError);
    });
  });

  describe('registerUserForEvent', () => {
    it('should throw NotFoundError if event does not exist', async () => {
      eventsRepository.findEventById.mockResolvedValue(null);
      await expect(
        eventsService.registerUserForEvent(mockUserId, 'non-existent')
      ).rejects.toThrow(NotFoundError);
    });

    it('should register user if event exists and capacity available', async () => {
      eventsRepository.findEventById.mockResolvedValue({
        id: mockEventId,
        max_capacity: 100,
        _count: { registrations: 10 },
      } as never);

      eventsRepository.getUserRegistration.mockResolvedValue(null);
      eventsRepository.registerUserForEvent.mockResolvedValue({
        id: 'reg-1',
        ticket_code: 'TICK-123',
      } as never);

      const result = await eventsService.registerUserForEvent(mockUserId, mockEventId);
      expect(result.ticket_code).toBe('TICK-123');
    });
  });

  describe('markQRAttendance', () => {
    it('should mark attendance for valid ticket code', async () => {
      eventsRepository.findRegistrationByTicketCode.mockResolvedValue({
        id: 'reg-1',
        attendance_status: 'REGISTERED',
      } as never);

      eventsRepository.markAttendance.mockResolvedValue({
        id: 'reg-1',
        attendance_status: 'ATTENDED',
      } as never);

      const result = await eventsService.markQRAttendance({ ticket_code: 'TICK-123' });
      expect(result.attendance_status).toBe('ATTENDED');
    });
  });
});
