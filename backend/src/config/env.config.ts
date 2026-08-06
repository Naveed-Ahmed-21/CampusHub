import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.string().transform((val) => parseInt(val, 10)).default('5000'),
  LOG_LEVEL: z.string().default('info'),
  DATABASE_URL: z.string().default('postgresql://postgres:postgres@localhost:5432/campushub?schema=public'),
  JWT_ACCESS_SECRET: z.string().default('super_secret_jwt_access_token_key_32bytes_long'),
  JWT_REFRESH_SECRET: z.string().default('super_secret_jwt_refresh_token_key_32bytes_long'),
  JWT_ACCESS_EXPIRES_IN: z.string().default('15m'),
  JWT_REFRESH_EXPIRES_IN: z.string().default('7d'),
  CORS_ORIGIN: z.string().default('*'),
});

export const env = envSchema.parse(process.env);

if (!process.env.DATABASE_URL) {
  process.env.DATABASE_URL = env.DATABASE_URL;
}
