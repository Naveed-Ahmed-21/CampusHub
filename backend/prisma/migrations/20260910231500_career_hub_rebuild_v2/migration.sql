-- AlterTable
ALTER TABLE "learning_resources" ADD COLUMN IF NOT EXISTS "channel_name" VARCHAR(255),
ADD COLUMN IF NOT EXISTS "difficulty" VARCHAR(50) NOT NULL DEFAULT 'Beginner',
ADD COLUMN IF NOT EXISTS "github_forks" INTEGER,
ADD COLUMN IF NOT EXISTS "github_stars" INTEGER,
ADD COLUMN IF NOT EXISTS "github_updated_at" TIMESTAMP(3),
ADD COLUMN IF NOT EXISTS "language" VARCHAR(50) NOT NULL DEFAULT 'English',
ADD COLUMN IF NOT EXISTS "metadata" JSONB,
ADD COLUMN IF NOT EXISTS "resource_type" VARCHAR(50) NOT NULL DEFAULT 'DOCUMENTATION',
ADD COLUMN IF NOT EXISTS "updated_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS "verification_status" VARCHAR(50) NOT NULL DEFAULT 'VERIFIED',
ADD COLUMN IF NOT EXISTS "view_count" INTEGER;

-- CreateTable
CREATE TABLE IF NOT EXISTS "career_pathfinder_sessions" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "stage" VARCHAR(50) NOT NULL DEFAULT 'CAREER_DISCOVERY',
    "current_question" JSONB,
    "collected_evidence" JSONB,
    "contradictions" JSONB,
    "question_history" JSONB,
    "career_hypotheses" JSONB,
    "missing_information" JSONB,
    "mindset_signals" JSONB,
    "career_analysis" JSONB,
    "preferred_language" VARCHAR(50) NOT NULL DEFAULT 'English',
    "completed" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "career_pathfinder_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE IF NOT EXISTS "skill_dependencies" (
    "id" UUID NOT NULL,
    "roadmap_id" UUID,
    "source_skill" VARCHAR(100) NOT NULL,
    "target_skill" VARCHAR(100) NOT NULL,
    "dependency_type" VARCHAR(50) NOT NULL DEFAULT 'PREREQUISITE',
    "confidence" DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    "metadata" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "skill_dependencies_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE IF NOT EXISTS "project_evidences" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "title" VARCHAR(255) NOT NULL,
    "description" TEXT NOT NULL,
    "github_url" TEXT,
    "demo_url" TEXT,
    "tech_stack" JSONB,
    "verified" BOOLEAN NOT NULL DEFAULT false,
    "ai_review" TEXT,
    "evidence_score" INTEGER DEFAULT 70,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "project_evidences_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX IF NOT EXISTS "career_pathfinder_sessions_user_id_idx" ON "career_pathfinder_sessions"("user_id");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "skill_dependencies_roadmap_id_idx" ON "skill_dependencies"("roadmap_id");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "skill_dependencies_source_skill_idx" ON "skill_dependencies"("source_skill");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "skill_dependencies_target_skill_idx" ON "skill_dependencies"("target_skill");

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "skill_dependencies_roadmap_id_source_skill_target_skill_key" ON "skill_dependencies"("roadmap_id", "source_skill", "target_skill");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "project_evidences_user_id_idx" ON "project_evidences"("user_id");

-- AddForeignKey
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'career_pathfinder_sessions_user_id_fkey'
  ) THEN
    ALTER TABLE "career_pathfinder_sessions" ADD CONSTRAINT "career_pathfinder_sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END $$;

-- AddForeignKey
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'skill_dependencies_roadmap_id_fkey'
  ) THEN
    ALTER TABLE "skill_dependencies" ADD CONSTRAINT "skill_dependencies_roadmap_id_fkey" FOREIGN KEY ("roadmap_id") REFERENCES "career_roadmaps"("id") ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END $$;

-- AddForeignKey
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'project_evidences_user_id_fkey'
  ) THEN
    ALTER TABLE "project_evidences" ADD CONSTRAINT "project_evidences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END $$;
