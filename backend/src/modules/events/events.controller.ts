import { Request, Response } from 'express';
import { EventsService } from './events.service';
import { asyncHandler } from '../../shared/utils/async-handler.util';
import { ResponseUtil } from '../../shared/utils/api-response.util';

export class EventsController {
  constructor(private readonly eventsService: EventsService) {}

  createEvent = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const event = await this.eventsService.createEvent(user.userId, user.collegeId, req.body);
    ResponseUtil.success(res, event, 'Event created successfully', 201);
  });

  getEvents = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const query = {
      scope: req.query.scope as 'COLLEGE' | 'DEPARTMENT' | 'CLUB',
      department_id: req.query.department_id as string,
      club_id: req.query.club_id as string,
      category: req.query.category as string,
      search: req.query.search as string,
      page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 20,
    };
    const events = await this.eventsService.getEvents(user.collegeId, query);
    ResponseUtil.success(res, events, 'Events retrieved successfully');
  });

  getEventDetails = asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params;
    const event = await this.eventsService.getEventDetails(id);
    ResponseUtil.success(res, event, 'Event details retrieved');
  });

  getCalendarEvents = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const month = req.query.month ? parseInt(req.query.month as string, 10) : undefined;
    const year = req.query.year ? parseInt(req.query.year as string, 10) : undefined;

    const events = await this.eventsService.getCalendarEvents(user.collegeId, { month, year });
    ResponseUtil.success(res, events, 'Calendar events retrieved');
  });

  registerForEvent = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { eventId } = req.params;
    const registration = await this.eventsService.registerUserForEvent(user.userId, eventId);
    ResponseUtil.success(res, registration, 'Registered for event successfully', 201);
  });

  getUserRegistrations = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const registrations = await this.eventsService.getUserRegistrations(user.userId);
    ResponseUtil.success(res, registrations, 'User event registrations retrieved');
  });

  cancelRegistration = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { eventId } = req.params;
    await this.eventsService.cancelRegistration(user.userId, eventId);
    ResponseUtil.success(res, null, 'Event registration cancelled successfully');
  });

  markQRAttendance = asyncHandler(async (req: Request, res: Response) => {
    const attendance = await this.eventsService.markQRAttendance(req.body);
    ResponseUtil.success(res, attendance, 'QR attendance marked successfully');
  });
}
