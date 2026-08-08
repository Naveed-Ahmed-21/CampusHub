import request from 'supertest';
import { createApp } from '../../app';
import { generateAccessToken } from '../../shared/utils/jwt.util';
import { Role } from '@prisma/client';

const app = createApp();

describe('RBAC Security & Authorization Test Suite', () => {
  // Mock JWT Access Tokens for each role
  const studentToken = generateAccessToken({
    sub: 'std_1001',
    userId: 'std_1001',
    collegeId: 'clg_88291',
    role: Role.STUDENT,
    email: 'student@campushub.edu',
  });

  const facultyToken = generateAccessToken({
    sub: 'fac_2002',
    userId: 'fac_2002',
    collegeId: 'clg_88291',
    role: Role.FACULTY,
    email: 'faculty@campushub.edu',
  });

  const placementOfficerToken = generateAccessToken({
    sub: 'po_3003',
    userId: 'po_3003',
    collegeId: 'clg_88291',
    role: Role.PLACEMENT_OFFICER,
    email: 'placement@campushub.edu',
  });

  const adminToken = generateAccessToken({
    sub: 'adm_4004',
    userId: 'adm_4004',
    collegeId: 'clg_88291',
    role: Role.ADMIN,
    email: 'admin@campushub.edu',
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
        .patch('/api/v1/admin/users/adm_4004/role')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ newRole: 'STUDENT' });

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
      expect(res.body.message).toContain('Users cannot modify their own role');
    });

    it('ADMIN updating role of another user succeeds with 200', async () => {
      const res = await request(app)
        .patch('/api/v1/admin/users/std_target_888/role')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ newRole: 'PLACEMENT_OFFICER' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });
  });

  describe('5. Public Registration Security', () => {
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

    it('rejects public registration attempts with PLACEMENT_OFFICER role', async () => {
      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({
          collegeId: 'clg_88291',
          email: 'hacker_po@campushub.edu',
          password: 'securePassword123',
          firstName: 'Hacker',
          lastName: 'PO',
          role: 'PLACEMENT_OFFICER',
        });

      expect([400, 403]).toContain(res.status);
      expect(res.body.success).toBe(false);
    });
  });
});
