import { z } from 'zod';
import { MediaCategory, MediaType } from '@prisma/client';

export const saveMediaMetadataSchema = z.object({
  body: z.object({
    category: z.nativeEnum(MediaCategory),
    fileType: z.nativeEnum(MediaType).default(MediaType.IMAGE),
    mimeType: z.string().min(1),
    originalName: z.string().min(1),
    fileName: z.string().min(1),
    fileSize: z.number().positive(),
    url: z.string().url(),
    thumbnailUrl: z.string().url().optional(),
    imagekitFileId: z.string().min(1),
    folderPath: z.string().min(1),
    width: z.number().positive().optional(),
    height: z.number().positive().optional(),
  }),
});
