import { Response } from 'express';

export interface ApiResponse<T = any> {
  success: boolean;
  message?: string;
  data?: T;
  code?: string;
  errors?: any[];
}

export class ResponseUtil {
  public static success<T>(
    res: Response,
    data: T,
    message = 'Request successful',
    statusCode = 200
  ): Response {
    const payload: ApiResponse<T> = {
      success: true,
      message,
      data,
    };
    return res.status(statusCode).json(payload);
  }

  public static error(
    res: Response,
    message = 'An unexpected error occurred',
    statusCode = 500,
    code = 'INTERNAL_SERVER_ERROR',
    errors: any[] = []
  ): Response {
    const payload: ApiResponse = {
      success: false,
      code,
      message,
      errors: errors.length > 0 ? errors : undefined,
    };
    return res.status(statusCode).json(payload);
  }
}
