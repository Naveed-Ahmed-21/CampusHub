import { z } from 'zod';
import { updateProfileSchema, addSkillSchema, addProjectSchema } from './profile.validation';

export type UpdateProfileDTO = z.infer<typeof updateProfileSchema>['body'];
export type AddSkillDTO = z.infer<typeof addSkillSchema>['body'];
export type AddProjectDTO = z.infer<typeof addProjectSchema>['body'];

export interface ProfileResponseDTO {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  rollNumber?: string | null;
  phone?: string | null;
  avatarUrl?: string | null;
  bio?: string | null;
  githubUrl?: string | null;
  linkedinUrl?: string | null;
  websiteUrl?: string | null;
  resumeUrl?: string | null;
  skills: Array<{ id: string; skillName: string; proficiency?: string | null }>;
  projects: Array<{ id: string; title: string; description?: string | null; projectUrl?: string | null; repoUrl?: string | null }>;
}
