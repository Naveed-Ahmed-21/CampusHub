import { z } from 'zod';
import { updateProfileSchema, addSkillSchema, addProjectSchema } from './profile.validation';

export type UpdateProfileDTO = z.infer<typeof updateProfileSchema>['body'];
export type AddSkillDTO = z.infer<typeof addSkillSchema>['body'];
export type AddProjectDTO = z.infer<typeof addProjectSchema>['body'];

export interface ProfileResponseDTO {
  id: string;
  email: string;
  username?: string;
  firstName: string;
  lastName: string;
  role?: string;
  department?: { id: string; name: string } | null;
  rollNumber?: string | null;
  phone?: string | null;
  avatarUrl?: string | null;
  bio?: string | null;
  githubUrl?: string | null;
  linkedinUrl?: string | null;
  websiteUrl?: string | null;
  resumeUrl?: string | null;
  followersCount?: number;
  followingCount?: number;
  postsCount?: number;
  isFollowing?: boolean;
  skills: Array<{ id: string; skillName: string; proficiency?: string | null }>;
  projects: Array<{ id: string; title: string; description?: string | null; projectUrl?: string | null; repoUrl?: string | null }>;
}
