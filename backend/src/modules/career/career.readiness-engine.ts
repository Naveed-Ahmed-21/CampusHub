import { prisma } from '../../config/database';

export interface CategoryReadiness {
  score: number | null; // null means "Not assessed"
  status: string; // e.g. "Not assessed", "78%", etc.
  evidence: string;
}

export interface RealJobReadinessReport {
  overallPercent: number | null; // null means "Not enough data yet"
  overallStatus: string; // "Not enough data yet" or "72%"
  readinessLevel: string; // "Placement Ready", "Intermediate Builder", "Early Foundations", or "Not enough data yet"
  technical: CategoryReadiness;
  projects: CategoryReadiness;
  problemSolving: CategoryReadiness;
  interview: CategoryReadiness;
  portfolio: CategoryReadiness;
  learningConsistency: CategoryReadiness;
  whyThisScore: string[];
  topPriorities: string[];
}

export class JobReadinessEngine {
  static async calculateReadiness(userId: string): Promise<RealJobReadinessReport> {
    // 1. Technical Skills & Quizzes
    const skills = await prisma.studentSkill.findMany({ where: { user_id: userId } });
    const quizAttempts = await prisma.quizAttempt.findMany({ where: { user_id: userId } });

    let technicalScore: number | null = null;
    let technicalStatus = 'Not assessed';
    let technicalEvidence = 'No verified skills or quizzes recorded yet.';

    if (skills.length > 0 || quizAttempts.length > 0) {
      const avgSkill = skills.length > 0
        ? skills.reduce((acc, s) => acc + s.confidence_score, 0) / skills.length
        : 60;
      const passedQuizzes = quizAttempts.filter((q) => q.passed).length;
      const quizRatio = quizAttempts.length > 0 ? (passedQuizzes / quizAttempts.length) * 100 : avgSkill;
      technicalScore = Math.round((avgSkill + quizRatio) / 2);
      technicalStatus = `${technicalScore}%`;
      technicalEvidence = `Based on ${skills.length} verified skills and ${passedQuizzes}/${quizAttempts.length} passed quizzes.`;
    }

    // 2. Projects (Portfolio Projects + Mini Project Submissions)
    const portfolioProjects = await prisma.portfolioProject.findMany({
      where: { portfolio: { user_id: userId } },
    });
    const miniProjectSubmissions = await prisma.userMiniProjectSubmission.findMany({
      where: { user_id: userId },
    });
    const totalProjects = portfolioProjects.length + miniProjectSubmissions.length;

    let projectsScore: number | null = null;
    let projectsStatus = 'Not assessed';
    let projectsEvidence = 'No completed projects submitted yet.';

    if (totalProjects > 0) {
      projectsScore = Math.min(100, Math.round(totalProjects * 30));
      projectsStatus = `${projectsScore}%`;
      projectsEvidence = `${totalProjects} project deliverables published (${portfolioProjects.length} portfolio, ${miniProjectSubmissions.length} mini projects).`;
    }

    // 3. Problem Solving / DSA
    const dsaQuizzes = quizAttempts.filter((q) =>
      q.topic.toLowerCase().includes('dsa') ||
      q.topic.toLowerCase().includes('algorithm') ||
      q.topic.toLowerCase().includes('data structure')
    );

    let psScore: number | null = null;
    let psStatus = 'Not assessed';
    let psEvidence = 'No problem-solving or DSA checkpoints evaluated yet.';

    if (dsaQuizzes.length > 0) {
      const passed = dsaQuizzes.filter((q) => q.passed).length;
      psScore = Math.round((passed / dsaQuizzes.length) * 100);
      psStatus = `${psScore}%`;
      psEvidence = `${passed}/${dsaQuizzes.length} algorithm checkpoints passed.`;
    }

    // 4. Interview (From actual completed InterviewSession records)
    const interviewSessions = await prisma.interviewSession.findMany({
      where: { user_id: userId, status: 'COMPLETED' },
      orderBy: { completed_at: 'desc' },
    });

    let interviewScore: number | null = null;
    let interviewStatus = 'Not assessed';
    let interviewEvidence = 'No mock interviews completed with EVA AI yet.';

    if (interviewSessions.length > 0) {
      const latest = interviewSessions[0];
      interviewScore = latest.overall_score || 70;
      interviewStatus = `${interviewScore}%`;
      interviewEvidence = `Latest EVA interview score: ${interviewScore}% across technical & communication skills.`;
    }

    // 5. Portfolio Completion
    const userPortfolio = await prisma.portfolio.findUnique({
      where: { user_id: userId },
      include: { projects: true, skills: true, certificates: true },
    });

    let portfolioScore: number | null = null;
    let portfolioStatus = 'Not assessed';
    let portfolioEvidence = 'Portfolio profile not initialized.';

    if (userPortfolio) {
      let score = 20; // baseline for created portfolio
      if (userPortfolio.bio && userPortfolio.bio.length > 20) score += 20;
      if (userPortfolio.github_url) score += 20;
      if (userPortfolio.linkedin_url) score += 10;
      if (userPortfolio.projects.length > 0) score += 20;
      if (userPortfolio.skills.length > 0) score += 10;
      portfolioScore = Math.min(100, score);
      portfolioStatus = `${portfolioScore}%`;
      portfolioEvidence = `Portfolio completeness at ${portfolioScore}% with ${userPortfolio.projects.length} projects and external links.`;
    }

    // 6. Learning Consistency (From Learning Sessions)
    const learningSessions = await prisma.learningSession.findMany({
      where: { user_id: userId },
    });
    const completedSessions = learningSessions.filter((s) => s.status === 'COMPLETED').length;

    let consistencyScore: number | null = null;
    let consistencyStatus = 'Not assessed';
    let consistencyEvidence = 'No study sessions recorded.';

    if (learningSessions.length > 0) {
      consistencyScore = Math.min(100, Math.round(completedSessions * 15 + 20));
      consistencyStatus = `${consistencyScore}%`;
      consistencyEvidence = `${completedSessions} structured learning sessions logged.`;
    }

    // 7. Overall transparent calculation
    const evaluatedScores = [
      technicalScore,
      projectsScore,
      psScore,
      interviewScore,
      portfolioScore,
      consistencyScore,
    ].filter((s): s is number => s !== null);

    let overallPercent: number | null = null;
    let overallStatus = 'Not enough data yet';
    let readinessLevel = 'Not enough data yet';

    if (evaluatedScores.length >= 2) {
      overallPercent = Math.round(
        evaluatedScores.reduce((acc, val) => acc + val, 0) / evaluatedScores.length
      );
      overallStatus = `${overallPercent}%`;
      readinessLevel =
        overallPercent >= 75
          ? 'Placement Ready'
          : overallPercent >= 50
          ? 'Intermediate Builder'
          : 'Early Foundations';
    }

    // Explanations & Priorities
    const whyThisScore: string[] = [];
    if (technicalScore !== null) whyThisScore.push(`Technical Skills: ${technicalEvidence}`);
    if (projectsScore !== null) whyThisScore.push(`Projects: ${projectsEvidence}`);
    if (interviewScore !== null) whyThisScore.push(`Interview: ${interviewEvidence}`);
    if (psScore !== null) whyThisScore.push(`Problem Solving: ${psEvidence}`);
    if (portfolioScore !== null) whyThisScore.push(`Portfolio: ${portfolioEvidence}`);
    if (whyThisScore.length === 0) {
      whyThisScore.push('Complete your first checkpoint quiz and project to see verified analytics.');
    }

    const topPriorities: string[] = [];
    if (interviewScore === null) {
      topPriorities.push('Take your first mock interview with EVA AI');
    }
    if (projectsScore === null || projectsScore < 60) {
      topPriorities.push('Build and publish your first Phase portfolio capstone project');
    }
    if (technicalScore === null || technicalScore < 70) {
      topPriorities.push('Complete pending checkpoint quizzes to verify skill mastery');
    }
    if (psScore === null) {
      topPriorities.push('Solve DSA & scenario algorithmic challenges');
    }
    if (topPriorities.length === 0) {
      topPriorities.push('Review system design trade-offs for upcoming placement drives');
    }

    return {
      overallPercent,
      overallStatus,
      readinessLevel,
      technical: { score: technicalScore, status: technicalStatus, evidence: technicalEvidence },
      projects: { score: projectsScore, status: projectsStatus, evidence: projectsEvidence },
      problemSolving: { score: psScore, status: psStatus, evidence: psEvidence },
      interview: { score: interviewScore, status: interviewStatus, evidence: interviewEvidence },
      portfolio: { score: portfolioScore, status: portfolioStatus, evidence: portfolioEvidence },
      learningConsistency: { score: consistencyScore, status: consistencyStatus, evidence: consistencyEvidence },
      whyThisScore,
      topPriorities,
    };
  }
}
