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
