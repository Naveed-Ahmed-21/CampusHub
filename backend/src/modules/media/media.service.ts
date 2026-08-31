import ImageKit from 'imagekit';
import crypto from 'crypto';
import path from 'path';
import fs from 'fs';
import sharp from 'sharp';
import { env } from '../../config/env.config';
import { MediaRepository, CreateMediaAssetDto } from './media.repository';
import { NotFoundError, ForbiddenError, BadRequestError } from '../../shared/errors/AppError';
import { MediaCategory } from '@prisma/client';
import { logger } from '../../infrastructure/logger/logger';

export class MediaService {
  private imagekit: ImageKit;

  constructor(private readonly mediaRepository: MediaRepository) {
    this.imagekit = new ImageKit({
      publicKey: env.IMAGEKIT_PUBLIC_KEY,
      privateKey: env.IMAGEKIT_PRIVATE_KEY,
      urlEndpoint: env.IMAGEKIT_URL_ENDPOINT,
    });
  }

  getUploadAuth() {
    try {
      const authParams = this.imagekit.getAuthenticationParameters();
      return {
        ...authParams,
        publicKey: env.IMAGEKIT_PUBLIC_KEY,
        urlEndpoint: env.IMAGEKIT_URL_ENDPOINT,
      };
    } catch (_) {
      // Direct crypto fallback
      const token = crypto.randomBytes(16).toString('hex');
      const expire = Math.floor(Date.now() / 1000) + 1800; // 30 mins
      const signature = crypto
        .createHmac('sha1', env.IMAGEKIT_PRIVATE_KEY)
        .update(token + expire)
        .digest('hex');

      return {
        token,
        expire,
        signature,
        publicKey: env.IMAGEKIT_PUBLIC_KEY,
        urlEndpoint: env.IMAGEKIT_URL_ENDPOINT,
      };
    }
  }

  private async optimizeImageBuffer(inputBuffer: Buffer, mimeType?: string): Promise<{ buffer: Buffer; mimeType: string }> {
    const isImage = !mimeType || mimeType.startsWith('image/');
    if (!isImage || mimeType?.includes('svg') || mimeType?.includes('gif')) {
      return { buffer: inputBuffer, mimeType: mimeType || 'application/octet-stream' };
    }

    try {
      const optimized = await sharp(inputBuffer)
        .rotate() // Auto-rotate based on EXIF orientation
        .resize({ width: 1920, height: 1920, fit: 'inside', withoutEnlargement: true })
        .jpeg({ quality: 85, mozjpeg: true })
        .toBuffer();
      return { buffer: optimized, mimeType: 'image/jpeg' };
    } catch (e) {
      logger.warn({ err: e }, 'Sharp image optimization skipped/failed, using raw buffer');
      return { buffer: inputBuffer, mimeType: mimeType || 'image/jpeg' };
    }
  }

  async handleDirectUpload(file?: Express.Multer.File, base64Data?: string, originalName?: string, mimeType?: string) {
    const uploadDir = path.join(process.cwd(), 'uploads');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }

    if (file) {
      const rawBuffer = fs.readFileSync(file.path);
      const { buffer: processedBuffer, mimeType: effectiveMime } = await this.optimizeImageBuffer(rawBuffer, file.mimetype);

      // 1. Try ImageKit upload first
      try {
        if (env.IMAGEKIT_PRIVATE_KEY && !env.IMAGEKIT_PRIVATE_KEY.includes('dummy')) {
          const ikResponse = await this.imagekit.upload({
            file: processedBuffer,
            fileName: file.originalname,
            folder: '/campushub_uploads',
            useUniqueFileName: true,
          });

          if (ikResponse && ikResponse.url) {
            return {
              url: ikResponse.url,
              fileName: file.originalname,
              fileType: effectiveMime,
              fileSize: processedBuffer.length,
              mimeType: effectiveMime,
              fileId: ikResponse.fileId,
            };
          }
        }
      } catch (ikErr) {
        logger.warn({ ikErr }, 'ImageKit upload failed, using local storage fallback');
      }

      // 2. Fallback to local uploads
      const savedFileName = `${Date.now()}-${file.filename}`;
      const localFilePath = path.join(uploadDir, savedFileName);
      fs.writeFileSync(localFilePath, processedBuffer);

      return {
        url: `/uploads/${savedFileName}`,
        fileName: file.originalname,
        fileType: effectiveMime,
        fileSize: processedBuffer.length,
        mimeType: effectiveMime,
      };
    }

