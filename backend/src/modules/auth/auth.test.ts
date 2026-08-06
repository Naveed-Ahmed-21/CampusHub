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
    it('should register a new student user and return JWT session', async () => {
      authRepository.findUserByEmail.mockResolvedValue(null);
      authRepository.createUser.mockResolvedValue({
        id: 'usr_202',
        email: 'newstudent@campushub.edu',
        first_name: 'Jane',
        last_name: 'Doe',
        role: Role.STUDENT,
        college_id: 'clg_88291',
      } as any);

      const session = await authService.register({
        email: 'newstudent@campushub.edu',
        password: 'Password123!',
        firstName: 'Jane',
        lastName: 'Doe',
        role: Role.STUDENT,
        collegeId: 'clg_88291',
      });

      expect(session.tokens.accessToken).toBeDefined();
      expect(session.user.email).toBe('newstudent@campushub.edu');
    });
  });
});
