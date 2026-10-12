import { AuthService } from './auth.service';
import { AuthRepository } from './auth.repository';
import { Role } from '@prisma/client';
import * as argon2 from 'argon2';

describe('AuthService', () => {
  let authService: AuthService;
  let authRepository: jest.Mocked<AuthRepository>;

  beforeEach(() => {
    authRepository = {
      findUserByEmail: jest.fn(),
      findUserByRollNumber: jest.fn(),
      createUser: jest.fn(),
      findUserById: jest.fn(),
    } as unknown as jest.Mocked<AuthRepository>;

    authService = new AuthService(authRepository);
  });

  describe('login', () => {
    it('should create auth session successfully on valid credentials', async () => {
      const passwordHash = await argon2.hash('Password123!');
      const mockUser = {
        id: 'usr_101',
        email: 'student@campushub.edu',
        password_hash: passwordHash,
        first_name: 'Alex',
        last_name: 'Vance',
        role: Role.STUDENT,
        college_id: 'clg_1',
        is_password_configured: true,
        is_profile_completed: true,
        status: 'ACTIVE',
      };

      authRepository.findUserByEmail.mockResolvedValue(mockUser as any);

      const session = await authService.login({
        email: 'student@campushub.edu',
        password: 'Password123!',
      });

      expect(session.tokens.accessToken).toBeDefined();
      expect(session.tokens.refreshToken).toBeDefined();
      expect(session.user.email).toBe('student@campushub.edu');
    });

    it('should throw UnauthorizedError when account is not activated', async () => {
      const passwordHash = await argon2.hash('Password123!');
      const unactivatedUser = {
        id: 'usr_102',
        email: 'invited@campushub.edu',
        password_hash: passwordHash,
        first_name: 'Invited',
        last_name: 'User',
        role: Role.STUDENT,
        college_id: 'clg_1',
        is_password_configured: false,
        status: 'INVITED',
      };

      authRepository.findUserByEmail.mockResolvedValue(unactivatedUser as any);

      await expect(
        authService.login({
          email: 'invited@campushub.edu',
          password: 'Password123!',
        }),
      ).rejects.toThrow('Your account needs to be activated');
    });

    it('should throw error when DB is offline', async () => {
      authRepository.findUserByEmail.mockRejectedValue(new Error('DB offline'));

      await expect(
        authService.login({
          email: 'student@campushub.edu',
          password: 'Password123!',
        }),
      ).rejects.toThrow('Invalid email or password');
    });
  });

  describe('checkStatus', () => {
    it('should return status details for existing user', async () => {
      authRepository.findUserByEmail.mockResolvedValue({
        id: 'usr_101',
        email: 'test@campushub.edu',
        role: Role.STUDENT,
        is_password_configured: false,
        is_profile_completed: false,
        first_login_completed: false,
        status: 'INVITED',
      } as any);

      const res = await authService.checkStatus('test@campushub.edu');
      expect(res.exists).toBe(true);
      expect(res.isPasswordConfigured).toBe(false);
      expect(res.status).toBe('INVITED');
    });

    it('should return exists: false for non-existent user', async () => {
      authRepository.findUserByEmail.mockResolvedValue(null);

      const res = await authService.checkStatus('none@campushub.edu');
      expect(res.exists).toBe(false);
    });
  });


  describe('firstLoginOtp', () => {
    it('should generate and send OTP for first-time unactivated student', async () => {
      authRepository.findUserByEmail.mockResolvedValue({
        id: 'usr_new_student',
        email: 'freshman@campushub.edu',
        first_name: 'Freshman',
        last_name: 'Student',
        role: Role.STUDENT,
        is_password_configured: false,
        first_login_completed: false,
        status: 'INVITED',
      } as any);

      const res = await authService.sendFirstLoginOtp({ email: 'freshman@campushub.edu' });
      expect(res.message).toContain('Verification code and activation link sent');
      expect(res.previewOtp).toBeDefined();
      expect(res.previewOtp?.length).toBe(6);

      // Verify OTP
      const verifyRes = await authService.verifyFirstLoginOtp({
        email: 'freshman@campushub.edu',
        otp: res.previewOtp!,
      });
      expect(verifyRes.verified).toBe(true);
      expect(verifyRes.token).toBeDefined();
    });

    it('should throw error when invalid OTP is provided', async () => {
      authRepository.findUserByEmail.mockResolvedValue({
        id: 'usr_new_student',
        email: 'freshman2@campushub.edu',
        first_name: 'Freshman',
        last_name: 'Student',
        role: Role.STUDENT,
        is_password_configured: false,
        first_login_completed: false,
        status: 'INVITED',
      } as any);

      await authService.sendFirstLoginOtp({ email: 'freshman2@campushub.edu' });

      await expect(
        authService.verifyFirstLoginOtp({
          email: 'freshman2@campushub.edu',
          otp: '000000',
        }),
      ).rejects.toThrow('Invalid OTP code');
    });
  });

  describe('forgotPassword OTP Flow', () => {
    it('should generate and verify OTP for forgot password, then allow password reset', async () => {
      authRepository.findUserByEmail.mockResolvedValue({
        id: 'usr_faculty',
        email: 'faculty@campushub.edu',
        first_name: 'Robert',
        last_name: 'Taylor',
        role: Role.FACULTY,
        status: 'ACTIVE',
      } as any);

      authRepository.savePasswordResetToken = jest.fn().mockResolvedValue({ id: 'tok_1' } as any);
      authRepository.findPasswordResetToken = jest.fn().mockResolvedValue({
        id: 'tok_1',
        user_id: 'usr_faculty',
        expires_at: new Date(Date.now() + 60 * 60 * 1000),
      } as any);
      authRepository.updateUserPassword = jest.fn().mockResolvedValue({ id: 'usr_faculty' } as any);
      authRepository.deletePasswordResetToken = jest.fn().mockResolvedValue({ id: 'tok_1' } as any);
      authRepository.revokeAllUserRefreshTokens = jest.fn().mockResolvedValue({ count: 1 } as any);

      // Step 1: Request OTP
      const res = await authService.forgotPassword({ email: 'faculty@campushub.edu' });
      expect(res.previewOtp).toBeDefined();
      expect(res.previewOtp?.length).toBe(6);

      // Step 2: Verify OTP
      const verifyRes = await authService.verifyForgotPasswordOtp({
        email: 'faculty@campushub.edu',
        otp: res.previewOtp!,
      });
      expect(verifyRes.verified).toBe(true);
      expect(verifyRes.token).toBeDefined();

      // Step 3: Reset Password using verified token
      const resetRes = await authService.resetPassword({
        token: verifyRes.token,
        newPassword: 'NewSecurePassword123!',
      });
      expect(resetRes.message).toContain('reset successfully');
    });

    it('should reject invalid OTP for forgot password', async () => {
      authRepository.findUserByEmail.mockResolvedValue({
        id: 'usr_faculty',
        email: 'faculty2@campushub.edu',
        first_name: 'Robert',
        last_name: 'Taylor',
        role: Role.FACULTY,
        status: 'ACTIVE',
      } as any);

      await authService.forgotPassword({ email: 'faculty2@campushub.edu' });

      await expect(
        authService.verifyForgotPasswordOtp({
          email: 'faculty2@campushub.edu',
          otp: '999999',
        }),
      ).rejects.toThrow('Invalid verification code');
    });
  });

  describe('register', () => {
    it('should throw ForbiddenError because public account registration is disabled', async () => {
      await expect(
        authService.register({
          email: 'newstudent@campushub.edu',
          password: 'Password123!',
          firstName: 'Jane',
          lastName: 'Doe',
          role: Role.STUDENT,
          collegeId: 'clg_88291',
        })
      ).rejects.toThrow('Public account creation is disabled');
    });
  });
});
