import { z } from 'zod';

export const updatePortfolioSchema = z.object({
  body: z.object({
    bio: z.string().optional(),
    github_url: z.string().url().optional().or(z.literal('')),
    linkedin_url: z.string().url().optional().or(z.literal('')),
    website_url: z.string().url().optional().or(z.literal('')),
    resume_url: z.string().url().optional().or(z.literal('')),
    cgpa: z.number().min(0).max(10).optional(),
    custom_username: z.string().min(3).max(50).optional(),
    is_public: z.boolean().optional(),
  }),
});

export const addProjectSchema = z.object({
  body: z.object({
    title: z.string().min(2, 'Project title is required').max(255),
    description: z.string().optional(),
    tech_stack: z.array(z.string()).optional(),
    project_url: z.string().url().optional().or(z.literal('')),
    repo_url: z.string().url().optional().or(z.literal('')),
    image_url: z.string().url().optional().or(z.literal('')),
  }),
});

export const addSkillSchema = z.object({
  body: z.object({
    skill_name: z.string().min(1, 'Skill name is required').max(100),
    category: z.string().optional(),
    proficiency: z.enum(['Beginner', 'Intermediate', 'Advanced', 'Expert']).optional(),
  }),
});

export const addCertificateSchema = z.object({
  body: z.object({
    title: z.string().min(2, 'Title is required').max(255),
    issuer: z.string().min(2, 'Issuer is required').max(255),
    issue_date: z.string().optional(),
    credential_url: z.string().url().optional().or(z.literal('')),
    credential_id: z.string().optional(),
  }),
});

export const addAchievementSchema = z.object({
  body: z.object({
    title: z.string().min(2, 'Title is required').max(255),
    category: z.string().optional(),
    description: z.string().optional(),
    date_achieved: z.string().optional(),
    proof_url: z.string().url().optional().or(z.literal('')),
  }),
});
