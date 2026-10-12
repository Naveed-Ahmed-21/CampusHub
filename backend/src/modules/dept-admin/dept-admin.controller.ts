import { Request, Response } from 'express';
import { DeptAdminService } from './dept-admin.service';
import { asyncHandler } from '../../shared/utils/async-handler.util';
import { ResponseUtil } from '../../shared/utils/api-response.util';

export class DeptAdminController {
  constructor(private readonly service: DeptAdminService) {}

  private getUserContext(req: Request) {
    const user = req.user!;
    return {
      id: user.userId || (user as any).id,
      role: user.role,
      departmentId: user.departmentId || (user as any).department_id,
      collegeId: user.collegeId || (user as any).college_id,
    };
  }

  getDashboard = asyncHandler(async (req: Request, res: Response) => {
    const user = this.getUserContext(req);
    const queryDeptId = req.query.department_id as string | undefined;
    const data = await this.service.getDashboard(user.collegeId, user, queryDeptId);
    ResponseUtil.success(res, data, 'Department dashboard retrieved successfully');
  });

  getStudents = asyncHandler(async (req: Request, res: Response) => {
    const user = this.getUserContext(req);
    const data = await this.service.getStudents(user.collegeId, user, {
      year: req.query.year as string,
      batchId: req.query.batch_id as string,
      section: req.query.section as string,
      search: req.query.search as string,
      placementStatus: req.query.placement_status as string,
      page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 20,
    });
    ResponseUtil.success(res, data, 'Department students retrieved successfully');
  });

  getStudentById = asyncHandler(async (req: Request, res: Response) => {
    const user = this.getUserContext(req);
    const data = await this.service.getStudentById(user.collegeId, user, req.params.id);
    ResponseUtil.success(res, data, 'Student details retrieved successfully');
  });

  getFaculty = asyncHandler(async (req: Request, res: Response) => {
    const user = this.getUserContext(req);
    const data = await this.service.getFaculty(user.collegeId, user, {
      search: req.query.search as string,
      designation: req.query.designation as string,
      page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 20,
    });
    ResponseUtil.success(res, data, 'Department faculty retrieved successfully');
  });

  getFacultyById = asyncHandler(async (req: Request, res: Response) => {
    const user = this.getUserContext(req);
    const data = await this.service.getFacultyById(user.collegeId, user, req.params.id);
    ResponseUtil.success(res, data, 'Faculty profile retrieved successfully');
  });

  getAcademics = asyncHandler(async (req: Request, res: Response) => {
    const user = this.getUserContext(req);
    const data = await this.service.getAcademics(user.collegeId, user);
    ResponseUtil.success(res, data, 'Academic overview retrieved successfully');
  });

  getTimetable = asyncHandler(async (req: Request, res: Response) => {
    const user = this.getUserContext(req);
    const data = await this.service.getTimetable(user.collegeId, user, {
      dayOfWeek: (req.query.day_of_week || req.query.day) as string,
      classId: req.query.class_id as string,
    });
    ResponseUtil.success(res, data, 'Timetable schedule retrieved successfully');
  });

  createTimetableSlot = asyncHandler(async (req: Request, res: Response) => {
    const user = this.getUserContext(req);
    const data = await this.service.createTimetableSlot(user.collegeId, user, req.body);
    ResponseUtil.success(res, data, 'Timetable slot created successfully', 201);
  });

  getAttendance = asyncHandler(async (req: Request, res: Response) => {
    const user = this.getUserContext(req);
    const data = await this.service.getAttendance(user.collegeId, user);
    ResponseUtil.success(res, data, 'Department attendance retrieved successfully');
  });

  getLowAttendanceStudents = asyncHandler(async (req: Request, res: Response) => {
    const user = this.getUserContext(req);
    const data = await this.service.getLowAttendanceStudents(user.collegeId, user);
    ResponseUtil.success(res, data, 'Low attendance students retrieved successfully');
  });

  getAssignments = asyncHandler(async (req: Request, res: Response) => {
    const user = this.getUserContext(req);
    const data = await this.service.getAssignments(user.collegeId, user, {
      status: req.query.status as string,
    });
    ResponseUtil.success(res, data, 'Department assignments retrieved successfully');
  });

  getAssessments = asyncHandler(async (req: Request, res: Response) => {
    const user = this.getUserContext(req);
    const data = await this.service.getAssessments(user.collegeId, user);
    ResponseUtil.success(res, data, 'Department assessments retrieved successfully');
  });

  getResources = asyncHandler(async (req: Request, res: Response) => {
    const user = this.getUserContext(req);
    const data = await this.service.getResources(user.collegeId, user);
    ResponseUtil.success(res, data, 'Department resources retrieved successfully');
  });

  getPlacementSummary = asyncHandler(async (req: Request, res: Response) => {
    const user = this.getUserContext(req);
    const data = await this.service.getPlacementSummary(user.collegeId, user);
    ResponseUtil.success(res, data, 'Placement summary retrieved successfully');
  });

  getReports = asyncHandler(async (req: Request, res: Response) => {
    const user = this.getUserContext(req);
    const data = await this.service.getReports(user.collegeId, user, req.query.academic_year as string);
    ResponseUtil.success(res, data, 'Department reports retrieved successfully');
  });

  createAnnouncement = asyncHandler(async (req: Request, res: Response) => {
    const user = this.getUserContext(req);
    const data = await this.service.createAnnouncement(user.collegeId, user, req.body);
    ResponseUtil.success(res, data, 'Announcement published successfully', 201);
  });
}
