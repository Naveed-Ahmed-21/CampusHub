import { prisma } from '../../../config/database';
import { logger } from '../../../infrastructure/logger/logger';

export interface DimensionScore {
  id: string;
  name: string;
  score: number;
  weight: number; // e.g. 0.25
  status: 'STRONG' | 'GROWING' | 'NEEDS_WORK';
  evidence: string;
  tips: string[];
}

export interface NextBestAction {
  title: string;
  actionType: 'QUIZ' | 'PROJECT' | 'INTERVIEW' | 'LEARN';
  description: string;
  targetRef?: string;
  estimatedMinutes?: number;
}

export interface RadarDataPoint {
  dimension: string;
  score: number;
  fullMark: number;
}

export interface ComprehensiveJobReadinessReport {
  overallScore: number;
  overallPercent: number; // backward compatibility
  overallStatus: string;
  readinessLevel: string; // 'Placement Ready', 'Intermediate Builder', 'Early Foundations', or 'Getting Started'
  targetRole: string;
  dimensions: DimensionScore[];
  radarData: RadarDataPoint[];
  strongAreas: string[];
  areasToImprove: string[];
  nextBestAction: NextBestAction;
  summaryStats: {
    verifiedSkillsCount: number;
    quizzesTaken: number;
    quizPassRate: number;
    projectsSubmitted: number;
    verifiedProjects: number;
    mockInterviewsCompleted: number;
    avgInterviewScore: number;
    roadmapProgressPercentage: number;
  };
  // Backward compatible fields for legacy clients
  technical: { score: number | null; status: string; evidence: string };
  projects: { score: number | null; status: string; evidence: string };
  problemSolving: { score: number | null; status: string; evidence: string };
  interview: { score: number | null; status: string; evidence: string };
  portfolio: { score: number | null; status: string; evidence: string };
  learningConsistency: { score: number | null; status: string; evidence: string };
  whyThisScore: string[];
  topPriorities: string[];
}

