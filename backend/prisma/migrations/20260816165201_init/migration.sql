-- CreateEnum
CREATE TYPE "Role" AS ENUM ('STUDENT', 'FACULTY', 'PLACEMENT_OFFICER', 'ADMIN', 'DEPT_ADMIN', 'COLLEGE_ADMIN', 'CLUB_COORDINATOR', 'SUPER_ADMIN');

-- CreateEnum
CREATE TYPE "UserStatus" AS ENUM ('PENDING', 'ACTIVE', 'SUSPENDED', 'DEACTIVATED');

-- CreateEnum
CREATE TYPE "PostType" AS ENUM ('ANNOUNCEMENT', 'GENERAL', 'ACADEMIC', 'EVENT_PROMO', 'PLACEMENT');

-- CreateEnum
CREATE TYPE "ClubRole" AS ENUM ('MEMBER', 'LEAD', 'FACULTY_ADVISOR');

-- CreateEnum
CREATE TYPE "ClubStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

-- CreateEnum
CREATE TYPE "DriveStatus" AS ENUM ('UPCOMING', 'ONGOING', 'COMPLETED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "ApplicationStatus" AS ENUM ('APPLIED', 'SHORTLISTED', 'INTERVIEW_SCHEDULED', 'REJECTED', 'OFFERED');

-- CreateEnum
CREATE TYPE "ChatRoomType" AS ENUM ('DIRECT', 'GROUP', 'ANNOUNCEMENT');

-- CreateEnum
CREATE TYPE "NotificationType" AS ENUM ('SYSTEM', 'ANNOUNCEMENT', 'EVENT_REMINDER', 'CHAT_MESSAGE', 'PLACEMENT_UPDATE', 'LIKE', 'COMMENT');

-- CreateEnum
CREATE TYPE "RegistrationStatus" AS ENUM ('REGISTERED', 'ATTENDED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "MediaType" AS ENUM ('IMAGE', 'DOCUMENT');

-- CreateEnum
CREATE TYPE "MediaCategory" AS ENUM ('PROFILE_IMAGE', 'POST_IMAGE', 'CLUB_LOGO', 'CLUB_RESOURCE', 'CHAT_IMAGE', 'CHAT_DOCUMENT', 'EVENT_MEDIA', 'EVENT_DOCUMENT', 'CAREER_RESOURCE', 'RESUME', 'CERTIFICATE', 'PORTFOLIO_IMAGE', 'PORTFOLIO_DOCUMENT');

-- CreateTable
CREATE TABLE "colleges" (
    "id" UUID NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "code" VARCHAR(50) NOT NULL,
    "domain" VARCHAR(255) NOT NULL,
    "logo_url" TEXT,
    "address" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "deleted_at" TIMESTAMP(3),

    CONSTRAINT "colleges_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "departments" (
    "id" UUID NOT NULL,
    "college_id" UUID NOT NULL,
    "name" VARCHAR(150) NOT NULL,
    "code" VARCHAR(50) NOT NULL,
    "description" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "departments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "college_id" UUID NOT NULL,
    "department_id" UUID,
    "email" VARCHAR(255) NOT NULL,
    "password_hash" TEXT NOT NULL,
    "first_name" VARCHAR(100) NOT NULL,
    "last_name" VARCHAR(100) NOT NULL,
    "roll_number" VARCHAR(50),
    "role" "Role" NOT NULL DEFAULT 'STUDENT',
    "status" "UserStatus" NOT NULL DEFAULT 'ACTIVE',
    "avatar_url" TEXT,
    "phone" VARCHAR(20),
    "is_online" BOOLEAN NOT NULL DEFAULT false,
    "last_seen" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "deleted_at" TIMESTAMP(3),

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "refresh_tokens" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "token_hash" TEXT NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "is_revoked" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "password_reset_tokens" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "token_hash" TEXT NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "password_reset_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_follows" (
    "id" UUID NOT NULL,
    "follower_id" UUID NOT NULL,
    "following_id" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_follows_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "posts" (
    "id" UUID NOT NULL,
    "college_id" UUID NOT NULL,
    "department_id" UUID,
    "club_id" UUID,
    "author_id" UUID NOT NULL,
    "title" VARCHAR(255) NOT NULL,
    "content" TEXT NOT NULL,
    "type" "PostType" NOT NULL DEFAULT 'GENERAL',
    "is_pinned" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "posts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "post_attachments" (
    "id" UUID NOT NULL,
    "post_id" UUID NOT NULL,
    "file_name" VARCHAR(255) NOT NULL,
    "file_url" TEXT NOT NULL,
    "file_type" VARCHAR(100) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "post_attachments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "post_comments" (
    "id" UUID NOT NULL,
    "post_id" UUID NOT NULL,
    "author_id" UUID NOT NULL,
    "content" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "post_comments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "post_likes" (
    "id" UUID NOT NULL,
    "post_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "post_likes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "saved_posts" (
    "id" UUID NOT NULL,
    "post_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "saved_posts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "clubs" (
    "id" UUID NOT NULL,
    "college_id" UUID NOT NULL,
    "created_by_id" UUID,
    "verified_by_id" UUID,
    "name" VARCHAR(150) NOT NULL,
    "category" VARCHAR(100) NOT NULL,
    "description" TEXT,
    "logo_url" TEXT,
    "status" "ClubStatus" NOT NULL DEFAULT 'PENDING',
    "is_cross_department" BOOLEAN NOT NULL DEFAULT true,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "verified_at" TIMESTAMP(3),
    "rejection_reason" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "clubs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "club_resources" (
    "id" UUID NOT NULL,
    "club_id" UUID NOT NULL,
    "uploaded_by_id" UUID NOT NULL,
    "title" VARCHAR(255) NOT NULL,
    "description" TEXT,
    "file_url" TEXT NOT NULL,
    "file_name" VARCHAR(255) NOT NULL,
    "file_type" VARCHAR(100) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "club_resources_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "club_members" (
    "id" UUID NOT NULL,
    "club_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "role" "ClubRole" NOT NULL DEFAULT 'MEMBER',
    "joined_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "club_members_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "events" (
    "id" UUID NOT NULL,
    "college_id" UUID NOT NULL,
    "department_id" UUID,
    "club_id" UUID,
    "organizer_id" UUID NOT NULL,
    "scope" VARCHAR(50) NOT NULL DEFAULT 'COLLEGE',
    "category" VARCHAR(100),
    "title" VARCHAR(255) NOT NULL,
    "description" TEXT,
    "venue" VARCHAR(255),
    "start_time" TIMESTAMP(3) NOT NULL,
    "end_time" TIMESTAMP(3) NOT NULL,
    "banner_url" TEXT,
    "max_capacity" INTEGER,
    "registration_deadline" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "event_registrations" (
    "id" UUID NOT NULL,
    "event_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "status" "RegistrationStatus" NOT NULL DEFAULT 'REGISTERED',
    "ticket_code" VARCHAR(100) NOT NULL,
    "qr_code_token" TEXT,
    "attendance_status" VARCHAR(50) NOT NULL DEFAULT 'REGISTERED',
    "attended_at" TIMESTAMP(3),
    "registered_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "event_registrations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "chat_rooms" (
    "id" UUID NOT NULL,
    "college_id" UUID NOT NULL,
    "club_id" UUID,
    "department_id" UUID,
    "name" VARCHAR(150),
    "type" "ChatRoomType" NOT NULL DEFAULT 'DIRECT',
    "last_message_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "chat_rooms_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "chat_participants" (
    "id" UUID NOT NULL,
    "room_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "last_read_at" TIMESTAMP(3),
    "joined_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "chat_participants_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "chat_messages" (
    "id" UUID NOT NULL,
    "sender_id" UUID NOT NULL,
    "room_id" UUID NOT NULL,
    "message" TEXT NOT NULL,
    "media_url" TEXT,
    "media_type" VARCHAR(50),
    "file_name" VARCHAR(255),
    "file_size" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "chat_messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "chat_read_receipts" (
    "id" UUID NOT NULL,
    "message_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "read_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "chat_read_receipts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "companies" (
    "id" UUID NOT NULL,
    "college_id" UUID NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "website" VARCHAR(255),
    "logo_url" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "companies_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "placement_drives" (
    "id" UUID NOT NULL,
    "college_id" UUID NOT NULL,
    "company_id" UUID,
    "company_name" VARCHAR(255) NOT NULL,
    "role_title" VARCHAR(255) NOT NULL,
    "package_ctc" VARCHAR(100),
    "location" VARCHAR(255),
    "eligibility" TEXT,
    "min_cgpa" DOUBLE PRECISION DEFAULT 0.0,
    "allowed_departments" JSONB,
    "max_backlogs" INTEGER DEFAULT 0,
    "job_description" TEXT,
    "deadline" TIMESTAMP(3) NOT NULL,
    "status" "DriveStatus" NOT NULL DEFAULT 'UPCOMING',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "placement_drives_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "placement_applications" (
    "id" UUID NOT NULL,
    "drive_id" UUID NOT NULL,
    "student_id" UUID NOT NULL,
    "status" "ApplicationStatus" NOT NULL DEFAULT 'APPLIED',
    "resume_url" TEXT,
    "offer_ctc" VARCHAR(100),
    "offer_status" VARCHAR(50),
    "applied_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "placement_applications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "placement_interviews" (
    "id" UUID NOT NULL,
    "application_id" UUID NOT NULL,
    "round_name" VARCHAR(150) NOT NULL,
    "scheduled_at" TIMESTAMP(3) NOT NULL,
    "location_or_link" TEXT,
    "status" VARCHAR(50) NOT NULL DEFAULT 'SCHEDULED',
    "notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "placement_interviews_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "portfolios" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "custom_username" VARCHAR(100),
    "is_public" BOOLEAN NOT NULL DEFAULT true,
    "bio" TEXT,
    "github_url" VARCHAR(255),
    "linkedin_url" VARCHAR(255),
    "website_url" VARCHAR(255),
    "resume_url" TEXT,
    "cgpa" DOUBLE PRECISION DEFAULT 0.0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "portfolios_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "portfolio_projects" (
    "id" UUID NOT NULL,
    "portfolio_id" UUID NOT NULL,
    "title" VARCHAR(255) NOT NULL,
    "description" TEXT,
    "tech_stack" JSONB,
    "project_url" TEXT,
    "repo_url" TEXT,
    "image_url" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "portfolio_projects_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "portfolio_skills" (
    "id" UUID NOT NULL,
    "portfolio_id" UUID NOT NULL,
    "skill_name" VARCHAR(100) NOT NULL,
    "category" VARCHAR(100) DEFAULT 'General',
    "proficiency" VARCHAR(50),

    CONSTRAINT "portfolio_skills_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "portfolio_certificates" (
    "id" UUID NOT NULL,
    "portfolio_id" UUID NOT NULL,
    "title" VARCHAR(255) NOT NULL,
    "issuer" VARCHAR(255) NOT NULL,
    "issue_date" TIMESTAMP(3),
    "credential_url" TEXT,
    "credential_id" VARCHAR(255),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "portfolio_certificates_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "portfolio_achievements" (
    "id" UUID NOT NULL,
    "portfolio_id" UUID NOT NULL,
    "title" VARCHAR(255) NOT NULL,
    "category" VARCHAR(100),
    "description" TEXT,
    "date_achieved" TIMESTAMP(3),
    "proof_url" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "portfolio_achievements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "title" VARCHAR(255) NOT NULL,
    "body" TEXT NOT NULL,
    "type" "NotificationType" NOT NULL DEFAULT 'SYSTEM',
    "category" VARCHAR(100),
    "deep_link" TEXT,
    "is_read" BOOLEAN NOT NULL DEFAULT false,
    "metadata" JSONB,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notification_tokens" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "fcm_token" TEXT NOT NULL,
    "device_type" VARCHAR(50),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notification_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "career_roadmaps" (
    "id" UUID NOT NULL,
    "title" VARCHAR(255) NOT NULL,
    "slug" VARCHAR(100) NOT NULL,
    "category" VARCHAR(100) NOT NULL,
    "description" TEXT NOT NULL,
    "level" VARCHAR(50) NOT NULL DEFAULT 'Beginner',
    "estimated_months" INTEGER NOT NULL DEFAULT 3,
    "icon_name" VARCHAR(100),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "career_roadmaps_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "roadmap_nodes" (
    "id" UUID NOT NULL,
    "roadmap_id" UUID NOT NULL,
    "title" VARCHAR(255) NOT NULL,
    "description" TEXT,
    "order_index" INTEGER NOT NULL,
    "estimated_hours" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "roadmap_nodes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "learning_resources" (
    "id" UUID NOT NULL,
    "roadmap_id" UUID,
    "node_id" UUID,
    "title" VARCHAR(255) NOT NULL,
    "type" VARCHAR(50) NOT NULL,
    "url" TEXT NOT NULL,
    "duration_mins" INTEGER,
    "is_free" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "learning_resources_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_roadmap_progress" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "roadmap_id" UUID NOT NULL,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "completed_node_count" INTEGER NOT NULL DEFAULT 0,
    "progress_percent" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "started_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_roadmap_progress_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_node_progress" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "node_id" UUID NOT NULL,
    "is_completed" BOOLEAN NOT NULL DEFAULT true,
    "completed_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_node_progress_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "weekly_goals" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "title" VARCHAR(255) NOT NULL,
    "target_date" TIMESTAMP(3) NOT NULL,
    "is_completed" BOOLEAN NOT NULL DEFAULT false,
    "completed_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "weekly_goals_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "resume_tips" (
    "id" UUID NOT NULL,
    "category" VARCHAR(100) NOT NULL,
    "title" VARCHAR(255) NOT NULL,
    "content" TEXT NOT NULL,
    "bullet_points" JSONB,
    "sample_url" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "resume_tips_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "placement_prep_modules" (
    "id" UUID NOT NULL,
    "title" VARCHAR(255) NOT NULL,
    "category" VARCHAR(100) NOT NULL,
    "description" TEXT,
    "content_json" JSONB NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "placement_prep_modules_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "mini_project_ideas" (
    "id" UUID NOT NULL,
    "title" VARCHAR(255) NOT NULL,
    "difficulty" VARCHAR(50) NOT NULL,
    "tech_stack" JSONB NOT NULL,
    "problem_statement" TEXT NOT NULL,
    "key_features" JSONB NOT NULL,
    "github_template_url" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "mini_project_ideas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_mini_project_submissions" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "project_id" UUID NOT NULL,
    "repo_url" TEXT NOT NULL,
    "live_demo_url" TEXT,
    "status" VARCHAR(50) NOT NULL DEFAULT 'IN_PROGRESS',
    "submitted_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_mini_project_submissions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "media_assets" (
    "id" UUID NOT NULL,
    "college_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "category" "MediaCategory" NOT NULL,
    "file_type" "MediaType" NOT NULL DEFAULT 'IMAGE',
    "mime_type" VARCHAR(100) NOT NULL,
    "original_name" VARCHAR(255) NOT NULL,
    "file_name" VARCHAR(255) NOT NULL,
    "file_size" INTEGER NOT NULL,
    "url" TEXT NOT NULL,
    "thumbnail_url" TEXT,
    "imagekit_file_id" VARCHAR(255) NOT NULL,
    "folder_path" VARCHAR(255) NOT NULL,
    "width" INTEGER,
    "height" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "media_assets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "subjects" (
    "id" UUID NOT NULL,
    "college_id" UUID NOT NULL,
    "department_id" UUID,
    "faculty_id" UUID NOT NULL,
    "code" VARCHAR(50) NOT NULL,
    "name" VARCHAR(255) NOT NULL,
    "semester" VARCHAR(50) NOT NULL,
    "section" VARCHAR(20) NOT NULL DEFAULT 'A',
    "credits" INTEGER NOT NULL DEFAULT 3,
    "description" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "subjects_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "subject_resources" (
    "id" UUID NOT NULL,
    "subject_id" UUID NOT NULL,
    "uploaded_by_id" UUID NOT NULL,
    "title" VARCHAR(255) NOT NULL,
    "description" TEXT,
    "file_url" TEXT NOT NULL,
    "file_type" VARCHAR(100) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "subject_resources_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "subject_announcements" (
    "id" UUID NOT NULL,
    "subject_id" UUID NOT NULL,
    "faculty_id" UUID NOT NULL,
    "title" VARCHAR(255) NOT NULL,
    "content" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "subject_announcements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "subject_enrollments" (
    "id" UUID NOT NULL,
    "subject_id" UUID NOT NULL,
    "student_id" UUID NOT NULL,
    "enrolled_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "subject_enrollments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "student_mentorships" (
    "id" UUID NOT NULL,
    "faculty_id" UUID NOT NULL,
    "student_id" UUID NOT NULL,
    "assigned_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "notes" TEXT,

    CONSTRAINT "student_mentorships_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "colleges_code_key" ON "colleges"("code");

-- CreateIndex
CREATE UNIQUE INDEX "colleges_domain_key" ON "colleges"("domain");

-- CreateIndex
CREATE INDEX "departments_college_id_idx" ON "departments"("college_id");

-- CreateIndex
CREATE UNIQUE INDEX "departments_college_id_code_key" ON "departments"("college_id", "code");

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "users_college_id_idx" ON "users"("college_id");

-- CreateIndex
CREATE INDEX "users_department_id_idx" ON "users"("department_id");

-- CreateIndex
CREATE INDEX "users_email_idx" ON "users"("email");

-- CreateIndex
CREATE INDEX "users_roll_number_idx" ON "users"("roll_number");

-- CreateIndex
CREATE INDEX "users_created_at_idx" ON "users"("created_at");

-- CreateIndex
CREATE INDEX "refresh_tokens_user_id_idx" ON "refresh_tokens"("user_id");

-- CreateIndex
CREATE INDEX "refresh_tokens_token_hash_idx" ON "refresh_tokens"("token_hash");

-- CreateIndex
CREATE INDEX "password_reset_tokens_user_id_idx" ON "password_reset_tokens"("user_id");

-- CreateIndex
CREATE INDEX "password_reset_tokens_token_hash_idx" ON "password_reset_tokens"("token_hash");

-- CreateIndex
CREATE INDEX "user_follows_follower_id_idx" ON "user_follows"("follower_id");

-- CreateIndex
CREATE INDEX "user_follows_following_id_idx" ON "user_follows"("following_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_follows_follower_id_following_id_key" ON "user_follows"("follower_id", "following_id");

-- CreateIndex
CREATE INDEX "posts_college_id_idx" ON "posts"("college_id");

-- CreateIndex
CREATE INDEX "posts_department_id_idx" ON "posts"("department_id");

-- CreateIndex
CREATE INDEX "posts_club_id_idx" ON "posts"("club_id");

-- CreateIndex
CREATE INDEX "posts_author_id_idx" ON "posts"("author_id");

-- CreateIndex
CREATE INDEX "posts_created_at_idx" ON "posts"("created_at" DESC);

-- CreateIndex
CREATE INDEX "post_attachments_post_id_idx" ON "post_attachments"("post_id");

-- CreateIndex
CREATE INDEX "post_comments_post_id_idx" ON "post_comments"("post_id");

-- CreateIndex
CREATE INDEX "post_comments_author_id_idx" ON "post_comments"("author_id");

-- CreateIndex
CREATE UNIQUE INDEX "post_likes_post_id_user_id_key" ON "post_likes"("post_id", "user_id");

-- CreateIndex
CREATE INDEX "saved_posts_user_id_idx" ON "saved_posts"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "saved_posts_post_id_user_id_key" ON "saved_posts"("post_id", "user_id");

-- CreateIndex
CREATE INDEX "clubs_college_id_idx" ON "clubs"("college_id");

-- CreateIndex
CREATE INDEX "clubs_created_by_id_idx" ON "clubs"("created_by_id");

-- CreateIndex
CREATE INDEX "clubs_status_idx" ON "clubs"("status");

-- CreateIndex
CREATE INDEX "club_resources_club_id_idx" ON "club_resources"("club_id");

-- CreateIndex
CREATE INDEX "club_resources_uploaded_by_id_idx" ON "club_resources"("uploaded_by_id");

-- CreateIndex
CREATE INDEX "club_members_user_id_idx" ON "club_members"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "club_members_club_id_user_id_key" ON "club_members"("club_id", "user_id");

-- CreateIndex
CREATE INDEX "events_college_id_idx" ON "events"("college_id");

-- CreateIndex
CREATE INDEX "events_department_id_idx" ON "events"("department_id");

-- CreateIndex
CREATE INDEX "events_club_id_idx" ON "events"("club_id");

-- CreateIndex
CREATE INDEX "events_scope_idx" ON "events"("scope");

-- CreateIndex
CREATE INDEX "events_start_time_idx" ON "events"("start_time");

-- CreateIndex
CREATE INDEX "event_registrations_user_id_idx" ON "event_registrations"("user_id");

-- CreateIndex
CREATE INDEX "event_registrations_ticket_code_idx" ON "event_registrations"("ticket_code");

-- CreateIndex
CREATE UNIQUE INDEX "event_registrations_event_id_user_id_key" ON "event_registrations"("event_id", "user_id");

-- CreateIndex
CREATE UNIQUE INDEX "chat_rooms_club_id_key" ON "chat_rooms"("club_id");

-- CreateIndex
CREATE UNIQUE INDEX "chat_rooms_department_id_key" ON "chat_rooms"("department_id");

-- CreateIndex
CREATE INDEX "chat_rooms_college_id_idx" ON "chat_rooms"("college_id");

-- CreateIndex
CREATE INDEX "chat_participants_user_id_idx" ON "chat_participants"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "chat_participants_room_id_user_id_key" ON "chat_participants"("room_id", "user_id");

-- CreateIndex
CREATE INDEX "chat_messages_room_id_idx" ON "chat_messages"("room_id");

-- CreateIndex
CREATE INDEX "chat_messages_sender_id_idx" ON "chat_messages"("sender_id");

-- CreateIndex
CREATE INDEX "chat_messages_created_at_idx" ON "chat_messages"("created_at");

-- CreateIndex
CREATE INDEX "chat_read_receipts_user_id_idx" ON "chat_read_receipts"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "chat_read_receipts_message_id_user_id_key" ON "chat_read_receipts"("message_id", "user_id");

-- CreateIndex
CREATE INDEX "placement_drives_college_id_idx" ON "placement_drives"("college_id");

-- CreateIndex
CREATE INDEX "placement_drives_status_idx" ON "placement_drives"("status");

-- CreateIndex
CREATE INDEX "placement_applications_student_id_idx" ON "placement_applications"("student_id");

-- CreateIndex
CREATE UNIQUE INDEX "placement_applications_drive_id_student_id_key" ON "placement_applications"("drive_id", "student_id");

-- CreateIndex
CREATE INDEX "placement_interviews_application_id_idx" ON "placement_interviews"("application_id");

-- CreateIndex
CREATE UNIQUE INDEX "portfolios_user_id_key" ON "portfolios"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "portfolios_custom_username_key" ON "portfolios"("custom_username");

-- CreateIndex
CREATE INDEX "portfolio_projects_portfolio_id_idx" ON "portfolio_projects"("portfolio_id");

-- CreateIndex
CREATE INDEX "portfolio_skills_portfolio_id_idx" ON "portfolio_skills"("portfolio_id");

-- CreateIndex
CREATE INDEX "portfolio_certificates_portfolio_id_idx" ON "portfolio_certificates"("portfolio_id");

-- CreateIndex
CREATE INDEX "portfolio_achievements_portfolio_id_idx" ON "portfolio_achievements"("portfolio_id");

-- CreateIndex
CREATE INDEX "notifications_user_id_idx" ON "notifications"("user_id");

-- CreateIndex
CREATE INDEX "notifications_is_read_idx" ON "notifications"("is_read");

-- CreateIndex
CREATE INDEX "notifications_created_at_idx" ON "notifications"("created_at" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "notification_tokens_fcm_token_key" ON "notification_tokens"("fcm_token");

-- CreateIndex
CREATE INDEX "notification_tokens_user_id_idx" ON "notification_tokens"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "career_roadmaps_slug_key" ON "career_roadmaps"("slug");

-- CreateIndex
CREATE INDEX "roadmap_nodes_roadmap_id_idx" ON "roadmap_nodes"("roadmap_id");

-- CreateIndex
CREATE INDEX "learning_resources_roadmap_id_idx" ON "learning_resources"("roadmap_id");

-- CreateIndex
CREATE INDEX "learning_resources_node_id_idx" ON "learning_resources"("node_id");

-- CreateIndex
CREATE INDEX "user_roadmap_progress_user_id_idx" ON "user_roadmap_progress"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_roadmap_progress_user_id_roadmap_id_key" ON "user_roadmap_progress"("user_id", "roadmap_id");

-- CreateIndex
CREATE INDEX "user_node_progress_user_id_idx" ON "user_node_progress"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_node_progress_user_id_node_id_key" ON "user_node_progress"("user_id", "node_id");

-- CreateIndex
CREATE INDEX "weekly_goals_user_id_idx" ON "weekly_goals"("user_id");

-- CreateIndex
CREATE INDEX "user_mini_project_submissions_user_id_idx" ON "user_mini_project_submissions"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_mini_project_submissions_user_id_project_id_key" ON "user_mini_project_submissions"("user_id", "project_id");

-- CreateIndex
CREATE INDEX "media_assets_college_id_idx" ON "media_assets"("college_id");

-- CreateIndex
CREATE INDEX "media_assets_user_id_idx" ON "media_assets"("user_id");

-- CreateIndex
CREATE INDEX "media_assets_category_idx" ON "media_assets"("category");

-- CreateIndex
CREATE INDEX "subjects_faculty_id_idx" ON "subjects"("faculty_id");

-- CreateIndex
CREATE INDEX "subjects_department_id_idx" ON "subjects"("department_id");

-- CreateIndex
CREATE UNIQUE INDEX "subjects_college_id_code_semester_section_key" ON "subjects"("college_id", "code", "semester", "section");

-- CreateIndex
CREATE INDEX "subject_resources_subject_id_idx" ON "subject_resources"("subject_id");

-- CreateIndex
CREATE INDEX "subject_announcements_subject_id_idx" ON "subject_announcements"("subject_id");

-- CreateIndex
CREATE INDEX "subject_enrollments_student_id_idx" ON "subject_enrollments"("student_id");

-- CreateIndex
CREATE UNIQUE INDEX "subject_enrollments_subject_id_student_id_key" ON "subject_enrollments"("subject_id", "student_id");

-- CreateIndex
CREATE INDEX "student_mentorships_student_id_idx" ON "student_mentorships"("student_id");

-- CreateIndex
CREATE UNIQUE INDEX "student_mentorships_faculty_id_student_id_key" ON "student_mentorships"("faculty_id", "student_id");

-- AddForeignKey
ALTER TABLE "departments" ADD CONSTRAINT "departments_college_id_fkey" FOREIGN KEY ("college_id") REFERENCES "colleges"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_college_id_fkey" FOREIGN KEY ("college_id") REFERENCES "colleges"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_department_id_fkey" FOREIGN KEY ("department_id") REFERENCES "departments"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "password_reset_tokens" ADD CONSTRAINT "password_reset_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_follows" ADD CONSTRAINT "user_follows_follower_id_fkey" FOREIGN KEY ("follower_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_follows" ADD CONSTRAINT "user_follows_following_id_fkey" FOREIGN KEY ("following_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "posts" ADD CONSTRAINT "posts_college_id_fkey" FOREIGN KEY ("college_id") REFERENCES "colleges"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "posts" ADD CONSTRAINT "posts_department_id_fkey" FOREIGN KEY ("department_id") REFERENCES "departments"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "posts" ADD CONSTRAINT "posts_club_id_fkey" FOREIGN KEY ("club_id") REFERENCES "clubs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "posts" ADD CONSTRAINT "posts_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "post_attachments" ADD CONSTRAINT "post_attachments_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "post_comments" ADD CONSTRAINT "post_comments_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "post_comments" ADD CONSTRAINT "post_comments_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "post_likes" ADD CONSTRAINT "post_likes_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "post_likes" ADD CONSTRAINT "post_likes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "saved_posts" ADD CONSTRAINT "saved_posts_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "saved_posts" ADD CONSTRAINT "saved_posts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "clubs" ADD CONSTRAINT "clubs_college_id_fkey" FOREIGN KEY ("college_id") REFERENCES "colleges"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "clubs" ADD CONSTRAINT "clubs_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "clubs" ADD CONSTRAINT "clubs_verified_by_id_fkey" FOREIGN KEY ("verified_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "club_resources" ADD CONSTRAINT "club_resources_club_id_fkey" FOREIGN KEY ("club_id") REFERENCES "clubs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "club_resources" ADD CONSTRAINT "club_resources_uploaded_by_id_fkey" FOREIGN KEY ("uploaded_by_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "club_members" ADD CONSTRAINT "club_members_club_id_fkey" FOREIGN KEY ("club_id") REFERENCES "clubs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "club_members" ADD CONSTRAINT "club_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "events" ADD CONSTRAINT "events_college_id_fkey" FOREIGN KEY ("college_id") REFERENCES "colleges"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "events" ADD CONSTRAINT "events_department_id_fkey" FOREIGN KEY ("department_id") REFERENCES "departments"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "events" ADD CONSTRAINT "events_club_id_fkey" FOREIGN KEY ("club_id") REFERENCES "clubs"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "events" ADD CONSTRAINT "events_organizer_id_fkey" FOREIGN KEY ("organizer_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "event_registrations" ADD CONSTRAINT "event_registrations_event_id_fkey" FOREIGN KEY ("event_id") REFERENCES "events"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "event_registrations" ADD CONSTRAINT "event_registrations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "chat_rooms" ADD CONSTRAINT "chat_rooms_college_id_fkey" FOREIGN KEY ("college_id") REFERENCES "colleges"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "chat_rooms" ADD CONSTRAINT "chat_rooms_club_id_fkey" FOREIGN KEY ("club_id") REFERENCES "clubs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "chat_rooms" ADD CONSTRAINT "chat_rooms_department_id_fkey" FOREIGN KEY ("department_id") REFERENCES "departments"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "chat_participants" ADD CONSTRAINT "chat_participants_room_id_fkey" FOREIGN KEY ("room_id") REFERENCES "chat_rooms"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "chat_participants" ADD CONSTRAINT "chat_participants_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "chat_messages" ADD CONSTRAINT "chat_messages_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "chat_messages" ADD CONSTRAINT "chat_messages_room_id_fkey" FOREIGN KEY ("room_id") REFERENCES "chat_rooms"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "chat_read_receipts" ADD CONSTRAINT "chat_read_receipts_message_id_fkey" FOREIGN KEY ("message_id") REFERENCES "chat_messages"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "chat_read_receipts" ADD CONSTRAINT "chat_read_receipts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "companies" ADD CONSTRAINT "companies_college_id_fkey" FOREIGN KEY ("college_id") REFERENCES "colleges"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "placement_drives" ADD CONSTRAINT "placement_drives_college_id_fkey" FOREIGN KEY ("college_id") REFERENCES "colleges"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "placement_drives" ADD CONSTRAINT "placement_drives_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "companies"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "placement_applications" ADD CONSTRAINT "placement_applications_drive_id_fkey" FOREIGN KEY ("drive_id") REFERENCES "placement_drives"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "placement_applications" ADD CONSTRAINT "placement_applications_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "placement_interviews" ADD CONSTRAINT "placement_interviews_application_id_fkey" FOREIGN KEY ("application_id") REFERENCES "placement_applications"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "portfolios" ADD CONSTRAINT "portfolios_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "portfolio_projects" ADD CONSTRAINT "portfolio_projects_portfolio_id_fkey" FOREIGN KEY ("portfolio_id") REFERENCES "portfolios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "portfolio_skills" ADD CONSTRAINT "portfolio_skills_portfolio_id_fkey" FOREIGN KEY ("portfolio_id") REFERENCES "portfolios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "portfolio_certificates" ADD CONSTRAINT "portfolio_certificates_portfolio_id_fkey" FOREIGN KEY ("portfolio_id") REFERENCES "portfolios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "portfolio_achievements" ADD CONSTRAINT "portfolio_achievements_portfolio_id_fkey" FOREIGN KEY ("portfolio_id") REFERENCES "portfolios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notification_tokens" ADD CONSTRAINT "notification_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "roadmap_nodes" ADD CONSTRAINT "roadmap_nodes_roadmap_id_fkey" FOREIGN KEY ("roadmap_id") REFERENCES "career_roadmaps"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "learning_resources" ADD CONSTRAINT "learning_resources_roadmap_id_fkey" FOREIGN KEY ("roadmap_id") REFERENCES "career_roadmaps"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "learning_resources" ADD CONSTRAINT "learning_resources_node_id_fkey" FOREIGN KEY ("node_id") REFERENCES "roadmap_nodes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_roadmap_progress" ADD CONSTRAINT "user_roadmap_progress_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_roadmap_progress" ADD CONSTRAINT "user_roadmap_progress_roadmap_id_fkey" FOREIGN KEY ("roadmap_id") REFERENCES "career_roadmaps"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_node_progress" ADD CONSTRAINT "user_node_progress_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_node_progress" ADD CONSTRAINT "user_node_progress_node_id_fkey" FOREIGN KEY ("node_id") REFERENCES "roadmap_nodes"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "weekly_goals" ADD CONSTRAINT "weekly_goals_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_mini_project_submissions" ADD CONSTRAINT "user_mini_project_submissions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_mini_project_submissions" ADD CONSTRAINT "user_mini_project_submissions_project_id_fkey" FOREIGN KEY ("project_id") REFERENCES "mini_project_ideas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "media_assets" ADD CONSTRAINT "media_assets_college_id_fkey" FOREIGN KEY ("college_id") REFERENCES "colleges"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "media_assets" ADD CONSTRAINT "media_assets_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subjects" ADD CONSTRAINT "subjects_college_id_fkey" FOREIGN KEY ("college_id") REFERENCES "colleges"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subjects" ADD CONSTRAINT "subjects_department_id_fkey" FOREIGN KEY ("department_id") REFERENCES "departments"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subjects" ADD CONSTRAINT "subjects_faculty_id_fkey" FOREIGN KEY ("faculty_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subject_resources" ADD CONSTRAINT "subject_resources_subject_id_fkey" FOREIGN KEY ("subject_id") REFERENCES "subjects"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subject_resources" ADD CONSTRAINT "subject_resources_uploaded_by_id_fkey" FOREIGN KEY ("uploaded_by_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subject_announcements" ADD CONSTRAINT "subject_announcements_subject_id_fkey" FOREIGN KEY ("subject_id") REFERENCES "subjects"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subject_announcements" ADD CONSTRAINT "subject_announcements_faculty_id_fkey" FOREIGN KEY ("faculty_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subject_enrollments" ADD CONSTRAINT "subject_enrollments_subject_id_fkey" FOREIGN KEY ("subject_id") REFERENCES "subjects"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subject_enrollments" ADD CONSTRAINT "subject_enrollments_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "student_mentorships" ADD CONSTRAINT "student_mentorships_faculty_id_fkey" FOREIGN KEY ("faculty_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "student_mentorships" ADD CONSTRAINT "student_mentorships_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
