import { Router } from 'express';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { AdminRepository } from './admin.repository';
import { requireAuth, requireRole } from '../../shared/middlewares/auth.middleware';

const adminRepo = new AdminRepository();
const adminService = new AdminService(adminRepo);
const adminController = new AdminController(adminService);

export const adminRouter = Router();

// Protect ALL Admin endpoints with Authentication & ADMIN Role Authorization
adminRouter.use(requireAuth());
adminRouter.use(requireRole('ADMIN'));

adminRouter.get('/metrics', adminController.getMetrics);
adminRouter.get('/users', adminController.getUsers);
adminRouter.post('/users', adminController.createUser);
adminRouter.patch('/users/role', adminController.updateUserRole);
adminRouter.patch('/users/:id/role', adminController.updateUserRole);
adminRouter.patch('/users/status', adminController.updateUserStatus);
adminRouter.get('/departments', adminController.getDepartments);
adminRouter.post('/departments', adminController.createDepartment);
adminRouter.get('/analytics', adminController.getAnalytics);
adminRouter.get('/reports', adminController.getAuditReports);