export class JobReadinessService {
  /**
   * Calculates comprehensive multi-dimensional job readiness
   */
  static async calculateReadiness(
    userId: string,
    targetRole?: string
  ): Promise<ComprehensiveJobReadinessReport> {
    try {
      // 1. Fetch user data in parallel
      const [
        skills,
        quizAttempts,
        portfolioProjects,
        miniProjectSubmissions,
        projectEvidences,
        interviewSessions,
        userPortfolio,
        learningSessions,
        roadmapProgress,
        latestRoadmap,
      ] = await Promise.all([
        prisma.studentSkill.findMany({ where: { user_id: userId } }),
        prisma.quizAttempt.findMany({
          where: { user_id: userId },
          orderBy: { created_at: 'desc' },
        }),
        prisma.portfolioProject.findMany({
          where: { portfolio: { user_id: userId } },
        }),
        prisma.userMiniProjectSubmission.findMany({
          where: { user_id: userId },
        }),
        prisma.projectEvidence.findMany({
          where: { user_id: userId },
          orderBy: { created_at: 'desc' },
        }),
        prisma.interviewSession.findMany({
          where: { user_id: userId, status: 'COMPLETED' },
          orderBy: { completed_at: 'desc' },
        }),
        prisma.portfolio.findUnique({
          where: { user_id: userId },
          include: { projects: true, skills: true, certificates: true },
        }),
        prisma.learningSession.findMany({
          where: { user_id: userId },
        }),
        prisma.userRoadmapProgress.findFirst({
          where: { user_id: userId },
          orderBy: { updated_at: 'desc' },
        }),
        prisma.careerRoadmap.findFirst({
          where: { user_id: userId },
          orderBy: { updated_at: 'desc' },
        }),
      ]);

      const role =
        targetRole ||
        latestRoadmap?.title ||
        latestRoadmap?.category ||
        'Software Engineer';

      // -------------------------------------------------------------
      // Dimension 1: Technical Skills & Checkpoints (Weight: 25%)
      // -------------------------------------------------------------
      let techScore = 0;
      let techEvidence = 'No verified technical skills or checkpoint quizzes completed yet.';
      const techTips: string[] = [];

      if (skills.length > 0 || quizAttempts.length > 0) {
        const avgSkillConfidence =
          skills.length > 0
            ? skills.reduce((acc, s) => acc + (s.confidence_score || 50), 0) / skills.length
            : 60;

        const passedQuizzes = quizAttempts.filter((q) => q.passed).length;
        const quizAccuracy =
          quizAttempts.length > 0
            ? (passedQuizzes / quizAttempts.length) * 100
            : avgSkillConfidence;

        techScore = Math.round(avgSkillConfidence * 0.5 + quizAccuracy * 0.5);
        techEvidence = `${skills.length} skills tracked, ${passedQuizzes}/${quizAttempts.length} quizzes passed (${Math.round(quizAccuracy)}% accuracy).`;
        if (quizAccuracy < 70) {
          techTips.push('Retake quizzes where you scored under 70% to strengthen foundational concepts.');
        } else {
          techTips.push('Solid grasp of core technical topics; maintain checkpoint velocity.');
        }
      } else {
        techScore = 20; // baseline exploratory
        techTips.push('Complete Phase 1 checkpoint quizzes to validate your foundational knowledge.');
      }

      // -------------------------------------------------------------
      // Dimension 2: Practical Projects & Evidence (Weight: 20%)
      // -------------------------------------------------------------
      let projScore = 0;
      let projEvidence = 'No verified project submissions recorded yet.';
      const projTips: string[] = [];

      const totalProjectCount =
        projectEvidences.length +
        portfolioProjects.length +
        miniProjectSubmissions.length;
      const verifiedProjectsCount =
        projectEvidences.filter((p) => p.verified).length +
        portfolioProjects.filter((p) => !!p.repo_url).length;

      if (totalProjectCount > 0) {
        const countFactor = Math.min(60, totalProjectCount * 20);
        const verifiedBonus = Math.min(40, verifiedProjectsCount * 20);
        projScore = Math.min(100, countFactor + verifiedBonus);
        projEvidence = `${totalProjectCount} projects created (${verifiedProjectsCount} verified with public GitHub/demo evidence).`;
        if (verifiedProjectsCount === 0) {
          projTips.push('Link your GitHub repositories and live URLs to verify project evidence.');
        } else if (totalProjectCount < 3) {
          projTips.push('Build at least 2 full-stack or domain-specific capstone projects.');
        } else {
          projTips.push('Excellent project portfolio. Ensure README documentation has architecture diagrams.');
        }
      } else {
        projScore = 15;
        projTips.push('Submit your first phase project with a live GitHub repository to gain project credit.');
      }

      // -------------------------------------------------------------
      // Dimension 3: DSA & Problem Solving (Weight: 15%)
      // -------------------------------------------------------------
      const dsaKeywords = ['dsa', 'data structure', 'algorithm', 'complexity', 'array', 'tree', 'graph', 'sorting'];
      const dsaQuizzes = quizAttempts.filter((q) =>
        dsaKeywords.some((k) => q.topic.toLowerCase().includes(k))
      );

      let dsaScore = 0;
      let dsaEvidence = 'No DSA or algorithm checkpoints attempted yet.';
      const dsaTips: string[] = [];

      if (dsaQuizzes.length > 0) {
        const dsaPassed = dsaQuizzes.filter((q) => q.passed).length;
        dsaScore = Math.min(100, Math.round((dsaPassed / dsaQuizzes.length) * 90 + 10));
        dsaEvidence = `${dsaPassed}/${dsaQuizzes.length} algorithmic checkpoints completed successfully.`;
        if (dsaScore < 70) {
          dsaTips.push('Focus on two-pointer, hashing, and tree traversal problems.');
        } else {
          dsaTips.push('Good problem-solving performance. Practice time-complexity trade-offs.');
        }
      } else {
        dsaScore = 25;
        dsaTips.push('Attempt the Core DSA checkpoint to establish your algorithmic readiness score.');
      }

      // -------------------------------------------------------------
      // Dimension 4: Resume & Profile Readiness (Weight: 15%)
      // -------------------------------------------------------------
      let resumeScore = 20;
      let resumeEvidence = 'Portfolio profile incomplete.';
      const resumeTips: string[] = [];

      if (userPortfolio) {
        if (userPortfolio.bio && userPortfolio.bio.length > 30) resumeScore += 20;
        if (userPortfolio.github_url) resumeScore += 25;
        if (userPortfolio.linkedin_url) resumeScore += 15;
        if (userPortfolio.projects.length > 0) resumeScore += 10;
        if (userPortfolio.skills.length > 0) resumeScore += 10;
        resumeScore = Math.min(100, resumeScore);
        resumeEvidence = `Portfolio completed at ${resumeScore}% with professional links and summaries.`;
        if (!userPortfolio.github_url) {
          resumeTips.push('Add your GitHub profile URL to your student portfolio.');
        }
        if (!userPortfolio.linkedin_url) {
          resumeTips.push('Connect your LinkedIn profile to improve placement recruiter visibility.');
        }
      } else {
        resumeTips.push('Create and publish your student portfolio profile.');
      }

      // -------------------------------------------------------------
      // Dimension 5: Mock Interviews (Weight: 15%)
      // -------------------------------------------------------------
      let interviewScore = 0;
      let interviewEvidence = 'No AI mock interviews completed yet.';
      const interviewTips: string[] = [];

      if (interviewSessions.length > 0) {
        const totalAvg =
          interviewSessions.reduce((acc, s) => acc + (s.overall_score || 70), 0) /
          interviewSessions.length;
        interviewScore = Math.min(100, Math.round(totalAvg));
        interviewEvidence = `Completed ${interviewSessions.length} EVA mock interview(s) with an average of ${interviewScore}%.`;
        if (interviewScore < 70) {
          interviewTips.push('Practice answering technical system architecture and behavioral STAR questions.');
        } else {
          interviewTips.push('Strong interview technique. Focus on clear edge-case trade-off articulation.');
        }
      } else {
        interviewScore = 20;
        interviewTips.push('Schedule a 10-minute AI mock interview with EVA to assess placement interview readiness.');
      }

      // -------------------------------------------------------------
      // Dimension 6: Consistency & Soft Skills (Weight: 10%)
      // -------------------------------------------------------------
      const completedSessions = learningSessions.filter((s) => s.status === 'COMPLETED').length;
      let consistencyScore = 20;
      let consistencyEvidence = 'No recent learning sessions recorded.';
      const consistencyTips: string[] = [];

      if (completedSessions > 0) {
        consistencyScore = Math.min(100, Math.round(completedSessions * 12 + 30));
        consistencyEvidence = `${completedSessions} structured learning sessions logged.`;
        if (completedSessions < 5) {
          consistencyTips.push('Establish a regular daily habit of at least 30 minutes in your career roadmap.');
        } else {
          consistencyTips.push('Great learning consistency. Maintain this pace through Phase 3 and 4.');
        }
      } else {
        consistencyTips.push('Start a learning session from your roadmap to build consistency streaks.');
      }

      // -------------------------------------------------------------
      // Weighted Overall Calculation
      // -------------------------------------------------------------
      const weights = {
        tech: 0.25,
        proj: 0.20,
        dsa: 0.15,
        resume: 0.15,
        interview: 0.15,
        consistency: 0.10,
      };

      const rawOverall =
        techScore * weights.tech +
        projScore * weights.proj +
        dsaScore * weights.dsa +
        resumeScore * weights.resume +
        interviewScore * weights.interview +
        consistencyScore * weights.consistency;

      const overallScore = Math.min(100, Math.max(10, Math.round(rawOverall)));

      // Status label
      let readinessLevel: string;
      if (overallScore >= 80) {
        readinessLevel = 'Placement Ready';
      } else if (overallScore >= 60) {
        readinessLevel = 'Intermediate Builder';
      } else if (overallScore >= 40) {
        readinessLevel = 'Early Foundations';
      } else {
        readinessLevel = 'Getting Started';
      }

      // -------------------------------------------------------------
      // Dimensions Array
      // -------------------------------------------------------------
      const dimensions: DimensionScore[] = [
        {
          id: 'technical',
          name: 'Technical Skills',
          score: techScore,
          weight: weights.tech,
          status: techScore >= 75 ? 'STRONG' : techScore >= 50 ? 'GROWING' : 'NEEDS_WORK',
          evidence: techEvidence,
          tips: techTips,
        },
        {
          id: 'projects',
          name: 'Projects & Evidence',
          score: projScore,
          weight: weights.proj,
          status: projScore >= 75 ? 'STRONG' : projScore >= 50 ? 'GROWING' : 'NEEDS_WORK',
          evidence: projEvidence,
          tips: projTips,
        },
        {
          id: 'problemSolving',
          name: 'DSA & Problem Solving',
          score: dsaScore,
          weight: weights.dsa,
          status: dsaScore >= 75 ? 'STRONG' : dsaScore >= 50 ? 'GROWING' : 'NEEDS_WORK',
          evidence: dsaEvidence,
          tips: dsaTips,
        },
        {
          id: 'resume',
          name: 'Resume & Profile',
          score: resumeScore,
          weight: weights.resume,
          status: resumeScore >= 75 ? 'STRONG' : resumeScore >= 50 ? 'GROWING' : 'NEEDS_WORK',
          evidence: resumeEvidence,
          tips: resumeTips,
        },
        {
          id: 'interview',
          name: 'Interview Preparation',
          score: interviewScore,
          weight: weights.interview,
          status: interviewScore >= 75 ? 'STRONG' : interviewScore >= 50 ? 'GROWING' : 'NEEDS_WORK',
          evidence: interviewEvidence,
          tips: interviewTips,
        },
        {
          id: 'consistency',
          name: 'Consistency & Dedication',
          score: consistencyScore,
          weight: weights.consistency,
          status: consistencyScore >= 75 ? 'STRONG' : consistencyScore >= 50 ? 'GROWING' : 'NEEDS_WORK',
          evidence: consistencyEvidence,
          tips: consistencyTips,
        },
      ];

      // -------------------------------------------------------------
      // Radar Data
      // -------------------------------------------------------------
      const radarData: RadarDataPoint[] = dimensions.map((d) => ({
        dimension: d.name,
        score: d.score,
        fullMark: 100,
      }));

      // -------------------------------------------------------------
      // Strengths and Improvement Areas
      // -------------------------------------------------------------
      const strongAreas: string[] = [];
      const areasToImprove: string[] = [];

      dimensions.forEach((d) => {
        if (d.status === 'STRONG') {
          strongAreas.push(`${d.name} (${d.score}%)`);
        } else if (d.status === 'NEEDS_WORK') {
          areasToImprove.push(`${d.name} (${d.score}%)`);
        }
      });

      if (strongAreas.length === 0) {
        strongAreas.push('Continuous enthusiasm and initial milestone setup');
      }
      if (areasToImprove.length === 0) {
        areasToImprove.push('Target Tier-1 company coding rounds and architecture patterns');
      }

      // -------------------------------------------------------------
      // Next Best Action Determination
      // -------------------------------------------------------------
      let nextBestAction: NextBestAction;

      const sortedDimensions = [...dimensions].sort((a, b) => a.score - b.score);
      const lowest = sortedDimensions[0];

      if (lowest.id === 'projects') {
        nextBestAction = {
          title: 'Publish Phase Capstone Project',
          actionType: 'PROJECT',
          description: `Submit your latest mini-project with a verified GitHub repository link to jump from ${projScore}% to ${Math.min(100, projScore + 25)}%.`,
          targetRef: 'ProjectsTab',
          estimatedMinutes: 60,
        };
      } else if (lowest.id === 'interview') {
        nextBestAction = {
          title: 'Complete 10-Min Mock Interview with EVA',
          actionType: 'INTERVIEW',
          description: `Practice real questions on ${role} fundamentals to boost interview confidence.`,
          targetRef: 'InterviewRoom',
          estimatedMinutes: 15,
        };
      } else if (lowest.id === 'problemSolving') {
        nextBestAction = {
          title: 'Take Core Algorithms Checkpoint Quiz',
          actionType: 'QUIZ',
          description: 'Test your grasp on data structures and algorithmic complexity.',
          targetRef: 'QuizSection',
          estimatedMinutes: 10,
        };
      } else if (lowest.id === 'technical') {
        nextBestAction = {
          title: 'Complete Pending Skill Module',
          actionType: 'LEARN',
          description: 'Learn the next core topic in your active career roadmap.',
          targetRef: 'RoadmapTab',
          estimatedMinutes: 20,
        };
      } else {
        nextBestAction = {
          title: 'Optimize Portfolio Profile & GitHub Links',
          actionType: 'PROJECT',
          description: 'Add your latest work, live URLs, and bio to your student portfolio.',
          targetRef: 'Portfolio',
          estimatedMinutes: 10,
        };
      }

      // -------------------------------------------------------------
      // Summary Stats
      // -------------------------------------------------------------
      const passedQuizzesCount = quizAttempts.filter((q) => q.passed).length;
      const quizPassRate =
        quizAttempts.length > 0
          ? Math.round((passedQuizzesCount / quizAttempts.length) * 100)
          : 0;

      const avgInterview =
        interviewSessions.length > 0
          ? Math.round(
              interviewSessions.reduce((acc, s) => acc + (s.overall_score || 0), 0) /
                interviewSessions.length
            )
          : 0;

      const roadmapProgressPercent = roadmapProgress
        ? Math.round(roadmapProgress.progress_percent)
        : 0;

      return {
        overallScore,
        overallPercent: overallScore,
        overallStatus: `${overallScore}%`,
        readinessLevel,
        targetRole: role,
        dimensions,
        radarData,
        strongAreas,
        areasToImprove,
        nextBestAction,
        summaryStats: {
          verifiedSkillsCount: skills.length,
          quizzesTaken: quizAttempts.length,
          quizPassRate,
          projectsSubmitted: totalProjectCount,
          verifiedProjects: verifiedProjectsCount,
          mockInterviewsCompleted: interviewSessions.length,
          avgInterviewScore: avgInterview,
          roadmapProgressPercentage: roadmapProgressPercent,
        },
        // Legacy backward compatibility
        technical: {
          score: techScore,
          status: `${techScore}%`,
          evidence: techEvidence,
        },
        projects: {
          score: projScore,
          status: `${projScore}%`,
          evidence: projEvidence,
        },
        problemSolving: {
          score: dsaScore,
          status: `${dsaScore}%`,
          evidence: dsaEvidence,
        },
        interview: {
          score: interviewScore,
          status: `${interviewScore}%`,
          evidence: interviewEvidence,
        },
        portfolio: {
          score: resumeScore,
          status: `${resumeScore}%`,
          evidence: resumeEvidence,
        },
        learningConsistency: {
          score: consistencyScore,
          status: `${consistencyScore}%`,
          evidence: consistencyEvidence,
        },
        whyThisScore: [
          `Technical: ${techEvidence}`,
          `Projects: ${projEvidence}`,
          `Interview: ${interviewEvidence}`,
          `DSA: ${dsaEvidence}`,
          `Profile: ${resumeEvidence}`,
        ],
        topPriorities: [
          nextBestAction.title,
          ...dimensions
            .filter((d) => d.status === 'NEEDS_WORK')
            .flatMap((d) => d.tips)
            .slice(0, 3),
        ],
      };
    } catch (error) {
      logger.error({ error }, 'Error in JobReadinessService.calculateReadiness');
      throw error;
    }
  }
}
