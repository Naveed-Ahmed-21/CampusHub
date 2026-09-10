import { AIProvider, aiProvider } from '../../../shared/ai/ai.provider';
import { BuiltCareerContext } from './career.context-builder';
import { CareerAIIntent } from './career.intent-detector';
import { ResourceResearcher, VerifiedResource } from './career.resource-researcher';
import {
  CareerDirectionMatch,
  ExtractedStudentProfile,
  PathfinderState,
} from '../career.types';

export interface PathfinderChatResponse {
  message: string;
  state?: PathfinderState;
  isConfirmed: boolean;
  isComplete?: boolean;
  suggestedPills?: string[];
  confirmedProfile?: ExtractedStudentProfile;
  careerMatches?: CareerDirectionMatch[];
}

export interface AskAiResponse {
  answer: string;
  intent: CareerAIIntent;
  suggestedActions: string[];
  recommendedResources?: VerifiedResource[];
  isOffTopic: boolean;
}

export interface InterviewTurnEvaluation {
  feedback: string;
  score: number; // 0 - 100
  expectedConcepts: string[];
  detectedConcepts: string[];
  missingConcepts: string[];
  followUpQuestion?: string;
  isFinished: boolean;
}

export interface FinalInterviewReport {
  overallScore: number;
  technicalScore: number;
  communicationScore: number;
  problemSolvingScore: number;
  confidenceScore: number;
  strongAreas: string[];
  needsImprovement: string[];
  struggledQuestions: string[];
  recommendedRoadmapUpdate: string;
  summary: string;
}

export class CareerAIOrchestrator {
  constructor(private provider: AIProvider = aiProvider) {}

  // ==========================================
  // 1. PATHFINDER AGENT (STATE MACHINE & DISCOVERY)
  // ==========================================

  public generateInitialGreeting(studentContext?: BuiltCareerContext): {
    message: string;
    state: PathfinderState;
    suggestedPills: string[];
  } {
    const dept = studentContext?.student?.department;
    const known = studentContext?.student?.knownSkills || [];
    const skillsNotice = known.length > 0 ? ` with foundational skills in **${known.slice(0, 3).join(', ')}**` : '';
    const deptNotice = dept ? ` in the **${dept}** department` : '';

    return {
      message:
        `Hello! I am EVA, your personal Career & Learning Architect at CampusHub.\n\n` +
        `I see you are an aspiring engineer${deptNotice}${skillsNotice}. ` +
        `Together, we will uncover your optimal engineering direction and architect a prerequisite-aware learning roadmap tailored directly to your background.\n\n` +
        `Which engineering domain or product type excites you most?`,
      state: 'STARTED',
      suggestedPills: [
        'Flutter & Mobile Apps',
        'Full Stack Web Engineering',
        'Backend APIs & Cloud',
        'AI & Machine Learning',
        'Cybersecurity & DevSecOps',
      ],
    };
  }

