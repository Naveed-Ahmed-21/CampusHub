import { z } from 'zod';
import { prisma } from '../../../config/database';
import { aiProvider } from '../../../shared/ai/ai.provider';
import { logger } from '../../../infrastructure/logger/logger';

export interface PathfinderQuestionPayload {
  step: number;
  totalSteps: number;
  stage: string;
  question: string;
  options: string[];
  difficulty: 'Basic' | 'Beginner' | 'Intermediate' | 'Advanced';
  skillsTargeted: string[];
  reason: string;
  allowCustomInput?: boolean;
}

const pathfinderQuestionSchema = z.object({
  question: z.string().min(5),
  options: z.array(z.string()).min(2).max(8),
  difficulty: z.enum(['Basic', 'Beginner', 'Intermediate', 'Advanced']),
  skillsTargeted: z.array(z.string()),
  reason: z.string(),
});

export const careerAnalysisSchema = z.object({
  primaryDirection: z.object({
    title: z.string(),
    fitPercentage: z.number().min(50).max(100),
    description: z.string(),
  }),
  alternativePaths: z.array(
    z.object({
      title: z.string(),
      fitPercentage: z.number().min(30).max(95),
      description: z.string(),
    })
  ).min(1).max(4),
  keyStrengths: z.array(z.string()).min(2),
  areasToImprove: z.array(z.string()).min(2),
  skillGaps: z.array(z.string()).min(2),
  learningStyle: z.string(),
  recommendedNextAction: z.string(),
  evidenceSummary: z.array(z.string()),
});

export type CareerAnalysisResult = z.infer<typeof careerAnalysisSchema>;

export class CareerPathfinderService {
  static async startSession(
    userId: string,
    options?: {
      targetDomain?: string;
      preferredLanguage?: string;
      department?: string;
      resumeActive?: boolean;
    }
  ) {
    let dept = options?.department;
    if (!dept) {
      const user = await prisma.user.findUnique({
        where: { id: userId },
        include: { department: true },
      });
      dept = user?.department?.name || 'Computer Science and Engineering';
    }
    return careerPathfinderService.getOrCreateSession(
      userId,
      dept,
      options?.preferredLanguage || 'English'
    );
  }

  static async answerQuestion(
    _userId: string,
    sessionId: string,
    answerText: string,
    _questionId?: string
  ) {
    return careerPathfinderService.submitAnswer(sessionId, answerText);
  }

  static async getSession(userId: string, sessionId: string) {
    const session = await prisma.careerPathfinderSession.findFirst({
      where: { id: sessionId, user_id: userId },
    });
    if (!session) {
      throw new Error('Pathfinder session not found');
    }
    return session;
  }

  /**
   * Starts or resumes a dynamic Pathfinder session for a student.
   */
  async getOrCreateSession(userId: string, studentDepartment?: string, preferredLanguage: string = 'English') {
    let session = await prisma.careerPathfinderSession.findFirst({
      where: { user_id: userId, completed: false },
      orderBy: { created_at: 'desc' },
    });

    if (!session) {
      // Generate initial discovery question calibrated to department
      const initialQuestion = this.generateDepartmentInitialQuestion(studentDepartment || 'General Engineering');
      session = await prisma.careerPathfinderSession.create({
        data: {
          user_id: userId,
          stage: 'CAREER_DISCOVERY',
          current_question: initialQuestion as any,
          collected_evidence: [],
          contradictions: [],
          question_history: [],
          career_hypotheses: [],
          missing_information: ['primary_interest', 'technical_depth', 'learning_goal'],
          preferred_language: preferredLanguage,
          completed: false,
        },
      });
    }

    return session;
  }

