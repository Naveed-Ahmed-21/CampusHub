import request from 'supertest';
import { createApp } from '../../app';
import { generateAccessToken } from '../../shared/utils/jwt.util';
import { Role } from '@prisma/client';
import { prisma } from '../../infrastructure/prisma/prisma.service';
import { AdminRepository } from '../admin/admin.repository';

const app = createApp();

describe('RBAC Security & Authorization Test Suite', () => {
  let collegeId = '3cf77444-bd2c-42fc-99b2-458582976a85';
  let adminUserId = 'ec430759-e7fa-4b99-ba77-922229198f6f';
  let targetUserId = '74ea1083-6a4c-460a-9188-05143f8fb54e';

  let studentToken = '';
  let facultyToken = '';
  let placementOfficerToken = '';
  let adminToken = '';

  beforeAll(async () => {
    const college = await prisma.college.findFirst();
    if (college) {
      collegeId = college.id;
    }
    const admin = await prisma.user.findFirst({ where: { role: Role.ADMIN } });
    if (admin) {
      adminUserId = admin.id;
    }

    studentToken = generateAccessToken({
      sub: '47ff6b35-dc06-4dc3-a62a-346cb73be31f',
      userId: '47ff6b35-dc06-4dc3-a62a-346cb73be31f',
      collegeId,
      role: Role.STUDENT,
      email: 'student@campushub.edu',
    });

    facultyToken = generateAccessToken({
      sub: '58aa1083-6a4c-460a-9188-05143f8fb54d',
      userId: '58aa1083-6a4c-460a-9188-05143f8fb54d',
      collegeId,
      role: Role.FACULTY,
      email: 'faculty@campushub.edu',
    });

    placementOfficerToken = generateAccessToken({
      sub: '58aa1083-6a4c-460a-9188-05143f8fb54f',
      userId: '58aa1083-6a4c-460a-9188-05143f8fb54f',
      collegeId,
      role: Role.PLACEMENT,
      email: 'placement@campushub.edu',
    });

    adminToken = generateAccessToken({
      sub: adminUserId,
      userId: adminUserId,
      collegeId,
      role: Role.ADMIN,
      email: admin?.email || 'admin@campushub.edu',
    });

    // Dynamically create a temporary user for role update verification
    const tempUser = await prisma.user.create({
      data: {
        college_id: collegeId,
        email: `rbac.test.${Date.now()}@campushub.edu`,
        password_hash: '$argon2id$v=19$m=65536,t=3,p=4$dummy',
        first_name: 'RBAC',
        last_name: 'Tester',
        role: Role.STUDENT,
        status: 'ACTIVE',
        is_password_configured: true,
        is_profile_completed: true,
        first_login_completed: true,
      },
    });
    targetUserId = tempUser.id;

    // Dynamically create a temporary faculty user for faculty endpoint verification
    await prisma.user.upsert({
      where: { id: '58aa1083-6a4c-460a-9188-05143f8fb54d' },
      update: {},
      create: {
        id: '58aa1083-6a4c-460a-9188-05143f8fb54d',
        college_id: collegeId,
        email: `rbac.faculty.${Date.now()}@campushub.edu`,
        password_hash: '$argon2id$v=19$m=65536,t=3,p=4$dummy',
        first_name: 'RBAC',
        last_name: 'Faculty',
        role: Role.FACULTY,
        status: 'ACTIVE',
        is_password_configured: true,
        is_profile_completed: true,
        first_login_completed: true,
      },
    });
  });

  afterAll(async () => {
    const repo = new AdminRepository();
    if (targetUserId) {
      await repo.deleteUser(targetUserId).catch(() => {});
    }
    await repo.deleteUser('58aa1083-6a4c-460a-9188-05143f8fb54d').catch(() => {});
    await prisma.$disconnect();
  });

  describe('1. Authentication Verification (401 Unauthorized)', () => {
    it('returns 401 when Authorization header is missing in production/test mode', async () => {
      const originalEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'test';
      const res = await request(app).get('/api/v1/admin/metrics');
      process.env.NODE_ENV = originalEnv;

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('Authentication required');
    });

    it('returns 401 when invalid access token is provided', async () => {
      const originalEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'test';
      const res = await request(app)
        .get('/api/v1/admin/metrics')
        .set('Authorization', 'Bearer invalid.secret.token');
      process.env.NODE_ENV = originalEnv;

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
    });
  });

  describe('2. Role-Based Route Authorization Matrix (403 Forbidden)', () => {
    it('STUDENT accessing Admin endpoint returns 403 Forbidden', async () => {
      const res = await request(app)
        .get('/api/v1/admin/metrics')
        .set('Authorization', `Bearer ${studentToken}`);

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('You do not have permission');
    });

    it('STUDENT accessing Placement Officer dashboard returns 403 Forbidden', async () => {
      const res = await request(app)
        .get('/api/v1/placement/dashboard/officer')
        .set('Authorization', `Bearer ${studentToken}`);

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });

    it('FACULTY accessing Admin endpoint returns 403 Forbidden', async () => {
      const res = await request(app)
        .get('/api/v1/admin/users')
        .set('Authorization', `Bearer ${facultyToken}`);

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });

    it('PLACEMENT_OFFICER accessing Admin endpoint returns 403 Forbidden', async () => {
      const res = await request(app)
        .get('/api/v1/admin/metrics')
        .set('Authorization', `Bearer ${placementOfficerToken}`);

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });

    it('PLACEMENT_OFFICER accessing Placement Officer dashboard succeeds with 200', async () => {
      const res = await request(app)
        .get('/api/v1/placement/dashboard/officer')
        .set('Authorization', `Bearer ${placementOfficerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });

    it('ADMIN accessing Admin endpoint succeeds with 200', async () => {
      const res = await request(app)
        .get('/api/v1/admin/metrics')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });

    it('STUDENT accessing Faculty dashboard returns 403 Forbidden', async () => {
      const res = await request(app)
        .get('/api/v1/faculty/dashboard')
        .set('Authorization', `Bearer ${studentToken}`);

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });

    it('PLACEMENT_OFFICER accessing Faculty dashboard returns 403 Forbidden', async () => {
      const res = await request(app)
        .get('/api/v1/faculty/dashboard')
        .set('Authorization', `Bearer ${placementOfficerToken}`);

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });

    it('FACULTY accessing Faculty dashboard succeeds with 200', async () => {
      const res = await request(app)
        .get('/api/v1/faculty/dashboard')
        .set('Authorization', `Bearer ${facultyToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });

    it('ADMIN accessing Faculty dashboard succeeds with 200 oversight', async () => {
      const res = await request(app)
        .get('/api/v1/faculty/dashboard')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });
  });

  describe('3. Resource Ownership Security Checks', () => {
    it('STUDENT deleting another user post returns 403 Forbidden', async () => {
      const res = await request(app)
        .delete('/api/v1/posts/post_other_999')
        .set('Authorization', `Bearer ${studentToken}`);

      expect([403, 404]).toContain(res.status);
    });

    it('ADMIN can manage and access administrative resources', async () => {
      const res = await request(app)
        .get('/api/v1/admin/departments')
        .set('Authorization', `Bearer ${adminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });
  });

  describe('4. Role Escalation & Role Management Security', () => {
    it('STUDENT attempting to modify user roles returns 403 Forbidden', async () => {
      const res = await request(app)
        .patch('/api/v1/admin/users/std_1001/role')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({ newRole: 'ADMIN' });

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });

    it('FACULTY attempting to promote themselves returns 403 Forbidden', async () => {
      const res = await request(app)
        .patch('/api/v1/admin/users/fac_2002/role')
        .set('Authorization', `Bearer ${facultyToken}`)
        .send({ newRole: 'ADMIN' });

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });

    it('ADMIN attempting to modify their own role returns 403 Forbidden', async () => {
      const res = await request(app)
        .patch(`/api/v1/admin/users/${adminUserId}/role`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ newRole: 'STUDENT' });

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('Users cannot modify their own role');
    });

    it('ADMIN updating role of another user succeeds with 200', async () => {
      const res = await request(app)
        .patch(`/api/v1/admin/users/${targetUserId}/role`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ newRole: 'PLACEMENT' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });
  });

  describe('5. Public Registration Security', () => {
    it('rejects all public registration attempts with 403 or 400', async () => {
      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({
          collegeId: 'clg_88291',
          email: 'public_user@campushub.edu',
          password: 'securePassword123',
          firstName: 'Public',
          lastName: 'User',
          role: 'STUDENT',
        });

      expect([400, 403]).toContain(res.status);
      expect(res.body.success).toBe(false);
    });

    it('rejects public registration attempts with ADMIN role', async () => {
      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({
          collegeId: 'clg_88291',
          email: 'hacker_admin@campushub.edu',
          password: 'securePassword123',
          firstName: 'Hacker',
          lastName: 'Admin',
          role: 'ADMIN',
        });

      expect([400, 403]).toContain(res.status);
      expect(res.body.success).toBe(false);
    });
  });
});
