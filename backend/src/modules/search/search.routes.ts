import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { requireAuth } from '../../shared/middlewares/auth.middleware';
import { SearchRepository } from './search.repository';
import { SearchService } from './search.service';
import { SearchController } from './search.controller';

const prisma = new PrismaClient();
const searchRepository = new SearchRepository(prisma);
const searchService = new SearchService(searchRepository);
const searchController = new SearchController(searchService);

export const searchRouter = Router();

searchRouter.use(requireAuth);
searchRouter.get('/', searchController.search);

export default searchRouter;
