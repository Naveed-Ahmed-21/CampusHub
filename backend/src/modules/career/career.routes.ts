import { Router } from 'express';
import { CareerRepository } from './career.repository';
import { CareerService } from './career.service';
import { CareerController } from './career.controller';
import { authenticate } from '../../shared/middlewares/auth.middleware';
import { validateRequest } from '../../shared/middlewares/validate.middleware';
import {
  createWeeklyGoalSchema,
  updateWeeklyGoalSchema,
  toggleGoalSchema,
  toggleNodeProgressSchema,
  submitMiniProjectSchema,
  generateRoadmapSchema,
  checkDuplicateRoadmapSchema,
  updateRoadmapStatusSchema,
  toggleDailyTaskSchema,
  askAiRoadmapSchema,
  askMentorSchema,
  exportPortfolioSchema,
  generateQuizSchema,
  submitQuizSchema,
  pathfinderChatSchema,
  pathfinderConfirmSchema,
  startPathfinderSessionSchema,
  getPathfinderSessionSchema,
  sendPathfinderMessageSchema,
  confirmPathfinderSessionSchema,
  generatePathfinderJourneySchema,
  askAiDoubtSchema,
  improveRoadmapSchema,
  startLearningSessionSchema,
  finishLearningSessionSchema,
  startInterviewSchema,
  turnInterviewSchema,
  finishInterviewSchema,
  applyInterviewRoadmapSchema,
  startDynamicPathfinderSchema,
  answerDynamicPathfinderSchema,
  generatePersonalizedRoadmapSchema,
  createProjectEvidenceSchema,
} from './career.validation';

const careerRepository = new CareerRepository();
const careerService = new CareerService(careerRepository);
const careerController = new CareerController(careerService);

export const careerRouter = Router();

careerRouter.use(authenticate);

// Roadmaps & Node Progress
careerRouter.get('/roadmaps', careerController.getRoadmaps);
careerRouter.get('/user-roadmaps', careerController.getUserRoadmaps);
careerRouter.post('/check-duplicate', validateRequest(checkDuplicateRoadmapSchema), careerController.checkDuplicate);
careerRouter.get('/roadmaps/:id', careerController.getRoadmapDetails);
careerRouter.post('/roadmaps/:id/activate', careerController.setActiveRoadmap);
careerRouter.patch('/roadmaps/:id', validateRequest(updateRoadmapStatusSchema), careerController.updateRoadmap);
careerRouter.delete('/roadmaps/:id', careerController.deleteRoadmap);

// Roadmap Changes & Adaptation
careerRouter.get('/roadmaps/:id/changes', careerController.getRoadmapChanges);
careerRouter.post('/roadmaps/:id/improve', validateRequest(improveRoadmapSchema), careerController.improveRoadmap);

// Active Roadmap & Daily Learning
careerRouter.get('/active-roadmap', careerController.getActiveRoadmap);
careerRouter.post('/reset', careerController.resetCareerData);
careerRouter.delete('/reset', careerController.resetCareerData);
careerRouter.get('/daily-plan', careerController.getDailyPlan);
careerRouter.post('/roadmaps/:id/daily-task', validateRequest(toggleDailyTaskSchema), careerController.toggleDailyTask);
careerRouter.get('/progress', careerController.getUserProgress);
careerRouter.post('/nodes/progress', validateRequest(toggleNodeProgressSchema), careerController.toggleNodeProgress);

// Learning Sessions
careerRouter.post('/learning-session/start', validateRequest(startLearningSessionSchema), careerController.startLearningSession);
careerRouter.post('/learning-session/finish', validateRequest(finishLearningSessionSchema), careerController.finishLearningSession);

// Verified Resources Research & Documentation Reader
careerRouter.get('/resources/search', careerController.searchResources);
careerRouter.get('/docs', careerController.getVerifiedDocuments);
careerRouter.get('/docs/:docId', careerController.getVerifiedDocumentById);

// AI Discovery, Generation, Adaptation & Contextual Assistant
careerRouter.post('/assessment', careerController.evaluateAssessment);
careerRouter.post('/decide', careerController.helpMeDecide);
careerRouter.post('/generate-roadmap', validateRequest(generateRoadmapSchema), careerController.generateRoadmap);
careerRouter.post('/roadmaps/:id/adapt', careerController.adaptRoadmap);
careerRouter.post('/roadmaps/ask-ai', validateRequest(askAiRoadmapSchema), careerController.askAiAboutRoadmap);

// Conversational AI Pathfinder & Doubt Solver
careerRouter.post('/pathfinder/session', validateRequest(startPathfinderSessionSchema), careerController.startPathfinderSession);
careerRouter.get('/pathfinder/:sessionId', validateRequest(getPathfinderSessionSchema), careerController.getPathfinderSession);
careerRouter.post('/pathfinder/:sessionId/message', validateRequest(sendPathfinderMessageSchema), careerController.sendPathfinderMessage);
careerRouter.post('/pathfinder/:sessionId/confirm', validateRequest(confirmPathfinderSessionSchema), careerController.confirmPathfinderSession);
careerRouter.post('/pathfinder/:sessionId/generate-journey', validateRequest(generatePathfinderJourneySchema), careerController.generatePathfinderJourney);

