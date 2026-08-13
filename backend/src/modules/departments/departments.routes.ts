import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { requireAuth } from '../../shared/middlewares/auth.middleware';
import { DepartmentsRepository } from './departments.repository';
import { DepartmentsService } from './departments.service';
import { DepartmentsController } from './departments.controller';

const prisma = new PrismaClient();
const repo = new DepartmentsRepository(prisma);
const service = new DepartmentsService(repo);
const controller = new DepartmentsController(service);

export const departmentsRouter = Router();

departmentsRouter.use(requireAuth);
departmentsRouter.get('/related', controller.getRelatedDepartments);

export default departmentsRouter;
