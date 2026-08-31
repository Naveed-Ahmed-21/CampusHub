import { prisma } from '../../config/database';
import { User, RefreshToken, PasswordResetToken } from '@prisma/client';

export class AuthRepository {
  async findUserByEmail(email: string): Promise<User | null> {
    const cleanEmail = email.trim().toLowerCase();
    return prisma.user.findFirst({
      where: {
        email: {
          equals: cleanEmail,
          mode: 'insensitive',
        },
      },
    });
  }

  async findUserById(id: string): Promise<User | null> {
    return prisma.user.findUnique({ where: { id } });
  }

  async createUser(data: Partial<User>): Promise<User> {
    return prisma.user.create({ data: data as never });
  }

  async saveRefreshToken(userId: string, tokenHash: string, expiresAt: Date): Promise<RefreshToken> {
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
      where: { token_hash: tokenHash, is_revoked: false },
      include: { user: true },
    });
  }

  async revokeRefreshToken(id: string): Promise<void> {
    await prisma.refreshToken.update({
      where: { id },
      data: { is_revoked: true },
    });
  }

  async revokeAllUserRefreshTokens(userId: string): Promise<void> {
    await prisma.refreshToken.updateMany({
      where: { user_id: userId, is_revoked: false },
      data: { is_revoked: true },
    });
  }

  async savePasswordResetToken(userId: string, tokenHash: string, expiresAt: Date): Promise<PasswordResetToken> {
    return prisma.passwordResetToken.create({
      data: {
        user_id: userId,
        token_hash: tokenHash,
        expires_at: expiresAt,
      },
    });
  }

  async findPasswordResetToken(tokenHash: string): Promise<PasswordResetToken | null> {
    return prisma.passwordResetToken.findFirst({
      where: { token_hash: tokenHash },
      include: { user: true },
    });
  }

  async updateUserPassword(userId: string, passwordHash: string): Promise<void> {
    await prisma.user.update({
      where: { id: userId },
      data: { password_hash: passwordHash },
    });
  }

  async deletePasswordResetToken(id: string): Promise<void> {
    await prisma.passwordResetToken.delete({
      where: { id },
    });
  }
}
