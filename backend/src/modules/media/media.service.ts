import ImageKit from 'imagekit';
import crypto from 'crypto';
import { env } from '../../config/env.config';
import { MediaRepository, CreateMediaAssetDto } from './media.repository';
import { NotFoundError, ForbiddenError } from '../../shared/errors/AppError';
import { MediaCategory } from '@prisma/client';

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

    // Try deleting from ImageKit cloud
    if (asset.imagekit_file_id) {
      try {
        await this.imagekit.deleteFile(asset.imagekit_file_id);
      } catch (_) {
        // Log & proceed to delete DB metadata
      }
    }

    await this.mediaRepository.deleteById(assetId);
    return { id: assetId, deleted: true };
  }
}
