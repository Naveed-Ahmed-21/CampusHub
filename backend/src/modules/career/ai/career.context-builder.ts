import { prisma } from '../../../config/database';

export interface StudentContextProfile {
  userId: string;
  department?: string;
  year?: string;
  targetRole?: string;
  experienceLevel: string;
  knownSkills: string[];
  weakSkills: string[];
  preferredLanguage: string;
  dailyHours: number;
  placementGoal?: string;
  projectSubmissions?: string[];
}

export interface RoadmapContextProfile {
  roadmapId?: string;
  targetRole?: string;
  currentPhaseNumber: number;
  currentPhaseTitle: string;
  completedPhasesCount: number;
  recentQuizScores?: Record<string, any>;
  activeTasks: string[];
  weakAreas: string[];
  progressPercent: number;
}

export interface ConversationTurnContext {
  role: 'user' | 'assistant';
  content: string;
}

export interface BuiltCareerContext {
  student: StudentContextProfile;
  roadmap?: RoadmapContextProfile;
  recentTurns: ConversationTurnContext[];
  summaryString: string;
}

export class CareerContextBuilder {
  static async buildContext(
    userId: string,
    roadmapId?: string,
    recentMessages: { sender: string; content: string }[] = []
  ): Promise<BuiltCareerContext> {
    // 1. Fetch Student profile & Skills
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        department: { select: { name: true } },
      },
    });

    const studentSkills = await prisma.studentSkill.findMany({
      where: { user_id: userId },
      select: { skill_name: true, proficiency_level: true, confidence_score: true },
    });

    const knownSkills = studentSkills
      .filter((s) => s.confidence_score >= 60)
      .map((s) => s.skill_name);
    const weakSkills = studentSkills
      .filter((s) => s.confidence_score < 60)
      .map((s) => s.skill_name);

    // Fetch student's real mini project submissions
    const userProjects = await prisma.userMiniProjectSubmission.findMany({
      where: { user_id: userId },
      include: { project: { select: { title: true } } },
      take: 5,
    });
    const projectSubmissions = userProjects.map((p) => p.project.title);

    // 2. Fetch Active Roadmap & Progress
    let activeRoadmapProgress = roadmapId
      ? await prisma.userRoadmapProgress.findUnique({
          where: { user_id_roadmap_id: { user_id: userId, roadmap_id: roadmapId } },
          include: { roadmap: true },
        })
      : await prisma.userRoadmapProgress.findFirst({
          where: { user_id: userId, is_active: true },
          include: { roadmap: true },
        });

    const journey = await prisma.careerJourney.findFirst({
      where: { user_id: userId, status: 'ACTIVE' },
      orderBy: { updated_at: 'desc' },
    });

    const preferredLanguage =
      activeRoadmapProgress?.roadmap?.learning_language ||
      journey?.preferred_language ||
      'English';

    const experienceLevel =
      activeRoadmapProgress?.level ||
      journey?.current_level ||
      activeRoadmapProgress?.roadmap?.level ||
      'Beginner';

    const dailyHours =
      activeRoadmapProgress?.weekly_hours
        ? Math.round(activeRoadmapProgress.weekly_hours / 5)
        : journey?.daily_hours || 2;

    const student: StudentContextProfile = {
      userId,
      department: user?.department?.name,
      year: undefined,
      targetRole:
        activeRoadmapProgress?.target_role ||
        journey?.target_role ||
        activeRoadmapProgress?.roadmap?.target_role ||
        'Software Engineer',
      experienceLevel,
      knownSkills,
      weakSkills,
      preferredLanguage,
      dailyHours,
      placementGoal: journey?.goal || 'Campus Placement Readiness',
      projectSubmissions,
    };

    let roadmap: RoadmapContextProfile | undefined;

    if (activeRoadmapProgress?.roadmap) {
      const phases = (activeRoadmapProgress.roadmap.phases_json as any[]) || [];
      const currentPhase = phases[0] || { phase_number: 1, title: 'Foundations' };

      roadmap = {
        roadmapId: activeRoadmapProgress.roadmap_id,
        targetRole: activeRoadmapProgress.roadmap.target_role || activeRoadmapProgress.roadmap.title,
        currentPhaseNumber: currentPhase.phase_number || 1,
        currentPhaseTitle: currentPhase.title || 'Phase 1: Foundations',
        completedPhasesCount: activeRoadmapProgress.completed_node_count,
        recentQuizScores: (activeRoadmapProgress.quiz_scores as any) || undefined,
        activeTasks: (currentPhase.tasks || []).map((t: any) => t.title || t.name),
        weakAreas: weakSkills,
        progressPercent: activeRoadmapProgress.progress_percent,
      };
    }

    // 3. Format Recent Conversation Turns (last 6 max)
    const recentTurns: ConversationTurnContext[] = recentMessages
      .slice(-6)
      .map((m) => ({
        role: m.sender.toUpperCase() === 'USER' ? 'user' : 'assistant',
        content: m.content,
      }));

    // 4. Summarize for LLM injection
    const summaryString = [
      `STUDENT CONTEXT:`,
      `- Department: ${student.department || 'Not specified'}`,
      `- Target Role: ${student.targetRole}`,
      `- Experience Level: ${student.experienceLevel}`,
      `- Preferred Learning Language: ${student.preferredLanguage}`,
      `- Available Time: ${student.dailyHours} hours/day`,
      `- Verified Known Skills: ${knownSkills.length > 0 ? knownSkills.join(', ') : 'Early stage'}`,
      `- Identified Weak Skills: ${weakSkills.length > 0 ? weakSkills.join(', ') : 'None yet recorded'}`,
      `- Verified Projects: ${projectSubmissions.length > 0 ? projectSubmissions.join(', ') : 'None yet recorded'}`,
      roadmap
        ? [
            `CURRENT ROADMAP:`,
            `- Active Milestone: Phase ${roadmap.currentPhaseNumber} (${roadmap.currentPhaseTitle})`,
            `- Progress: ${roadmap.progressPercent}% completed`,
            `- Incomplete Milestone Tasks: ${roadmap.activeTasks.slice(0, 3).join('; ')}`,
          ].join('\n')
        : 'NO ACTIVE ROADMAP CREATED YET.',
    ].join('\n');

    return {
      student,
      roadmap,
      recentTurns,
      summaryString,
    };
  }
}