  /**
   * Processes a student answer, updates evidence, checks contradictions, and advances to next question or final analysis.
   */
  async submitAnswer(sessionId: string, answerText: string) {
    const session = await prisma.careerPathfinderSession.findUnique({
      where: { id: sessionId },
      include: { user: { include: { department: true } } },
    });

    if (!session) {
      throw new Error('Pathfinder session not found');
    }

    const currentQ = (session.current_question as unknown as PathfinderQuestionPayload) || {
      step: 1,
      totalSteps: 8,
      stage: session.stage,
      question: 'What is your primary engineering interest?',
      options: [],
    };

    const questionHistory = Array.isArray(session.question_history)
      ? [...(session.question_history as any[])]
      : [];
    questionHistory.push({
      step: currentQ.step || questionHistory.length + 1,
      stage: session.stage,
      question: currentQ.question,
      answer: answerText,
      timestamp: new Date().toISOString(),
    });

    const collectedEvidence = Array.isArray(session.collected_evidence)
      ? [...(session.collected_evidence as string[])]
      : [];
    const contradictions = Array.isArray(session.contradictions)
      ? [...(session.contradictions as any[])]
      : [];

    // 1. Analyze answer & extract evidence
    collectedEvidence.push(`Answered: "${answerText}" to "${currentQ.question}"`);

    // Contradiction detection heuristic
    const lowerAnswer = answerText.toLowerCase();
    const historyText = questionHistory.map((q) => q.answer.toLowerCase()).join(' ');

    let contradictionFound: string | null = null;
    if (lowerAnswer.includes('hate server') && historyText.includes('backend')) {
      contradictionFound = 'Expressed interest in Backend earlier but indicated dislike for server-side code.';
    } else if (lowerAnswer.includes('pure software') && historyText.includes('hardware only')) {
      contradictionFound = 'Switched from hardware-exclusive focus to pure software.';
    }

    if (contradictionFound) {
      contradictions.push({
        step: questionHistory.length,
        issue: contradictionFound,
        detectedAt: new Date().toISOString(),
      });
    }

    const currentStep = questionHistory.length;
    const totalSteps = 8;

    // 2. Check if reached final analysis step
    if (currentStep >= totalSteps) {
      const finalAnalysis = await this.generateCareerAnalysis(
        session.user.department?.name || 'Engineering',
        questionHistory,
        collectedEvidence,
        contradictions,
        session.preferred_language
      );

      const updated = await prisma.careerPathfinderSession.update({
        where: { id: sessionId },
        data: {
          stage: 'FINAL_ANALYSIS',
          question_history: questionHistory,
          collected_evidence: collectedEvidence,
          contradictions: contradictions,
          career_analysis: finalAnalysis as any,
          completed: true,
        },
      });

      return {
        isCompleted: true,
        session: updated,
        analysis: finalAnalysis,
      };
    }

    // 3. Determine next stage
    let nextStage = 'CAREER_DISCOVERY';
    if (currentStep >= 6) nextStage = 'CAREER_GOALS';
    else if (currentStep >= 4) nextStage = 'TECHNICAL_VALIDATION';
    else if (currentStep >= 2) nextStage = 'TECHNICAL_BACKGROUND';

    // 4. Generate next dynamic question
    const nextQuestion = await this.generateNextDynamicQuestion({
      department: session.user.department?.name || 'Engineering',
      step: currentStep + 1,
      totalSteps,
      stage: nextStage,
      history: questionHistory,
      contradiction: contradictionFound,
      preferredLanguage: session.preferred_language,
    });

    const updated = await prisma.careerPathfinderSession.update({
      where: { id: sessionId },
      data: {
        stage: nextStage,
        current_question: nextQuestion as any,
        question_history: questionHistory,
        collected_evidence: collectedEvidence,
        contradictions: contradictions,
      },
    });

    return {
      isCompleted: false,
      session: updated,
      nextQuestion,
    };
  }