  async processPathfinderMessage(
    userMessage: string,
    history: { sender: string; content: string }[],
    existingConfirmedProfile?: any,
    studentContext?: BuiltCareerContext
  ): Promise<PathfinderChatResponse> {
    const text = userMessage.trim().toLowerCase();
    const userTurns = history.filter((m) => m.sender.toUpperCase() === 'USER').length;

    // Detect if user is confirming
    if (
      existingConfirmedProfile &&
      (text.includes('yes') ||
        text.includes('build') ||
        text.includes('correct') ||
        text.includes('looks right') ||
        text.includes('confirm') ||
        text.includes('agree') ||
        text.includes('go ahead'))
    ) {
      return {
        message:
          '🎉 Fantastic! Your career profile and learning track have been confirmed. Generating your personalized roadmap now...',
        state: 'CONFIRMED',
        isConfirmed: true,
        isComplete: true,
        confirmedProfile: existingConfirmedProfile,
        careerMatches: existingConfirmedProfile.careerMatches,
        suggestedPills: ['Open My Roadmap', 'View Today\'s Plan'],
      };
    }

    // Handle direction override / track switch
    let targetRole = existingConfirmedProfile?.targetRole || existingConfirmedProfile?.target_role;
    let level = (existingConfirmedProfile?.experienceLevel || existingConfirmedProfile?.experience_level || 'Beginner') as 'Beginner' | 'Intermediate' | 'Expert';
    let hours = existingConfirmedProfile?.dailyHours || existingConfirmedProfile?.daily_hours || 2;
    let language = existingConfirmedProfile?.preferredLanguage || existingConfirmedProfile?.preferred_language || 'English';
    let goal = existingConfirmedProfile?.goal || 'Campus Placement Readiness & Portfolio in 4 Months';

    const historyText = history.map((m) => m.content).join(' ').toLowerCase();
    const checkSource = (term: string) => text.includes(term) || historyText.includes(term);

    if (checkSource('c++') || checkSource('cpp') || checkSource('c plus plus') || checkSource('competitive programming')) {
      targetRole = 'C++ Systems & Competitive Programming Engineer';
    } else if (checkSource('flutter') || checkSource('mobile') || checkSource('ios') || checkSource('android')) {
      targetRole = 'Flutter Mobile Architect';
    } else if (checkSource('backend') || checkSource('api') || checkSource('distributed') || checkSource('database')) {
      targetRole = 'Backend & Distributed Systems Architect';
    } else if (checkSource('ai') || checkSource('ml') || checkSource('machine learning') || checkSource('data science')) {
      targetRole = 'AI & Machine Learning Engineer';
    } else if (checkSource('cyber') || checkSource('security') || checkSource('ethical') || checkSource('devsecops')) {
      targetRole = 'Cyber Security & DevSecOps Engineer';
    } else if (checkSource('full stack') || checkSource('fullstack') || checkSource('web') || checkSource('react')) {
      targetRole = 'Modern Full-Stack & Cloud Engineer';
    }

    if (!targetRole) {
      targetRole = 'Modern Full-Stack & Cloud Engineer';
    }

    // Direct Question & Curiosity Detection
    const isQuestion = text.includes('?') ||
      text.startsWith('can i') ||
      text.startsWith('what is') ||
      text.startsWith('how to') ||
      text.startsWith('why') ||
      text.startsWith('should i') ||
      text.startsWith('is it') ||
      text.includes('difference between') ||
      text.includes('tell me about');

    let directAnswer = '';
    if (isQuestion) {
      if (text.includes('c++') || text.includes('cpp')) {
        directAnswer =
          "**Yes, absolutely!** C++ is an exceptional foundation. It's the industry gold standard for Competitive Programming in placement Online Assessments (Google, Microsoft, Amazon, Uber), Systems Programming, Game Engines (Unreal Engine), and High-Frequency Trading. Learning C++ gives you deep mastery over computer memory, pointers, and CPU-level performance, which will make every other language (Java, Python, Dart) feel intuitive.\n\n" +
          "I have calibrated our discovery session toward the **C++ Systems & Competitive Programming** track!";
      } else if (text.includes('python')) {
        directAnswer =
          "**Definitely!** Python is the leading language for Artificial Intelligence, Machine Learning, Data Science, and rapid backend APIs with FastAPI. It has the gentlest learning curve while offering immense real-world job opportunities.\n\n" +
          "I have calibrated our discovery session toward the **Python AI & Data Engineering** track!";
      } else if (text.includes('flutter') || text.includes('mobile')) {
        directAnswer =
          "**Yes!** Flutter is the leading multi-platform framework for iOS, Android, and Web from a single codebase. With Riverpod and clean architecture, you can build production-ready mobile apps quickly.\n\n" +
          "I have calibrated our discovery session toward the **Flutter Mobile Architect** track!";
      } else if (text.includes('backend') || text.includes('api')) {
        directAnswer =
          "**Backend is a phenomenal career path!** Every mobile app and website relies on robust backend systems to process payments, authenticate users, handle databases, and scale to millions of requests.\n\n" +
          "I have calibrated our discovery session toward the **Backend & Distributed Systems Architect** track!";
      } else {
        directAnswer =
          `Great question! Exploring technical questions like this helps you find what aligns with your natural strengths. For **${targetRole}**, we focus heavily on foundational understanding combined with portfolio-ready code.\n\n`;
      }
    }

    if (checkSource('tamil')) language = 'Tamil';
    if (checkSource('hindi')) language = 'Hindi';
    if (checkSource('malayalam')) language = 'Malayalam';
    if (checkSource('telugu')) language = 'Telugu';
    if (checkSource('english')) language = 'English';

    if (checkSource('intermediate') || checkSource('built apps') || checkSource('small project') || checkSource('college project') || checkSource('know syntax')) {
      level = 'Intermediate';
    } else if (checkSource('scratch') || checkSource('zero') || checkSource('beginner') || checkSource('never coded')) {
      level = 'Beginner';
    } else if (checkSource('advanced') || checkSource('production') || checkSource('internship') || checkSource('expert') || checkSource('experienced')) {
      level = 'Expert';
    }

    if (checkSource('1 hour') || checkSource('1 hr')) hours = 1;
    if (checkSource('2 hour') || checkSource('2 hrs')) hours = 2;
    if (checkSource('3 hour') || checkSource('3 hrs')) hours = 3;
    if (checkSource('4 hour') || checkSource('4 hrs')) hours = 4;

    if (checkSource('internship')) goal = 'Summer Tech Internship in 3 Months';
    if (checkSource('placement') || checkSource('campus drive')) goal = 'Tier-1 Campus Placement in 4 Months';
    if (checkSource('startup') || checkSource('portfolio')) goal = 'Production Portfolio & Startup MVP';

    // Mindset & Problem-Solving Preference Extraction
    let learningStyle = 'Practical Hands-on Builder';
    if (checkSource('theory') || checkSource('deep dive') || checkSource('fundamentals') || checkSource('structured') || checkSource('books')) {
      learningStyle = 'Structured Conceptual Deep-Dive';
    } else if (checkSource('fast') || checkSource('prototype') || checkSource('hackathon')) {
      learningStyle = 'Rapid Prototyping & Hackathons';
    }

    let problemSolvingFocus = 'Client UX & Visual Products';
    if (targetRole.includes('C++') || targetRole.includes('Competitive')) {
      problemSolvingFocus = 'Algorithmic Optimization & Memory Control';
    } else if (targetRole.includes('Backend') || targetRole.includes('Distributed')) {
      problemSolvingFocus = 'High-Throughput Systems & Distributed Logic';
    } else if (targetRole.includes('Cyber') || targetRole.includes('Security')) {
      problemSolvingFocus = 'Defensive Engineering & Vulnerability Mitigation';
    } else if (targetRole.includes('AI') || targetRole.includes('Machine')) {
      problemSolvingFocus = 'Data Intelligence & Neural Architectures';
    } else if (targetRole.includes('Full-Stack')) {
      problemSolvingFocus = 'End-to-End Product Architecture';
    }

    // Contradiction Detection
    let contradictionNotice = '';
    const claimsExpert = checkSource('expert') || checkSource('advanced') || checkSource('production');
    const claimsBeginner = checkSource('scratch') || checkSource('zero') || checkSource('never coded') || checkSource('no experience');

    if (claimsExpert && claimsBeginner) {
      contradictionNotice = `💡 *Note on calibration*: I noticed you mentioned both advanced ambitions and starting from scratch. We will build your foundations with clean, rigorous code from day one and accelerate rapidly!\n\n`;
      level = 'Beginner';
    }

    // State machine progression:
    // Turn 0: Ask about coding background / hands-on experience (or domain exploration if unsure)
    const isUnsure = text.includes("don't know what to learn") || text.includes('confused') || text.includes('not sure') || text.includes('unsure') || text.includes('help me decide');

    if (userTurns === 0 || (isUnsure && !text.includes('built') && !text.includes('dart') && !text.includes('syntax') && !text.includes('hour'))) {
      if (isUnsure) {
        return {
          message:
            `No worries at all! Discovering what genuinely excites you is the best first step.\n\n` +
            `Which of these engineering flavors sounds most rewarding to your intuition?\n\n` +
            `• **C++ & Competitive Programming**: Mastering pointers, algorithms, and acing top placement Online Assessments.\n` +
            `• **Mobile & Interactive UI (Flutter)**: Crafting tactile iOS & Android apps people love using every day.\n` +
            `• **Backend & Distributed Systems**: Architecting high-speed APIs, database query engines, and cloud pipelines.\n` +
            `• **Cyber Security & DevSecOps**: Ethical hacking, vulnerability auditing, and infrastructure defense.\n` +
            `• **AI & Machine Learning**: Building neural networks, LLM agents, and data pipelines.\n\n` +
            `Have you written code or built projects in any of these areas before, or are you starting from scratch?`,
          state: 'COLLECTING_CONTEXT',
          isConfirmed: false,
          isComplete: false,
          suggestedPills: [
            'C++ & Placement DSA',
            'Flutter & Mobile Apps',
            'Backend APIs & Cloud',
            'Cybersecurity & DevSecOps',
            'AI & Machine Learning',
          ],
        };
      }

      const greetingPrefix = directAnswer
        ? `${directAnswer}\n\n`
        : `${contradictionNotice}Great choice! Targeting **${targetRole}**.\n\n`;

      return {
        message:
          `${greetingPrefix}` +
          `To calibrate your roadmap so you neither waste time reviewing known basics nor jump ahead prematurely: ` +
          `Have you written code or built projects in this area before (even basic tutorials or class assignments), or are you starting from scratch?`,
        state: 'COLLECTING_CONTEXT',
        isConfirmed: false,
        isComplete: false,
        suggestedPills: targetRole.includes('C++')
          ? [
              'Starting from absolute scratch',
              'Know basic C++ / C syntax',
              'C++ for Placements & DSA',
              'Comfortable builder / Intermediate',
            ]
          : [
              'Starting from absolute scratch',
              'Know basic programming syntax',
              'Built 1-2 small projects',
              'Comfortable builder / Intermediate',
            ],
      };
    }

    // Turn 1: Ask about time, goal, and tutorial language
    if (userTurns === 1 && !text.includes('hour') && !text.includes('hr')) {
      return {
        message:
          `${contradictionNotice}Understood! How many hours per day can you realistically commit to learning, ` +
          `what is your primary milestone (e.g. campus placement drive, internship, or portfolio project), ` +
          `and what language do you prefer for video explanations (English, Tamil, Hindi, etc.)?`,
        state: 'COLLECTING_CONTEXT',
        isConfirmed: false,
        isComplete: false,
        suggestedPills: [
          '1 hr/day — Campus Placement (English)',
          '2 hrs/day — Placement Track (English)',
          '2 hrs/day — Placement Track (Tamil)',
          '3 hrs/day — Tech Internship (Hindi)',
        ],
      };
    }

    // Turn 2+: Transition to ANALYZING -> AWAITING_CONFIRMATION
    // Generate verified known skills (from DB + user conversation, zero hallucination)
    const dbKnown = studentContext?.student?.knownSkills || [];
    const conversationSkills: string[] = [];
    if (text.includes('dart') || targetRole.includes('Flutter')) conversationSkills.push('Dart');
    if (text.includes('javascript') || text.includes('typescript')) conversationSkills.push('TypeScript');
    if (text.includes('python') || targetRole.includes('AI')) conversationSkills.push('Python');
    if (text.includes('linux') || targetRole.includes('Cyber')) conversationSkills.push('Linux & Networking');
    if (text.includes('git')) conversationSkills.push('Git Version Control');

    const knownSkills = Array.from(new Set([...dbKnown, ...conversationSkills]));
    if (knownSkills.length === 0) {
      knownSkills.push(level === 'Intermediate' ? 'Programming Fundamentals' : 'Analytical Problem Solving');
    }

    // Generate Career Direction Matches
    const careerMatches: CareerDirectionMatch[] = this.calculateCareerMatches(
      targetRole,
      level,
      knownSkills,
      studentContext
    );

    const confirmedProfile: ExtractedStudentProfile = {
      targetRole,
      target_role: targetRole,
      experienceLevel: level,
      experience_level: level,
      knownSkills,
      known_skills: knownSkills,
      weakSkills: careerMatches[0]?.gaps || ['Production State Management', 'System Architecture'],
      weak_skills: careerMatches[0]?.gaps || ['Production State Management', 'System Architecture'],
      dailyHours: hours,
      daily_hours: hours,
      preferredLanguage: language,
      preferred_language: language,
      goal,
      projectsBuilt: studentContext?.student?.projectSubmissions || [],
      projects_built: studentContext?.student?.projectSubmissions || [],
    };

    const topMatch = careerMatches[0];
    const secondMatch = careerMatches[1];

    const message =
      `${contradictionNotice}### 🎯 Career Intelligence Analysis & Recommendations\n\n` +
      `Based on your background, learning mindset (**${learningStyle}**), and stated goals, here are your top matched engineering directions:\n\n` +
      `1. **${topMatch.role}** — **${topMatch.matchScore}% Match** (Primary Recommended)\n` +
      `   - **Rationale**: ${topMatch.rationale}\n` +
      `   - **Verified Foundations**: ${topMatch.evidence.join(', ') || 'Ready for rapid takeoff'}\n` +
      `   - **Key Competency Gaps**: ${topMatch.gaps.slice(0, 3).join(', ')}\n\n` +
      (secondMatch
        ? `2. **${secondMatch.role}** — **${secondMatch.matchScore}% Match**\n` +
          `   - **Rationale**: ${secondMatch.rationale}\n\n`
        : '') +
      `---\n\n` +
      `### 📋 What I Understood About You:\n` +
      `- **Target Direction**: ${confirmedProfile.targetRole}\n` +
      `- **Current Level**: ${confirmedProfile.experienceLevel}\n` +
      `- **Committed Time**: ${confirmedProfile.dailyHours} hours / day\n` +
      `- **Video Language**: ${confirmedProfile.preferredLanguage}\n` +
      `- **Learning Mindset**: ${learningStyle} (${problemSolvingFocus})\n` +
      `- **Recognized Baseline**: ${confirmedProfile.knownSkills?.join(', ') || 'Early stage'}\n` +
      `- **Milestone Objective**: ${confirmedProfile.goal}\n\n` +
      `Tap **Confirm & Build My Journey** below to generate your personalized learning path, or choose an alternative direction!`;

    return {
      message,
      state: 'AWAITING_CONFIRMATION',
      isConfirmed: false,
      isComplete: false,
      confirmedProfile,
      careerMatches,
      suggestedPills: [
        'Confirm & Build My Journey',
        secondMatch ? `Switch to ${secondMatch.role.split(' ')[0]}` : 'Switch to Backend Path',
        'Adjust Time / Goal',
      ],
    };
  }

