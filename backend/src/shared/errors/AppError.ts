export class AppError extends Error {
  public readonly statusCode: number;
  public readonly isOperational: boolean;
  public readonly code?: string;
  public readonly errors?: unknown;

  constructor(message: string, statusCode: number = 500, errors?: unknown, code?: string) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
    this.errors = errors;
    this.code = code;
    Object.setPrototypeOf(this, new.target.prototype);
    Error.captureStackTrace(this, this.constructor);
  }
}

export class NotFoundError extends AppError {
  constructor(message: string = 'Resource not found') {
    super(message, 404, undefined, 'NOT_FOUND');
  }
}

export class BadRequestError extends AppError {
  constructor(message: string = 'Bad request', errors?: unknown) {
    super(message, 400, errors, 'BAD_REQUEST');
  }
}

export class UnauthorizedError extends AppError {
  constructor(message: string = 'Unauthorized access') {
    super(message, 401, undefined, 'UNAUTHORIZED');
  }
}

export class ForbiddenError extends AppError {
  constructor(message: string = 'Forbidden access') {
    super(message, 403, undefined, 'FORBIDDEN');
  }
}

export class ConflictError extends AppError {
  constructor(message: string = 'Resource conflict') {
    super(message, 409, undefined, 'CONFLICT');
  }
}

export class ValidationError extends AppError {
  constructor(message: string = 'Validation failed', errors?: unknown) {
    super(message, 422, errors, 'VALIDATION_ERROR');
  }
}