  private generateDepartmentInitialQuestion(department: string): PathfinderQuestionPayload {
    const dept = department.toLowerCase();

    if (dept.includes('ece') || dept.includes('electronics')) {
      return {
        step: 1,
        totalSteps: 8,
        stage: 'CAREER_DISCOVERY',
        question: 'As an ECE engineer, which intersection of hardware and software excites you most?',
        options: [
          'IoT & Smart Connected Devices',
          'Embedded Systems & Microcontroller Firmware',
          'Robotics & Autonomous Systems',
          'Cross-Platform Mobile Apps (Flutter/Dart)',
          'High-Throughput Backend & Cloud APIs',
          'I am still exploring',
        ],
        difficulty: 'Beginner',
        skillsTargeted: ['Hardware/Software Interfacing', 'Exploration'],
        reason: 'Calibrates whether student intends to pursue core embedded/IoT or pivot to pure software engineering.',
      };
    }

    if (dept.includes('civil')) {
      return {
        step: 1,
        totalSteps: 8,
        stage: 'CAREER_DISCOVERY',
        question: 'As a Civil Engineering student, where would you like to direct your technical career?',
        options: [
          'Building Information Modeling (BIM) & Computational Design',
          'Smart City Infrastructure & GIS Systems',
          'Transitioning to Software Engineering / Full-Stack Web',
          'Structural Engineering & Project Automation',
          'I am still exploring',
        ],
        difficulty: 'Beginner',
        skillsTargeted: ['BIM', 'Software Transition', 'Civil Tech'],
        reason: 'Identifies civil-tech vs cross-domain software development goals.',
      };
    }

    if (dept.includes('mech') || dept.includes('automobile')) {
      return {
        step: 1,
        totalSteps: 8,
        stage: 'CAREER_DISCOVERY',
        question: 'In Mechanical & Automobile Engineering, which advanced direction draws your passion?',
        options: [
          'Robotics & Industrial Automation',
          'Automotive Software & Electric Vehicle (EV) Systems',
          'CAD/CAM & Mechanical Simulation Systems',
          'Transitioning to High-Paying Software / Cloud Engineering',
          'I am still exploring',
        ],
        difficulty: 'Beginner',
        skillsTargeted: ['Robotics', 'Automotive Software', 'Software Transition'],
        reason: 'Distinguishes between robotics/automotive embedded systems and software pivot.',
      };
    }

    if (dept.includes('ai') || dept.includes('data')) {
      return {
        step: 1,
        totalSteps: 8,
        stage: 'CAREER_DISCOVERY',
        question: 'In AI & Data Science, what kind of systems do you want to architect?',
        options: [
          'Applied Machine Learning & LLM AI Agents',
          'Big Data Pipelines & Distributed Data Engineering',
          'Full-Stack AI Applications (React/Flutter + Python Backend)',
          'Computer Vision & Autonomous Edge Devices',
          'I am still exploring',
        ],
        difficulty: 'Beginner',
        skillsTargeted: ['Machine Learning', 'Data Engineering', 'Full-Stack AI'],
        reason: 'Determines specialized AI research vs applied engineering direction.',
      };
    }

    // Default CSE / IT
    return {
      step: 1,
      totalSteps: 8,
      stage: 'CAREER_DISCOVERY',
      question: 'Which engineering domain or product type excites you most to build?',
      options: [
        'Full-Stack Web Engineering (React, Node.js & Cloud)',
        'Cross-Platform Mobile Apps (Flutter & Dart)',
        'Distributed Backend Architecture & High Scale APIs',
        'AI, LLM Agents & Machine Learning Engineering',
        'Cybersecurity, Ethical Hacking & DevSecOps',
        'C++ High-Performance Systems & Competitive Programming',
      ],
      difficulty: 'Beginner',
      skillsTargeted: ['Core Engineering Domain'],
      reason: 'Establishes primary engineering direction baseline.',
    };
  }

