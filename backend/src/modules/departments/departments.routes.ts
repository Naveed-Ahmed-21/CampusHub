import { Router } from 'express';
import { prisma } from '../../config/database';
import { authenticate } from '../../shared/middlewares/auth.middleware';
import { DepartmentsRepository } from './departments.repository';
import { DepartmentsService } from './departments.service';
import { DepartmentsController } from './departments.controller';

const repo = new DepartmentsRepository(prisma);
const service = new DepartmentsService(repo);
const controller = new DepartmentsController(service);

export const departmentsRouter = Router();

departmentsRouter.use(authenticate);
departmentsRouter.get('/related', controller.getRelatedDepartments);

export default departmentsRouter;
