import express, { Application, Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import path from 'path';
import rateLimit from 'express-rate-limit';
import { env } from './config/env.config';
import { httpLogger } from './infrastructure/logger/logger';
import { errorHandler } from './shared/middlewares/error.middleware';
import { authRouter } from './modules/auth/auth.routes';
import { profileRouter } from './modules/profile/profile.routes';
import { postsRouter } from './modules/posts/posts.routes';
import { storiesRouter } from './modules/stories/stories.routes';
import { clubsRouter } from './modules/clubs/clubs.routes';
import { chatRouter } from './modules/chat/chat.routes';
import { careerRouter } from './modules/career/career.routes';
import { eventsRouter } from './modules/events/events.routes';
import { placementRouter } from './modules/placement/placement.routes';
import { portfolioRouter } from './modules/portfolio/portfolio.routes';
import { notificationsRouter } from './modules/notifications/notifications.routes';
import { searchRouter } from './modules/search/search.routes';
import { departmentsRouter } from './modules/departments/departments.routes';
import { adminRouter } from './modules/admin/admin.routes';
import { mediaRouter } from './modules/media/routes/media.routes';
import { facultyRouter } from './modules/faculty/faculty.routes';

export const createApp = (): Application => {
  const app: Application = express();

  // Security & Utility Middlewares
  app.use(helmet({ crossOriginResourcePolicy: false }));
  app.use(cors({ origin: env.CORS_ORIGIN, credentials: true }));
  app.use('/uploads', express.static(path.join(process.cwd(), 'uploads')));
  app.use(express.json({ limit: '50mb' }));
  app.use(express.urlencoded({ extended: true, limit: '50mb' }));
  app.use(express.urlencoded({ extended: true }));
  app.use(httpLogger);

  // Global Rate Limiter
  const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: env.NODE_ENV === 'development' ? 10000 : 100,
    message: { success: false, message: 'Too many requests, please try again later.' },
  });
  app.use('/api', limiter);

  // Root Welcome & Status Page
  app.get('/', (req: Request, res: Response) => {
    res.status(200).send(`
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>CampusHub Backend API</title>
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; background: #0f172a; color: #f8fafc; margin: 0; padding: 40px; display: flex; justify-content: center; align-items: center; min-height: 80vh; }
          .card { background: #1e293b; border-radius: 16px; padding: 32px; max-width: 600px; width: 100%; box-shadow: 0 10px 25px rgba(0,0,0,0.5); border: 1px solid #334155; }
          h1 { color: #818cf8; margin-top: 0; font-size: 1.5rem; display: flex; align-items: center; justify-content: space-between; }
          .badge { background: #10b981; color: #022c22; padding: 4px 12px; border-radius: 20px; font-weight: bold; font-size: 0.8rem; }
          ul { list-style: none; padding: 0; margin: 20px 0; }
          li { padding: 10px 14px; background: #0f172a; margin-bottom: 8px; border-radius: 8px; border: 1px solid #334155; display: flex; justify-content: space-between; font-family: monospace; font-size: 0.9rem; }
          a { color: #38bdf8; text-decoration: none; }
          a:hover { text-decoration: underline; }
          .footer { color: #94a3b8; font-size: 0.85rem; margin-top: 20px; line-height: 1.5; }
          code { background: #0f172a; padding: 2px 6px; border-radius: 4px; color: #f472b6; }
        </style>
      </head>
      <body>
        <div class="card">
          <h1>🚀 CampusHub API Backend <span class="badge">ONLINE</span></h1>
          <p>The Node.js Express REST API & Socket.IO server is running on port <strong>5000</strong>.</p>
          <h3>Core API Modules:</h3>
          <ul>
            <li><span>GET /health</span> <a href="/health" target="_blank">Health Check</a></li>
            <li><span>POST /api/v1/auth/login</span> Authentication</li>
            <li><span>GET /api/v1/admin/metrics</span> Admin Panel Metrics</li>
            <li><span>GET /api/v1/posts</span> Feed & Community</li>
            <li><span>GET /api/v1/events</span> Campus Events</li>
            <li><span>GET /api/v1/clubs</span> Club Management</li>
            <li><span>GET /api/v1/placement/drives</span> Placement Drives</li>
            <li><span>GET /api/v1/career/roadmaps</span> Career Roadmaps</li>
            <li><span>GET /api/v1/notifications</span> FCM Notifications</li>
          </ul>
          <div class="footer">
            💡 <strong>Front-end App Note:</strong> Port <code>5000</code> is the backend API server. To open the web application UI in Chrome, run <code>flutter run -d chrome</code> inside <code>apps/campus_hub_app</code>.
          </div>
        </div>
      </body>
      </html>
    `);
  });

  // Health Check
  app.get('/health', (req: Request, res: Response) => {
    res.status(200).json({ status: 'UP', environment: env.NODE_ENV, timestamp: new Date() });
  });

  // API Routes
  app.use('/api/v1/auth', authRouter);
  app.use('/api/v1/profile', profileRouter);
  app.use('/api/v1/posts', postsRouter);
  app.use('/api/v1/stories', storiesRouter);
  app.use('/api/v1/posts/stories', storiesRouter);
  app.use('/api/v1/clubs', clubsRouter);
  app.use('/api/v1/chat', chatRouter);
  app.use('/api/v1/career', careerRouter);
  app.use('/api/v1/events', eventsRouter);
  app.use('/api/v1/placement', placementRouter);
  app.use('/api/v1/portfolio', portfolioRouter);
  app.use('/api/v1/notifications', notificationsRouter);
  app.use('/api/v1/search', searchRouter);
  app.use('/api/v1/departments', departmentsRouter);
  app.use('/api/v1/admin', adminRouter);
  app.use('/api/v1/media', mediaRouter);
  app.use('/api/v1/faculty', facultyRouter);

  // Global Error Handler
  app.use(errorHandler);

  return app;
};