  private async generateNextDynamicQuestion(params: {
    department: string;
    step: number;
    totalSteps: number;
    stage: string;
    history: Array<{ question: string; answer: string }>;
    contradiction: string | null;
    preferredLanguage: string;
  }): Promise<PathfinderQuestionPayload> {
    const historySummary = params.history
      .map((h, i) => `Q${i + 1}: ${h.question} -> A: ${h.answer}`)
      .join('\n');

    const prompt = `You are EVA, an expert Career Architect at CampusHub University.
Context:
- Student Department: ${params.department}
- Current Step: ${params.step} of ${params.totalSteps}
- Current Stage: ${params.stage}
- Preferred Language: ${params.preferredLanguage}
- Previous Answers:
${historySummary}
${params.contradiction ? `- Detected Contradiction to Resolve: ${params.contradiction}` : ''}

Generate exactly ONE context-aware multiple-choice question for step ${params.step}.
Rules:
1. Adapt directly to previous answers. If they picked IoT, explore microcontrollers vs sensors vs cloud. If they picked robotics, explore ROS vs control.
2. If there is a contradiction, ask a clarifying question to resolve it.
3. Provide 4 to 6 realistic, specific answer options.
4. Output ONLY valid JSON matching the schema:
{
  "question": "...",
  "options": ["Option A", "Option B", "Option C", "Option D"],
  "difficulty": "Beginner" | "Intermediate" | "Advanced",
  "skillsTargeted": ["Skill 1", "Skill 2"],
  "reason": "Why this question was chosen based on evidence"
}`;

    try {
      const generated = await aiProvider.generateStructured(prompt, pathfinderQuestionSchema);
      return {
        step: params.step,
        totalSteps: params.totalSteps,
        stage: params.stage,
        question: generated.question,
        options: generated.options,
        difficulty: generated.difficulty,
        skillsTargeted: generated.skillsTargeted,
        reason: generated.reason,
      };
    } catch (err) {
      logger.warn({ err }, 'Dynamic question generation fallback');
      return this.getFallbackQuestion(params.step, params.totalSteps, params.stage, params.history);
    }
  }

  private getFallbackQuestion(
    step: number,
    totalSteps: number,
    stage: string,
    history: Array<{ question: string; answer: string }>
  ): PathfinderQuestionPayload {
    const lastAnswer = history[history.length - 1]?.answer.toLowerCase() || '';

    if (lastAnswer.includes('iot') || lastAnswer.includes('hardware') || lastAnswer.includes('embedded')) {
      return {
        step,
        totalSteps,
        stage,
        question: 'When you combine hardware and programming, which specific layer interests you most?',
        options: [
          'Microcontroller Programming (ESP32 / Arduino / C++)',
          'Sensor Interfacing & Actuator Control',
          'IoT Protocols (MQTT, WebSockets, HTTP)',
          'Cloud IoT Dashboards & Backend Ingestion',
          'Firmware & Real-Time Operating Systems (FreeRTOS)',
        ],
        difficulty: 'Intermediate',
        skillsTargeted: ['ESP32', 'Sensors', 'MQTT'],
        reason: 'Drills down into IoT architecture layers.',
      };
    }

    if (lastAnswer.includes('mobile') || lastAnswer.includes('flutter')) {
      return {
        step,
        totalSteps,
        stage,
        question: 'In mobile development, what architecture experience do you currently have?',
        options: [
          'Complete Beginner - learning UI widgets and Dart syntax',
          'Built small apps - used setState or basic state management',
          'Intermediate - comfortable with Riverpod/Bloc and REST APIs',
          'Advanced - offline SQLite sync, custom RenderObjects & CI/CD',
        ],
        difficulty: 'Intermediate',
        skillsTargeted: ['Flutter State Management', 'Architecture'],
        reason: 'Calibrates practical mobile engineering maturity.',
      };
    }

    return {
      step,
      totalSteps,
      stage,
      question: 'What is your primary learning goal and target milestone for this semester?',
      options: [
        'Secure a campus placement / internship in a top tech company',
        'Build a production-ready real-world capstone project for my portfolio',
        'Master data structures, algorithms and competitive programming',
        'Learn full-stack engineering from scratch to industry standards',
      ],
      difficulty: 'Beginner',
      skillsTargeted: ['Goal Setting', 'Timeline'],
      reason: 'Clarifies semester readiness priorities.',
    };
  }

