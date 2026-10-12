import { z } from 'zod';
import {
  updateProfileSchema,
  addSkillSchema,
  addProjectSchema,
  submitOnboardingSchema,
  updateCareerProfileSchema,
  createChangeRequestSchema,
} from './profile.validation';

export type UpdateProfileDTO = z.infer<typeof updateProfileSchema>['body'];
export type AddSkillDTO = z.infer<typeof addSkillSchema>['body'];
export type AddProjectDTO = z.infer<typeof addProjectSchema>['body'];
export type SubmitOnboardingDTO = z.infer<typeof submitOnboardingSchema>['body'];
export type UpdateCareerProfileDTO = z.infer<typeof updateCareerProfileSchema>['body'];
export type CreateChangeRequestDTO = z.infer<typeof createChangeRequestSchema>['body'];

export interface OnboardingContextDTO {
  userId: string;
  email: string;
  firstName: string;
  lastName: string;
  departmentId?: string | null;
  departmentName?: string | null;
  programId?: string | null;
  programName?: string | null;
  batchName?: string | null;
  section?: string | null;
  rollNumber?: string | null;
  registrationNumber?: string | null;
}

export type FieldPolicy = 'LOCKED' | 'APPROVAL_REQUIRED' | 'EDITABLE';

export interface DetailedStudentProfileDTO {
  overview: {
    userId: string;
    email: string;
    fullName: string;
    avatarUrl?: string | null;
    role: string;
    status: string;
    isProfileCompleted: boolean;
    completionPercentage: number;
    badges: string[];
  };
  officialIdentity: {
    rollNumber?: string | null;
    registrationNumber?: string | null;
    departmentId?: string | null;
    departmentName?: string | null;
    departmentCode?: string | null;
    programId?: string | null;
    programName?: string | null;
    batchName?: string | null;
    section?: string | null;
    currentStatus?: string | null;
    admissionYear?: number | null;
  };
  personal: {
    firstName: string;
    lastName: string;
    dob?: string | null;
    age?: number | null;
    gender?: string | null;
    bloodGroup?: string | null;
    phone?: string | null;
    email: string;
  };
  family: {
    fatherName?: string | null;
    fatherPhone?: string | null;
    motherName?: string | null;
    motherPhone?: string | null;
    guardianName?: string | null;
    guardianPhone?: string | null;
  };
  address: {
    permanentAddress?: string | null;
    permanentCity?: string | null;
    permanentState?: string | null;
    permanentCountry?: string | null;
    permanentPincode?: string | null;
    currentAddress?: string | null;
    currentCity?: string | null;
    currentState?: string | null;
    currentCountry?: string | null;
    currentPincode?: string | null;
  };
  emergency: {
    contactName?: string | null;
    contactRelation?: string | null;
    contactPhone?: string | null;
  };
  education: {
    tenthPercentage?: number | null;
    twelfthPercentage?: number | null;
  };
  career: {
    bio?: string | null;
    skills: Array<{ id: string; skillName: string; proficiency?: string | null }>;
    projects: Array<{ id: string; title: string; description?: string | null; projectUrl?: string | null; repoUrl?: string | null }>;
    githubUrl?: string | null;
    linkedinUrl?: string | null;
    websiteUrl?: string | null;
    resumeUrl?: string | null;
  };
  fieldPolicies: Record<string, FieldPolicy>;
}

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
  status?: string;
  createdAt?: Date;
  updatedAt?: Date;
  lastSeen?: Date | null;
  skills: Array<{ id: string; skillName: string; proficiency?: string | null }>;
  projects: Array<{ id: string; title: string; description?: string | null; projectUrl?: string | null; repoUrl?: string | null }>;
  clubs?: Array<{
    id: string;
    clubId: string;
    name: string;
    category: string;
    logoUrl?: string | null;
    role: string;
  }>;
}

