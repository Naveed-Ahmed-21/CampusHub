import request from 'supertest';
import { createApp } from '../../app';
import { generateAccessToken } from '../../shared/utils/jwt.util';
import { prisma } from '../../config/database';

const app = createApp();

describe('Media Module Integration Tests', () => {
  let userToken: string;

  beforeAll(async () => {
    const existingUser = await prisma.user.findFirst({
      include: { college: true },
    });

    if (existingUser) {
      userToken = generateAccessToken({
        userId: existingUser.id,
        collegeId: existingUser.college_id,
        role: existingUser.role,
        email: existingUser.email,
      });
    } else {
      userToken = generateAccessToken({
        userId: '10000000-0000-4000-8000-000000000101',
        collegeId: '10000000-0000-4000-8000-000000000001',
        role: 'STUDENT',
        email: 'media_student@campushub.edu',
      });
    }
  });

  describe('GET /api/v1/media/auth', () => {
    it('should throw 401 Unauthorized if unauthenticated', async () => {
      const res = await request(app).get('/api/v1/media/auth');
      expect(res.status).toBe(401);
    });

    it('should return ImageKit upload auth credentials when authenticated', async () => {
      const res = await request(app)
        .get('/api/v1/media/auth')
        .set('Authorization', `Bearer ${userToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('token');
      expect(res.body.data).toHaveProperty('expire');
      expect(res.body.data).toHaveProperty('signature');
      expect(res.body.data).toHaveProperty('publicKey');
    });
  });

  describe('POST /api/v1/media/metadata', () => {
    it('should fail with 400 Bad Request if missing required fields', async () => {
      const res = await request(app)
        .post('/api/v1/media/metadata')
        .set('Authorization', `Bearer ${userToken}`)
        .send({ category: 'PROFILE_IMAGE' });

      expect(res.status).toBe(400);
    });

    it('should save media asset metadata successfully', async () => {
      const payload = {
        category: 'PROFILE_IMAGE',
        fileType: 'IMAGE',
        mimeType: 'image/jpeg',
        originalName: 'avatar.jpg',
        fileName: 'user-profile-uuid.jpg',
        fileSize: 1024 * 500,
        url: 'https://ik.imagekit.io/campushub/users/test/profile/avatar.jpg',
        thumbnailUrl: 'https://ik.imagekit.io/campushub/users/test/profile/tr:w-150,h-150/avatar.jpg',
        imagekitFileId: 'ik_file_991823',
        folderPath: '/campushub/users/test/profile/',
        width: 500,
        height: 500,
      };

      const res = await request(app)
        .post('/api/v1/media/metadata')
        .set('Authorization', `Bearer ${userToken}`)
        .send(payload);

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('id');
      expect(res.body.data.imagekit_file_id).toBe('ik_file_991823');
    });
  });
});
