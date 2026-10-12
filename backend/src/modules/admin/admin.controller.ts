import { Request, Response, NextFunction } from 'express';
import { AdminService } from './admin.service';
import { Role } from '@prisma/client';
import { BadRequestError, ForbiddenError, UnauthorizedError } from '../../shared/errors/AppError';

export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  private getActorContext(req: Request) {
    return {
      actorUserId: req.user?.userId,
      actorRole: req.user?.role,
      actorDeptId: req.user?.departmentId,
    };
  }

  private getCollegeId(req: Request): string {
    const collegeId = req.user?.collegeId;
    if (!collegeId) {
      throw new UnauthorizedError('Unauthorized: Missing college context in session');
    }
    return collegeId;
  }

  getMetrics = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const metrics = await this.adminService.getDashboardMetrics(collegeId);
      res.status(200).json({ success: true, data: metrics });
    } catch (err) {
      next(err);
    }
  };

  getUsers = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const query = {
        role: req.query.role as Role | undefined,
        departmentId: req.query.departmentId as string | undefined,
        search: req.query.search as string | undefined,
        page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
        limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 10,
      };

      const actor = this.getActorContext(req);
      const result = await this.adminService.getUsers(collegeId, query, actor);
      res.status(200).json({ success: true, ...result });
    } catch (err) {
      next(err);
    }
  };

  getUserById = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const userId = req.params.id;
      if (!userId) {
        throw new BadRequestError('User ID is required');
      }
      const actor = this.getActorContext(req);
      const user = await this.adminService.getUserById(userId, actor);
      res.status(200).json({ success: true, data: user });
    } catch (err) {
      next(err);
    }
  };

  createUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const { email, role } = req.body;
      if (!email || !role) {
        throw new BadRequestError('Email and role are required');
      }
      const actor = this.getActorContext(req);
      const user = await this.adminService.createUser(collegeId, req.body, actor);
      res.status(201).json({ success: true, message: 'User account created successfully', data: user });
    } catch (err) {
      next(err);
    }
  };

  updateUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const targetUserId = req.params.id;
      if (!targetUserId) {
        throw new BadRequestError('User ID is required');
      }
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const user = await this.adminService.updateUser(collegeId, targetUserId, req.body, actor);
      res.status(200).json({ success: true, message: 'User updated successfully', data: user });
    } catch (err) {
      next(err);
    }
  };

  updateUserRole = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const targetUserId = req.params.id || req.body.userId;
      const newRole = req.body.newRole || req.body.role;
      const actor = this.getActorContext(req);
      const collegeId = this.getCollegeId(req);

      if (!targetUserId) {
        throw new BadRequestError('User ID is required');
      }

      const validRoles = Object.values(Role);
      if (!newRole || !validRoles.includes(newRole)) {
        throw new BadRequestError(`Invalid role. Allowed roles: ${validRoles.join(', ')}`);
      }

      const result = await this.adminService.updateUserRole(
        { userId: targetUserId, newRole: newRole as Role },
        actor,
        collegeId
      );
      res.status(200).json({ success: true, message: 'User role updated successfully', data: result });
    } catch (err) {
      next(err);
    }
  };

  updateUserStatus = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const targetUserId = req.params.id || req.body.userId;
      const { isActive, status } = req.body;
      const actor = this.getActorContext(req);
      const collegeId = this.getCollegeId(req);

      if (!targetUserId) {
        throw new BadRequestError('User ID is required');
      }

      const result = await this.adminService.updateUserStatus(
        { userId: targetUserId, isActive, status },
        actor,
        collegeId
      );
      res.status(200).json({ success: true, message: 'User status updated successfully', data: result });
    } catch (err) {
      next(err);
    }
  };

  deleteUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const targetUserId = req.params.id;
      if (!targetUserId) {
        throw new BadRequestError('User ID is required');
      }
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      await this.adminService.deleteUser(collegeId, targetUserId, actor);
      res.status(200).json({ success: true, message: 'User moved to recycle bin successfully' });
    } catch (err) {
      next(err);
    }
  };

  getDeletedUsers = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const query = {
        role: req.query.role as any,
        departmentId: req.query.departmentId as string,
        search: req.query.search as string,
        page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
        limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 50,
      };
      const actor = this.getActorContext(req);
      const result = await this.adminService.getDeletedUsers(collegeId, query, actor);
      res.status(200).json({ success: true, data: result.data, pagination: result.meta });
    } catch (err) {
      next(err);
    }
  };

  restoreUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const targetUserId = req.params.id;
      if (!targetUserId) {
        throw new BadRequestError('User ID is required');
      }
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const restored = await this.adminService.restoreUser(collegeId, targetUserId, actor);
      res.status(200).json({ success: true, message: 'User restored successfully', data: restored });
    } catch (err) {
      next(err);
    }
  };

  permanentlyDeleteUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const targetUserId = req.params.id;
      if (!targetUserId) {
        throw new BadRequestError('User ID is required');
      }
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      await this.adminService.permanentlyDeleteUser(collegeId, targetUserId, actor);
      res.status(200).json({ success: true, message: 'User permanently deleted' });
    } catch (err) {
      next(err);
    }
  };

  purgeExpiredDeletedUsers = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const result = await this.adminService.purgeExpiredDeletedUsers(collegeId, actor);
      res.status(200).json({ success: true, message: `Purged ${result.count} expired users`, data: result });
    } catch (err) {
      next(err);
    }
  };

  setTemporaryPassword = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const targetUserId = req.params.id;
      if (!targetUserId) {
        throw new BadRequestError('User ID is required');
      }
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const { tempPassword } = req.body;
      const result = await this.adminService.setTemporaryPassword(actor, collegeId, targetUserId, tempPassword);
      res.status(200).json({ success: true, message: result.message, data: result });
    } catch (err) {
      next(err);
    }
  };

  getDepartments = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const departments = await this.adminService.getDepartments(collegeId);
      res.status(200).json({ success: true, data: departments });
    } catch (err) {
      next(err);
    }
  };

  getDepartmentById = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const deptId = req.params.id;
      if (!deptId) {
        throw new BadRequestError('Department ID is required');
      }
      const department = await this.adminService.getDepartmentById(deptId);
      res.status(200).json({ success: true, data: department });
    } catch (err) {
      next(err);
    }
  };

  getDepartmentOverview = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const deptId = req.params.id;
      if (!deptId) {
        throw new BadRequestError('Department ID is required');
      }
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const overview = await this.adminService.getDepartmentOverview(collegeId, deptId, actor);
      res.status(200).json({ success: true, data: overview });
    } catch (err) {
      next(err);
    }
  };

  getDepartmentStudents = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const deptId = req.params.id;
      if (!deptId) {
        throw new BadRequestError('Department ID is required');
      }
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const query = {
        year: req.query.year as string | undefined,
        search: req.query.search as string | undefined,
        page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
        limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 20,
      };
      const result = await this.adminService.getDepartmentStudents(collegeId, deptId, query, actor);
      res.status(200).json({ success: true, ...result });
    } catch (err) {
      next(err);
    }
  };

  getDepartmentFaculty = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const deptId = req.params.id;
      if (!deptId) {
        throw new BadRequestError('Department ID is required');
      }
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const query = {
        search: req.query.search as string | undefined,
        page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
        limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 20,
      };
      const result = await this.adminService.getDepartmentFaculty(collegeId, deptId, query, actor);
      res.status(200).json({ success: true, ...result });
    } catch (err) {
      next(err);
    }
  };

  createDepartment = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const { name, code, description, hodName } = req.body;
      if (!name || !code) {
        throw new BadRequestError('Department name and code are required');
      }
      const actor = this.getActorContext(req);
      const dept = await this.adminService.createDepartment(collegeId, { name, code, description, hodName }, actor);
      res.status(201).json({ success: true, message: 'Department created successfully', data: dept });
    } catch (err) {
      next(err);
    }
  };

  updateDepartment = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const deptId = req.params.id;
      if (!deptId) {
        throw new BadRequestError('Department ID is required');
      }
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const dept = await this.adminService.updateDepartment(collegeId, deptId, req.body, actor);
      res.status(200).json({ success: true, message: 'Department updated successfully', data: dept });
    } catch (err) {
      next(err);
    }
  };

  updateDepartmentStatus = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const deptId = req.params.id || req.body.departmentId;
      const { isActive, is_active } = req.body;
      const active = isActive !== undefined ? isActive : is_active;
      if (!deptId) {
        throw new BadRequestError('Department ID is required');
      }
      if (typeof active !== 'boolean') {
        throw new BadRequestError('isActive boolean is required');
      }
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const dept = await this.adminService.updateDepartment(collegeId, deptId, { isActive: active }, actor);
      res.status(200).json({
        success: true,
        message: `Department ${active ? 'activated' : 'deactivated'} successfully`,
        data: dept,
      });
    } catch (err) {
      next(err);
    }
  };

  deleteDepartment = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const deptId = req.params.id;
      if (!deptId) {
        throw new BadRequestError('Department ID is required');
      }
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      await this.adminService.deleteDepartment(collegeId, deptId, actor);
      res.status(200).json({ success: true, message: 'Department deleted successfully' });
    } catch (err) {
      next(err);
    }
  };

  getAnalytics = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const analytics = await this.adminService.getAnalytics(collegeId);
      res.status(200).json({ success: true, data: analytics });
    } catch (err) {
      next(err);
    }
  };

  getAuditReports = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const reports = await this.adminService.getAuditReports(collegeId, req.query);
      res.status(200).json({ success: true, data: reports });
    } catch (err) {
      next(err);
    }
  };

  getAuditReportsCsv = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const csv = await this.adminService.getAuditReportsCsv(collegeId, req.query);
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', 'attachment; filename="campushub-audit-logs.csv"');
      res.status(200).send(csv);
    } catch (err) {
      next(err);
    }
  };

  getCollegeSettings = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const college = await this.adminService.getCollegeSettings(collegeId);
      res.status(200).json({ success: true, data: college });
    } catch (err) {
      next(err);
    }
  };

  updateCollegeSettings = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const college = await this.adminService.updateCollegeSettings(collegeId, req.body, actor);
      res.status(200).json({ success: true, message: 'College settings updated successfully', data: college });
    } catch (err) {
      next(err);
    }
  };

  // ==========================================
  // ACADEMIC YEARS
  // ==========================================
  getAcademicYears = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const years = await this.adminService.getAcademicYears(collegeId);
      res.status(200).json({ success: true, data: years });
    } catch (err) {
      next(err);
    }
  };

  getAcademicYearById = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const year = await this.adminService.getAcademicYearById(req.params.id);
      res.status(200).json({ success: true, data: year });
    } catch (err) {
      next(err);
    }
  };

  createAcademicYear = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const { yearName, startDate, endDate, isActive } = req.body;
      if (!yearName || !startDate || !endDate) {
        throw new BadRequestError('yearName, startDate, and endDate are required');
      }
      const actor = this.getActorContext(req);
      const year = await this.adminService.createAcademicYear(collegeId, { yearName, startDate, endDate, isActive }, actor);
      res.status(201).json({ success: true, message: 'Academic year created successfully', data: year });
    } catch (err) {
      next(err);
    }
  };

  updateAcademicYear = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const year = await this.adminService.updateAcademicYear(collegeId, req.params.id, req.body, actor);
      res.status(200).json({ success: true, message: 'Academic year updated successfully', data: year });
    } catch (err) {
      next(err);
    }
  };

  setActiveAcademicYear = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const year = await this.adminService.setActiveAcademicYear(collegeId, req.params.id, actor);
      res.status(200).json({ success: true, message: 'Academic year activated successfully', data: year });
    } catch (err) {
      next(err);
    }
  };

  processAcademicTransition = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const result = await this.adminService.processAcademicTransition(collegeId, req.params.id, actor);
      res.status(200).json({ success: true, message: result.message, data: result });
    } catch (err) {
      next(err);
    }
  };

  // ==========================================
  // ACADEMIC TERMS
  // ==========================================
  getAcademicTerms = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const academicYearId = req.query.academicYearId as string | undefined;
      const terms = await this.adminService.getAcademicTerms(academicYearId, collegeId);
      res.status(200).json({ success: true, data: terms });
    } catch (err) {
      next(err);
    }
  };

  getAcademicTermById = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const term = await this.adminService.getAcademicTermById(req.params.id);
      res.status(200).json({ success: true, data: term });
    } catch (err) {
      next(err);
    }
  };

  createAcademicTerm = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const { academicYearId, name, termType, semesterNumber, startDate, endDate, status } = req.body;
      if (!academicYearId || !name || semesterNumber === undefined || !startDate || !endDate) {
        throw new BadRequestError('academicYearId, name, semesterNumber, startDate, and endDate are required');
      }
      const actor = this.getActorContext(req);
      const term = await this.adminService.createAcademicTerm(collegeId, req.body, actor);
      res.status(201).json({ success: true, message: 'Academic term created successfully', data: term });
    } catch (err) {
      next(err);
    }
  };

  updateAcademicTerm = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const term = await this.adminService.updateAcademicTerm(collegeId, req.params.id, req.body, actor);
      res.status(200).json({ success: true, message: 'Academic term updated successfully', data: term });
    } catch (err) {
      next(err);
    }
  };

  // ==========================================
  // ACADEMIC PROGRAMS
  // ==========================================
  getAcademicPrograms = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const departmentId = req.query.departmentId as string | undefined;
      const actor = this.getActorContext(req);
      const programs = await this.adminService.getAcademicPrograms(collegeId, departmentId, actor);
      res.status(200).json({ success: true, data: programs });
    } catch (err) {
      next(err);
    }
  };

  getAcademicProgramById = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const actor = this.getActorContext(req);
      const program = await this.adminService.getAcademicProgramById(req.params.id, actor);
      res.status(200).json({ success: true, data: program });
    } catch (err) {
      next(err);
    }
  };

  createAcademicProgram = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const { departmentId, name, code } = req.body;
      if (!departmentId || !name || !code) {
        throw new BadRequestError('departmentId, name, and code are required');
      }
      const actor = this.getActorContext(req);
      const program = await this.adminService.createAcademicProgram(collegeId, req.body, actor);
      res.status(201).json({ success: true, message: 'Academic program created successfully', data: program });
    } catch (err) {
      next(err);
    }
  };

  updateAcademicProgram = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const program = await this.adminService.updateAcademicProgram(collegeId, req.params.id, req.body, actor);
      res.status(200).json({ success: true, message: 'Academic program updated successfully', data: program });
    } catch (err) {
      next(err);
    }
  };

  // ==========================================
  // BATCHES
  // ==========================================
  getBatches = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const programId = req.query.programId as string | undefined;
      const departmentId = req.query.departmentId as string | undefined;
      const actor = this.getActorContext(req);
      const batches = await this.adminService.getBatches(collegeId, programId, departmentId, actor);
      res.status(200).json({ success: true, data: batches });
    } catch (err) {
      next(err);
    }
  };

  getBatchById = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const actor = this.getActorContext(req);
      const batch = await this.adminService.getBatchById(req.params.id, actor);
      res.status(200).json({ success: true, data: batch });
    } catch (err) {
      next(err);
    }
  };

  createBatch = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const { name, admissionYear, graduationYear } = req.body;
      if (!name || admissionYear === undefined || graduationYear === undefined) {
        throw new BadRequestError('name, admissionYear, and graduationYear are required');
      }
      const actor = this.getActorContext(req);
      const batch = await this.adminService.createBatch(collegeId, req.body, actor);
      res.status(201).json({ success: true, message: 'Batch created successfully', data: batch });
    } catch (err) {
      next(err);
    }
  };

  updateBatch = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const batch = await this.adminService.updateBatch(collegeId, req.params.id, req.body, actor);
      res.status(200).json({ success: true, message: 'Batch updated successfully', data: batch });
    } catch (err) {
      next(err);
    }
  };

  // ==========================================
  // SUBJECTS & COURSES
  // ==========================================
  getSubjects = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const departmentId = req.query.departmentId as string | undefined;
      const semester = req.query.semester as string | undefined;
      const academicTermId = req.query.academicTermId as string | undefined;
      const actor = this.getActorContext(req);
      const subjects = await this.adminService.getSubjects(collegeId, departmentId, semester, academicTermId, actor);
      res.status(200).json({ success: true, data: subjects });
    } catch (err) {
      next(err);
    }
  };

  getSubjectById = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const actor = this.getActorContext(req);
      const subject = await this.adminService.getSubjectById(req.params.id, actor);
      res.status(200).json({ success: true, data: subject });
    } catch (err) {
      next(err);
    }
  };

  createSubject = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const { code, name, facultyId, semester } = req.body;
      if (!code || !name || !facultyId || !semester) {
        throw new BadRequestError('code, name, facultyId, and semester are required');
      }
      const actor = this.getActorContext(req);
      const subject = await this.adminService.createSubject(collegeId, req.body, actor);
      res.status(201).json({ success: true, message: 'Subject created successfully', data: subject });
    } catch (err) {
      next(err);
    }
  };

  updateSubject = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const subject = await this.adminService.updateSubject(collegeId, req.params.id, req.body, actor);
      res.status(200).json({ success: true, message: 'Subject updated successfully', data: subject });
    } catch (err) {
      next(err);
    }
  };

  // ==========================================
  // CURRICULUM SUBJECTS
  // ==========================================
  getCurriculumSubjects = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const programId = req.query.programId as string | undefined;
      const batchYear = req.query.batchYear ? parseInt(req.query.batchYear as string, 10) : undefined;
      const semesterNumber = req.query.semesterNumber ? parseInt(req.query.semesterNumber as string, 10) : undefined;
      const items = await this.adminService.getCurriculumSubjects(programId, batchYear, semesterNumber);
      res.status(200).json({ success: true, data: items });
    } catch (err) {
      next(err);
    }
  };

  createCurriculumSubject = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const { programId, subjectId, batchYear, semesterNumber } = req.body;
      if (!programId || !subjectId || batchYear === undefined || semesterNumber === undefined) {
        throw new BadRequestError('programId, subjectId, batchYear, and semesterNumber are required');
      }
      const actor = this.getActorContext(req);
      const item = await this.adminService.createCurriculumSubject(collegeId, req.body, actor);
      res.status(201).json({ success: true, message: 'Subject mapped to curriculum successfully', data: item });
    } catch (err) {
      next(err);
    }
  };

  deleteCurriculumSubject = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const deleted = await this.adminService.deleteCurriculumSubject(collegeId, req.params.id, actor);
      res.status(200).json({ success: true, message: 'Subject removed from curriculum successfully', data: deleted });
    } catch (err) {
      next(err);
    }
  };

  // ==========================================
  // ACADEMIC CLASSES
  // ==========================================
  getAcademicClasses = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const departmentId = req.query.departmentId as string | undefined;
      const yearOfStudy = req.query.yearOfStudy ? parseInt(req.query.yearOfStudy as string, 10) : undefined;
      const semester = req.query.semester ? parseInt(req.query.semester as string, 10) : undefined;
      const actor = this.getActorContext(req);
      const classes = await this.adminService.getAcademicClasses(collegeId, departmentId, yearOfStudy, semester, actor);
      res.status(200).json({ success: true, data: classes });
    } catch (err) {
      next(err);
    }
  };

  getAcademicClassById = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const actor = this.getActorContext(req);
      const cls = await this.adminService.getAcademicClassById(req.params.id, actor);
      res.status(200).json({ success: true, data: cls });
    } catch (err) {
      next(err);
    }
  };

  createAcademicClass = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const { departmentId, name, yearOfStudy, semester } = req.body;
      if (!departmentId || !name || yearOfStudy === undefined || semester === undefined) {
        throw new BadRequestError('departmentId, name, yearOfStudy, and semester are required');
      }
      const actor = this.getActorContext(req);
      const cls = await this.adminService.createAcademicClass(collegeId, req.body, actor);
      res.status(201).json({ success: true, message: 'Academic class section created successfully', data: cls });
    } catch (err) {
      next(err);
    }
  };

  updateAcademicClass = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const cls = await this.adminService.updateAcademicClass(collegeId, req.params.id, req.body, actor);
      res.status(200).json({ success: true, message: 'Academic class section updated successfully', data: cls });
    } catch (err) {
      next(err);
    }
  };

  // ==========================================
  // ROOMS
  // ==========================================
  getRooms = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const roomType = req.query.roomType as string | undefined;
      const isActive = req.query.isActive !== undefined ? req.query.isActive === 'true' : undefined;
      const rooms = await this.adminService.getRooms(collegeId, { roomType, isActive });
      res.status(200).json({ success: true, data: rooms });
    } catch (err) {
      next(err);
    }
  };

  getRoomById = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const room = await this.adminService.getRoomById(collegeId, req.params.id);
      res.status(200).json({ success: true, data: room });
    } catch (err) {
      next(err);
    }
  };

  createRoom = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const { code, name } = req.body;
      if (!code || !name) {
        throw new BadRequestError('code and name are required');
      }
      const actor = this.getActorContext(req);
      const room = await this.adminService.createRoom(collegeId, req.body, actor);
      res.status(201).json({ success: true, message: 'Room created successfully', data: room });
    } catch (err) {
      next(err);
    }
  };

  updateRoom = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const room = await this.adminService.updateRoom(collegeId, req.params.id, req.body, actor);
      res.status(200).json({ success: true, message: 'Room updated successfully', data: room });
    } catch (err) {
      next(err);
    }
  };

  // ==========================================
  // FACULTY SUBJECT ASSIGNMENTS
  // ==========================================
  getFacultyAssignments = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const facultyId = req.query.facultyId as string | undefined;
      const subjectId = req.query.subjectId as string | undefined;
      const academicTermId = req.query.academicTermId as string | undefined;
      const assignments = await this.adminService.getFacultyAssignments(collegeId, { facultyId, subjectId, academicTermId });
      res.status(200).json({ success: true, data: assignments });
    } catch (err) {
      next(err);
    }
  };

  createFacultyAssignment = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const { facultyId, subjectId, academicTermId } = req.body;
      if (!facultyId || !subjectId || !academicTermId) {
        throw new BadRequestError('facultyId, subjectId, and academicTermId are required');
      }
      const actor = this.getActorContext(req);
      const assignment = await this.adminService.createFacultyAssignment(collegeId, req.body, actor);
      res.status(201).json({ success: true, message: 'Faculty assigned to subject successfully', data: assignment });
    } catch (err) {
      next(err);
    }
  };

  deleteFacultyAssignment = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const result = await this.adminService.deleteFacultyAssignment(collegeId, req.params.id, actor);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  };

  // ==========================================
  // FACULTY SCHEDULES / TIMETABLE
  // ==========================================
  getSchedules = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const facultyId = req.query.facultyId as string | undefined;
      const classId = req.query.classId as string | undefined;
      const roomId = req.query.roomId as string | undefined;
      const dayOfWeek = req.query.dayOfWeek as string | undefined;
      const academicTermId = req.query.academicTermId as string | undefined;
      const schedules = await this.adminService.getSchedules(collegeId, {
        facultyId,
        classId,
        roomId,
        dayOfWeek,
        academicTermId,
      });
      res.status(200).json({ success: true, data: schedules });
    } catch (err) {
      next(err);
    }
  };

  getScheduleById = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const schedule = await this.adminService.getScheduleById(collegeId, req.params.id);
      res.status(200).json({ success: true, data: schedule });
    } catch (err) {
      next(err);
    }
  };

  createSchedule = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const { facultyId, dayOfWeek, startTime, endTime } = req.body;
      if (!facultyId || !dayOfWeek || !startTime || !endTime) {
        throw new BadRequestError('facultyId, dayOfWeek, startTime, and endTime are required');
      }
      const actor = this.getActorContext(req);
      const schedule = await this.adminService.createSchedule(collegeId, req.body, actor);
      res.status(201).json({ success: true, message: 'Timetable schedule slot created successfully', data: schedule });
    } catch (err) {
      next(err);
    }
  };

  updateSchedule = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const schedule = await this.adminService.updateSchedule(collegeId, req.params.id, req.body, actor);
      res.status(200).json({ success: true, message: 'Timetable schedule slot updated successfully', data: schedule });
    } catch (err) {
      next(err);
    }
  };

  deleteSchedule = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const result = await this.adminService.deleteSchedule(collegeId, req.params.id, actor);
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  };

  // ==========================================
  // ACADEMIC MONITORING (PHASE 6)
  // ==========================================
  getMonitoringMetrics = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const departmentId = req.query.departmentId as string | undefined;
      const actor = this.getActorContext(req);
      const metrics = await this.adminService.getMonitoringMetrics(collegeId, departmentId, actor);
      res.status(200).json({ success: true, data: metrics });
    } catch (err) {
      next(err);
    }
  };

  getAttendanceSessions = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const sessions = await this.adminService.getAttendanceSessions(collegeId, req.query, actor);
      res.status(200).json({ success: true, data: sessions });
    } catch (err) {
      next(err);
    }
  };

  getAttendanceSessionById = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const session = await this.adminService.getAttendanceSessionById(collegeId, req.params.id, actor);
      res.status(200).json({ success: true, data: session });
    } catch (err) {
      next(err);
    }
  };

  getSubjectAssignments = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const assignments = await this.adminService.getSubjectAssignments(collegeId, req.query, actor);
      res.status(200).json({ success: true, data: assignments });
    } catch (err) {
      next(err);
    }
  };

  getSubjectAssignmentById = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const assignment = await this.adminService.getSubjectAssignmentById(collegeId, req.params.id, actor);
      res.status(200).json({ success: true, data: assignment });
    } catch (err) {
      next(err);
    }
  };

  getSubjectAssessments = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const assessments = await this.adminService.getSubjectAssessments(collegeId, req.query, actor);
      res.status(200).json({ success: true, data: assessments });
    } catch (err) {
      next(err);
    }
  };

  getSubjectAssessmentById = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const assessment = await this.adminService.getSubjectAssessmentById(collegeId, req.params.id, actor);
      res.status(200).json({ success: true, data: assessment });
    } catch (err) {
      next(err);
    }
  };

  // ==========================================
  // PHASE 7: BROADCAST NOTIFICATIONS & MODERATION
  // ==========================================
  sendBroadcastNotification = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const result = await this.adminService.sendBroadcastNotification(collegeId, req.body, actor);
      res.status(200).json({ success: true, message: result.message, data: result });
    } catch (err) {
      next(err);
    }
  };

  getModerationEvents = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const events = await this.adminService.getModerationEvents(collegeId, req.query, actor);
      res.status(200).json({ success: true, data: events });
    } catch (err) {
      next(err);
    }
  };

  deleteModerationEvent = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const result = await this.adminService.deleteModerationEvent(collegeId, req.params.id, actor);
      res.status(200).json({ success: true, message: result.message });
    } catch (err) {
      next(err);
    }
  };

  getModerationPosts = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const posts = await this.adminService.getModerationPosts(collegeId, req.query, actor);
      res.status(200).json({ success: true, data: posts });
    } catch (err) {
      next(err);
    }
  };

  deleteModerationPost = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const result = await this.adminService.deleteModerationPost(collegeId, req.params.id, actor);
      res.status(200).json({ success: true, message: result.message });
    } catch (err) {
      next(err);
    }
  };

  // ==========================================
  // PROFILE CHANGE REQUESTS
  // ==========================================
  getChangeRequests = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const result = await this.adminService.getChangeRequests(
        collegeId,
        {
          status: req.query.status as string | undefined,
          departmentId: req.query.departmentId as string | undefined,
          category: req.query.category as string | undefined,
          page: req.query.page ? parseInt(req.query.page as string, 10) : undefined,
          limit: req.query.limit ? parseInt(req.query.limit as string, 10) : undefined,
        },
        actor,
      );
      res.status(200).json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  };

  getChangeRequestById = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const request = await this.adminService.getChangeRequestById(collegeId, req.params.id, actor);
      res.status(200).json({ success: true, data: request });
    } catch (err) {
      next(err);
    }
  };

  approveChangeRequest = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const result = await this.adminService.approveChangeRequest(
        collegeId,
        req.params.id,
        req.body?.reviewComment,
        actor,
      );
      res.status(200).json({ success: true, message: 'Profile change request approved and applied', data: result });
    } catch (err) {
      next(err);
    }
  };

  rejectChangeRequest = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = this.getCollegeId(req);
      const actor = this.getActorContext(req);
      const rejectionReason = req.body?.rejectionReason || req.body?.reviewComment || req.body?.reason;
      const result = await this.adminService.rejectChangeRequest(
        collegeId,
        req.params.id,
        rejectionReason,
        actor,
      );
      res.status(200).json({ success: true, message: 'Profile change request rejected', data: result });
    } catch (err) {
      next(err);
    }
  };
}

