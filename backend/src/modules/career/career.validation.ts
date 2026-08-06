import { z } from 'zod';

export const createWeeklyGoalSchema = z.object({
  body: z.object({
    title: z.string().min(3, 'Goal title must be at least 3 characters').max(255),
    target_date: z.string().optional(),
  }),
});

export const toggleGoalSchema = z.object({
  body: z.object({
    is_completed: z.boolean(),
  }),
});

export const toggleNodeProgressSchema = z.object({
  body: z.object({
    node_id: z.string().uuid('Invalid node ID'),
    is_completed: z.boolean(),
  }),
});

export const submitMiniProjectSchema = z.object({
  body: z.object({
    project_id: z.string().uuid('Invalid project ID'),
    repo_url: z.string().url('Invalid GitHub repository URL'),
    live_demo_url: z.string().url('Invalid demo URL').optional().or(z.literal('')),
  }),
});
