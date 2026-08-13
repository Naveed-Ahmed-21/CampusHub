import { Request, Response, NextFunction } from 'express';
import { SearchService } from './search.service';

export class SearchController {
  constructor(private searchService: SearchService) {}

  search = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const q = (req.query.q as string) || '';
      const type = (req.query.type as string) || 'all';
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 10;
      const collegeId = req.user!.collegeId;

      const data = await this.searchService.search(collegeId, q, type, page, limit);

      return res.status(200).json({
        success: true,
        message: 'Search results retrieved successfully',
        data,
      });
    } catch (error) {
      next(error);
    }
  };
}