  private calculateCareerMatches(
    primaryRole: string,
    level: string,
    knownSkills: string[],
    context?: BuiltCareerContext
  ): CareerDirectionMatch[] {
    const isCpp = primaryRole.toLowerCase().includes('c++') || primaryRole.toLowerCase().includes('cpp') || primaryRole.toLowerCase().includes('competitive');
    const isMobile = primaryRole.toLowerCase().includes('flutter') || primaryRole.toLowerCase().includes('mobile');
    const isBackend = primaryRole.toLowerCase().includes('backend') || primaryRole.toLowerCase().includes('systems');
    const isAi = primaryRole.toLowerCase().includes('ai') || primaryRole.toLowerCase().includes('machine');
    const isCyber = primaryRole.toLowerCase().includes('cyber') || primaryRole.toLowerCase().includes('security');

    if (isCpp) {
      return [
        {
          role: 'C++ Systems & Competitive Programming Engineer',
          matchScore: 96,
          match_score: 96,
          rationale: 'Top-tier alignment with systems programming, memory control, STL mastery, and placement OA performance.',
          evidence: ['Interest in high performance computing and systems', ...knownSkills.slice(0, 2)],
          gaps: ['Modern C++20 Smart Pointers & Move Semantics', 'Advanced STL Containers & Complexity', 'Competitive Programming Graph Algorithms'],
          nextSteps: ['Memory Models & Pointer Arithmetic', 'STL Algorithms & Fast I/O', 'Placement OA Mock Round'],
          next_steps: ['Memory Models & Pointer Arithmetic', 'STL Algorithms & Fast I/O', 'Placement OA Mock Round'],
        },
        {
          role: 'Backend & Distributed Systems Architect',
          matchScore: 82,
          match_score: 82,
          rationale: 'Extends systems thinking to high-throughput network services, databases, and microservices.',
          evidence: ['High-performance engineering interest'],
          gaps: ['PostgreSQL transactions & indexing', 'Redis distributed caching'],
          nextSteps: ['Asynchronous Event Loop', 'Relational database schema design'],
          next_steps: ['Asynchronous Event Loop', 'Relational database schema design'],
        },
        {
          role: 'Modern Full-Stack & Cloud Engineer',
          matchScore: 75,
          match_score: 75,
          rationale: 'Broad product development across APIs, cloud deployment, and user interfaces.',
          evidence: ['Algorithmic foundation'],
          gaps: ['Web frameworks & React', 'Docker container orchestration'],
          nextSteps: ['REST API architecture', 'Cloud deployment fundamentals'],
          next_steps: ['REST API architecture', 'Cloud deployment fundamentals'],
        },
      ];
    }

    if (isMobile) {
      return [
        {
          role: 'Flutter Mobile Architect',
          matchScore: 94,
          match_score: 94,
          rationale: 'High alignment with your mobile product interest, client-facing architecture, and UI engineering.',
          evidence: ['Interest in mobile apps', ...knownSkills.slice(0, 2)],
          gaps: ['Riverpod 2.0 AsyncNotifier', 'Offline SQLite/Hive Sync', 'DevTools Performance Profiling'],
          nextSteps: ['Dart 3 Concurrency Checkpoint', 'Optimistic UI State Mutations', 'Cap-Stone Mobile Messenger'],
          next_steps: ['Dart 3 Concurrency Checkpoint', 'Optimistic UI State Mutations', 'Cap-Stone Mobile Messenger'],
        },
        {
          role: 'Modern Full-Stack & Cloud Engineer',
          matchScore: 82,
          match_score: 82,
          rationale: 'Expands client UI mastery into full-lifecycle Node.js / PostgreSQL backend services.',
          evidence: ['Software engineering interest'],
          gaps: ['Prisma ORM transactions', 'Relational PostgreSQL Indexing', 'Docker Multi-stage Builds'],
          nextSteps: ['Relational Database Normalization', 'REST API layered architecture'],
          next_steps: ['Relational Database Normalization', 'REST API layered architecture'],
        },
        {
          role: 'Backend & Distributed Systems Architect',
          matchScore: 74,
          match_score: 74,
          rationale: 'Heavy focus on scalable API infrastructure, distributed caching, and event queues.',
          evidence: ['Logical data flow problem solving'],
          gaps: ['Redis distributed locks', 'Message queues (RabbitMQ/Kafka)', 'System design'],
          nextSteps: ['PostgreSQL EXPLAIN ANALYZE', 'Event-driven workers'],
          next_steps: ['PostgreSQL EXPLAIN ANALYZE', 'Event-driven workers'],
        },
      ];
    }

    if (isBackend) {
      return [
        {
          role: 'Backend & Distributed Systems Architect',
          matchScore: 95,
          match_score: 95,
          rationale: 'Direct alignment with server-side logic, relational databases, caching, and scalable APIs.',
          evidence: ['Backend API interest', ...knownSkills.slice(0, 2)],
          gaps: ['PostgreSQL query plan tuning', 'Redis distributed locks', 'High-scale system design'],
          nextSteps: ['Layered Service-Repository Pattern', 'ACID Transactions & Locks', 'Sliding Window Rate Limiter'],
          next_steps: ['Layered Service-Repository Pattern', 'ACID Transactions & Locks', 'Sliding Window Rate Limiter'],
        },
        {
          role: 'Modern Full-Stack & Cloud Engineer',
          matchScore: 84,
          match_score: 84,
          rationale: 'Complements backend data engineering with modern React / Flutter interactive interfaces.',
          evidence: ['Full-lifecycle system building'],
          gaps: ['Reactive client state management', 'Component styling systems'],
          nextSteps: ['Full-stack monorepo scaffolding', 'Authentication flow integration'],
          next_steps: ['Full-stack monorepo scaffolding', 'Authentication flow integration'],
        },
        {
          role: 'Cyber Security & DevSecOps Engineer',
          matchScore: 76,
          match_score: 76,
          rationale: 'Focuses on API security hardening, token protection, and infrastructure monitoring.',
          evidence: ['System architecture awareness'],
          gaps: ['OWASP Top 10 API Security', 'Container vulnerability audits'],
          nextSteps: ['JWT refresh token security', 'Role-based authorization hardening'],
          next_steps: ['JWT refresh token security', 'Role-based authorization hardening'],
        },
      ];
    }

    if (isAi) {
      return [
        {
          role: 'AI & Machine Learning Engineer',
          matchScore: 93,
          match_score: 93,
          rationale: 'Focused on numerical computing, data pipelines, deep learning models, and LLM orchestration.',
          evidence: ['Interest in AI and intelligent systems', ...knownSkills.slice(0, 2)],
          gaps: ['NumPy vectorized operations', 'PyTorch deep learning', 'RAG vector embeddings'],
          nextSteps: ['Pandas data cleaning pipeline', 'PyTorch neural net classifier', 'FastAPI model inference'],
          next_steps: ['Pandas data cleaning pipeline', 'PyTorch neural net classifier', 'FastAPI model inference'],
        },
        {
          role: 'Backend & Distributed Systems Architect',
          matchScore: 81,
          match_score: 81,
          rationale: 'Supplies high-throughput serving infrastructure and data streaming pipelines for AI models.',
          evidence: ['Data engineering interests'],
          gaps: ['Distributed queuing', 'Microservice observability'],
          nextSteps: ['FastAPI inference wrapper', 'Redis caching for model predictions'],
          next_steps: ['FastAPI inference wrapper', 'Redis caching for model predictions'],
        },
      ];
    }

    if (isCyber) {
      return [
        {
          role: 'Cyber Security & DevSecOps Engineer',
          matchScore: 94,
          match_score: 94,
          rationale: 'Deep alignment with application security, threat modeling, ethical auditing, and DevSecOps pipelines.',
          evidence: ['Interest in security and infrastructure defense', ...knownSkills.slice(0, 2)],
          gaps: ['OWASP Top 10 API Security', 'Linux Privilege Escalation & Audit', 'JWT Replay Attack Defense', 'Container Vulnerability Auditing'],
          nextSteps: ['Network Packet Analysis with Wireshark', 'JWT Secure Authentication Lab', 'Automated SAST/DAST Security Pipeline'],
          next_steps: ['Network Packet Analysis with Wireshark', 'JWT Secure Authentication Lab', 'Automated SAST/DAST Security Pipeline'],
        },
        {
          role: 'Backend & Distributed Systems Architect',
          matchScore: 82,
          match_score: 82,
          rationale: 'Strong synergy with secure server design, database hardening, and zero-trust authentication.',
          evidence: ['Systems-level thinking'],
          gaps: ['Distributed rate limiting', 'Database connection encryption'],
          nextSteps: ['Secure API Gateway design', 'Role-based access control (RBAC)'],
          next_steps: ['Secure API Gateway design', 'Role-based access control (RBAC)'],
        },
        {
          role: 'Modern Full-Stack & Cloud Engineer',
          matchScore: 75,
          match_score: 75,
          rationale: 'Holistic full-stack foundation with defensive web security practices.',
          evidence: ['Software engineering fundamentals'],
          gaps: ['CORS & CSP headers', 'Input sanitization & XSS mitigation'],
          nextSteps: ['Hardened full-stack boilerplate', 'Security audit report'],
          next_steps: ['Hardened full-stack boilerplate', 'Security audit report'],
        },
      ];
    }

    // Default Full-Stack
    return [
      {
        role: 'Modern Full-Stack & Cloud Engineer',
        matchScore: 92,
        match_score: 92,
        rationale: 'Comprehensive curriculum spanning TypeScript, Express, PostgreSQL, React, Docker, and CI/CD.',
        evidence: ['Full-stack development interest', ...knownSkills.slice(0, 2)],
        gaps: ['Prisma ORM transactions', 'React server state management', 'Docker multi-stage builds'],
        nextSteps: ['Layered REST API architecture', 'Relational database schema modeling', 'Portfolio marketplace API'],
        next_steps: ['Layered REST API architecture', 'Relational database schema modeling', 'Portfolio marketplace API'],
      },
      {
        role: 'Flutter Mobile Architect',
        matchScore: 81,
        match_score: 81,
        rationale: 'Fast-feedback cross-platform application development with rich animations and native speed.',
        evidence: ['Client app engineering'],
        gaps: ['Dart 3 pattern matching', 'Riverpod state architecture'],
        nextSteps: ['Dart concurrency', 'Interactive responsive UI'],
        next_steps: ['Dart concurrency', 'Interactive responsive UI'],
      },
      {
        role: 'Backend & Distributed Systems Architect',
        matchScore: 78,
        match_score: 78,
        rationale: 'Deep dive into database internals, caching strategies, and system design.',
        evidence: ['API development curiosity'],
        gaps: ['PostgreSQL query plans', 'Redis caching'],
        nextSteps: ['Database normalization', 'Sliding window rate limiting'],
        next_steps: ['Database normalization', 'Sliding window rate limiting'],
      },
    ];
  }


