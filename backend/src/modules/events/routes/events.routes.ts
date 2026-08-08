import { Router } from 'express';
import { EventsRepository } from '../events.repository';
import { EventsService } from '../events.service';
import { EventsController } from '../events.controller';
import { requireAuth, requireRole } from '../../../shared/middlewares/auth.middleware';
import { validateRequest } from '../../../shared/middlewares/validate.middleware';
import {
  createEventSchema,
  queryEventsSchema,
  markQRAttendanceSchema,
} from '../events.validation';

const eventsRepository = new EventsRepository();
const eventsService = new EventsService(eventsRepository);
const eventsController = new EventsController(eventsService);

export const eventsRouter = Router();

eventsRouter.use(requireAuth());

// Events CRUD & Listing
eventsRouter.get('/', validateRequest(queryEventsSchema), eventsController.getEvents);
eventsRouter.post('/', requireRole('STUDENT', 'FACULTY', 'PLACEMENT_OFFICER', 'ADMIN'), validateRequest(createEventSchema), eventsController.createEvent);
eventsRouter.get('/calendar', eventsController.getCalendarEvents);
eventsRouter.get('/my-registrations', eventsController.getUserRegistrations);
eventsRouter.get('/:id', eventsController.getEventDetails);

// Registrations & QR Attendance
eventsRouter.post('/:eventId/register', requireRole('STUDENT', 'FACULTY', 'ADMIN'), eventsController.registerForEvent);
eventsRouter.delete('/:eventId/register', eventsController.cancelRegistration);
eventsRouter.post('/attendance/scan', requireRole('FACULTY', 'ADMIN', 'PLACEMENT_OFFICER'), validateRequest(markQRAttendanceSchema), eventsController.markQRAttendance);

export default eventsRouter;
