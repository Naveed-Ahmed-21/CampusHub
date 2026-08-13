import { Router } from 'express';
import { MediaRepository } from '../media.repository';
import { MediaService } from '../media.service';
import { MediaController } from '../media.controller';
import { authenticate } from '../../../shared/middlewares/auth.middleware';
import { validateRequest } from '../../../shared/middlewares/validate.middleware';
import { saveMediaMetadataSchema } from '../media.validation';

const mediaRepository = new MediaRepository();
const mediaService = new MediaService(mediaRepository);
const mediaController = new MediaController(mediaService);

export const mediaRouter = Router();

mediaRouter.use(authenticate);

mediaRouter.get('/auth', mediaController.getUploadAuth);
mediaRouter.post('/metadata', validateRequest(saveMediaMetadataSchema), mediaController.saveMetadata);
mediaRouter.get('/user', mediaController.getUserMedia);
mediaRouter.delete('/:id', mediaController.deleteMedia);

export default mediaRouter;
