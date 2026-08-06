export interface UpdatePortfolioDto {
  bio?: string;
  github_url?: string;
  linkedin_url?: string;
  website_url?: string;
  resume_url?: string;
  cgpa?: number;
  custom_username?: string;
  is_public?: boolean;
}

export interface AddProjectDto {
  title: string;
  description?: string;
  tech_stack?: string[];
  project_url?: string;
  repo_url?: string;
  image_url?: string;
}

export interface AddSkillDto {
  skill_name: string;
  category?: string;
  proficiency?: string;
}

export interface AddCertificateDto {
  title: string;
  issuer: string;
  issue_date?: string;
  credential_url?: string;
  credential_id?: string;
}

export interface AddAchievementDto {
  title: string;
  category?: string;
  description?: string;
  date_achieved?: string;
  proof_url?: string;
}
