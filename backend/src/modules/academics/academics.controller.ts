import { Request, Response } from 'express';
import { AcademicsService } from './academics.service';
import { ResponseUtil } from '../../shared/utils/api-response.util';
import { asyncHandler } from '../../shared/utils/async-handler.util';

export class AcademicsController {
  constructor(private readonly service: AcademicsService = new AcademicsService()) {}

  getSubjects = asyncHandler(async (req: Request, res: Response) => {
    const userId = req.user?.userId;
    const collegeId = req.user?.collegeId;
    const filter = {
      search: req.query.q as string || req.query.search as string,
      departmentId: req.query.departmentId as string,
      semester: req.query.semester as string,
      academicYear: req.query.academicYear as string,
      limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 50,
      page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
    };

    const subjects = await this.service.getSubjects(filter, userId, collegeId);
    ResponseUtil.success(res, subjects, 'Academic subjects retrieved successfully');
  });

  getSubjectDetails = asyncHandler(async (req: Request, res: Response) => {
    const subjectId = req.params.id as string;
    const userId = req.user?.userId;
    const data = await this.service.getSubjectDetails(subjectId, userId);
    ResponseUtil.success(res, data, 'Subject details retrieved successfully');
  });

  enrollSubject = asyncHandler(async (req: Request, res: Response) => {
    const subjectId = req.params.id as string;
    const studentId = req.user!.userId;
    const result = await this.service.enrollInSubject(subjectId, studentId);
    ResponseUtil.success(res, result, 'Enrolled in subject successfully');
  });

  unenrollSubject = asyncHandler(async (req: Request, res: Response) => {
    const subjectId = req.params.id as string;
    const studentId = req.user!.userId;
    const result = await this.service.unenrollFromSubject(subjectId, studentId);
    ResponseUtil.success(res, result, 'Unenrolled from subject successfully');
  });

  getMySubjects = asyncHandler(async (req: Request, res: Response) => {
    const studentId = req.user!.userId;
    const collegeId = req.user?.collegeId;
    const subjects = await this.service.getMyEnrolledSubjects(studentId, collegeId);
    ResponseUtil.success(res, subjects, 'Enrolled academic subjects retrieved successfully');
  });

  searchResources = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = req.user?.collegeId;
    const filter = {
      search: req.query.q as string || req.query.search as string,
      departmentId: req.query.departmentId as string,
      semester: req.query.semester as string,
      unit: req.query.unit as string,
      resourceType: req.query.resourceType as string,
      limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 50,
      page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
    };

    const resources = await this.service.searchResources(filter, collegeId);
    ResponseUtil.success(res, resources, 'Academic resources retrieved successfully');
  });

  viewResource = asyncHandler(async (req: Request, res: Response) => {
    const resourceId = req.params.id as string;
    const result = await this.service.recordResourceView(resourceId);
    ResponseUtil.success(res, result, 'Resource view recorded');
  });

  downloadResource = asyncHandler(async (req: Request, res: Response) => {
    const resourceId = req.params.id as string;
    const result = await this.service.recordResourceDownload(resourceId);
    ResponseUtil.success(res, result, 'Resource download recorded');
  });

  getFacultyDirectory = asyncHandler(async (req: Request, res: Response) => {
    const collegeId = req.user?.collegeId;
    const search = req.query.q as string || req.query.search as string;
    const departmentId = req.query.departmentId as string;
    const faculty = await this.service.getFacultyDirectory(collegeId, search, departmentId);
    ResponseUtil.success(res, faculty, 'Faculty directory retrieved successfully');
  });

  getFacultyProfile = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.params.id as string;
    const faculty = await this.service.getFacultyProfile(facultyId);
    ResponseUtil.success(res, faculty, 'Faculty profile retrieved successfully');
  });
}
