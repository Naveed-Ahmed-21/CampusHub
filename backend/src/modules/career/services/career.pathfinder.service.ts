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

export const contradictionSchema = z.object({
  hasContradiction: z.boolean(),
  contradictionDescription: z.string().nullable().optional(),
  conflictingThemes: z.array(z.string()).default([]),
  suggestedClarification: z.string().nullable().optional(),
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
    userId: string,
    sessionId: string,
    answerText: string,
    _questionId?: string
  ) {
    return careerPathfinderService.submitAnswer(sessionId, answerText, userId);
  }

  static async previousQuestion(userId: string, sessionId: string) {
    return careerPathfinderService.stepBack(sessionId, userId);
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
  async submitAnswer(sessionId: string, answerText: string, userId?: string) {
    const session = await prisma.careerPathfinderSession.findUnique({
      where: { id: sessionId },
      include: { user: { include: { department: true } } },
    });

    if (!session) {
      throw new Error('Pathfinder session not found');
    }

    if (userId && session.user_id !== userId) {
      throw new Error('Unauthorized to submit answers to this session');
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
      options: currentQ.options || [],
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

    // Semantic contradiction detection
    let contradictionFound: string | null = null;
    let suggestedClarification: string | null = null;

    if (questionHistory.length >= 2) {
      const priorHistory = questionHistory.slice(0, -1);
      const contradictionResult = await this.detectSemanticContradiction(
        currentQ.question,
        answerText,
        priorHistory
      );
      if (contradictionResult.hasContradiction && contradictionResult.description) {
        contradictionFound = contradictionResult.description;
        suggestedClarification = contradictionResult.suggestedClarification;
        contradictions.push({
          step: questionHistory.length,
          issue: contradictionFound,
          suggestedClarification: suggestedClarification,
          detectedAt: new Date().toISOString(),
        });
      }
    }

    // Dynamic career hypotheses scoring
    const careerHypotheses = this.computeActiveCareerHypotheses(
      session.user.department?.name || 'Engineering',
      questionHistory
    );

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
          career_hypotheses: careerHypotheses as any,
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
      contradiction: suggestedClarification || contradictionFound,
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
        career_hypotheses: careerHypotheses as any,
      },
    });

    return {
      isCompleted: false,
      session: updated,
      nextQuestion,
    };
  }

  /**
   * Steps back to the previous question, restoring state and previous answer.
   */
  async stepBack(sessionId: string, userId?: string) {
    const session = await prisma.careerPathfinderSession.findUnique({
      where: { id: sessionId },
      include: { user: { include: { department: true } } },
    });

    if (!session) {
      throw new Error('Pathfinder session not found');
    }

    if (userId && session.user_id !== userId) {
      throw new Error('Unauthorized to step back in this session');
    }

    const questionHistory = Array.isArray(session.question_history)
      ? [...(session.question_history as any[])]
      : [];

    if (questionHistory.length === 0) {
      return { session, previousAnswer: null };
    }

    const popped = questionHistory.pop();
    const collectedEvidence = Array.isArray(session.collected_evidence)
      ? [...(session.collected_evidence as string[])]
      : [];
    if (collectedEvidence.length > 0) {
      collectedEvidence.pop();
    }

    const currentStep = questionHistory.length + 1;
    let nextStage = 'CAREER_DISCOVERY';
    if (currentStep >= 6) nextStage = 'CAREER_GOALS';
    else if (currentStep >= 4) nextStage = 'TECHNICAL_VALIDATION';
    else if (currentStep >= 2) nextStage = 'TECHNICAL_BACKGROUND';

    let restoredQuestion: PathfinderQuestionPayload;
    if (currentStep === 1) {
      restoredQuestion = this.generateDepartmentInitialQuestion(
        session.user?.department?.name || 'General Engineering'
      );
    } else {
      const domain = this.detectDomainFromHistory(questionHistory);
      restoredQuestion = this.getDomainQuestion(domain, currentStep, 8, nextStage);
      if (popped?.question) {
        restoredQuestion.question = popped.question;
      }
      if (popped?.options && popped.options.length > 0) {
        restoredQuestion.options = popped.options;
      }
    }

    const updated = await prisma.careerPathfinderSession.update({
      where: { id: sessionId },
      data: {
        stage: nextStage,
        current_question: restoredQuestion as any,
        question_history: questionHistory,
        collected_evidence: collectedEvidence,
        completed: false,
      },
    });

    return {
      session: updated,
      previousAnswer: popped?.answer || null,
      restoredQuestion,
    };
  }

  /**
   * Semantic Contradiction Detector using fast polarity heuristics with optional LLM verification
   */
  private async detectSemanticContradiction(
    currentQuestion: string,
    currentAnswer: string,
    history: Array<{ question: string; answer: string }>
  ): Promise<{ hasContradiction: boolean; description: string | null; suggestedClarification: string | null }> {
    if (history.length < 1) {
      return { hasContradiction: false, description: null, suggestedClarification: null };
    }

    const curLower = currentAnswer.toLowerCase();
    const prevAnswers = history.map((h) => h.answer.toLowerCase()).join(' ');

    // Polarity 1: Backend preference vs Backend aversion
    const backendDislike =
      (curLower.includes('server') || curLower.includes('backend') || curLower.includes('database')) &&
      (curLower.includes('dislike') || curLower.includes('hate') || curLower.includes('avoid') || curLower.includes('no server'));
    const backendPrior =
      prevAnswers.includes('backend') || prevAnswers.includes('server') || prevAnswers.includes('cloud api');
    if (backendDislike && backendPrior) {
      return {
        hasContradiction: true,
        description: 'Previously expressed strong interest in backend engineering, but now indicated dislike or aversion toward server-side development.',
        suggestedClarification: 'Would you prefer focusing on frontend visual design, full-stack integration, or client-side mobile applications?',
      };
    }

    // Polarity 2: Pure Hardware vs Pure Web
    const hardwareDislike =
      (curLower.includes('hardware') || curLower.includes('circuits') || curLower.includes('microcontroller')) &&
      (curLower.includes('hate') || curLower.includes('dislike') || curLower.includes('avoid') || curLower.includes('no hardware'));
    const hardwarePrior =
      prevAnswers.includes('iot') || prevAnswers.includes('embedded') || prevAnswers.includes('hardware');
    if (hardwareDislike && hardwarePrior) {
      return {
        hasContradiction: true,
        description: 'Previously prioritized hardware and embedded systems, but now expressed aversion to hardware.',
        suggestedClarification: 'Would you prefer transitioning to pure software engineering such as cloud, mobile, or web?',
      };
    }

    // Polarity 3: Frontend vs UI aversion
    const frontendDislike =
      (curLower.includes('frontend') || curLower.includes('ui') || curLower.includes('css')) &&
      (curLower.includes('dislike') || curLower.includes('hate') || curLower.includes('avoid') || curLower.includes('no ui'));
    const frontendPrior =
      prevAnswers.includes('frontend') || prevAnswers.includes('react') || prevAnswers.includes('web ui');
    if (frontendDislike && frontendPrior) {
      return {
        hasContradiction: true,
        description: 'Previously selected frontend UI engineering, but now stated an aversion to UI development.',
        suggestedClarification: 'Would you prefer focusing on backend distributed APIs or database architecture?',
      };
    }

    // If it's a standard option selection, skip heavy remote LLM check to keep navigation instant
    if (currentAnswer.split(/\s+/).length < 8) {
      return { hasContradiction: false, description: null, suggestedClarification: null };
    }

    try {
      const historySummary = history
        .map((h, i) => `Turn ${i + 1}: Q: "${h.question}" -> A: "${h.answer}"`)
        .join('\n');

      const prompt = `You are EVA, an expert Career Architect and consistency auditor at CampusHub.
Analyze whether the latest student response introduces a genuine semantic contradiction with their previous statements.

Previous Responses:
${historySummary}

Latest Question: "${currentQuestion}"
Latest Answer: "${currentAnswer}"

Return strictly JSON:
{
  "hasContradiction": boolean,
  "contradictionDescription": string or null,
  "conflictingThemes": string[],
  "suggestedClarification": string or null
}`;

      const result = await aiProvider.generateStructured(prompt, contradictionSchema);
      if (result.hasContradiction && result.contradictionDescription) {
        return {
          hasContradiction: true,
          description: result.contradictionDescription,
          suggestedClarification: result.suggestedClarification || null,
        };
      }
    } catch {
      // Graceful fallback
    }

    return { hasContradiction: false, description: null, suggestedClarification: null };
  }

  /**
   * Dynamically tracks and updates candidate career hypotheses across conversation turns
   */
  private computeActiveCareerHypotheses(
    _department: string,
    history: Array<{ question: string; answer: string }>
  ): Array<{ career: string; confidence: number; reason: string }> {
    const combined = history.map((h) => `${h.question} ${h.answer}`).join(' ').toLowerCase();

    const candidates = [
      {
        career: 'Full-Stack Web Engineer',
        keywords: ['web', 'react', 'node', 'full-stack', 'frontend', 'javascript', 'html', 'css', 'api'],
      },
      {
        career: 'Backend & Cloud Architect',
        keywords: ['backend', 'distributed', 'microservices', 'database', 'sql', 'high-throughput', 'cloud', 'aws'],
      },
      {
        career: 'Cross-Platform Mobile Engineer',
        keywords: ['mobile', 'flutter', 'dart', 'android', 'ios', 'apps'],
      },
      {
        career: 'AI & Machine Learning Engineer',
        keywords: ['ai', 'machine learning', 'data', 'deep learning', 'llm', 'python', 'analytics', 'models'],
      },
      {
        career: 'IoT & Embedded Systems Developer',
        keywords: ['iot', 'embedded', 'firmware', 'esp32', 'arduino', 'sensors', 'hardware', 'c++', 'microcontroller'],
      },
      {
        career: 'Cybersecurity & DevSecOps Engineer',
        keywords: ['security', 'ethical hacking', 'devsecops', 'network', 'penetration', 'linux'],
      },
    ];

    const scored = candidates.map((cand) => {
      let matchCount = 0;
      for (const kw of cand.keywords) {
        if (combined.includes(kw)) matchCount += 1;
      }
      const score = Math.min(0.95, Math.max(0.35, 0.40 + matchCount * 0.12));
      return {
        career: cand.career,
        confidence: Math.round(score * 100) / 100,
        reason: `Matched ${matchCount} domain indicators across conversation turns.`,
      };
    });

    return scored.sort((a, b) => b.confidence - a.confidence).slice(0, 3);
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

  private detectDomainFromHistory(history: Array<{ question: string; answer: string }>): string {
    const combined = history.map((h) => `${h.question} ${h.answer}`).join(' ').toLowerCase();
    if (combined.includes('cyber') || combined.includes('security') || combined.includes('devsecops') || combined.includes('ethical hacking') || combined.includes('pen-test') || combined.includes('wireshark') || combined.includes('nmap') || combined.includes('owasp')) {
      return 'cybersecurity';
    }
    if (combined.includes('ai') || combined.includes('machine learning') || combined.includes('data science') || combined.includes('data scientist') || combined.includes('llm') || combined.includes('deep learning') || combined.includes('neural') || combined.includes('pandas')) {
      return 'ai';
    }
    if (combined.includes('mobile') || combined.includes('flutter') || combined.includes('dart') || combined.includes('android') || combined.includes('ios')) {
      return 'mobile';
    }
    if (combined.includes('iot') || combined.includes('embedded') || combined.includes('esp32') || combined.includes('microcontroller') || combined.includes('hardware') || combined.includes('sensor')) {
      return 'iot';
    }
    if (combined.includes('backend') || combined.includes('distributed') || combined.includes('microservices') || combined.includes('database') || combined.includes('sql') || combined.includes('cloud api')) {
      return 'backend';
    }
    return 'fullstack';
  }

  private getDomainQuestion(
    domain: string,
    step: number,
    totalSteps: number,
    stage: string
  ): PathfinderQuestionPayload {
    if (domain === 'cybersecurity') {
      const qMap: Record<number, PathfinderQuestionPayload> = {
        2: {
          step,
          totalSteps,
          stage,
          question: 'What is your current hands-on experience with networking and operating systems?',
          options: [
            'Familiar with Linux CLI, file permissions, and TCP/IP basics',
            'Configured firewalls, DNS records, subnets, and SSH keys',
            'Used security tools like Wireshark, Nmap, or Burp Suite in labs',
            'Beginner in networking, motivated to build security depth',
          ],
          difficulty: 'Beginner',
          skillsTargeted: ['Linux Security', 'TCP/IP Networking'],
          reason: 'Calibrates practical networking and OS foundation.',
        },
        3: {
          step,
          totalSteps,
          stage,
          question: 'Which branch of cybersecurity excites you most to specialize in?',
          options: [
            'Offensive Security: Ethical Hacking & Penetration Testing',
            'Defensive Security: SOC Analysis, Threat Hunting & SIEM',
            'DevSecOps: CI/CD Pipeline Hardening & Container Security',
            'Application Security: Code Auditing & OWASP Top 10 Remediation',
          ],
          difficulty: 'Intermediate',
          skillsTargeted: ['Offensive vs Defensive Security'],
          reason: 'Identifies core cybersecurity discipline preference.',
        },
        4: {
          step,
          totalSteps,
          stage,
          question: 'Which scripting language or tooling stack do you prefer for security automation?',
          options: [
            'Python (Scapy, requests, socket programming, exploit scripts)',
            'Bash scripting & Linux command-line pipeline automation',
            'Go / C for low-level network tools and binary analysis',
            'Burp Suite, OWASP ZAP, Metasploit & Postman',
          ],
          difficulty: 'Intermediate',
          skillsTargeted: ['Security Automation', 'Python & Bash'],
          reason: 'Validates programmatic security tool capabilities.',
        },
        5: {
          step,
          totalSteps,
          stage,
          question: 'In a production incident, how would you respond to an alert indicating potential data exfiltration?',
          options: [
            'Isolate the compromised server network interface and preserve volatile RAM for forensics',
            'Analyze firewall, DNS, and NetFlow traffic to trace and block malicious IP endpoints',
            'Review recent pull requests and git commits for leaked API tokens or backdoors',
            'Deploy automated endpoint detection (EDR) rules to terminate rogue processes',
          ],
          difficulty: 'Intermediate',
          skillsTargeted: ['Incident Response', 'Network Forensics'],
          reason: 'Evaluates incident response and defensive problem solving.',
        },
        6: {
          step,
          totalSteps,
          stage,
          question: 'What is your target technical milestone or certification horizon for this year?',
          options: [
            'CompTIA Security+ / CEH (Certified Ethical Hacker)',
            'OSCP (Offensive Security Certified Professional) / eJPT',
            'AWS or Azure Certified Security Specialty',
            'Active rank on Hack The Box, TryHackMe, or Bug Bounty platforms',
          ],
          difficulty: 'Intermediate',
          skillsTargeted: ['Certification Goals', 'Career Horizon'],
          reason: 'Aligns study timeline with industry credential benchmarks.',
        },
        7: {
          step,
          totalSteps,
          stage,
          question: 'What learning approach builds your practical security confidence fastest?',
          options: [
            'Capture The Flag (CTF) challenges and vulnerable practice VMs',
            'Building defensive homelabs (pfSense, Splunk, Wazuh SIEM)',
            'Reading security advisories, CVE reports, and OWASP documentation',
            'Step-by-step video breakdowns accompanied by hands-on labs',
          ],
          difficulty: 'Intermediate',
          skillsTargeted: ['Hands-on CTF Labs', 'Defensive Homelabs'],
          reason: 'Tailors recommended resources to practical learning style.',
        },
        8: {
          step,
          totalSteps,
          stage,
          question: 'What capstone security project would you like to present on your resume?',
          options: [
            'End-to-end DevSecOps CI/CD pipeline with automated SAST/DAST and secret scanners',
            'Custom Python Network Intrusion Detection System (NIDS) with real-time alerts',
            'Full-scale Web Application Pen-Test Report with PoC exploits and patch guides',
            'SIEM Security Operations Dashboard analyzing simulated enterprise attack logs',
          ],
          difficulty: 'Advanced',
          skillsTargeted: ['DevSecOps Capstone', 'NIDS Architecture'],
          reason: 'Determines milestone capstone project for portfolio.',
        },
      };
      return qMap[step] || qMap[2];
    }

    if (domain === 'ai') {
      const qMap: Record<number, PathfinderQuestionPayload> = {
        2: {
          step,
          totalSteps,
          stage,
          question: 'What is your current foundation in Python programming, mathematics, and statistics?',
          options: [
            'Proficient in Python (NumPy, Pandas) with linear algebra and statistics knowledge',
            'Hands-on experience with Scikit-Learn or PyTorch building initial models',
            'Experimented with LLM APIs, LangChain, or HuggingFace transformers',
            'Beginner in Python, eager to build rigorous data foundations',
          ],
          difficulty: 'Beginner',
          skillsTargeted: ['Python Data Stack', 'Math & Statistics'],
          reason: 'Calibrates mathematical and algorithmic machine learning prerequisites.',
        },
        3: {
          step,
          totalSteps,
          stage,
          question: 'Which AI & Data Science domain interests you most?',
          options: [
            'Generative AI, Large Language Models (LLMs) & Autonomous Multi-Agent Systems',
            'Machine Learning Engineering & Predictive Analytics (Supervised/Unsupervised)',
            'Computer Vision & Autonomous Perception (YOLO, OpenCV, PyTorch)',
            'Big Data Engineering & Distributed Pipelines (Spark, SQL, Airflow)',
          ],
          difficulty: 'Intermediate',
          skillsTargeted: ['Generative AI', 'Predictive Modeling'],
          reason: 'Pinpoints specialized subfield of Artificial Intelligence.',
        },
        4: {
          step,
          totalSteps,
          stage,
          question: 'What datasets or model architectures have you worked with so far?',
          options: [
            'Tabular datasets (Kaggle competitions, XGBoost, Random Forests, Regression)',
            'Fine-tuning open-source LLMs (Llama, Mistral) with LoRA/QLoRA',
            'Convolutional Neural Networks (CNNs) on computer vision image datasets',
            'Ready to begin my first end-to-end machine learning project',
          ],
          difficulty: 'Intermediate',
          skillsTargeted: ['Model Architectures', 'Kaggle & Tabular Data'],
          reason: 'Validates hands-on dataset manipulation proficiency.',
        },
        5: {
          step,
          totalSteps,
          stage,
          question: 'When training a model that severely overfits on training data, how do you diagnose and fix it?',
          options: [
            'Apply regularization (L1/L2, Dropout), prune features, and gather/augment more training samples',
            'Tune hyperparameters with K-fold cross-validation and add early stopping callbacks',
            'Simplify model capacity and verify there is no target leakage in features',
            'Use ensemble bagging techniques (e.g. Random Forest) to reduce variance',
          ],
          difficulty: 'Intermediate',
          skillsTargeted: ['Regularization', 'Cross-Validation'],
          reason: 'Tests core ML diagnostic reasoning and feature engineering.',
        },
        6: {
          step,
          totalSteps,
          stage,
          question: 'What milestone would you like to achieve in AI over the coming semester?',
          options: [
            'Deploy a production-ready AI application with FastAPI and Docker on cloud infrastructure',
            'Publish a high-ranking Kaggle notebook or open-source HuggingFace dataset/model',
            'Build an enterprise-grade Retrieval-Augmented Generation (RAG) knowledge assistant',
            'Secure an AI Engineer / Data Science internship in a high-growth tech company',
          ],
          difficulty: 'Intermediate',
          skillsTargeted: ['Production AI Serving', 'Kaggle Portfolio'],
          reason: 'Clarifies semester milestones and production readiness goals.',
        },
        7: {
          step,
          totalSteps,
          stage,
          question: 'Which learning format helps you master complex AI algorithms most effectively?',
          options: [
            'Interactive Jupyter / Google Colab notebooks with real-world datasets',
            'Building full-stack deployable prototypes with Python backends and modern UI',
            'Reading research papers (ArXiv) and implementing algorithms from scratch',
            'Visual video explanations breaking down mathematics into intuitive concepts',
          ],
          difficulty: 'Intermediate',
          skillsTargeted: ['Notebook Learning', 'ArXiv Papers'],
          reason: 'Determines the highest-impact learning resources.',
        },
        8: {
          step,
          totalSteps,
          stage,
          question: 'What capstone AI project do you want to feature in your placement portfolio?',
          options: [
            'Multi-Document Enterprise RAG Assistant with ChromaDB vector search and FastAPI',
            'Automated Student Placement Early-Warning & Performance Predictive Engine',
            'Real-Time Edge Computer Vision Detection System with alert streaming',
            'Autonomous Multi-Agent Researcher executing multi-step web and document synthesis',
          ],
          difficulty: 'Advanced',
          skillsTargeted: ['Enterprise RAG', 'Predictive Analytics'],
          reason: 'Establishes headline portfolio showcase project.',
        },
      };
      return qMap[step] || qMap[2];
    }

    if (domain === 'mobile') {
      const qMap: Record<number, PathfinderQuestionPayload> = {
        2: {
          step,
          totalSteps,
          stage,
          question: 'What is your current hands-on experience with mobile app development and Dart?',
          options: [
            'Familiar with Dart basics (null safety, OOP, async/await)',
            'Built simple Flutter apps with basic widgets and setState',
            'Experienced with Riverpod or Bloc and Dio REST API integration',
            'Complete beginner eager to build production mobile apps',
          ],
          difficulty: 'Beginner',
          skillsTargeted: ['Dart Language', 'Flutter Widgets'],
          reason: 'Assesses current mobile development maturity.',
        },
        3: {
          step,
          totalSteps,
          stage,
          question: 'Which aspect of modern mobile development excites you most?',
          options: [
            'Polished micro-animations, custom paint, and fluid glassmorphic UI',
            'Offline-first synchronization with SQLite, Hive, and background sync',
            'Architecting clean scalable codebase with Riverpod and domain separation',
            'Native device integration (Camera, GPS, Bluetooth, Push Notifications)',
          ],
          difficulty: 'Intermediate',
          skillsTargeted: ['Mobile UI & Architecture'],
          reason: 'Identifies specialized interest within mobile engineering.',
        },
        4: {
          step,
          totalSteps,
          stage,
          question: 'Which state management pattern do you want to specialize in?',
          options: [
            'Riverpod 2.0 (Notifier, AsyncNotifier, code generation)',
            'BLoC / Cubit (Event-driven unidirectional streams)',
            'Provider & ChangeNotifier (Standard lightweight pattern)',
            'MobX or GetX for reactive observable state',
          ],
          difficulty: 'Intermediate',
          skillsTargeted: ['Riverpod', 'BLoC Pattern'],
          reason: 'Validates state management architectural preference.',
        },
        5: {
          step,
          totalSteps,
          stage,
          question: 'How do you diagnose and eliminate frame drops (jank) in a mobile application?',
          options: [
            'Profile with Flutter DevTools CPU profiler and inspect widget rebuild counts',
            'Avoid heavy work on the main UI isolate by offloading to compute() isolates',
            'Use const constructors and RepaintBoundary for isolated animated widgets',
            'Optimize image assets and use cached network images with memory limits',
          ],
          difficulty: 'Intermediate',
          skillsTargeted: ['Performance Profiling', 'Flutter Isolates'],
          reason: 'Evaluates real-world mobile performance optimization knowledge.',
        },
        6: {
          step,
          totalSteps,
          stage,
          question: 'What is your target mobile milestone for this year?',
          options: [
            'Publish an app with real active users to Google Play Store / Apple App Store',
            'Build an offline-first capstone app featuring live push notifications',
            'Master custom platform channels to bridge Kotlin/Swift native code',
            'Secure a Flutter Mobile Engineer internship at a leading startup',
          ],
          difficulty: 'Intermediate',
          skillsTargeted: ['App Store Deployment', 'Mobile Internship'],
          reason: 'Clarifies semester timeline and publishing goals.',
        },
        7: {
          step,
          totalSteps,
          stage,
          question: 'How do you prefer to learn mobile UI and architecture?',
          options: [
            'Replicating designs from Dribbble/Figma with live hot reload',
            'Studying production open-source Flutter apps on GitHub',
            'Reading official Flutter architectural guidelines and documentation',
            'Following project-based video series building complete real apps',
          ],
          difficulty: 'Intermediate',
          skillsTargeted: ['UI Prototyping', 'Open Source Analysis'],
          reason: 'Tailors mobile curriculum format to student strengths.',
        },
        8: {
          step,
          totalSteps,
          stage,
          question: 'What capstone mobile application do you want to publish on your portfolio?',
          options: [
            'Campus Super-App: Attendance, GPA Calculator, and Peer Chat with WebSocket sync',
            'Personal Finance & Expense Tracker with interactive charts and offline SQLite',
            'AI-Powered Study Assistant with voice transcription and smart flashcards',
            'Real-Time College Event Ticketing app with QR scanner and payment gateway',
          ],
          difficulty: 'Advanced',
          skillsTargeted: ['Mobile Super-App', 'Offline-First Sync'],
          reason: 'Establishes headline capstone project.',
        },
      };
      return qMap[step] || qMap[2];
    }

    if (domain === 'backend') {
      const qMap: Record<number, PathfinderQuestionPayload> = {
        2: {
          step,
          totalSteps,
          stage,
          question: 'What is your current experience with server-side programming and databases?',
          options: [
            'Familiar with Node.js / Express or Python / FastAPI basics',
            'Designed relational database schemas and executed SQL queries',
            'Implemented JWT authentication and role-based access control',
            'Beginner in backend, eager to build high-scale distributed systems',
          ],
          difficulty: 'Beginner',
          skillsTargeted: ['Server-Side Architecture', 'SQL Foundations'],
          reason: 'Assesses backend and database foundation baseline.',
        },
        3: {
          step,
          totalSteps,
          stage,
          question: 'Which backend architecture style aligns best with your career goals?',
          options: [
            'Distributed Microservices with gRPC and Event-Driven Message Brokers',
            'High-Performance Modular Monolith with PostgreSQL and Redis caching',
            'Cloud-Native Serverless APIs on AWS Lambda and DynamoDB',
            'Data-Intensive Real-Time Streaming backends with WebSockets and Kafka',
          ],
          difficulty: 'Intermediate',
          skillsTargeted: ['Microservices', 'Event-Driven Systems'],
          reason: 'Determines architectural direction and scale focus.',
        },
        4: {
          step,
          totalSteps,
          stage,
          question: 'Which database paradigm and caching tools do you want to master?',
          options: [
            'PostgreSQL with Prisma ORM and Redis multi-tier caching',
            'NoSQL document stores (MongoDB) and search indices (Elasticsearch)',
            'Time-series & graph databases (TimescaleDB / Neo4j)',
            'Managed cloud databases (AWS RDS, Aurora, DynamoDB)',
          ],
          difficulty: 'Intermediate',
          skillsTargeted: ['PostgreSQL', 'Redis Caching'],
          reason: 'Identifies database and caching preferences.',
        },
        5: {
          step,
          totalSteps,
          stage,
          question: 'How would you handle a sudden 10x traffic spike causing database connection pool exhaustion?',
          options: [
            'Add a Redis caching layer for read-heavy endpoints and implement PgBouncer connection pooling',
            'Scale database vertically and increase max_connections configuration without pooling',
            'Queue non-critical write operations into RabbitMQ/BullMQ to smooth out write spikes',
            'Implement rate-limiting middleware (Token Bucket) to throttle abusive clients',
          ],
          difficulty: 'Intermediate',
          skillsTargeted: ['Connection Pooling', 'System Reliability'],
          reason: 'Evaluates production scalability and crisis mitigation.',
        },
        6: {
          step,
          totalSteps,
          stage,
          question: 'What is your primary backend milestone this semester?',
          options: [
            'Build and benchmark a service capable of handling 5,000+ requests per second',
            'Containerize microservices with Docker and deploy to Kubernetes / AWS ECS',
            'Implement enterprise authentication with OAuth2, OIDC, and multi-tenant isolation',
            'Secure a Backend Software Engineer placement at a product company',
          ],
          difficulty: 'Intermediate',
          skillsTargeted: ['High Concurrency', 'Kubernetes Deployment'],
          reason: 'Sets concrete semester backend milestones.',
        },
        7: {
          step,
          totalSteps,
          stage,
          question: 'What learning approach sharpens your distributed systems intuition fastest?',
          options: [
            'Building and load-testing services with Apache Bench / k6',
            'Reading system design case studies (Uber, Netflix, Discord architectures)',
            'Contributing to open-source developer tooling and backend SDKs',
            'Step-by-step code walkthroughs building microservices from scratch',
          ],
          difficulty: 'Intermediate',
          skillsTargeted: ['Load Testing', 'System Design Case Studies'],
          reason: 'Calibrates optimal instructional method.',
        },
        8: {
          step,
          totalSteps,
          stage,
          question: 'What capstone backend system do you want to showcase to tech recruiters?',
          options: [
            'High-Throughput Distributed Rate Limiter & API Gateway in Go / Node.js',
            'E-Commerce Order & Inventory Engine with Distributed Saga Transactions',
            'Real-Time Collaborative Document Backend with Operational Transformation (OT)',
            'Multi-Region Cloud Analytics Ingestion Pipeline with Kafka and PostgreSQL',
          ],
          difficulty: 'Advanced',
          skillsTargeted: ['Distributed API Gateway', 'Saga Transactions'],
          reason: 'Establishes headline resume backend system.',
        },
      };
      return qMap[step] || qMap[2];
    }

    if (domain === 'iot') {
      const qMap: Record<number, PathfinderQuestionPayload> = {
        2: {
          step,
          totalSteps,
          stage,
          question: 'What is your current familiarity with microcontrollers and embedded programming?',
          options: [
            'Familiar with C/C++ memory management, pointers, and bitwise operations',
            'Programmed Arduino or ESP32 boards using the Arduino IDE or ESP-IDF',
            'Interfaced analog/digital sensors and controlled stepper motors / servos',
            'Beginner excited to bridge hardware with cloud programming',
          ],
          difficulty: 'Beginner',
          skillsTargeted: ['C/C++ Embedded', 'ESP32 Hardware'],
          reason: 'Assesses hardware and firmware foundation.',
        },
        3: {
          step,
          totalSteps,
          stage,
          question: 'Which layer of the IoT technology stack do you want to focus on?',
          options: [
            'Microcontroller Firmware (Bare-metal C and FreeRTOS concurrency)',
            'Hardware Sensor Interfacing & Analog-to-Digital Signal Processing',
            'IoT Networking Protocols (MQTT, CoAP, WebSockets, Bluetooth LE)',
            'Cloud IoT Telemetry Ingestion & Remote Dashboard Monitoring',
          ],
          difficulty: 'Intermediate',
          skillsTargeted: ['FreeRTOS', 'IoT Protocols'],
          reason: 'Pinpoints specific layer in embedded architecture.',
        },
        4: {
          step,
          totalSteps,
          stage,
          question: 'Which hardware communication protocol have you used or want to master?',
          options: [
            'I2C (Inter-Integrated Circuit) for sensor chains with 2 wires (SDA/SCL)',
            'SPI (Serial Peripheral Interface) for high-speed displays and flash memory',
            'UART for serial debug logging and GPS/GSM module interfacing',
            'CAN Bus / Modbus for automotive and industrial automation',
          ],
          difficulty: 'Intermediate',
          skillsTargeted: ['I2C Protocol', 'SPI & UART'],
          reason: 'Validates serial bus communication understanding.',
        },
        5: {
          step,
          totalSteps,
          stage,
          question: 'How do you handle memory allocation and latency constraints inside an embedded interrupt handler (ISR)?',
          options: [
            'Never use malloc(); keep ISR execution sub-millisecond and defer work using a FreeRTOS queue',
            'Allocate memory dynamically and execute blocking delay() inside the ISR',
            'Disable all interrupts permanently inside the ISR',
            'Write debug statements using slow serial print directly in ISR',
          ],
          difficulty: 'Intermediate',
          skillsTargeted: ['Interrupt Service Routines', 'FreeRTOS Queues'],
          reason: 'Tests embedded firmware reliability and ISR safety.',
        },
        6: {
          step,
          totalSteps,
          stage,
          question: 'What is your target embedded systems milestone this year?',
          options: [
            'Design a custom PCB schematic and have it fabricated via JLCPCB',
            'Build a battery-powered low-power sensor node with deep sleep modes',
            'Master FreeRTOS task scheduling, semaphores, and mutex synchronization',
            'Secure an Embedded Firmware / IoT Systems Engineer placement',
          ],
          difficulty: 'Intermediate',
          skillsTargeted: ['PCB Design', 'Low-Power Modes'],
          reason: 'Aligns hardware goals with timeline.',
        },
        7: {
          step,
          totalSteps,
          stage,
          question: 'How do you learn best when interfacing hardware with software?',
          options: [
            'Hands-on breadboard prototyping with physical microcontroller boards',
            'Simulating circuits using Wokwi or Proteus virtual environments',
            'Reading microcontroller hardware reference manuals and datasheets',
            'Step-by-step video lab tutorials with code walkthroughs',
          ],
          difficulty: 'Intermediate',
          skillsTargeted: ['Breadboard Prototyping', 'Datasheet Analysis'],
          reason: 'Optimizes learning material format for hardware focus.',
        },
        8: {
          step,
          totalSteps,
          stage,
          question: 'What capstone hardware-connected IoT system do you want to build?',
          options: [
            'Smart Campus Environmental Monitoring Mesh with ESP32, BME280 & LoRaWAN',
            'Autonomous Smart Irrigation & Soil Quality System with MQTT Cloud Telemetry',
            'Industrial Machine Vibration & Anomaly Detector using Edge TinyML',
            'Connected Smart Energy Meter with real-time billing dashboard and relay cutoff',
          ],
          difficulty: 'Advanced',
          skillsTargeted: ['LoRaWAN Mesh', 'Edge TinyML'],
          reason: 'Establishes headline hardware capstone.',
        },
      };
      return qMap[step] || qMap[2];
    }

    // Default Full-Stack
    const qMap: Record<number, PathfinderQuestionPayload> = {
      2: {
        step,
        totalSteps,
        stage,
        question: 'What is your current experience with full-stack web technologies?',
        options: [
          'Proficient with HTML, CSS, JavaScript/TypeScript fundamentals',
          'Built responsive frontends using React or Next.js',
          'Created REST APIs with Node.js/Express and connected a database',
          'Beginner eager to master complete modern full-stack web development',
        ],
        difficulty: 'Beginner',
        skillsTargeted: ['Full-Stack Fundamentals'],
        reason: 'Calibrates fullstack engineering baseline.',
      },
      3: {
        step,
        totalSteps,
        stage,
        question: 'Which layer of full-stack engineering do you enjoy building most?',
        options: [
          'Modern Frontend UI: Component design, smooth animations, and UX',
          'Scalable Backend: Server architecture, database schema, and APIs',
          'Full-Stack Integration: Connecting stateful UIs to robust APIs',
          'Cloud & DevOps: Containerization, CI/CD pipelines, and hosting',
        ],
        difficulty: 'Intermediate',
        skillsTargeted: ['Full-Stack Focus Area'],
        reason: 'Identifies student preference along the full-stack spectrum.',
      },
      4: {
        step,
        totalSteps,
        stage,
        question: 'Which frontend and backend stack combination do you prefer?',
        options: [
          'React / Next.js frontend with Node.js / Express & PostgreSQL backend',
          'Vue / Nuxt frontend with Python / FastAPI backend',
          'Flutter Web & Mobile frontend with Go backend',
          'Full TypeScript Stack with Prisma ORM and Tailwind CSS',
        ],
        difficulty: 'Intermediate',
        skillsTargeted: ['Tech Stack Selection'],
        reason: 'Validates preferred software technology stack.',
      },
      5: {
        step,
        totalSteps,
        stage,
        question: 'How do you ensure seamless state synchronization between the client UI and server database?',
        options: [
          'Use React Query / TanStack Query for automatic caching, refetching, and optimistic updates',
          'Redux Toolkit with async thunks and normalized entity state',
          'WebSockets for bi-directional live synchronization',
          'Simple fetch() calls inside useEffect with manual state loading indicators',
        ],
        difficulty: 'Intermediate',
        skillsTargeted: ['State Synchronization', 'TanStack Query'],
        reason: 'Tests practical client-server data synchronization knowledge.',
      },
      6: {
        step,
        totalSteps,
        stage,
        question: 'What is your primary full-stack engineering milestone this year?',
        options: [
          'Deploy a complete multi-user SaaS web product with stripe billing and auth',
          'Contribute significant features to a widely-used open-source web application',
          'Master advanced system design and scalable SQL indexing patterns',
          'Secure a Full-Stack Software Engineer placement at a top product firm',
        ],
        difficulty: 'Intermediate',
        skillsTargeted: ['SaaS Milestone', 'Career Placement'],
        reason: 'Clarifies primary milestone for semester curriculum.',
      },
      7: {
        step,
        totalSteps,
        stage,
        question: 'What learning format accelerates your full-stack development best?',
        options: [
          'Building full-stack projects incrementally with clean git commits',
          'Pair-programming walkthroughs dissecting production open-source repos',
          'Reading official documentation (MDN, React docs, Node.js specs)',
          'High-quality video courses accompanied by coding exercises',
        ],
        difficulty: 'Intermediate',
        skillsTargeted: ['Project-Driven Learning'],
        reason: 'Selects the most effective learning materials.',
      },
      8: {
        step,
        totalSteps,
        stage,
        question: 'What capstone full-stack product do you want to build and deploy?',
        options: [
          'Comprehensive Campus Marketplace with secure auth, listings, and chat',
          'Real-time Collaborative Code Editor with multi-user presence and execution',
          'AI-Powered Job & Internship Matcher with resume analysis and tracking',
          'Cloud Resource Monitoring Dashboard with live metrics and Slack alerts',
        ],
        difficulty: 'Advanced',
        skillsTargeted: ['Full-Stack Capstone'],
        reason: 'Establishes headline portfolio showcase project.',
      },
    };
    return qMap[step] || qMap[2];
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
    const domain = this.detectDomainFromHistory(params.history);
    const domainQuestion = this.getDomainQuestion(domain, params.step, params.totalSteps, params.stage);

    if (params.contradiction) {
      domainQuestion.reason = `Resolving contradiction: ${params.contradiction}`;
    }

    return domainQuestion;
  }

  private async generateCareerAnalysis(
    department: string,
    history: Array<{ question: string; answer: string }>,
    evidence: string[],
    contradictions: any[],
    preferredLanguage: string
  ): Promise<CareerAnalysisResult> {
    const domain = this.detectDomainFromHistory(history);

    if (domain === 'cybersecurity') {
      return {
        primaryDirection: {
          title: 'Cybersecurity & DevSecOps Engineer',
          fitPercentage: 95,
          description: 'Your strong orientation toward network security, vulnerability defense, and secure architecture makes you an ideal candidate for modern security operations and DevSecOps engineering.',
        },
        alternativePaths: [
          { title: 'SOC Analyst & Threat Hunter', fitPercentage: 86, description: 'Monitor enterprise telemetry, analyze security events, and investigate active intrusion attempts.' },
          { title: 'Application Security & Penetration Tester', fitPercentage: 81, description: 'Identify and remediate software vulnerabilities using ethical hacking methodologies.' },
          { title: 'Cloud Security Architect', fitPercentage: 76, description: 'Design secure, zero-trust cloud infrastructure on AWS and Azure.' },
        ],
        keyStrengths: ['Network Protocols & Linux Security', 'Vulnerability Assessment', 'Security Automation', 'Threat Modeling'],
        areasToImprove: ['SIEM Rule Engineering', 'Zero-Trust Architectures', 'Binary Analysis & Reverse Engineering'],
        skillGaps: ['OWASP Top 10 Remediation', 'Docker Security Hardening', 'Burp Suite Professional Suite'],
        learningStyle: 'Lab-driven Offensive & Defensive Prototyping',
        recommendedNextAction: 'Generate your personalized roadmap to begin with Linux Security & Network Defense foundations.',
        evidenceSummary: ['Demonstrated explicit dedication toward defensive and offensive security operations throughout discovery.'],
      };
    }

    if (domain === 'ai') {
      return {
        primaryDirection: {
          title: 'AI & Machine Learning Engineer',
          fitPercentage: 94,
          description: 'Your statistical and computational interests align strongly with training predictive models, orchestrating neural architectures, and deploying production generative AI systems.',
        },
        alternativePaths: [
          { title: 'Data Scientist & Analytics Engineer', fitPercentage: 87, description: 'Extract business insights and build statistical regression models from massive datasets.' },
          { title: 'Generative AI & LLM Solutions Architect', fitPercentage: 83, description: 'Build enterprise RAG pipelines, agentic workflows, and vector search systems.' },
          { title: 'Computer Vision Specialist', fitPercentage: 76, description: 'Engineer autonomous visual recognition and object detection models.' },
        ],
        keyStrengths: ['Statistical Reasoning', 'Python Data Stack (NumPy/Pandas)', 'Model Architecture Thinking', 'Analytical Problem Solving'],
        areasToImprove: ['Distributed Model Training (DeepSpeed/Ray)', 'Model Quantization & TensorRT', 'Production Inference Optimization'],
        skillGaps: ['FastAPI Production Serving', 'Vector Databases (Chroma/Pinecone)', 'RAG Pipeline Orchestration'],
        learningStyle: 'Code-first Interactive Notebook & Experiment-driven Learning',
        recommendedNextAction: 'Generate your personalized roadmap to begin with Python Data Science & ML Model foundations.',
        evidenceSummary: ['Verified continuous interest in machine learning algorithms, dataset analysis, and AI agent architectures.'],
      };
    }

    if (domain === 'mobile') {
      return {
        primaryDirection: {
          title: 'Cross-Platform Mobile Engineer',
          fitPercentage: 93,
          description: 'Your aptitude for responsive UI architecture, reactive state management, and fluid animations positions you for high-impact cross-platform mobile engineering.',
        },
        alternativePaths: [
          { title: 'Flutter & Dart Frontend Specialist', fitPercentage: 88, description: 'Build fluid, pixel-perfect user interfaces with custom animations.' },
          { title: 'Native Android Engineer (Kotlin)', fitPercentage: 79, description: 'Develop high-performance native Android applications with Jetpack Compose.' },
          { title: 'Full-Stack Mobile & Cloud Architect', fitPercentage: 75, description: 'Architect end-to-end mobile products backed by scalable cloud APIs.' },
        ],
        keyStrengths: ['Client UI Architecture', 'Reactive State Management (Riverpod)', 'Cross-Platform Optimization', 'Mobile UX Design'],
        areasToImprove: ['Native Platform Channels (Kotlin/Swift)', 'Offline Sync Conflict Resolution', 'Mobile CI/CD Automation'],
        skillGaps: ['Riverpod AsyncValue Pattern', 'SQLite / Hive Local Persistence', 'Custom RenderObjects & Slivers'],
        learningStyle: 'Interactive UI Prototyping & Visual Testing',
        recommendedNextAction: 'Generate your personalized roadmap to begin with Flutter UI & State Management foundations.',
        evidenceSummary: ['Consistent dedication toward cross-platform mobile applications verified across all turns.'],
      };
    }

    if (domain === 'backend') {
      return {
        primaryDirection: {
          title: 'Backend & Cloud Distributed Systems Engineer',
          fitPercentage: 94,
          description: 'Your focus on database transactions, microservice scalability, and server-side performance aligns directly with distributed backend systems engineering.',
        },
        alternativePaths: [
          { title: 'Cloud Architect & DevOps Engineer', fitPercentage: 86, description: 'Design automated, resilient cloud infrastructure on AWS and Kubernetes.' },
          { title: 'Database Reliability Engineer', fitPercentage: 80, description: 'Optimize high-throughput SQL databases, caching, and connection pooling.' },
          { title: 'High-Throughput API Architect', fitPercentage: 78, description: 'Build lightning-fast REST and gRPC services handling thousands of requests per second.' },
        ],
        keyStrengths: ['System Design Thinking', 'Relational & NoSQL Modeling', 'API Performance Optimization', 'Microservices Architecture'],
        areasToImprove: ['Distributed Consensus (Raft/Paxos)', 'Event-Driven Message Queues (Kafka)', 'Kubernetes Cluster Orchestration'],
        skillGaps: ['Redis Distributed Caching', 'Docker Container Hardening', 'PostgreSQL Query Index Tuning'],
        learningStyle: 'Architecture-driven Building & Benchmarking',
        recommendedNextAction: 'Generate your personalized roadmap to begin with RESTful API & Distributed Database foundations.',
        evidenceSummary: ['Strong backend orientation prioritizing high-throughput services and database scalability.'],
      };
    }

    if (domain === 'iot') {
      return {
        primaryDirection: {
          title: 'IoT & Embedded Systems Developer',
          fitPercentage: 93,
          description: 'Your background and expressed interests strongly align with IoT architecture, microcontroller firmware, and connected sensor systems.',
        },
        alternativePaths: [
          { title: 'Embedded Software Engineer', fitPercentage: 80, description: 'Direct firmware programming on bare-metal and RTOS platforms.' },
          { title: 'Robotics Developer', fitPercentage: 74, description: 'Autonomous motion control, sensor fusion, and actuator integration.' },
          { title: 'Firmware Engineer', fitPercentage: 70, description: 'Low-level device drivers and board bring-up programming.' },
        ],
        keyStrengths: ['Hardware/Software Interfacing', 'Problem Solving', 'Low-level C/C++', 'Willingness to Learn'],
        areasToImprove: ['Cyber-Physical Systems', 'FreeRTOS Concurrency', 'Hardware Debugging'],
        skillGaps: ['ESP32 & Arduino Architecture', 'MQTT Protocols', 'FreeRTOS Tasks'],
        learningStyle: 'Hands-on Practical & Hardware Prototyping',
        recommendedNextAction: 'Generate your personalized roadmap to begin with Microcontroller foundations.',
        evidenceSummary: ['Identified enthusiasm for sensor-driven embedded software and microcontrollers.'],
      };
    }

    // Default Full-Stack
    return {
      primaryDirection: {
        title: 'Modern Full-Stack Developer',
        fitPercentage: 92,
        description: 'Your problem solving aptitude and interest in end-to-end product development align with modern full stack software engineering.',
      },
      alternativePaths: [
        { title: 'Backend & Cloud Systems Engineer', fitPercentage: 84, description: 'Microservices, database scaling, and distributed APIs.' },
        { title: 'Frontend UI/UX Engineer', fitPercentage: 80, description: 'High performance web interfaces and reactive state management.' },
        { title: 'Cross-Platform Mobile Engineer', fitPercentage: 76, description: 'High performance client-side mobile development.' },
      ],
      keyStrengths: ['Logical Reasoning', 'Full-Stack Integration', 'Software Architecture', 'Continuous Learning'],
      areasToImprove: ['Distributed Systems', 'Database Optimization', 'Cloud CI/CD Pipelines'],
      skillGaps: ['Advanced SQL', 'Docker & Kubernetes', 'System Design'],
      learningStyle: 'Project-driven active learning',
      recommendedNextAction: 'Generate your personalized roadmap to begin with core API & frontend architecture.',
      evidenceSummary: ['Strong full-stack software development orientation verified across discovery turns.'],
    };
  }
}

export const careerPathfinderService = new CareerPathfinderService();