  private async generateCareerAnalysis(
    department: string,
    history: Array<{ question: string; answer: string }>,
    evidence: string[],
    contradictions: any[],
    preferredLanguage: string
  ): Promise<CareerAnalysisResult> {
    const historyText = history.map((h) => `${h.question} -> ${h.answer}`).join('\n');

    const prompt = `Analyze this student's complete career discovery trajectory and generate a comprehensive career direction recommendation.
Department: ${department}
Preferred Language: ${preferredLanguage}
Evidence:
${historyText}

Generate a structured JSON analysis:
{
  "primaryDirection": {
    "title": "e.g. IoT & Embedded Systems Developer",
    "fitPercentage": 92,
    "description": "2-3 sentences explaining why this direction matches their strengths."
  },
  "alternativePaths": [
    { "title": "e.g. Embedded Software Engineer", "fitPercentage": 78, "description": "..." },
    { "title": "e.g. Robotics Developer", "fitPercentage": 72, "description": "..." },
    { "title": "e.g. Firmware Engineer", "fitPercentage": 68, "description": "..." }
  ],
  "keyStrengths": ["Problem Solving", "Hardware Interest", "Logical Thinking", "Willing to Learn"],
  "areasToImprove": ["Cyber-Physical Systems", "C++", "RTOS"],
  "skillGaps": ["ESP32 Architecture", "MQTT Protocols", "FreeRTOS Basics"],
  "learningStyle": "Hands-on Practical & Code-first",
  "recommendedNextAction": "Generate your personalized roadmap to begin with Microcontroller foundations.",
  "evidenceSummary": ["Demonstrated strong interest in combining hardware with C++ code."]
}`;

    try {
      return await aiProvider.generateStructured(prompt, careerAnalysisSchema);
    } catch (err) {
      logger.warn({ err }, 'Career analysis generation fallback');
      const allText = historyText.toLowerCase();

      if (allText.includes('iot') || allText.includes('embedded') || allText.includes('hardware')) {
        return {
          primaryDirection: {
            title: 'IoT & Embedded Systems Developer',
            fitPercentage: 92,
            description: 'Your background and expressed interests strongly align with IoT architecture, microcontroller firmware, and connected sensor systems.',
          },
          alternativePaths: [
            { title: 'Embedded Software Engineer', fitPercentage: 78, description: 'Direct firmware programming on bare-metal and RTOS platforms.' },
            { title: 'Robotics Developer', fitPercentage: 72, description: 'Autonomous motion control, sensor fusion, and actuator integration.' },
            { title: 'Firmware Engineer', fitPercentage: 68, description: 'Low-level device drivers and board bring-up programming.' },
          ],
          keyStrengths: ['Hardware Interest', 'Problem Solving', 'Logical Thinking', 'Willing to Learn'],
          areasToImprove: ['Cyber-Physical Systems', 'C++', 'RTOS'],
          skillGaps: ['ESP32 & Arduino Architecture', 'MQTT Protocols', 'FreeRTOS Concurrency'],
          learningStyle: 'Hands-on Practical & Hardware Prototyping',
          recommendedNextAction: 'Generate your personalized roadmap to begin with Microcontroller foundations.',
          evidenceSummary: ['Identified enthusiasm for sensor-driven embedded software.'],
        };
      }

      return {
        primaryDirection: {
          title: 'Modern Full-Stack & Cloud Engineer',
          fitPercentage: 90,
          description: 'Your problem solving aptitude and interest in scalable systems align with modern end-to-end full stack software development.',
        },
        alternativePaths: [
          { title: 'Backend & Cloud Systems Engineer', fitPercentage: 82, description: 'Microservices, database scaling, and distributed APIs.' },
          { title: 'Cross-Platform Mobile Engineer', fitPercentage: 75, description: 'High performance client-side mobile development.' },
        ],
        keyStrengths: ['Logical Reasoning', 'Software Architecture', 'Continuous Learning'],
        areasToImprove: ['Distributed Systems', 'Database Optimization', 'Cloud CI/CD'],
        skillGaps: ['Advanced SQL', 'Docker & Kubernetes', 'System Design'],
        learningStyle: 'Project-driven active learning',
        recommendedNextAction: 'Generate your personalized roadmap to begin with core API architecture.',
        evidenceSummary: ['Strong software development orientation verified across all discovery turns.'],
      };
    }
  }
}

export const careerPathfinderService = new CareerPathfinderService();