    if (base64Data) {
      let cleanBase64 = base64Data;
      let detectedMime = mimeType || 'image/jpeg';

      if (base64Data.startsWith('data:')) {
        const matches = base64Data.match(/^data:([a-zA-Z0-9/+-]+);base64,(.+)$/);
        if (matches) {
          detectedMime = matches[1];
          cleanBase64 = matches[2];
        }
      }

      const rawBuffer = Buffer.from(cleanBase64, 'base64');
      const { buffer: processedBuffer, mimeType: effectiveMime } = await this.optimizeImageBuffer(rawBuffer, detectedMime);

      const ext = effectiveMime.includes('png')
        ? '.png'
        : effectiveMime.includes('pdf')
        ? '.pdf'
        : effectiveMime.includes('mp4')
        ? '.mp4'
        : effectiveMime.includes('webm')
        ? '.webm'
        : effectiveMime.includes('audio') || effectiveMime.includes('mp3')
        ? '.mp3'
        : '.jpg';

      const fileName = originalName || `upload_${Date.now()}${ext}`;

      // 1. Try ImageKit upload first
      try {
        if (env.IMAGEKIT_PRIVATE_KEY && !env.IMAGEKIT_PRIVATE_KEY.includes('dummy')) {
          const ikResponse = await this.imagekit.upload({
            file: processedBuffer,
            fileName: fileName,
            folder: '/campushub_uploads',
            useUniqueFileName: true,
          });

          if (ikResponse && ikResponse.url) {
            return {
              url: ikResponse.url,
              fileName,
              fileType: effectiveMime,
              fileSize: processedBuffer.length,
              mimeType: effectiveMime,
              fileId: ikResponse.fileId,
            };
          }
        }
      } catch (ikErr) {
        logger.warn({ ikErr }, 'ImageKit base64 upload failed, using local storage fallback');
      }

      // 2. Fallback to local storage
      const savedFileName = `${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`;
      const filePath = path.join(uploadDir, savedFileName);

      fs.writeFileSync(filePath, processedBuffer);

      return {
        url: `/uploads/${savedFileName}`,
        fileName,
        fileType: effectiveMime,
        fileSize: processedBuffer.length,
        mimeType: effectiveMime,
      };
    }

    throw new BadRequestError('No file or base64 data provided for upload');
  }

  async saveMediaMetadata(userId: string, collegeId: string, dto: CreateMediaAssetDto) {
    return this.mediaRepository.createMediaAsset(userId, collegeId, dto);
  }

  async getUserMedia(userId: string, category?: MediaCategory) {
    return this.mediaRepository.findByUserId(userId, category);
  }

  async deleteMedia(assetId: string, requestingUserId: string, isCollegeAdmin: boolean = false) {
    const asset = await this.mediaRepository.findById(assetId);
    if (!asset) {
      throw new NotFoundError('Media asset not found');
    }

    if (asset.user_id !== requestingUserId && !isCollegeAdmin) {
      throw new ForbiddenError('You are not authorized to delete this media asset');
    }

    if (asset.imagekit_file_id) {
      try {
        await this.imagekit.deleteFile(asset.imagekit_file_id);
      } catch (_) {}
    }

    await this.mediaRepository.deleteById(assetId);
    return { id: assetId, deleted: true };
  }
}
