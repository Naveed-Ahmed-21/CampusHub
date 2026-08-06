import { z } from 'zod';

export const updateProfileSchema = z.object({
  body: z.object({
    firstName: z.string().min(1, 'First name cannot be empty').optional(),
    lastName: z.string().min(1, 'Last name cannot be empty').optional(),
    phone: z.string().optional(),
    bio: z.string().max(500, 'Bio must be at most 500 characters').optional(),
    githubUrl: z.string().url('Invalid GitHub URL').or(z.literal('')).optional(),
    linkedinUrl: z.string().url('Invalid LinkedIn URL').or(z.literal('')).optional(),
    websiteUrl: z.string().url('Invalid Website URL').or(z.literal('')).optional(),
  }),
});

export const addSkillSchema = z.object({
  body: z.object({
    skillName: z.string().min(1, 'Skill name is required'),
    proficiency: z.enum(['BEGINNER', 'INTERMEDIATE', 'ADVANCED', 'EXPERT']).optional(),
  }),
});

export const addProjectSchema = z.object({
  body: z.object({
    title: z.string().min(1, 'Project title is required'),
    description: z.string().optional(),
    projectUrl: z.string().url('Invalid project URL').or(z.literal('')).optional(),
    repoUrl: z.string().url('Invalid repository URL').or(z.literal('')).optional(),
  }),
});