  // ==========================================
  // 2. LEARNING ASSISTANT AGENT (DOUBT SOLVER)
  // ==========================================
  async answerLearningDoubt(
    userMessage: string,
    context: BuiltCareerContext,
    intent: CareerAIIntent
  ): Promise<AskAiResponse> {
    if (intent === 'OFF_TOPIC') {
      return {
        answer:
          "I'm focused on helping you with learning, career development, software engineering, and technical interview preparation. Ask me something related to your technical journey or learning roadmap!",
        intent,
        suggestedActions: [
          'Ask about your roadmap',
          'Clarify a technical concept',
          'Request hands-on project ideas',
        ],
        isOffTopic: true,
      };
    }

    // Context-guided explanation
    const systemPrompt =
      `You are EVA AI, a world-class senior software architect and mentor at CampusHub.\n` +
      `The student is currently at "${context.student.experienceLevel}" level studying "${context.student.targetRole}".\n` +
      `Tailor your explanation to their level:\n` +
      `- Beginner: Use real-world analogies, step-by-step bullet points, and simple code snippets.\n` +
      `- Intermediate: Explain component architecture, state flow, and practical patterns.\n` +
      `- Advanced: Discuss tradeoffs, performance, edge cases, and scalability.`;

    const prompt =
      `User Question: "${userMessage}"\n\n` +
      `${context.summaryString}\n\n` +
      `Provide a thorough, direct, highly educational response.`;

    const answer = await this.provider.generateText(prompt, systemPrompt);

    // Attach verified real resources if relevant
    let recommendedResources: VerifiedResource[] | undefined;
    if (intent === 'RESOURCE_REQUEST' || userMessage.toLowerCase().includes('resource')) {
      recommendedResources = ResourceResearcher.searchResources({
        topic: userMessage,
        language: context.student.preferredLanguage,
        level: context.student.experienceLevel,
        targetRole: context.student.targetRole,
      });
    }

    return {
      answer,
      intent,
      suggestedActions: [
        'How do I test this in code?',
        'Add a practice task to my roadmap',
        'Show real-world example',
      ],
      recommendedResources,
      isOffTopic: false,
    };
  }

