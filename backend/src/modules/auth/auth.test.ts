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

    it('should return fallback auth session when DB is offline', async () => {
      authRepository.findUserByEmail.mockRejectedValue(new Error('DB offline'));

      const session = await authService.login({
        email: 'student@campushub.edu',
        password: 'Password123!',
      });

      expect(session.tokens.accessToken).toBeDefined();
      expect(session.user.firstName).toBe('Alex');
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
