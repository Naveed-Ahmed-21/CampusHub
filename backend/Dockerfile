# Multi-stage Dockerfile for Node.js Express TypeScript Backend

# Stage 1: Dependencies & Builder
FROM node:22-alpine AS builder

WORKDIR /app

# Copy root package definitions and workspace package definitions
COPY package.json package-lock.json ./
COPY backend/package.json ./backend/
COPY backend/prisma ./backend/prisma

# Install all dependencies (including devDependencies)
RUN npm ci

# Copy backend source code
COPY backend ./backend

# Build TypeScript code and generate Prisma Client
WORKDIR /app/backend
RUN npm run build

# Stage 2: Production Runner
FROM node:22-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=5000

# Copy package files and install production dependencies only
COPY package.json package-lock.json ./
COPY backend/package.json ./backend/
COPY backend/prisma ./backend/prisma

RUN npm ci --only=production

# Copy compiled JavaScript dist and generated Prisma client from builder
COPY --from=builder /app/backend/dist ./backend/dist
COPY --from=builder /app/backend/node_modules/.prisma ./backend/node_modules/.prisma
COPY --from=builder /app/backend/node_modules/@prisma ./backend/node_modules/@prisma

WORKDIR /app/backend

EXPOSE 5000

CMD ["node", "dist/server.js"]
