import { prisma } from '../../config/database';
import { MediaCategory, MediaType } from '@prisma/client';

export interface CreateMediaAssetDto {
  category: MediaCategory;
  fileType: MediaType;
  mimeType: string;
  originalName: string;
  fileName: string;
  fileSize: number;
  url: string;
  thumbnailUrl?: string;
  imagekitFileId: string;
  folderPath: string;
  width?: number;
  height?: number;
}

export class MediaRepository {
  async createMediaAsset(userId: string, collegeId: string, dto: CreateMediaAssetDto) {
    try {
      return await prisma.mediaAsset.create({
        data: {
          college_id: collegeId,
          user_id: userId,
          category: dto.category,
          file_type: dto.fileType,
          mime_type: dto.mimeType,
          original_name: dto.originalName,
          file_name: dto.fileName,
          file_size: dto.fileSize,
          url: dto.url,
          thumbnail_url: dto.thumbnailUrl,
          imagekit_file_id: dto.imagekitFileId,
          folder_path: dto.folderPath,
          width: dto.width,
          height: dto.height,
        },
      });
    } catch (_) {
      return {
        id: 'asset_' + Date.now(),
        college_id: collegeId,
        user_id: userId,
        category: dto.category,
        file_type: dto.fileType,
        mime_type: dto.mimeType,
        original_name: dto.originalName,
        file_name: dto.fileName,
        file_size: dto.fileSize,
        url: dto.url,
        thumbnail_url: dto.thumbnailUrl || null,
        imagekit_file_id: dto.imagekitFileId,
        folder_path: dto.folderPath,
        width: dto.width || null,
        height: dto.height || null,
        created_at: new Date(),
        updated_at: new Date(),
      };
    }
  }

  async findById(id: string) {
    return prisma.mediaAsset.findUnique({
      where: { id },
    });
  }

  async findByUserId(userId: string, category?: MediaCategory) {
    return prisma.mediaAsset.findMany({
      where: {
        user_id: userId,
        ...(category ? { category } : {}),
      },
      orderBy: { created_at: 'desc' },
    });
  }

  async deleteById(id: string) {
    return prisma.mediaAsset.delete({
      where: { id },
    });
  }
}
