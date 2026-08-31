import { z } from 'zod';

export const createStorySchema = z.object({
  body: z.object({
    mediaUrl: z.string().min(1, 'Media URL is required'),
    mediaType: z.enum(['IMAGE', 'VIDEO']).default('IMAGE'),
    caption: z.string().max(500, 'Caption too long').optional(),
    duration: z.number().int().min(1).max(60).default(5),
  }),
});
