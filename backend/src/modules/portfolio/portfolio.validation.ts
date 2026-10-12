import { z } from 'zod';

export const updatePortfolioSchema = z.object({
  body: z.object({
    bio: z.string().optional().nullable(),
    github_url: z.string().url().optional().or(z.literal('')).nullable(),
    linkedin_url: z.string().url().optional().or(z.literal('')).nullable(),
    website_url: z.string().url().optional().or(z.literal('')).nullable(),
    resume_url: z.string().url().optional().or(z.literal('')).nullable(),
    cgpa: z.number().min(0).max(10).optional().nullable(),
    custom_username: z.string().min(3).max(50).optional().nullable(),
    is_public: z.boolean().optional().nullable(),
  }),
});

export const addProjectSchema = z.object({
  body: z.object({
    title: z.string().trim().min(1, 'Project title is required').max(255),
    description: z.string().optional().nullable(),
    tech_stack: z.array(z.string()).optional().nullable(),
    project_url: z.string().url().optional().or(z.literal('')).nullable(),
    repo_url: z.string().url().optional().or(z.literal('')).nullable(),
    image_url: z.string().url().optional().or(z.literal('')).nullable(),
  }),
});

export const addSkillSchema = z.object({
  body: z.object({
    skill_name: z.string().trim().min(1, 'Skill name is required').max(100),
    category: z.string().optional().nullable(),
    proficiency: z.string().optional().nullable(),
  }),
});

export const addCertificateSchema = z.object({
  body: z.object({
    title: z.string().trim().min(1, 'Title is required').max(255),
    issuer: z.string().trim().min(1, 'Issuer is required').max(255),
    issue_date: z.string().optional().nullable(),
    credential_url: z.string().url().optional().or(z.literal('')).nullable(),
    credential_id: z.string().optional().nullable(),
  }),
});

export const addAchievementSchema = z.object({
  body: z.object({
    title: z.string().trim().min(1, 'Title is required').max(255),
    category: z.string().optional().nullable(),
    description: z.string().optional().nullable(),
    date_achieved: z.string().optional().nullable(),
    proof_url: z.string().url().optional().or(z.literal('')).nullable(),
  }),
});
