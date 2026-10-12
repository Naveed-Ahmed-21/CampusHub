import { Request, Response, NextFunction } from 'express';
import { verifyAccessToken, TokenPayload } from '../utils/jwt.util';
import { UnauthorizedError, ForbiddenError } from '../errors/AppError';
import { Role } from '@prisma/client';

export type JwtPayload = TokenPayload;

declare global {
  namespace Express {
    interface Request {
      user?: TokenPayload;
    }
  }
}

export const requireAuth = (arg1?: any, arg2?: any, arg3?: any): any => {
  const middleware = (req: Request, res: Response, next: NextFunction): void => {
    const authHeader = req.headers.authorization;

    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      try {
        const payload = verifyAccessToken(token);
        req.user = payload;
        return next();
      } catch (err) {
        throw new UnauthorizedError('Invalid or expired access token');
      }
    }

    throw new UnauthorizedError('Authentication required');
  };

  // If called directly as middleware: requireAuth(req, res, next)
  if (arg1 && arg2 && typeof arg3 === 'function') {
    return middleware(arg1, arg2, arg3);
  }

  return middleware;
};

export const authenticate = requireAuth();
export const authenticateJwt = authenticate;

/**
 * Authorization Middleware: Answers "What is this user allowed to do?"
 * Checks authenticated user's role against allowed roles.
 */
export const requireRole = (...allowedRoles: (Role | 'ADMIN' | string)[]) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user) {
      throw new UnauthorizedError('Authentication required');
    }

    const userRole = req.user.role as string;

    // Expand administrative aliases and legacy roles
    const expandedAllowed = new Set<string>();
    for (const r of allowedRoles) {
      const roleStr = r as string;
      expandedAllowed.add(roleStr);
      if (roleStr === 'PLACEMENT' || roleStr === 'PLACEMENT_OFFICER') {
        expandedAllowed.add('PLACEMENT');
        expandedAllowed.add('PLACEMENT_OFFICER');
      }
      if (roleStr === 'ADMIN') {
        expandedAllowed.add('ADMIN');
        expandedAllowed.add('COLLEGE_ADMIN');
        expandedAllowed.add('SUPER_ADMIN');
      }
      if (roleStr === 'DEPT_ADMIN') {
        expandedAllowed.add('DEPT_ADMIN');
      }
    }

    const hasPermission = expandedAllowed.has(userRole);

    if (!hasPermission) {
      throw new ForbiddenError('You do not have permission to perform this action');
    }

    return next();
  };
};

export const authorize = (...allowedRoles: (Role | string)[]) => requireRole(...(allowedRoles as Role[]));

/**
 * Resource Ownership Helper
 * Checks if current user is owner of resource OR holds ADMIN privileges.
 */
export const isOwnerOrAdmin = (userId: string, ownerId: string, role: Role | string): boolean => {
  if (userId === ownerId) return true;
  return role === Role.ADMIN || role === 'ADMIN';
};
