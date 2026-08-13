import { Request, Response } from 'express';
import { ClubsService } from './clubs.service';
import { asyncHandler } from '../../shared/utils/async-handler.util';
import { ResponseUtil } from '../../shared/utils/api-response.util';
import { ClubStatus } from '@prisma/client';

export class ClubsController {
  constructor(private readonly clubsService: ClubsService) {}

  createClub = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const club = await this.clubsService.createClub(user.userId, user.collegeId, user.role, req.body);
    ResponseUtil.success(res, club, 'Club created successfully', 201);
  });

  getClubs = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const query = {
      category: req.query.category as string,
      status: req.query.status as ClubStatus,
      search: req.query.search as string,
      is_cross_department: req.query.is_cross_department !== undefined ? req.query.is_cross_department === 'true' : undefined,
      page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 10,
    };

    const result = await this.clubsService.getClubs(user.collegeId, query);
    ResponseUtil.success(res, result, 'Clubs retrieved successfully');
  });

  getPendingClubs = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const page = req.query.page ? parseInt(req.query.page as string, 10) : 1;
    const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 10;

    const result = await this.clubsService.getPendingClubs(user.collegeId, user.role, page, limit);
    ResponseUtil.success(res, result, 'Pending club requests retrieved successfully');
  });

  getMyProposedClubs = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const clubs = await this.clubsService.getMyProposedClubs(user.userId);
    ResponseUtil.success(res, clubs, 'User proposed clubs retrieved successfully');
  });

  getClubDetails = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { clubId } = req.params;
    const club = await this.clubsService.getClubDetails(clubId, user.collegeId);
    ResponseUtil.success(res, club, 'Club details retrieved successfully');
  });

  verifyClub = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const clubId = req.params?.clubId || req.body?.clubId || '';
    const club = await this.clubsService.verifyClub(clubId, user.collegeId, user.userId, user.role, req.body);
    ResponseUtil.success(res, club, `Club status updated to ${req.body.status}`);
  });

  deleteClub = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const clubId = req.params?.clubId || req.body?.clubId || '';
    await this.clubsService.deleteClub(clubId, user.userId, user.role);
    ResponseUtil.success(res, null, 'Club request withdrawn successfully');
  });

  joinClub = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { clubId } = req.params;
    const member = await this.clubsService.joinClub(clubId, user.userId, user.collegeId);
    ResponseUtil.success(res, member, 'Successfully joined the club');
  });

  leaveClub = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { clubId } = req.params;
    const result = await this.clubsService.leaveClub(clubId, user.userId, user.collegeId);
    ResponseUtil.success(res, result, 'Successfully left the club');
  });

  addMember = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const clubId = req.params?.clubId || req.body?.clubId || '';
    const member = await this.clubsService.addMember(clubId, user.collegeId, user.userId, user.role, req.body);
    ResponseUtil.success(res, member, 'Member added to club successfully', 201);
  });

  updateMemberRole = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { clubId, userId } = req.params;
    const updated = await this.clubsService.updateMemberRole(
      clubId,
      userId,
      user.userId,
      user.collegeId,
      user.role,
      req.body
    );
    ResponseUtil.success(res, updated, 'Member role updated successfully');
  });

  getClubMembers = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { clubId } = req.params;
    const members = await this.clubsService.getClubMembers(clubId, user.collegeId);
    ResponseUtil.success(res, members, 'Club members retrieved successfully');
  });

  getClubFeed = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { clubId } = req.params;
    const page = req.query.page ? parseInt(req.query.page as string, 10) : 1;
    const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 10;
    const feed = await this.clubsService.getClubFeed(clubId, user.collegeId, user.userId, page, limit);
    ResponseUtil.success(res, feed, 'Club feed retrieved successfully');
  });

  createClubPost = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { clubId } = req.params;
    const post = await this.clubsService.createClubPost(clubId, user.userId, user.collegeId, user.role, req.body);
    ResponseUtil.success(res, post, 'Post created in club feed', 201);
  });

  getClubEvents = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { clubId } = req.params;
    const events = await this.clubsService.getClubEvents(clubId, user.collegeId);
    ResponseUtil.success(res, events, 'Club events retrieved successfully');
  });

  createClubEvent = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { clubId } = req.params;
    const event = await this.clubsService.createClubEvent(clubId, user.userId, user.collegeId, user.role, req.body);
    ResponseUtil.success(res, event, 'Club event created successfully', 201);
  });

  getClubResources = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { clubId } = req.params;
    const resources = await this.clubsService.getClubResources(clubId, user.collegeId);
    ResponseUtil.success(res, resources, 'Club resources retrieved successfully');
  });

  createClubResource = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { clubId } = req.params;
    const resource = await this.clubsService.createClubResource(clubId, user.userId, user.collegeId, user.role, req.body);
    ResponseUtil.success(res, resource, 'Club resource uploaded successfully', 201);
  });

  deleteClubResource = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { clubId, resourceId } = req.params;
    await this.clubsService.deleteClubResource(clubId, resourceId, user.userId, user.collegeId, user.role);
    ResponseUtil.success(res, null, 'Club resource deleted successfully');
  });

  getClubChatRoom = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { clubId } = req.params;
    const room = await this.clubsService.getClubChatRoom(clubId, user.userId, user.collegeId, user.role);
    ResponseUtil.success(res, room, 'Club chat room retrieved successfully');
  });

  getClubChatMessages = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { clubId } = req.params;
    const messages = await this.clubsService.getClubChatMessages(clubId, user.userId, user.collegeId, user.role);
    ResponseUtil.success(res, messages, 'Club chat messages retrieved successfully');
  });

  sendClubChatMessage = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { clubId } = req.params;
    const message = await this.clubsService.sendClubChatMessage(clubId, user.userId, user.collegeId, user.role, req.body);
    ResponseUtil.success(res, message, 'Message sent successfully', 201);
  });
}
