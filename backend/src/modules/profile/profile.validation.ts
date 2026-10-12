import { z } from 'zod';

export const updateProfileSchema = z.object({
  body: z.object({
    firstName: z.string().min(1, 'First name cannot be empty').optional().nullable(),
    lastName: z.string().min(1, 'Last name cannot be empty').optional().nullable(),
    phone: z.string().optional().nullable(),
    avatarUrl: z.string().optional().nullable(),
    avatar_url: z.string().optional().nullable(),
    bio: z.string().max(500, 'Bio must be at most 500 characters').optional().nullable(),
    githubUrl: z.string().url('Invalid GitHub URL').or(z.literal('')).optional().nullable(),
    linkedinUrl: z.string().url('Invalid LinkedIn URL').or(z.literal('')).optional().nullable(),
    websiteUrl: z.string().url('Invalid Website URL').or(z.literal('')).optional().nullable(),
  }),
});

export const addSkillSchema = z.object({
  body: z.object({
    skillName: z.string().trim().min(1, 'Skill name is required'),
    proficiency: z.string().optional().nullable(),
  }),
});

export const addProjectSchema = z.object({
  body: z.object({
    title: z.string().trim().min(1, 'Project title is required'),
    description: z.string().optional().nullable(),
    projectUrl: z.string().url('Invalid project URL').or(z.literal('')).optional().nullable(),
    repoUrl: z.string().url('Invalid repository URL').or(z.literal('')).optional().nullable(),
  }),
});

export const submitOnboardingSchema = z.object({
  body: z
    .object({
      firstName: z.string().min(1).optional(),
      lastName: z.string().min(1).optional(),
      phone: z.string().min(10, 'Valid phone number is required'),
      dob: z.string().min(1, 'Date of birth is required'),
      bloodGroup: z.string().optional(),
      fatherName: z.string().min(1, 'Father name is required'),
      fatherPhone: z.string().min(10, 'Valid father phone number is required'),
      motherName: z.string().min(1, 'Mother name is required'),
      motherPhone: z.string().min(10, 'Valid mother phone number is required'),
      guardianName: z.string().optional(),
      guardianPhone: z.string().optional(),
      emergencyContactName: z.string().min(1, 'Emergency contact name is required'),
      emergencyContactRelation: z.string().min(1, 'Emergency contact relation is required'),
      emergencyContactPhone: z.string().min(10, 'Valid emergency contact phone number is required'),
      permanentAddress: z.string().min(1, 'Permanent address is required'),
      permanentCity: z.string().min(1, 'City is required'),
      permanentState: z.string().min(1, 'State is required'),
      permanentPincode: z.string().min(4, 'Pincode is required'),
      currentAddress: z.string().optional(),
      currentCity: z.string().optional(),
      currentState: z.string().optional(),
      currentPincode: z.string().optional(),
      tenthPercentage: z.number().min(0).max(100, 'Tenth percentage must be between 0 and 100'),
      twelfthPercentage: z.number().min(0).max(100, 'Twelfth percentage must be between 0 and 100').optional(),
      registrationNumber: z.string().optional(),
      rollNumber: z.string().optional(),
    })
    .refine((data) => data.phone !== data.fatherPhone, {
      message: 'Student mobile number cannot be identical to father mobile number',
      path: ['fatherPhone'],
    })
    .refine((data) => data.phone !== data.motherPhone, {
      message: 'Student mobile number cannot be identical to mother mobile number',
      path: ['motherPhone'],
    })
    .refine((data) => data.fatherPhone !== data.motherPhone, {
      message: 'Father mobile number cannot be identical to mother mobile number',
      path: ['motherPhone'],
    }),
});

export const updateCareerProfileSchema = z.object({
  body: z.object({
    bio: z.string().max(1000).optional().nullable(),
    githubUrl: z.string().url('Invalid GitHub URL').or(z.literal('')).optional().nullable(),
    linkedinUrl: z.string().url('Invalid LinkedIn URL').or(z.literal('')).optional().nullable(),
    websiteUrl: z.string().url('Invalid Website URL').or(z.literal('')).optional().nullable(),
    resumeUrl: z.string().url('Invalid Resume URL').or(z.literal('')).optional().nullable(),
    skills: z.array(z.string()).optional().nullable(),
  }),
});

export const createChangeRequestSchema = z.object({
  body: z.object({
    field: z.string().min(1, 'Field name is required'),
    category: z.enum(['PERSONAL_CHANGE', 'ACADEMIC_IDENTITY_CHANGE', 'CAREER_PROFILE_CHANGE']),
    requestedValue: z.string().min(1, 'Requested value is required'),
    reason: z.string().min(5, 'Reason must be at least 5 characters long'),
    supportingDocument: z.string().optional(),
  }),
});

