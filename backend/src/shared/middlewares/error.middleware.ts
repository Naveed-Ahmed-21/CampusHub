import { Request, Response, NextFunction } from 'express';
import { AppError } from '../errors/AppError';
import { logger } from '../../infrastructure/logger/logger';
import { env } from '../../config/env.config';

export const errorHandler = (
  err: Error,
  req: Request,
  res: Response,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  next: NextFunction
): void => {
  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      success: false,
      message: err.message,
      errors: err.errors,
      stack: env.NODE_ENV === 'development' ? err.stack : undefined,
    });
    return;
  }

  logger.error({ err, path: req.path }, 'Unhandled Exception');

  res.status(500).json({
    success: false,
    message: 'Internal Server Error',
    stack: env.NODE_ENV === 'development' ? err.stack : undefined,
  });
};
