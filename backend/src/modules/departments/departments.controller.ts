import { Request, Response, NextFunction } from 'express';
import { DepartmentsService } from './departments.service';

export class DepartmentsController {
  constructor(private service: DepartmentsService) {}

  getRelatedDepartments = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const collegeId = req.user!.collegeId;
      const departmentId = req.user!.departmentId;

      const data = await this.service.getRelatedDepartments(collegeId, departmentId);

      return res.status(200).json({
        success: true,
        message: 'Related departments retrieved successfully',
        data,
      });
    } catch (error) {
      next(error);
    }
  };
}
