export interface CreateWeeklyGoalDto {
  title: string;
  target_date: string;
}

export interface ToggleGoalDto {
  is_completed: boolean;
}

export interface ToggleNodeProgressDto {
  node_id: string;
  is_completed: boolean;
}

export interface SubmitMiniProjectDto {
  project_id: string;
  repo_url: string;
  live_demo_url?: string;
}

export interface QueryRoadmapsDto {
  category?: string;
  level?: string;
  search?: string;
}

export interface AssessmentSubmissionDto {
  year: string;
  primary_interest: string;
  math_theory_comfort: string;
  coding_experience: string;
  learning_style: string;
  weekly_hours: number;
  target_outcome: string;
  known_languages?: string[];
  preferred_ecosystem?: string;
  struggle_area?: string;
}

export interface CareerPathRecommendation {
  id: string;
  title: string;
  slug: string;
  category: string;
  match_percentage: number;
  difficulty: 'Beginner' | 'Intermediate' | 'Expert';
  reasoning: string;
  weekly_commitment: string;
  key_skills: string[];
  suggested_projects: string[];
  phases: Array<{
    phase_number: number;
    title: string;
    weeks: number;
    description: string;
    topics: string[];
  }>;
}

export interface HelpMeDecideDto {
  visual_vs_logic: 'VISUAL' | 'LOGIC';
  fast_vs_deep: 'FAST_FEEDBACK' | 'DEEP_SYSTEMS' | 'DEEP_THEORY';
  startup_vs_enterprise: 'AGILE_STARTUP' | 'ENTERPRISE_SCALE' | 'ENTERPRISE';
  confusion_notes?: string;
  query?: string;
}

export interface GenerateRoadmapDto {
  roadmap_id?: string;
  role: string;
  level: 'Beginner' | 'Intermediate' | 'Expert';
  weekly_hours: number;
  goal?: string;
  deadline_days?: number;
  is_placement_focused?: boolean;
  create_new_version?: boolean;
  assessment_data?: Record<string, unknown>;
}

export interface SubmitQuizDto {
  roadmap_id?: string;
  phase_number: number;
  role: string;
  answers: Record<string | number, number>;
}

export interface RoadmapTask {
  id: string;
  title: string;
  type: 'LEARN' | 'PRACTICE' | 'CHALLENGE';
  duration_mins: number;
  is_completed: boolean;
  resource_ref?: string;
}

export interface RoadmapQuizQuestion {
  question: string;
  options: string[];
  correct_index: number;
  explanation: string;
}

export interface RoadmapPracticalChallenge {
  title: string;
  description: string;
  requirements: string[];
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced';
}

export interface RoadmapProject {
  title: string;
  description: string;
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced';
  tech_stack: string[];
  milestones: string[];
  is_completed?: boolean;
  repo_url?: string;
  live_demo_url?: string;
}

export interface RoadmapPhase {
  phase_number: number;
  title: string;
  weeks: number;
  description: string;
  objectives: string[];
  skills: string[];
  tasks: RoadmapTask[];
  practical_challenge?: RoadmapPracticalChallenge;
  project?: RoadmapProject;
  quiz?: {
    title: string;
    questions: RoadmapQuizQuestion[];
  };
  completion_criteria: string;
}

export interface SkillGapAnalysis {
  target_role: string;
  strong_skills: string[];
  needs_work_skills: string[];
  missing_skills: string[];
  recommended_next_step: string;
}

export interface SkillMapNode {
  id: string;
  name: string;
  category: string;
  status: 'COMPLETED' | 'IN_PROGRESS' | 'NEEDS_WORK' | 'LOCKED';
  depends_on: string[];
}

export interface DailyLearningPlan {
  today_goal: string;
  estimated_minutes: number;
  priority: 'HIGH' | 'MEDIUM' | 'NORMAL';
  phase_number: number;
  phase_title: string;
  tasks: RoadmapTask[];
}

