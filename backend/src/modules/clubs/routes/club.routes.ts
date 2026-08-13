import { Router } from 'express';
import { ClubsRepository } from '../clubs.repository';
import { ClubsService } from '../clubs.service';
import { ClubsController } from '../clubs.controller';
import { requireAuth, requireRole } from '../../../shared/middlewares/auth.middleware';
import { validateRequest } from '../../../shared/middlewares/validate.middleware';
import {
  createClubSchema,
  verifyClubSchema,
  updateClubMemberSchema,
  createClubPostSchema,
  createClubEventSchema,
  createClubResourceSchema,
  sendClubChatMessageSchema,
  queryClubsSchema,
} from '../clubs.validation';

const clubsRepository = new ClubsRepository();
const clubsService = new ClubsService(clubsRepository);
const clubsController = new ClubsController(clubsService);

export const clubsRouter = Router();

clubsRouter.use(requireAuth());

// Public / Approved Clubs Listing
clubsRouter.get('/', validateRequest(queryClubsSchema), clubsController.getClubs);

// Admin: List pending club requests for verification
clubsRouter.get(
  '/pending',
  requireRole('ADMIN'),
  clubsController.getPendingClubs
);

// Get user proposed clubs and approval status
clubsRouter.get('/my-proposed', clubsController.getMyProposedClubs);

// Create a new club (Students & Faculty can create, admins can auto-approve)
clubsRouter.post('/', requireRole('STUDENT', 'FACULTY', 'ADMIN'), validateRequest(createClubSchema), clubsController.createClub);

// Club Details
clubsRouter.get('/:clubId', clubsController.getClubDetails);

// Admin: Verify (Approve / Reject) Club
clubsRouter.patch(
  '/:clubId/verify',
  requireRole('ADMIN'),
  validateRequest(verifyClubSchema),
  clubsController.verifyClub
);

// Delete / Withdraw Club
clubsRouter.delete('/:clubId', clubsController.deleteClub);

// Join & Leave Club
clubsRouter.post('/:clubId/join', clubsController.joinClub);
clubsRouter.post('/:clubId/leave', clubsController.leaveClub);

// Club Members
clubsRouter.get('/:clubId/members', clubsController.getClubMembers);
clubsRouter.post('/:clubId/members', clubsController.addMember);
clubsRouter.patch(
  '/:clubId/members/:userId',
  validateRequest(updateClubMemberSchema),
  clubsController.updateMemberRole
);

// Club Feed (Posts)
clubsRouter.get('/:clubId/feed', clubsController.getClubFeed);
clubsRouter.post(
  '/:clubId/feed',
  validateRequest(createClubPostSchema),
  clubsController.createClubPost
);

// Club Events
clubsRouter.get('/:clubId/events', clubsController.getClubEvents);
clubsRouter.post(
  '/:clubId/events',
  validateRequest(createClubEventSchema),
  clubsController.createClubEvent
);

// Club Resources
clubsRouter.get('/:clubId/resources', clubsController.getClubResources);
clubsRouter.post(
  '/:clubId/resources',
  validateRequest(createClubResourceSchema),
  clubsController.createClubResource
);
clubsRouter.delete('/:clubId/resources/:resourceId', clubsController.deleteClubResource);

// Club Real-time Chat
clubsRouter.get('/:clubId/chat/room', clubsController.getClubChatRoom);
clubsRouter.get('/:clubId/chat/messages', clubsController.getClubChatMessages);
clubsRouter.post(
  '/:clubId/chat/messages',
  validateRequest(sendClubChatMessageSchema),
  clubsController.sendClubChatMessage
);

export default clubsRouter;