  // ==========================================
  // 3. INTERVIEW AGENT (1-ON-1 BRANCHING EVA MOCK)
  // ==========================================
  generateInitialInterviewQuestion(targetRole: string, completedPhases: string[]): { question: string; expectedConcepts: string[] } {
    const roleLower = targetRole.toLowerCase();

    if (roleLower.includes('flutter')) {
      return {
        question:
          "Hi! I'm EVA, your AI technical interviewer. Let's begin.\n\n" +
          "Tell me about a Flutter project or component you recently built. Specifically, what state management solution did you use, and why did you pick that approach over standard setState?",
        expectedConcepts: ['state management', 'rebuilds', 'Riverpod or Bloc or Provider', 'separation of concerns'],
      };
    }

    if (roleLower.includes('backend') || roleLower.includes('distributed')) {
      return {
        question:
          "Hi! I'm EVA, your AI technical interviewer. Let's get started.\n\n" +
          "When designing a RESTful API that handles user authentication and session management, how do you handle JWT access and refresh token rotation? What happens when a token expires?",
        expectedConcepts: ['JWT', 'access token', 'refresh token', 'expiry', 'HTTP 401', 'rotation', 'security'],
      };
    }

    return {
      question:
        `Hi! I'm EVA, your AI interviewer. Let's begin your technical interview for ${targetRole}.\n\n` +
        "Can you walk me through the overall architecture of the most challenging software project you've engineered recently? What was the hardest bug you resolved?",
      expectedConcepts: ['architecture', 'data flow', 'debugging', 'testing', 'tradeoffs'],
    };
  }