export interface WeeklyReviewData {
  study_minutes: number;
  tasks_completed: number;
  quizzes_completed: number;
  projects_completed: number;
  strongest_skills: string[];
  weakest_skills: string[];
  ai_recommendation: string;
  streak_days: number;
}

export interface JobReadinessData {
  overall_percent: number;
  technical_percent: number;
  projects_percent: number;
  problem_solving_percent: number;
  interview_percent: number;
  portfolio_percent: number;
  next_priority: string;
}

export interface InterviewQuestion {
  id: string;
  type: 'TECHNICAL' | 'PROJECT' | 'SYSTEM_DESIGN' | 'BEHAVIORAL';
  question: string;
  context?: string;
  tips: string[];
}

export interface CheckDuplicateDto {
  target_role: string;
}

export interface AskAiRoadmapDto {
  prompt: string;
  roadmap_id: string;
  current_phase?: number;
}

export interface AskMentorDto {
  roadmap_id: string;
  message: string;
  faculty_id?: string;
}

export interface ExportPortfolioDto {
  roadmap_id: string;
  title: string;
  description?: string;
  tech_stack: string[];
  project_url?: string;
  repo_url?: string;
}

export interface UpdateRoadmapStatusDto {
  status?: 'ACTIVE' | 'PAUSED' | 'COMPLETED' | 'ARCHIVED';
  title?: string;
}

export interface GenerateQuizDto {
  roadmap_id?: string | null;
  phase_number?: number;
  role?: string;
  topic?: string;
  difficulty?: 'Beginner' | 'Intermediate' | 'Advanced';
  num_questions?: number;
}

export type QuizQuestionType =
  | 'MCQ'
  | 'SCENARIO'
  | 'DEBUGGING'
  | 'CODE_UNDERSTANDING'
  | 'EDGE_CASE'
  | 'PERFORMANCE'
  | 'SECURITY'
  | 'ARCHITECTURE_TRADEOFF';

export interface AdaptiveQuizQuestion {
  id: string;
  type: QuizQuestionType;
  question: string;
  code_snippet?: string;
  scenario?: string;
  options: string[];
  correct_index: number;
  explanation: string;
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced';
  tested_concept: string;
}

export interface AdaptiveQuizResponse {
  quiz_id: string;
  topic: string;
  phase_number: number;
  role: string;
  difficulty: string;
  questions: AdaptiveQuizQuestion[];
  total_questions: number;
}

// ==========================================
// AI PATHFINDER & INTELLIGENCE FOUNDATION
// ==========================================

export type PathfinderState =
  | 'STARTED'
  | 'COLLECTING_CONTEXT'
  | 'ANALYZING'
  | 'AWAITING_CONFIRMATION'
  | 'CONFIRMED'
  | 'JOURNEY_CREATED'
  | 'ABANDONED';

export interface CareerDirectionMatch {
  role: string;
  match_score: number;
  matchScore?: number;
  rationale: string;
  evidence: string[];
  gaps: string[];
  next_steps: string[];
  nextSteps?: string[];
}

export interface ExtractedStudentProfile {
  target_role?: string;
  targetRole?: string;
  experience_level?: 'Beginner' | 'Intermediate' | 'Expert';
  experienceLevel?: 'Beginner' | 'Intermediate' | 'Expert';
  known_skills?: string[];
  knownSkills?: string[];
  weak_skills?: string[];
  weakSkills?: string[];
  daily_hours?: number;
  dailyHours?: number;
  preferred_language?: string;
  preferredLanguage?: string;
  goal?: string;
  interests?: string[];
  constraints?: string[];
  projects_built?: string[];
  projectsBuilt?: string[];
}

export interface PathfinderSessionResponse {
  session_id: string;
  state: PathfinderState;
  message: string;
  suggested_pills: string[];
  extracted_profile?: ExtractedStudentProfile;
  career_matches?: CareerDirectionMatch[];
  is_confirmed: boolean;
  is_complete: boolean;
  created_at?: string;
  updated_at?: string;
}
