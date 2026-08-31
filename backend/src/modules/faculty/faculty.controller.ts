import { Request, Response } from 'express';
import { FacultyService } from './faculty.service';
import { ResponseUtil } from '../../shared/utils/api-response.util';
import { asyncHandler } from '../../shared/utils/async-handler.util';

export class FacultyController {
  constructor(private readonly service: FacultyService = new FacultyService()) {}

  getDashboard = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const collegeId = req.user!.collegeId;
    const data = await this.service.getDashboard(facultyId, collegeId);
    ResponseUtil.success(res, data, 'Faculty dashboard retrieved successfully');
  });

  getSubjects = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const collegeId = req.user!.collegeId;
    const data = await this.service.getSubjects(facultyId, collegeId);
    ResponseUtil.success(res, data, 'Faculty subjects retrieved successfully');
  });

  createSubject = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const collegeId = req.user!.collegeId;
    const data = await this.service.createSubject(facultyId, collegeId, req.body);
    ResponseUtil.success(res, data, 'Subject created and assigned successfully', 201);
  });

  getSubjectDetails = asyncHandler(async (req: Request, res: Response) => {
    const subjectId = req.params.id as string;
    const userId = req.user!.userId;
    const userRole = req.user!.role;
    const data = await this.service.getSubjectDetails(subjectId, userId, userRole);
    ResponseUtil.success(res, data, 'Subject details retrieved successfully');
  });

  addSubjectResource = asyncHandler(async (req: Request, res: Response) => {
    const subjectId = req.params.id as string;
    const facultyId = req.user!.userId;
    const userRole = req.user!.role;
    const data = await this.service.addSubjectResource(facultyId, subjectId, req.body, userRole);
    ResponseUtil.success(res, data, 'Academic resource uploaded and linked successfully', 201);
  });

  deleteSubjectResource = asyncHandler(async (req: Request, res: Response) => {
    const subjectId = req.params.id as string;
    const resourceId = req.params.resourceId as string;
    const facultyId = req.user!.userId;
    const userRole = req.user!.role;
    const data = await this.service.deleteSubjectResource(facultyId, subjectId, resourceId, userRole);
    ResponseUtil.success(res, data, 'Academic resource deleted successfully');
  });

  addSubjectAnnouncement = asyncHandler(async (req: Request, res: Response) => {
    const subjectId = req.params.id as string;
    const facultyId = req.user!.userId;
    const userRole = req.user!.role;
    const data = await this.service.addSubjectAnnouncement(facultyId, subjectId, req.body, userRole);
    ResponseUtil.success(res, data, 'Subject announcement published successfully', 201);
  });

  getTodaySchedule = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const data = await this.service.getTodaySchedule(facultyId);
    ResponseUtil.success(res, data, "Today's class schedule retrieved successfully");
  });

  getMentees = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const collegeId = req.user!.collegeId;
    const data = await this.service.getMentees(facultyId, collegeId);
    ResponseUtil.success(res, data, 'Faculty student mentees retrieved successfully');
  });
}
