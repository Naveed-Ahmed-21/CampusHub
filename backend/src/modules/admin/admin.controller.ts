import { Request, Response, NextFunction } from 'express';
import { AdminService } from './admin.service';
import { Role } from '@prisma/client';
import { BadRequestError, ForbiddenError } from '../../shared/errors/AppError';

export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  getMetrics = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = req.user?.collegeId || 'clg_default';
      const metrics = await this.adminService.getDashboardMetrics(collegeId);
      res.status(200).json({ success: true, data: metrics });
    } catch (err) {
      next(err);
    }
  };

  getUsers = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = req.user?.collegeId || 'clg_default';
      const query = {
        role: req.query.role as Role | undefined,
        departmentId: req.query.departmentId as string | undefined,
        search: req.query.search as string | undefined,
        page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
        limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 10,
      };

      const result = await this.adminService.getUsers(collegeId, query);
      res.status(200).json({ success: true, ...result });
    } catch (err) {
      next(err);
    }
  };

  createUser = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = req.user?.collegeId || 'clg_default';
      const { email, firstName, lastName, role, departmentId, rollNumber } = req.body;
      if (!email || !firstName || !lastName || !role) {
        throw new BadRequestError('Email, firstName, lastName, and role are required');
      }
      const user = await this.adminService.createUser(collegeId, { email, firstName, lastName, role, departmentId, rollNumber });
      res.status(201).json({ success: true, message: 'User account created by admin successfully', data: user });
    } catch (err) {
      next(err);
    }
  };

  updateUserRole = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const targetUserId = req.params.id || req.body.userId;
      const newRole = req.body.newRole || req.body.role;
      const actorUserId = req.user?.userId;

      if (!targetUserId) {
        throw new BadRequestError('User ID is required');
      }

      if (actorUserId && actorUserId === targetUserId) {
        throw new ForbiddenError('Users cannot modify their own role');
      }

      const validRoles = ['STUDENT', 'FACULTY', 'PLACEMENT_OFFICER', 'ADMIN', 'DEPT_ADMIN', 'COLLEGE_ADMIN', 'SUPER_ADMIN'];
      if (!newRole || !validRoles.includes(newRole)) {
        throw new BadRequestError(`Invalid role. Allowed roles: ${validRoles.join(', ')}`);
      }

      const result = await this.adminService.updateUserRole({ userId: targetUserId, newRole: newRole as Role });
      res.status(200).json({ success: true, message: 'User role updated successfully', data: result });
    } catch (err) {
      next(err);
    }
  };

  updateUserStatus = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const { userId, isActive } = req.body;
      const result = await this.adminService.updateUserStatus({ userId, isActive });
      res.status(200).json({ success: true, message: 'User status updated successfully', data: result });
    } catch (err) {
      next(err);
    }
  };

  getDepartments = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = req.user?.collegeId || 'clg_default';
      const departments = await this.adminService.getDepartments(collegeId);
      res.status(200).json({ success: true, data: departments });
    } catch (err) {
      next(err);
    }
  };

  createDepartment = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = req.user?.collegeId || 'clg_default';
      const { name, code, hodName } = req.body;
      const dept = await this.adminService.createDepartment(collegeId, { name, code, hodName });
      res.status(201).json({ success: true, message: 'Department created successfully', data: dept });
    } catch (err) {
      next(err);
    }
  };

  getAnalytics = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = req.user?.collegeId || 'clg_default';
      const analytics = await this.adminService.getAnalytics(collegeId);
      res.status(200).json({ success: true, data: analytics });
    } catch (err) {
      next(err);
    }
  };

  getAuditReports = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const collegeId = req.user?.collegeId || 'clg_default';
      const reports = await this.adminService.getAuditReports(collegeId);
      res.status(200).json({ success: true, data: reports });
    } catch (err) {
      next(err);
    }
  };
}
