import { Router } from 'express';
import { prisma } from '../../config/database';
import { authenticate } from '../../shared/middlewares/auth.middleware';
import { SearchRepository } from './search.repository';
import { SearchService } from './search.service';
import { SearchController } from './search.controller';

const searchRepository = new SearchRepository(prisma);
const searchService = new SearchService(searchRepository);
const searchController = new SearchController(searchService);

export const searchRouter = Router();

searchRouter.use(authenticate);
searchRouter.get('/', searchController.search);

export default searchRouter;
