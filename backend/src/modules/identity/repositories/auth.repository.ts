import { prisma } from '../../../infrastructure/prisma/prisma.service.js';
import { User, College, RefreshToken, Role } from '@prisma/client';

export class AuthRepository {
  async findCollegeByCode(code: string): Promise<College | null> {
    return prisma.college.findUnique({
      where: { code, deleted_at: null },
    });
  }

  async findUserByEmail(email: string): Promise<User | null> {
    return prisma.user.findUnique({
      where: { email, deleted_at: null },
      include: { college: true },
    });
  }

  async createUser(data: {
    college_id: string;
    department_id?: string;
    email: string;
    password_hash: string;
    first_name: string;
    last_name: string;
    roll_number?: string;
    role: Role;
  }): Promise<User> {
    return prisma.user.create({
      data,
    });
  }

  async createRefreshToken(userId: string, tokenHash: string, expiresAt: Date): Promise<RefreshToken> {
    return prisma.refreshToken.create({
      data: {
        user_id: userId,
        token_hash: tokenHash,
        expires_at: expiresAt,
      },
    });
  }

  async findRefreshToken(tokenHash: string): Promise<RefreshToken | null> {
    return prisma.refreshToken.findFirst({
      where: {
        token_hash: tokenHash,
        is_revoked: false,
        expires_at: { gt: new Date() },
      },
      include: { user: true },
    });
  }

  async revokeRefreshToken(tokenId: string): Promise<void> {
    await prisma.refreshToken.update({
      where: { id: tokenId },
      data: { is_revoked: true },
    });
  }
}

export const authRepository = new AuthRepository();
