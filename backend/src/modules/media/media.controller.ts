import { Request, Response } from 'express';
import { MediaService } from './media.service';
import { asyncHandler } from '../../shared/utils/async-handler.util';
import { ResponseUtil } from '../../shared/utils/api-response.util';
import { MediaCategory } from '@prisma/client';

export class MediaController {
  constructor(private readonly mediaService: MediaService) {}

  uploadFile = asyncHandler(async (req: Request, res: Response) => {
    const file = req.file;
    const { base64, dataUrl, fileName, mimeType } = req.body || {};

    const uploadResult = await this.mediaService.handleDirectUpload(
      file,
      base64 || dataUrl,
      fileName,
      mimeType
    );

    ResponseUtil.success(res, uploadResult, 'File uploaded successfully', 201);
  });

  getUploadAuth = asyncHandler(async (req: Request, res: Response) => {
    const authData = this.mediaService.getUploadAuth();
    ResponseUtil.success(res, authData, 'ImageKit upload credentials generated');
  });

  saveMetadata = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const asset = await this.mediaService.saveMediaMetadata(user.userId, user.collegeId, req.body);
    ResponseUtil.success(res, asset, 'Media asset metadata saved successfully', 201);
  });

  getUserMedia = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const category = req.query.category as MediaCategory | undefined;
    const assets = await this.mediaService.getUserMedia(user.userId, category);
    ResponseUtil.success(res, assets, 'User media assets retrieved');
  });

  deleteMedia = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { id } = req.params;
    const isCollegeAdmin = user.role === 'ADMIN';
    const result = await this.mediaService.deleteMedia(id, user.userId, isCollegeAdmin);
    ResponseUtil.success(res, result, 'Media asset deleted successfully');
  });
}
