import { z } from 'zod';

export const createWeeklyGoalSchema = z.object({
  body: z.object({
    title: z.string().min(1, 'Goal title must be at least 1 character').max(255),
    target_date: z.string().nullish(),
    targetDate: z.string().nullish(),
    category: z.string().nullish(),
  }),
});

export const updateWeeklyGoalSchema = z.object({
  body: z.object({
    title: z.string().min(1).max(255).optional(),
    target_date: z.string().nullish(),
    targetDate: z.string().nullish(),
    category: z.string().nullish(),
    is_completed: z.boolean().optional(),
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

export const generateRoadmapSchema = z.object({
  body: z.object({
    role: z.string().min(2, 'Career role is required').max(100),
    level: z
      .string()
      .nullish()
      .transform((val) => {
        if (!val) return 'Beginner' as const;
        const lower = val.toLowerCase();
        if (lower.includes('expert') || lower.includes('advanc')) return 'Expert' as const;
        if (lower.includes('inter') || lower.includes('build')) return 'Intermediate' as const;
        return 'Beginner' as const;
      }),
    weekly_hours: z
      .union([z.number(), z.string()])
      .nullish()
      .transform((val) => {
        if (val === null || val === undefined) return 10;
        const num = typeof val === 'number' ? val : parseInt(String(val), 10);
        return isNaN(num) ? 10 : Math.min(Math.max(num, 1), 80);
      }),
    goal: z.string().max(500).nullish(),
    deadline_days: z
      .union([z.number(), z.string()])
      .nullish()
      .transform((val) => {
        if (val === null || val === undefined) return undefined;
        const num = typeof val === 'number' ? val : parseInt(String(val), 10);
        return isNaN(num) ? undefined : num;
      }),
    is_placement_focused: z.boolean().nullish(),
    create_new_version: z.boolean().nullish(),
    assessment_data: z.record(z.any()).nullish(),
  }),
});

export const checkDuplicateRoadmapSchema = z.object({
  body: z.object({
    target_role: z.string().min(2, 'Target role is required'),
  }),
});

export const updateRoadmapStatusSchema = z.object({
  body: z.object({
    status: z.enum(['ACTIVE', 'PAUSED', 'COMPLETED', 'ARCHIVED']).optional(),
    title: z.string().min(2).max(255).optional(),
  }),
});

export const toggleDailyTaskSchema = z.object({
  body: z.object({
    task_id: z.string().min(1),
    is_completed: z.boolean(),
  }),
});

export const askAiRoadmapSchema = z.object({
  body: z.object({
    prompt: z.string().min(2, 'Prompt must not be empty').max(1000),
    roadmap_id: z.string().uuid('Invalid roadmap ID').optional().or(z.literal('')).nullable(),
    current_phase: z.number().optional(),
  }),
});

export const askMentorSchema = z.object({
  body: z.object({
    roadmap_id: z.string().uuid('Invalid roadmap ID'),
    message: z.string().min(5, 'Message must be at least 5 characters').max(2000),
    faculty_id: z.string().uuid().optional(),
  }),
});

export const exportPortfolioSchema = z.object({
  body: z.object({
    roadmap_id: z.string().uuid('Invalid roadmap ID'),
    title: z.string().min(2, 'Project title required').max(255),
    description: z.string().max(2000).optional(),
    tech_stack: z.array(z.string()).min(1, 'At least one tech stack skill required'),
    project_url: z.string().url().optional().or(z.literal('')),
    repo_url: z.string().url().optional().or(z.literal('')),
  }),
});

export const generateQuizSchema = z.object({
  body: z.object({
    roadmap_id: z.string().uuid().optional().or(z.literal('')).nullable(),
    phase_number: z.coerce.number().optional().default(1),
    role: z.string().optional().default('Modern Full-Stack & Cloud Engineer'),
    topic: z.string().optional(),
    difficulty: z.enum(['Beginner', 'Intermediate', 'Advanced']).optional().default('Beginner'),
    num_questions: z.coerce.number().min(1).max(15).optional().default(5),
  }),
});

export const submitQuizSchema = z.object({
  body: z.object({
    roadmap_id: z.string().uuid().optional().or(z.literal('')).nullable(),
    phase_number: z.coerce.number().min(1),
    role: z.string().optional().default('Full-Stack'),
    answers: z.record(z.coerce.number()).or(z.any()),
  }),
});

export const pathfinderChatSchema = z.object({
  body: z.object({
    message: z.string().min(1, 'Message cannot be empty').max(2000),
    conversation_id: z.string().uuid().optional(),
  }),
});

export const pathfinderConfirmSchema = z.object({
  body: z.object({
    conversation_id: z.string().uuid('Invalid conversation ID'),
  }),
});

export const startPathfinderSessionSchema = z.object({
  body: z
    .object({
      resume_active: z.boolean().optional().default(true),
    })
    .optional(),
});

export const getPathfinderSessionSchema = z.object({
  params: z.object({
    sessionId: z.string().uuid('Invalid session ID'),
  }),
});

export const sendPathfinderMessageSchema = z.object({
  params: z.object({
    sessionId: z.string().uuid('Invalid session ID'),
  }),
  body: z.object({
    message: z.string().min(1, 'Message cannot be empty').max(2000),
  }),
});

export const confirmPathfinderSessionSchema = z.object({
  params: z.object({
    sessionId: z.string().uuid('Invalid session ID'),
  }),
  body: z
    .object({
      selected_direction: z.string().optional(),
      overrides: z
        .object({
          targetRole: z.string().optional(),
          experienceLevel: z.enum(['Beginner', 'Intermediate', 'Expert']).optional(),
          dailyHours: z.number().int().min(1).max(12).optional(),
          preferredLanguage: z.string().optional(),
          goal: z.string().optional(),
        })
        .optional(),
    })
    .optional(),
});

export const generatePathfinderJourneySchema = z.object({
  params: z.object({
    sessionId: z.string().uuid('Invalid session ID'),
  }),
  body: z
    .object({
      selected_direction: z.string().optional(),
    })
    .optional(),
});

export const askAiDoubtSchema = z.object({
  body: z.object({
    prompt: z.string().min(1, 'Prompt cannot be empty').max(2000),
    roadmap_id: z.string().uuid().optional().or(z.literal('')).nullable(),
  }),
});

export const improveRoadmapSchema = z.object({
  body: z.object({
    reason: z.string().min(2, 'Reason is required').max(255),
    details: z.string().max(1000).optional(),
  }),
});

export const startLearningSessionSchema = z.object({
  body: z.object({
    roadmap_id: z.string().uuid('Invalid roadmap ID'),
    task_id: z.string().min(1),
    task_title: z.string().min(1),
    phase_number: z.number().optional().default(1),
  }),
});

export const finishLearningSessionSchema = z.object({
  body: z.object({
    session_id: z.string().uuid('Invalid session ID'),
    duration_minutes: z.number().min(0),
    status: z.enum(['COMPLETED', 'SKIPPED', 'NEEDS_REVIEW']).default('COMPLETED'),
    self_rating: z.number().min(1).max(5).optional(),
  }),
});

export const startInterviewSchema = z.object({
  body: z.object({
    roadmap_id: z.string().uuid().optional(),
    target_role: z.string().optional(),
    mode: z.enum(['TEXT', 'VOICE', 'VIDEO']).default('TEXT'),
  }),
});

export const turnInterviewSchema = z.object({
  body: z.object({
    session_id: z.string().uuid('Invalid session ID'),
    student_answer: z.string().min(1, 'Answer cannot be empty').max(4000),
  }),
});

export const finishInterviewSchema = z.object({
  body: z.object({
    session_id: z.string().uuid('Invalid session ID'),
  }),
});

export const applyInterviewRoadmapSchema = z.object({
  body: z.object({
    session_id: z.string().uuid('Invalid session ID'),
  }),
});

export const startDynamicPathfinderSchema = z.object({
  body: z
    .object({
      target_domain: z.string().optional(),
      preferred_language: z.string().optional(),
      department: z.string().optional(),
      resume_active: z.boolean().optional(),
    })
    .optional(),
});

export const answerDynamicPathfinderSchema = z.object({
  params: z.object({
    sessionId: z.string().uuid('Invalid session ID'),
  }),
  body: z.object({
    answer: z.string().min(1, 'Answer is required').max(3000),
    question_id: z.string().optional(),
  }),
});

export const generatePersonalizedRoadmapSchema = z.object({
  body: z.object({
    target_role: z.string().min(2, 'Target role is required').max(150),
    department: z.string().optional(),
    current_level: z.string().optional(),
    hours_per_week: z
      .union([z.number(), z.string()])
      .nullish()
      .transform((val) => {
        if (val === null || val === undefined) return 10;
        const num = typeof val === 'number' ? val : parseInt(String(val), 10);
        return isNaN(num) ? 10 : Math.min(Math.max(num, 1), 80);
      }),
    timeline_weeks: z
      .union([z.number(), z.string()])
      .nullish()
      .transform((val) => {
        if (val === null || val === undefined) return 16;
        const num = typeof val === 'number' ? val : parseInt(String(val), 10);
        return isNaN(num) ? 16 : Math.min(Math.max(num, 2), 52);
      }),
    primary_goal: z.string().max(500).optional(),
    preferred_language: z.string().optional(),
    skill_focus_areas: z.array(z.string()).optional(),
  }),
});

const normalizeUrl = (val: unknown) => {
  if (!val || typeof val !== 'string') return '';
  const trimmed = val.trim();
  if (!trimmed) return '';
  if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
    return `https://${trimmed}`;
  }
  return trimmed;
};

export const createProjectEvidenceSchema = z.object({
  body: z.object({
    title: z.string().min(2, 'Title is required').max(255),
    description: z.string().min(5, 'Description is required').max(3000),
    github_url: z.string().optional().nullable().transform(normalizeUrl),
    demo_url: z.string().optional().nullable().transform(normalizeUrl),
    tech_stack: z.array(z.string()).optional().default([]),
  }),
});

