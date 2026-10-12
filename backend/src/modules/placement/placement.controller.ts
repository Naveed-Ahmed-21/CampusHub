import { Request, Response } from 'express';
import { PlacementService } from './placement.service';
import { asyncHandler } from '../../shared/utils/async-handler.util';
import { ResponseUtil } from '../../shared/utils/api-response.util';
import { ApplicationStatus, DriveStatus } from '@prisma/client';

export class PlacementController {
  constructor(private readonly placementService: PlacementService) {}

  private getCollegeId(user: any): string {
    return user?.collegeId || user?.college_id || '';
  }

  private getUserId(user: any): string {
    return user?.userId || user?.id || '';
  }

  private getDepartmentId(user: any): string | null {
    return user?.departmentId || user?.department_id || null;
  }

  // ==========================================
  // DASHBOARDS & ANALYTICS
  // ==========================================

  getOfficerDashboard = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const collegeId = this.getCollegeId(user);
    const stats = await this.placementService.getOfficerDashboard(collegeId, user.role);
    ResponseUtil.success(res, stats, 'Placement officer dashboard metrics retrieved');
  });

  getDepartmentPlacementStats = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const collegeId = this.getCollegeId(user);
    const userDeptId = this.getDepartmentId(user);
    const queryDeptId = (req.query.department_id as string) || userDeptId || '';
    const stats = await this.placementService.getDepartmentPlacementStats(
      collegeId,
      userDeptId,
      queryDeptId,
      user.role
    );
    ResponseUtil.success(res, stats, 'Department placement statistics retrieved');
  });

  getStudentDashboard = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const userId = this.getUserId(user);
    const stats = await this.placementService.getStudentDashboard(userId);
    ResponseUtil.success(res, stats, 'Student placement dashboard retrieved');
  });

  // ==========================================
  // DRIVES
  // ==========================================

  createDrive = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const collegeId = this.getCollegeId(user);
    const userId = this.getUserId(user);
    const drive = await this.placementService.createDrive(collegeId, userId, user.role, req.body);
    ResponseUtil.success(res, drive, 'Placement drive created successfully', 201);
  });

  updateDrive = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const collegeId = this.getCollegeId(user);
    const { id } = req.params;
    const drive = await this.placementService.updateDrive(id, collegeId, user.role, req.body);
    ResponseUtil.success(res, drive, 'Placement drive updated successfully');
  });

  getDrives = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const collegeId = this.getCollegeId(user);
    const query = {
      status: req.query.status as DriveStatus,
      search: req.query.search as string,
      target_year: req.query.target_year ? parseInt(req.query.target_year as string, 10) : undefined,
      employment_type: req.query.employment_type as string,
      page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 20,
    };
    const drives = await this.placementService.getDrives(collegeId, query);
    ResponseUtil.success(res, drives, 'Placement drives retrieved successfully');
  });

  getDriveDetails = asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params;
    const drive = await this.placementService.getDriveDetails(id);
    ResponseUtil.success(res, drive, 'Placement drive details retrieved');
  });

  // ==========================================
  // APPLICATIONS
  // ==========================================

  applyForDrive = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const userId = this.getUserId(user);
    const collegeId = this.getCollegeId(user);
    const application = await this.placementService.applyForDrive(userId, collegeId, req.body);
    ResponseUtil.success(res, application, 'Applied for placement drive successfully', 201);
  });

  getApplications = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const collegeId = this.getCollegeId(user);
    const query = {
      drive_id: req.query.drive_id as string,
      status: req.query.status as ApplicationStatus,
      department_id: req.query.department_id as string,
      search: req.query.search as string,
      page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 20,
    };
    const applications = await this.placementService.getApplications(collegeId, user.role, query);
    ResponseUtil.success(res, applications, 'Applications retrieved successfully');
  });

  getApplicationById = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const userId = this.getUserId(user);
    const { id } = req.params;
    const application = await this.placementService.getApplicationById(id, userId, user.role);
    ResponseUtil.success(res, application, 'Application details retrieved');
  });

  updateApplicationStatus = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { applicationId } = req.params;
    const application = await this.placementService.updateApplicationStatus(applicationId, user.role, req.body);
    ResponseUtil.success(res, application, 'Application status updated');
  });

  bulkUpdateApplicationStatus = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const result = await this.placementService.bulkUpdateApplicationStatus(user.role, req.body);
    ResponseUtil.success(res, result, 'Bulk applications status updated');
  });

  // ==========================================
  // INTERVIEWS & OFFERS
  // ==========================================

  scheduleInterview = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const interview = await this.placementService.scheduleInterview(user.role, req.body);
    ResponseUtil.success(res, interview, 'Interview scheduled successfully', 201);
  });

  getInterviews = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const collegeId = this.getCollegeId(user);
    const query = {
      status: req.query.status as string,
      drive_id: req.query.drive_id as string,
      page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 20,
    };
    const interviews = await this.placementService.getInterviews(collegeId, query);
    ResponseUtil.success(res, interviews, 'Interviews retrieved successfully');
  });

  respondToOffer = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const userId = this.getUserId(user);
    const { applicationId } = req.params;
    const application = await this.placementService.respondToOffer(applicationId, userId, req.body);
    ResponseUtil.success(res, application, 'Offer response updated successfully');
  });

  // ==========================================
  // COMPANIES
  // ==========================================

  createCompany = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const collegeId = this.getCollegeId(user);
    const company = await this.placementService.createCompany(collegeId, user.role, req.body);
    ResponseUtil.success(res, company, 'Company profile created successfully', 201);
  });

  updateCompany = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const collegeId = this.getCollegeId(user);
    const { id } = req.params;
    const company = await this.placementService.updateCompany(id, collegeId, user.role, req.body);
    ResponseUtil.success(res, company, 'Company profile updated successfully');
  });

  getCompanies = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const collegeId = this.getCollegeId(user);
    const search = req.query.search as string;
    const companies = await this.placementService.getCompanies(collegeId, search);
    ResponseUtil.success(res, companies, 'Companies retrieved successfully');
  });

  lookupCompany = asyncHandler(async (req: Request, res: Response) => {
    const query = (req.query.query as string) || (req.query.name as string) || '';
    const results = await this.placementService.lookupCompany(query);
    ResponseUtil.success(res, results, 'Company online lookup results retrieved');
  });

  getCompanyDetails = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const collegeId = this.getCollegeId(user);
    const { id } = req.params;
    const company = await this.placementService.getCompanyDetails(id, collegeId);
    ResponseUtil.success(res, company, 'Company details retrieved');
  });

  // ==========================================
  // PREPARATION RESOURCES
  // ==========================================

  createResource = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const collegeId = this.getCollegeId(user);
    const userId = this.getUserId(user);
    const resource = await this.placementService.createResource(collegeId, userId, user.role, req.body);
    ResponseUtil.success(res, resource, 'Preparation resource uploaded successfully', 201);
  });

  getResources = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const collegeId = this.getCollegeId(user);
    const query = {
      category: req.query.category as string,
      resource_type: req.query.resource_type as string,
      company_id: req.query.company_id as string,
      drive_id: req.query.drive_id as string,
      search: req.query.search as string,
      page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 20,
    };
    const resources = await this.placementService.getResources(collegeId, query);
    ResponseUtil.success(res, resources, 'Preparation resources retrieved successfully');
  });

  getResourceDetails = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const collegeId = this.getCollegeId(user);
    const { id } = req.params;
    const resource = await this.placementService.getResourceDetails(id, collegeId);
    ResponseUtil.success(res, resource, 'Preparation resource details retrieved');
  });

  deleteResource = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const collegeId = this.getCollegeId(user);
    const { id } = req.params;
    await this.placementService.deleteResource(id, collegeId, user.role);
    ResponseUtil.success(res, null, 'Preparation resource deleted successfully');
  });

  // ==========================================
  // STUDENTS DIRECTORY FOR PLACEMENT
  // ==========================================

  getStudents = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const collegeId = this.getCollegeId(user);
    const userDeptId = this.getDepartmentId(user);

    // If DEPT_ADMIN, restrict student queries to their own department
    let departmentId = req.query.department_id as string;
    if (user.role === 'DEPT_ADMIN') {
      departmentId = userDeptId || '';
    }

    const query = {
      search: req.query.search as string,
      department_id: departmentId,
      year: req.query.year ? parseInt(req.query.year as string, 10) : undefined,
      status: req.query.status as any,
      min_cgpa: req.query.min_cgpa ? parseFloat(req.query.min_cgpa as string) : undefined,
      page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 20,
    };

    const students = await this.placementService.getStudentsForPlacement(collegeId, user.role, query);
    ResponseUtil.success(res, students, 'Placement student directory retrieved');
  });

  getStudentProfile = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const userId = this.getUserId(user);
    const targetUserId = req.params.id || userId;
    const profile = await this.placementService.getStudentPlacementProfile(targetUserId, user.role, userId);
    ResponseUtil.success(res, profile, 'Student placement profile retrieved');
  });
}
