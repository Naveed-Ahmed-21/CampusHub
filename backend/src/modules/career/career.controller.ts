import { Request, Response } from 'express';
import { CareerService } from './career.service';
import { asyncHandler } from '../../shared/utils/async-handler.util';
import { ResponseUtil } from '../../shared/utils/api-response.util';
import { CareerPathfinderService } from './services/career.pathfinder.service';
import { CareerRoadmapGenerator } from './services/career.roadmap-generator';
import { CareerGitHubService } from './services/career.github.service';
import { CareerYouTubeService } from './services/career.youtube.service';
import { CareerAdaptiveQuizService } from './services/career.adaptive-quiz.service';
import { JobReadinessService } from './services/career.job-readiness.service';
import { CareerDAGService } from './services/career.dag.service';
import { prisma } from '../../config/database';

export class CareerController {
  constructor(private readonly careerService: CareerService) {}

  getRoadmaps = asyncHandler(async (req: Request, res: Response) => {
    const query = {
      category: req.query.category as string,
      level: req.query.level as string,
      search: req.query.search as string,
    };
    const roadmaps = await this.careerService.getRoadmaps(query);
    ResponseUtil.success(res, roadmaps, 'Career roadmaps retrieved successfully');
  });

  getUserRoadmaps = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const roadmaps = await this.careerService.getUserRoadmaps(user.userId);
    ResponseUtil.success(res, roadmaps, 'User roadmaps retrieved successfully');
  });

  getRoadmapDetails = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { id } = req.params;
    const roadmap = await this.careerService.getRoadmapDetails(id, user.userId);
    ResponseUtil.success(res, roadmap, 'Roadmap details retrieved');
  });

  checkDuplicate = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { target_role } = req.body;
    const result = await this.careerService.checkDuplicate(user.userId, target_role);
    ResponseUtil.success(res, result, 'Duplicate check completed');
  });

  generateRoadmap = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const result = await this.careerService.generateOrActivateRoadmap(user.userId, req.body);
    ResponseUtil.success(res, result, 'Personalized roadmap generated or activated', 201);
  });

  setActiveRoadmap = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { id } = req.params;
    const result = await this.careerService.setActiveRoadmap(user.userId, id);
    ResponseUtil.success(res, result, 'Roadmap set as active');
  });

  updateRoadmap = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { id } = req.params;
    const result = await this.careerService.updateRoadmapStatus(id, user.userId, req.body);
    ResponseUtil.success(res, result, 'Roadmap updated');
  });

  deleteRoadmap = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { id } = req.params;
    await this.careerService.deleteRoadmap(id, user.userId);
    ResponseUtil.success(res, null, 'Roadmap deleted/archived successfully');
  });

  getActiveRoadmap = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const result = await this.careerService.getActiveRoadmap(user.userId);
    ResponseUtil.success(res, result, 'Active user roadmap retrieved');
  });

  getDailyPlan = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const roadmapId = req.query.roadmap_id as string | undefined;
    const plan = await this.careerService.getDailyPlan(user.userId, roadmapId);
    ResponseUtil.success(res, plan, 'Daily learning plan retrieved');
  });

  toggleDailyTask = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { id } = req.params;
    const { task_id, is_completed } = req.body;
    const result = await this.careerService.toggleDailyTask(user.userId, id, task_id, is_completed);
    ResponseUtil.success(res, result, 'Daily task updated');
  });

  getUserProgress = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const progress = await this.careerService.getUserProgress(user.userId);
    ResponseUtil.success(res, progress, 'User progress retrieved successfully');
  });

  toggleNodeProgress = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { node_id, is_completed } = req.body;
    const result = await this.careerService.toggleNodeProgress(user.userId, node_id, is_completed);
    ResponseUtil.success(res, result, 'Roadmap node progress updated');
  });

  adaptRoadmap = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { id } = req.params;
    const { feedback_note } = req.body;
    const result = await this.careerService.adaptRoadmap(user.userId, id, feedback_note);
    ResponseUtil.success(res, result, 'Roadmap adapted based on performance');
  });

  askAiAboutRoadmap = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const result = await this.careerService.askAiAboutRoadmap(user.userId, req.body);
    ResponseUtil.success(res, result, 'AI assistant response generated');
  });

  getSkillGapAnalysis = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { id } = req.params;
    const result = await this.careerService.getSkillGapAnalysis(user.userId, id);
    ResponseUtil.success(res, result, 'Skill gap analysis retrieved');
  });

  getSkillMap = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { id } = req.params;
    const result = await this.careerService.getSkillMap(user.userId, id);
    ResponseUtil.success(res, result, 'Skill dependency map retrieved');
  });

  getWeeklyReview = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const roadmapId = req.query.roadmap_id as string | undefined;
    const result = await this.careerService.getWeeklyReview(user.userId, roadmapId);
    ResponseUtil.success(res, result, 'Weekly review retrieved');
  });

  getJobReadiness = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const roadmapId = req.query.roadmap_id as string | undefined;
    const result = await this.careerService.getJobReadiness(user.userId, roadmapId);
    ResponseUtil.success(res, result, 'Job readiness evaluation retrieved');
  });

  getInterviewPrep = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const roadmapId = req.query.roadmap_id as string | undefined;
    const result = await this.careerService.getInterviewPrep(user.userId, roadmapId);
    ResponseUtil.success(res, result, 'Interview preparation questions retrieved');
  });

  exportProjectToPortfolio = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const result = await this.careerService.exportProjectToPortfolio(user.userId, req.body);
    ResponseUtil.success(res, result, 'Project published to portfolio', 201);
  });

  askFacultyMentor = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const result = await this.careerService.askFacultyMentor(user.userId, req.body);
    ResponseUtil.success(res, result, 'Question shared with faculty mentor', 201);
  });

  getMenteeRoadmaps = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const result = await this.careerService.getMenteeRoadmaps(user.userId);
    ResponseUtil.success(res, result, 'Mentee roadmaps retrieved');
  });

  generateQuiz = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const result = await this.careerService.generateAdaptiveQuiz(user.userId, req.body);
    ResponseUtil.success(res, result, 'Adaptive quiz generated successfully');
  });

  submitQuiz = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const result = await this.careerService.submitQuiz(user.userId, req.body);
    ResponseUtil.success(res, result, 'Quiz evaluated successfully');
  });

  evaluateAssessment = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const result = await this.careerService.evaluateAssessment(user.userId, req.body);
    ResponseUtil.success(res, result, 'Assessment evaluated successfully');
  });

  helpMeDecide = asyncHandler(async (req: Request, res: Response) => {
    const result = await this.careerService.helpMeDecide(req.body);
    ResponseUtil.success(res, result, 'Career decision helper generated');
  });

  // Weekly Goals (Existing)
  getWeeklyGoals = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const goals = await this.careerService.getWeeklyGoals(user.userId);
    ResponseUtil.success(res, goals, 'Weekly goals retrieved');
  });

  createWeeklyGoal = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const goal = await this.careerService.createWeeklyGoal(user.userId, req.body);
    ResponseUtil.success(res, goal, 'Weekly goal created', 201);
  });

  updateWeeklyGoal = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { goalId } = req.params;
    const goal = await this.careerService.updateWeeklyGoal(goalId, user.userId, req.body);
    ResponseUtil.success(res, goal, 'Weekly goal updated');
  });

  deleteWeeklyGoal = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { goalId } = req.params;
    await this.careerService.deleteWeeklyGoal(goalId, user.userId);
    ResponseUtil.success(res, null, 'Weekly goal deleted');
  });

  toggleWeeklyGoal = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { goalId } = req.params;
    const { is_completed } = req.body;
    const goal = await this.careerService.toggleWeeklyGoal(goalId, user.userId, is_completed);
    ResponseUtil.success(res, goal, 'Weekly goal updated');
  });

  getResumeTips = asyncHandler(async (_req: Request, res: Response) => {
    const tips = await this.careerService.getResumeTips();
    ResponseUtil.success(res, tips, 'Resume tips retrieved');
  });

  getPlacementPrep = asyncHandler(async (_req: Request, res: Response) => {
    const modules = await this.careerService.getPlacementPrepModules();
    ResponseUtil.success(res, modules, 'Placement preparation modules retrieved');
  });

  getMiniProjects = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const projects = await this.careerService.getMiniProjects(user.userId);
    ResponseUtil.success(res, projects, 'Mini projects retrieved');
  });

  submitMiniProject = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const submission = await this.careerService.submitMiniProject(user.userId, req.body);
    ResponseUtil.success(res, submission, 'Mini project submitted successfully', 201);
  });

  // ==========================================
  // CONVERSATIONAL PATHFINDER & DOUBT SOLVER
  // ==========================================

  startPathfinderSession = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const resumeActive = req.body?.resume_active !== false;
    const session = await this.careerService.startPathfinderSession(user.userId, resumeActive);
    ResponseUtil.success(res, session, 'Pathfinder session initialized', 201);
  });

  getPathfinderSession = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { sessionId } = req.params;
    const session = await this.careerService.getPathfinderSession(user.userId, sessionId);
    ResponseUtil.success(res, session, 'Pathfinder session retrieved');
  });

  sendPathfinderMessage = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { sessionId } = req.params;
    const { message } = req.body;
    const response = await this.careerService.sendPathfinderMessage(user.userId, sessionId, message);
    ResponseUtil.success(res, response, 'Pathfinder message processed');
  });

  confirmPathfinderSession = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { sessionId } = req.params;
    const result = await this.careerService.confirmPathfinderSession(user.userId, sessionId, req.body);
    ResponseUtil.success(res, result, 'Pathfinder profile confirmed');
  });

  generatePathfinderJourney = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { sessionId } = req.params;
    const { selected_direction } = req.body || {};
    const result = await this.careerService.generatePathfinderJourney(user.userId, sessionId, selected_direction);
    ResponseUtil.success(res, result, 'Career journey & roadmap generated', 201);
  });

  pathfinderChat = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { message, conversation_id } = req.body;
    const result = await this.careerService.pathfinderChat(user.userId, message, conversation_id);
    ResponseUtil.success(res, result, 'Pathfinder message processed');
  });

  confirmPathfinderJourney = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { conversation_id } = req.body;
    const result = await this.careerService.confirmPathfinderJourney(user.userId, conversation_id);
    ResponseUtil.success(res, result, 'Career journey & roadmap confirmed and generated', 201);
  });

  askAiDoubt = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { prompt, roadmap_id } = req.body;
    const result = await this.careerService.askAiDoubt(user.userId, prompt, roadmap_id);
    ResponseUtil.success(res, result, 'AI response generated');
  });

  // ==========================================
  // ROADMAP CHANGES & ADAPTATION
  // ==========================================

  getRoadmapChanges = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { id } = req.params;
    const changes = await this.careerService.getRoadmapChanges(user.userId, id);
    ResponseUtil.success(res, changes, 'Roadmap changes retrieved');
  });

  improveRoadmap = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { id } = req.params;
    const { reason, details } = req.body;
    const result = await this.careerService.improveRoadmap(user.userId, id, reason, details);
    ResponseUtil.success(res, result, 'Roadmap successfully adjusted');
  });

  // ==========================================
  // VERIFIED RESOURCE RESEARCH
  // ==========================================

  searchResources = asyncHandler(async (req: Request, res: Response) => {
    const topic = (req.query.topic as string) || 'Flutter';
    const language = req.query.language as string | undefined;
    const level = req.query.level as string | undefined;
    const targetRole = req.query.target_role as string | undefined;
    const results = this.careerService.searchResources(topic, language, level, targetRole);
    ResponseUtil.success(res, results, 'Verified learning resources retrieved');
  });

  getVerifiedDocuments = asyncHandler(async (req: Request, res: Response) => {
    const docs = this.careerService.getVerifiedDocuments();
    ResponseUtil.success(res, docs, 'Verified documentation books retrieved');
  });

  getVerifiedDocumentById = asyncHandler(async (req: Request, res: Response) => {
    const docId = req.params.docId;
    const doc = this.careerService.getVerifiedDocumentById(docId);
    if (!doc) {
      return ResponseUtil.error(res, 'Verified document not found', 404, 'NOT_FOUND');
    }
    ResponseUtil.success(res, doc, 'Verified document retrieved');
  });

  // ==========================================
  // LEARNING SESSIONS
  // ==========================================

  startLearningSession = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { roadmap_id, task_id, task_title, phase_number } = req.body;
    const session = await this.careerService.startLearningSession(user.userId, roadmap_id, task_id, task_title, phase_number);
    ResponseUtil.success(res, session, 'Learning session started', 201);
  });

  finishLearningSession = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { session_id, duration_minutes, status, self_rating } = req.body;
    const session = await this.careerService.finishLearningSession(user.userId, session_id, duration_minutes, status, self_rating);
    ResponseUtil.success(res, session, 'Learning session completed');
  });

  // ==========================================
  // 1-ON-1 EVA AI INTERVIEW
  // ==========================================

  getInterviewHistory = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const history = await this.careerService.getInterviewHistory(user.userId);
    ResponseUtil.success(res, history, 'Interview history retrieved');
  });

  startInterviewSession = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { roadmap_id, target_role, mode } = req.body;
    const session = await this.careerService.startInterviewSession(user.userId, roadmap_id, target_role, mode);
    ResponseUtil.success(res, session, 'EVA interview session initialized', 201);
  });

  submitInterviewTurn = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { session_id, student_answer } = req.body;
    const result = await this.careerService.submitInterviewTurn(user.userId, session_id, student_answer);
    ResponseUtil.success(res, result, 'Interview turn evaluated');
  });

  finishInterviewSession = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { session_id } = req.body;
    const report = await this.careerService.finishInterviewSession(user.userId, session_id);
    ResponseUtil.success(res, report, 'Final interview report compiled');
  });

  applyInterviewRoadmapUpdate = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { session_id } = req.body;
    const result = await this.careerService.applyInterviewRoadmapUpdate(user.userId, session_id);
    ResponseUtil.success(res, result, 'Roadmap reinforced based on interview recommendations');
  });

  resetCareerData = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const result = await this.careerService.resetCareerData(user.userId);
    ResponseUtil.success(res, result, 'Career data reset successfully');
  });

  // ==========================================
  // V2 REBUILD METHODS
  // ==========================================

  startDynamicPathfinder = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { target_domain, preferred_language, department, resume_active } = req.body || {};
    const result = await CareerPathfinderService.startSession(user.userId, {
      targetDomain: target_domain,
      preferredLanguage: preferred_language,
      department,
      resumeActive: resume_active !== false,
    });
    ResponseUtil.success(res, result, 'Pathfinder dynamic session started', 201);
  });

  answerDynamicPathfinder = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { sessionId } = req.params;
    const { answer, question_id } = req.body;
    const result = await CareerPathfinderService.answerQuestion(user.userId, sessionId, answer, question_id);
    ResponseUtil.success(res, result, 'Pathfinder response processed');
  });

  getDynamicPathfinderSession = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { sessionId } = req.params;
    const result = await CareerPathfinderService.getSession(user.userId, sessionId);
    ResponseUtil.success(res, result, 'Pathfinder session details');
  });

  generatePersonalizedRoadmap = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const {
      target_role,
      department,
      current_level,
      hours_per_week,
      timeline_weeks,
      primary_goal,
      preferred_language,
      skill_focus_areas,
    } = req.body;

    const result = await CareerRoadmapGenerator.generateRoadmap(user.userId, {
      targetRole: target_role,
      department,
      currentLevel: current_level,
      hoursPerWeek: hours_per_week,
      timelineWeeks: timeline_weeks,
      primaryGoal: primary_goal,
      preferredLanguage: preferred_language,
      skillFocusAreas: skill_focus_areas,
    });
    ResponseUtil.success(res, result, 'Personalized career roadmap generated', 201);
  });

  getRoadmapGraph = asyncHandler(async (req: Request, res: Response) => {
    const { id } = req.params;
    let roadmap = await prisma.careerRoadmap.findUnique({
      where: { id },
      include: {
        nodes: {
          orderBy: { order_index: 'asc' },
        },
        skill_dependencies: true,
      },
    });

    if (!roadmap) {
      return ResponseUtil.error(res, 'Roadmap not found', 404, 'NOT_FOUND');
    }

    // Auto-heal if 0 dependencies exist but nodes exist
    if (roadmap.skill_dependencies.length === 0 && roadmap.nodes.length > 0) {
      await CareerDAGService.autoHealRoadmapDependencies(id);
      roadmap = await prisma.careerRoadmap.findUnique({
        where: { id },
        include: {
          nodes: {
            orderBy: { order_index: 'asc' },
          },
          skill_dependencies: true,
        },
      });
    }

    const nodes = (roadmap?.nodes || []).map((node) => ({
      id: node.id,
      title: node.title,
      description: node.description || '',
      estimatedHours: node.estimated_hours || 4,
      orderIndex: node.order_index,
    }));

    const edges = (roadmap?.skill_dependencies || []).map((dep) => ({
      id: dep.id,
      sourceSkill: dep.source_skill,
      targetSkill: dep.target_skill,
      dependencyType: dep.dependency_type,
      confidence: dep.confidence,
    }));

    const validation = CareerDAGService.validateDAG(nodes, edges as any);

    ResponseUtil.success(
      res,
      {
        nodes,
        edges,
        dependencies: edges,
        topologicalOrder: validation.topologicalOrder,
        isDAG: validation.isDAG,
        roadmapTitle: roadmap?.title,
        category: roadmap?.category,
        phases: roadmap?.phases_json,
      },
      'Roadmap skill graph retrieved'
    );
  });

  searchGitHubResources = asyncHandler(async (req: Request, res: Response) => {
    const topic = (req.query.topic as string) || 'Full Stack Web Development';
    const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 6;
    const language = req.query.language as string | undefined;
    const results = await CareerGitHubService.searchRepositories(topic, limit, language);
    ResponseUtil.success(res, results, 'Verified GitHub resources retrieved');
  });

  getYouTubeResources = asyncHandler(async (req: Request, res: Response) => {
    const topic = (req.query.topic as string) || 'Data Structures and Algorithms';
    const language = (req.query.language as string) || 'English';
    const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 6;
    const results = await CareerYouTubeService.getEducationalVideos(topic, language, limit);
    ResponseUtil.success(res, results, 'Language-aware YouTube educational resources retrieved');
  });

  generateAdaptiveQuizV2 = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { topic, phase_number, roadmap_id, skill_name, difficulty } = req.body;
    const quiz = await CareerAdaptiveQuizService.generateAdaptiveQuiz(user.userId, {
      topic: topic || 'Core Technical Concepts',
      phaseNumber: phase_number || 1,
      roadmapId: roadmap_id,
      skillName: skill_name,
      targetDifficulty: difficulty,
    });
    ResponseUtil.success(res, quiz, 'Adaptive quiz generated');
  });

  submitAdaptiveQuizV2 = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const {
      roadmap_id,
      phase_number,
      topic,
      skill_name,
      answers,
      questions,
      time_spent_seconds,
    } = req.body;

    const result = await CareerAdaptiveQuizService.submitAndEvaluateQuiz(user.userId, {
      roadmapId: roadmap_id,
      phaseNumber: phase_number || 1,
      topic: topic || 'Technical Assessment',
      skillName: skill_name,
      answers,
      questions,
      timeSpentSeconds: time_spent_seconds,
    });
    ResponseUtil.success(res, result, 'Adaptive quiz evaluated and skills updated');
  });

  getProjectEvidences = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const evidences = await prisma.projectEvidence.findMany({
      where: { user_id: user.userId },
      orderBy: { created_at: 'desc' },
    });
    const portfolioProjects = await prisma.portfolioProject.findMany({
      where: { portfolio: { user_id: user.userId } },
      orderBy: { created_at: 'desc' },
    });
    ResponseUtil.success(res, { evidences, portfolioProjects }, 'Project evidence and deliverables retrieved');
  });

  createProjectEvidence = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const { title, description, github_url, demo_url, tech_stack } = req.body;
    const evidence = await prisma.projectEvidence.create({
      data: {
        user_id: user.userId,
        title,
        description,
        github_url: github_url || null,
        demo_url: demo_url || null,
        tech_stack: tech_stack || [],
        verified: !!(github_url && github_url.includes('github.com')),
        evidence_score: 80,
      },
    });
    ResponseUtil.success(res, evidence, 'Project evidence registered', 201);
  });

  getDetailedJobReadiness = asyncHandler(async (req: Request, res: Response) => {
    const user = req.user!;
    const targetRole = req.query.target_role as string | undefined;
    const report = await JobReadinessService.calculateReadiness(user.userId, targetRole);
    ResponseUtil.success(res, report, 'Detailed job readiness analytics retrieved');
  });
}
