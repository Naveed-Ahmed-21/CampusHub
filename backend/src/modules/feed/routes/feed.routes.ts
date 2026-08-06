import { Router, Request, Response, NextFunction } from 'express';
import { authenticateJwt } from '../../../shared/middlewares/auth.middleware.js';
import { ResponseUtil } from '../../../shared/utils/api-response.util.js';

const router = Router();

router.use(authenticateJwt);

router.get('/', (_req: Request, res: Response, _next: NextFunction) => {
  ResponseUtil.success(res, { feed: [] }, 'Campus feed retrieved successfully');
});

export default router;
