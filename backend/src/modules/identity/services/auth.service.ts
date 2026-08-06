import * as argon2 from 'argon2';
import jwt from 'jsonwebtoken';
import { authRepository, AuthRepository } from '../repositories/auth.repository.js';
import { RegisterDto, LoginDto } from '../dtos/auth.dto.js';
import { env } from '../../../config/env.config.js';
import { ConflictError, NotFoundError, UnauthorizedError } from '../../../shared/utils/custom-error.util.js';
import { JwtPayload } from '../../../shared/middlewares/auth.middleware.js';

export class AuthService {
  constructor(private repo: AuthRepository = authRepository) {}

  async register(dto: RegisterDto) {
    const college = await this.repo.findCollegeByCode(dto.collegeCode);
    if (!college) {
      throw new NotFoundError(`College code '${dto.collegeCode}' not found`);
    }

    const existingUser = await this.repo.findUserByEmail(dto.email);
    if (existingUser) {
      throw new ConflictError('User with this email already exists');
    }

    const passwordHash = await argon2.hash(dto.password);

    const user = await this.repo.createUser({
      college_id: college.id,
      email: dto.email,
      password_hash: passwordHash,
      first_name: dto.firstName,
      last_name: dto.lastName,
      roll_number: dto.rollNumber,
      department_id: dto.departmentId,
      role: dto.role,
    });

    const tokens = await this.generateTokens({
      userId: user.id,
      collegeId: user.college_id,
      role: user.role,
      email: user.email,
    });

    return {
      user: {
        id: user.id,
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name,
        role: user.role,
        collegeId: user.college_id,
      },
      tokens,
    };
  }

  async login(dto: LoginDto) {
    const user = await this.repo.findUserByEmail(dto.email);
    if (!user) {
      throw new UnauthorizedError('Invalid credentials');
    }

    const isPasswordValid = await argon2.verify(user.password_hash, dto.password);
    if (!isPasswordValid) {
      throw new UnauthorizedError('Invalid credentials');
    }

    const tokens = await this.generateTokens({
      userId: user.id,
      collegeId: user.college_id,
      role: user.role,
      email: user.email,
    });

    return {
      user: {
        id: user.id,
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name,
        role: user.role,
        collegeId: user.college_id,
      },
      tokens,
    };
  }

  private async generateTokens(payload: JwtPayload) {
    const accessToken = jwt.sign(payload, env.JWT_ACCESS_SECRET, {
      expiresIn: env.JWT_ACCESS_EXPIRES_IN as any,
    });

    const refreshTokenRaw = jwt.sign({ userId: payload.userId }, env.JWT_REFRESH_SECRET, {
      expiresIn: env.JWT_REFRESH_EXPIRES_IN as any,
    });

    const tokenHash = await argon2.hash(refreshTokenRaw);
    const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days

    await this.repo.createRefreshToken(payload.userId, tokenHash, expiresAt);

    return {
      accessToken,
      refreshToken: refreshTokenRaw,
      expiresIn: env.JWT_ACCESS_EXPIRES_IN,
    };
  }
}

export const authService = new AuthService();