// Dynamic 7-Stage AI Pathfinder (Rebuild V2)
careerRouter.post('/pathfinder/session/start', validateRequest(startDynamicPathfinderSchema), careerController.startDynamicPathfinder);
careerRouter.post('/pathfinder/session/:sessionId/answer', validateRequest(answerDynamicPathfinderSchema), careerController.answerDynamicPathfinder);
careerRouter.get('/pathfinder/session/:sessionId', careerController.getDynamicPathfinderSession);

// Personalized Roadmap & Skill Dependency Graph (Rebuild V2)
careerRouter.post('/generate-personalized-roadmap', validateRequest(generatePersonalizedRoadmapSchema), careerController.generatePersonalizedRoadmap);
careerRouter.get('/roadmaps/:id/graph', careerController.getRoadmapGraph);

// Verified External Resources (GitHub & YouTube Engines)
careerRouter.get('/resources/github', careerController.searchGitHubResources);
careerRouter.get('/resources/youtube', careerController.getYouTubeResources);

// Adaptive Assessment & Quizzes (Rebuild V2)
careerRouter.post('/quiz/adaptive-generate', careerController.generateAdaptiveQuizV2);
careerRouter.post('/quiz/adaptive-submit', careerController.submitAdaptiveQuizV2);

// Project Evidence & Portfolio Deliverables
careerRouter.get('/projects', careerController.getProjectEvidences);
careerRouter.post('/projects', validateRequest(createProjectEvidenceSchema), careerController.createProjectEvidence);

// Comprehensive Job Readiness Analytics (Rebuild V2)
careerRouter.get('/job-readiness/detailed', careerController.getDetailedJobReadiness);

// Backward-compatible Pathfinder routes
careerRouter.post('/pathfinder/chat', validateRequest(pathfinderChatSchema), careerController.pathfinderChat);
careerRouter.post('/pathfinder/confirm', validateRequest(pathfinderConfirmSchema), careerController.confirmPathfinderJourney);
careerRouter.post('/ask-ai', validateRequest(askAiDoubtSchema), careerController.askAiDoubt);

// 1-on-1 EVA AI Mock Interview
careerRouter.get('/interview/history', careerController.getInterviewHistory);
careerRouter.post('/interview/start', validateRequest(startInterviewSchema), careerController.startInterviewSession);
careerRouter.post('/interview/turn', validateRequest(turnInterviewSchema), careerController.submitInterviewTurn);
careerRouter.post('/interview/finish', validateRequest(finishInterviewSchema), careerController.finishInterviewSession);
careerRouter.post('/interview/apply-roadmap-update', validateRequest(applyInterviewRoadmapSchema), careerController.applyInterviewRoadmapUpdate);

// Skill Gap, Dependency Map & Analytics
careerRouter.get('/roadmaps/:id/skill-gap', careerController.getSkillGapAnalysis);
careerRouter.get('/roadmaps/:id/skill-map', careerController.getSkillMap);
careerRouter.get('/weekly-review', careerController.getWeeklyReview);
careerRouter.get('/job-readiness', careerController.getJobReadiness);
careerRouter.get('/interview-prep', careerController.getInterviewPrep);

// Quizzes
careerRouter.post('/quiz/generate', validateRequest(generateQuizSchema), careerController.generateQuiz);
careerRouter.post('/quiz/submit', validateRequest(submitQuizSchema), careerController.submitQuiz);

// Portfolio & Faculty Mentor Integration
careerRouter.post('/export-portfolio', validateRequest(exportPortfolioSchema), careerController.exportProjectToPortfolio);
careerRouter.post('/ask-mentor', validateRequest(askMentorSchema), careerController.askFacultyMentor);
careerRouter.get('/mentor/mentee-roadmaps', careerController.getMenteeRoadmaps);

// Weekly Goals (Existing)
careerRouter.get('/goals', careerController.getWeeklyGoals);
careerRouter.post('/goals', validateRequest(createWeeklyGoalSchema), careerController.createWeeklyGoal);
careerRouter.put('/goals/:goalId', validateRequest(updateWeeklyGoalSchema), careerController.updateWeeklyGoal);
careerRouter.delete('/goals/:goalId', careerController.deleteWeeklyGoal);
careerRouter.patch('/goals/:goalId', validateRequest(toggleGoalSchema), careerController.toggleWeeklyGoal);

// Resume Tips (Existing)
careerRouter.get('/resume-tips', careerController.getResumeTips);

// Placement Prep (Existing)
careerRouter.get('/placement-prep', careerController.getPlacementPrep);

// Mini Projects (Existing)
careerRouter.get('/mini-projects', careerController.getMiniProjects);
careerRouter.post('/mini-projects/submit', validateRequest(submitMiniProjectSchema), careerController.submitMiniProject);

export default careerRouter;