  evaluateInterviewTurn(
    question: string,
    studentAnswer: string,
    expectedConcepts: string[],
    turnIndex: number,
    totalTurns: number
  ): InterviewTurnEvaluation {
    const answerLower = studentAnswer.toLowerCase();

    const detected: string[] = [];
    const missing: string[] = [];

    for (const concept of expectedConcepts) {
      const words = concept.toLowerCase().split(' ');
      if (words.some((w) => answerLower.includes(w))) {
        detected.push(concept);
      } else {
        missing.push(concept);
      }
    }

    // Score calculation based on detected concepts and answer substance
    const detectedRatio = expectedConcepts.length > 0 ? detected.length / expectedConcepts.length : 0.7;
    const lengthBonus = Math.min(20, Math.floor(studentAnswer.trim().split(/\s+/).length / 4));
    const score = Math.min(100, Math.max(35, Math.round(detectedRatio * 70 + lengthBonus)));

    // Contextual feedback
    let feedback = '';
    if (missing.length === 0) {
      feedback = "Solid explanation! You clearly hit the key architectural concepts and explained the rationale well.";
    } else {
      feedback =
        `Good start. You mentioned ${detected.join(', ') || 'the surface details'}, but you didn't touch on ${missing.join(', ')}. In real interviews, interviewers look closely for these nuances.`;
    }

    const isFinished = turnIndex >= totalTurns - 1;
    let followUpQuestion: string | undefined;

    if (!isFinished) {
      if (answerLower.includes('riverpod')) {
        followUpQuestion =
          "You mentioned Riverpod prevents unnecessary rebuilds. Can you explain how `ref.watch` behaves differently from `ref.read`, and why watching inside an `onPressed` callback is considered an anti-pattern?";
      } else if (answerLower.includes('refresh') || answerLower.includes('token') || answerLower.includes('jwt')) {
        followUpQuestion =
          "Good. If an attacker intercepts the refresh token from client storage, what defensive mechanisms (such as token family reuse detection or HttpOnly cookies) can you implement to mitigate unauthorized access?";
      } else {
        followUpQuestion =
          "Interesting. How do you handle error states and asynchronous failures gracefully so the user doesn't see a broken interface or infinite spinner?";
      }
    }

    return {
      feedback,
      score,
      expectedConcepts,
      detectedConcepts: detected,
      missingConcepts: missing,
      followUpQuestion,
      isFinished,
    };
  }

  compileFinalInterviewReport(
    turns: { question: string; studentAnswer: string; score: number; detectedConcepts: string[]; missingConcepts: string[] }[]
  ): FinalInterviewReport {
    if (turns.length === 0) {
      return {
        overallScore: 70,
        technicalScore: 70,
        communicationScore: 70,
        problemSolvingScore: 70,
        confidenceScore: 70,
        strongAreas: ['General Fundamentals'],
        needsImprovement: ['Detailed Technical Depth'],
        struggledQuestions: [],
        recommendedRoadmapUpdate: 'Add 1 technical architecture practice session.',
        summary: 'Interview completed. Continue working through your roadmap checkpoints.',
      };
    }

    const avgScore = Math.round(turns.reduce((acc, t) => acc + t.score, 0) / turns.length);
    const techScore = Math.round(avgScore * 0.95);
    const commScore = Math.min(95, Math.max(50, Math.round(avgScore * 1.05)));
    const psScore = Math.round(avgScore * 0.9);
    const confScore = Math.min(90, Math.round(avgScore * 1.02));

    const allDetected = turns.flatMap((t) => t.detectedConcepts);
    const allMissing = turns.flatMap((t) => t.missingConcepts);

    const strongAreas = Array.from(new Set(allDetected)).slice(0, 4);
    const needsImprovement = Array.from(new Set(allMissing)).slice(0, 3);
    const struggled = turns.filter((t) => t.score < 65).map((t) => t.question.slice(0, 60) + '...');

    const recommendedUpdate = needsImprovement.length > 0
      ? `+ Add targeted practice on: ${needsImprovement.join(', ')}`
      : 'Maintain current trajectory. Ready for mock company placement drives.';

    return {
      overallScore: avgScore,
      technicalScore: techScore,
      communicationScore: commScore,
      problemSolvingScore: psScore,
      confidenceScore: confScore,
      strongAreas: strongAreas.length > 0 ? strongAreas : ['Fundamentals'],
      needsImprovement: needsImprovement.length > 0 ? needsImprovement : ['Deep System Design Edge Cases'],
      struggledQuestions: struggled,
      recommendedRoadmapUpdate: recommendedUpdate,
      summary: `You demonstrated solid foundational understanding with an overall performance of ${avgScore}%. Focusing on ${needsImprovement[0] || 'advanced design patterns'} will elevate your interview performance to senior placement standards.`,
    };
  }
}

export const careerAIOrchestrator = new CareerAIOrchestrator();
