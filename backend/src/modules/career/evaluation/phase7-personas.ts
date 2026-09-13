export interface StudentPersona {
  id: string;
  name: string;
  department: string;
  background: {
    programmingExperience: string;
    knownSkills: string[];
    weaknesses: string[];
    interest: string;
    learningStyle: string;
    hoursPerDay: number;
    goal: string;
  };
  pathfinderAnswers: Array<{
    turn: number;
    questionContext: string;
    answer: string;
    isContradiction?: boolean;
    resolvesContradiction?: boolean;
  }>;
  expectedOutcomes: {
    topRoles: string[];
    avoidRoles: string[];
    expectedGaps: string[];
    shouldFlagContradiction: boolean;
    startLevel: 'Beginner' | 'Intermediate' | 'Advanced';
  };
}

export const PHASE7_STUDENT_PERSONAS: Record<string, StudentPersona> = {
  PERSONA_A: {
    id: 'persona_a_mobile',
    name: 'Persona A — Beginner Mobile Developer',
    department: 'Information Technology',
    background: {
      programmingExperience: 'Beginner to Intermediate Dart and basic OOP concepts',
      knownSkills: ['Dart Basics', 'Basic Flutter Widgets', 'Stateless/Stateful Widgets'],
      weaknesses: ['Data Structures & Algorithms', 'Backend & Cloud APIs', 'Complex State Management'],
      interest: 'Cross-platform mobile applications for Android & iOS',
      learningStyle: 'Practical, project-driven learning with interactive UI code',
      hoursPerDay: 2,
      goal: 'Build interactive mobile apps and secure a junior mobile developer role',
    },
    pathfinderAnswers: [
      {
        turn: 1,
        questionContext: 'Primary engineering interest',
        answer: 'Cross-Platform Mobile Apps with Flutter & Dart',
      },
      {
        turn: 2,
        questionContext: 'Current mobile experience',
        answer: 'Built small calculator and todo apps using setState, know basic Dart syntax',
      },
      {
        turn: 3,
        questionContext: 'Architectural state management',
        answer: 'Looking to learn Riverpod or Bloc for structured mobile architecture',
      },
      {
        turn: 4,
        questionContext: 'Data structures and backend knowledge',
        answer: 'Very beginner in DSA and basic REST API consumption, want to improve',
      },
    ],
    expectedOutcomes: {
      topRoles: ['Cross-Platform Mobile Engineer', 'Flutter Mobile Architect', 'Mobile Application Developer'],
      avoidRoles: ['DevOps & Cloud Architect', 'Embedded Firmware Engineer'],
      expectedGaps: ['Riverpod State Management', 'Local SQLite Persistence', 'REST API Integration'],
      shouldFlagContradiction: false,
      startLevel: 'Beginner',
    },
  },

  PERSONA_B: {
    id: 'persona_b_backend',
    name: 'Persona B — Backend-Oriented Student',
    department: 'Computer Science & Engineering',
    background: {
      programmingExperience: 'Comfortable with JavaScript/TypeScript, Node.js, and Express',
      knownSkills: ['Node.js', 'Express.js', 'PostgreSQL', 'RESTful API Design', 'Git'],
      weaknesses: ['Frontend UI Frameworks', 'CSS Layouts', 'Distributed System Design'],
      interest: 'Scalable backend services, databases, and microservice APIs',
      learningStyle: 'Hands-on architectural coding and database optimization',
      hoursPerDay: 3,
      goal: 'Become a Backend Systems Engineer at a high-scale product company',
    },
    pathfinderAnswers: [
      {
        turn: 1,
        questionContext: 'Primary engineering interest',
        answer: 'Distributed Backend Architecture & High Scale APIs',
      },
      {
        turn: 2,
        questionContext: 'Current backend stack',
        answer: 'Comfortable building REST APIs with Node.js, Express, and PostgreSQL with Prisma',
      },
      {
        turn: 3,
        questionContext: 'Database scaling experience',
        answer: 'Handled relational joins and indexes, want to learn Redis caching and message queues',
      },
      {
        turn: 4,
        questionContext: 'Target engineering milestone',
        answer: 'Architect high-throughput microservices handling concurrent traffic and placement interview prep',
      },
    ],
    expectedOutcomes: {
      topRoles: ['Backend & Cloud Architect', 'Distributed Backend Engineer', 'API Platform Engineer'],
      avoidRoles: ['Frontend UI Designer', 'Mobile iOS Developer'],
      expectedGaps: ['Redis In-Memory Caching', 'Message Queues (RabbitMQ/Kafka)', 'Microservice Concurrency'],
      shouldFlagContradiction: false,
      startLevel: 'Intermediate',
    },
  },

  PERSONA_C: {
    id: 'persona_c_fullstack',
    name: 'Persona C — Full-Stack Student',
    department: 'Computer Science & Engineering',
    background: {
      programmingExperience: 'Built end-to-end applications using MERN / PERN stack',
      knownSkills: ['React', 'Node.js', 'Express', 'MongoDB', 'PostgreSQL', 'Basic Docker'],
      weaknesses: ['Automated End-to-End Testing', 'Advanced System Design', 'CI/CD Pipelines'],
      interest: 'Full-stack web application development and cloud deployment',
      learningStyle: 'Full lifecycle project development from database to interactive UI',
      hoursPerDay: 3,
      goal: 'Secure a Full Stack Developer campus placement in a top product tier company',
    },
    pathfinderAnswers: [
      {
        turn: 1,
        questionContext: 'Primary engineering interest',
        answer: 'Full-Stack Web Engineering (React, Node.js & Cloud)',
      },
      {
        turn: 2,
        questionContext: 'Frontend and backend comfort',
        answer: 'Built multiple MERN projects with React hooks and Express REST endpoints',
      },
      {
        turn: 3,
        questionContext: 'DevOps and production readiness',
        answer: 'Deployed basic apps on Render/Vercel, need to master automated testing and Docker Compose',
      },
      {
        turn: 4,
        questionContext: 'Placement priorities',
        answer: 'Master system design trade-offs and build a production capstone with test coverage',
      },
    ],
    expectedOutcomes: {
      topRoles: ['Full-Stack Web Engineer', 'Modern Full-Stack & Cloud Engineer', 'Software Engineer'],
      avoidRoles: ['Embedded Hardware Engineer'],
      expectedGaps: ['Automated Unit & E2E Testing (Jest/Playwright)', 'System Design Trade-offs', 'CI/CD Pipelines'],
      shouldFlagContradiction: false,
      startLevel: 'Intermediate',
    },
  },

  PERSONA_D: {
    id: 'persona_d_data_ai',
    name: 'Persona D — Data / AI Interested Student',
    department: 'Artificial Intelligence & Data Science',
    background: {
      programmingExperience: 'Python proficiency, SQL queries, basic probability and statistics',
      knownSkills: ['Python', 'SQL', 'Pandas', 'NumPy', 'Scikit-Learn Basics'],
      weaknesses: ['Production ML Deployment', 'LLM Agent Orchestration', 'Data Pipelines'],
      interest: 'Machine learning models, generative AI agents, and data engineering pipelines',
      learningStyle: 'Experimentation with datasets, notebooks, and applied ML models',
      hoursPerDay: 2,
      goal: 'Transition from academic notebooks to an Applied AI / ML Engineer role',
    },
    pathfinderAnswers: [
      {
        turn: 1,
        questionContext: 'Primary engineering interest',
        answer: 'AI, LLM Agents & Machine Learning Engineering',
      },
      {
        turn: 2,
        questionContext: 'Current ML foundations',
        answer: 'Trained supervised models in Jupyter notebooks using Pandas, Scikit-Learn, and basic PyTorch',
      },
      {
        turn: 3,
        questionContext: 'AI specialization choice',
        answer: 'Excited by applied LLM agent systems and RAG pipelines rather than theoretical research',
      },
      {
        turn: 4,
        questionContext: 'Production engineering experience',
        answer: 'Have not deployed ML models to production APIs with FastAPI or Docker yet',
      },
    ],
    expectedOutcomes: {
      topRoles: ['AI & Machine Learning Engineer', 'Applied AI Systems Architect', 'Data Engineer'],
      avoidRoles: ['Mobile Flutter Developer', 'Pure Hardware Firmware'],
      expectedGaps: ['FastAPI ML Serving', 'RAG Vector Database Integration', 'Model Monitoring & Docker'],
      shouldFlagContradiction: false,
      startLevel: 'Beginner',
    },
  },

  PERSONA_E: {
    id: 'persona_e_contradictory',
    name: 'Persona E — Contradictory Student',
    department: 'Computer Science & Engineering',
    background: {
      programmingExperience: 'Conflicted preferences between frontend and backend',
      knownSkills: ['Basic JavaScript', 'HTML/CSS'],
      weaknesses: ['Indecision', 'Contradictory architectural preferences'],
      interest: 'Expressed strong backend desire, then vehemently rejected server-side programming',
      learningStyle: 'Exploratory but inconsistent',
      hoursPerDay: 2,
      goal: 'Unclear direction requiring EVA AI contradiction audit',
    },
    pathfinderAnswers: [
      {
        turn: 1,
        questionContext: 'Primary engineering interest',
        answer: 'Distributed backend architecture, high-scale database servers, and microservice APIs',
      },
      {
        turn: 2,
        questionContext: 'Backend programming preferences',
        answer: 'I dislike server-side programming, hate backend databases, and prefer not touching servers at all',
        isContradiction: true,
      },
      {
        turn: 3,
        questionContext: 'EVA Clarification question',
        answer: 'I actually prefer designing beautiful interactive client user interfaces with React and Flutter',
        resolvesContradiction: true,
      },
    ],
    expectedOutcomes: {
      topRoles: ['Full-Stack Web Engineer', 'Frontend Application Engineer', 'Cross-Platform Mobile Engineer'],
      avoidRoles: ['High-Throughput Backend Server Architect'],
      expectedGaps: ['Core Frontend Primitives', 'Client-Side State Management'],
      shouldFlagContradiction: true,
      startLevel: 'Beginner',
    },
  },

  PERSONA_F: {
    id: 'persona_f_advanced',
    name: 'Persona F — Advanced Student',
    department: 'Computer Science & Engineering',
    background: {
      programmingExperience: 'Senior year, 400+ LeetCode problems solved, internship at tech startup',
      knownSkills: ['Advanced DSA', 'C++', 'Go', 'Kubernetes', 'Distributed Systems', 'PostgreSQL', 'Redis'],
      weaknesses: ['Specialized High-Scale Architecture Trade-offs', 'Observability at scale'],
      interest: 'High-performance distributed systems, fault-tolerant consensus, and staff engineer track',
      learningStyle: 'In-depth paper reading, open-source benchmarking, and system design drills',
      hoursPerDay: 4,
      goal: 'Crack Tier-1 FAANG / High-Frequency Trading software engineering placement',
    },
    pathfinderAnswers: [
      {
        turn: 1,
        questionContext: 'Primary engineering interest',
        answer: 'C++ High-Performance Systems & Competitive Programming',
      },
      {
        turn: 2,
        questionContext: 'DSA and algorithm mastery',
        answer: 'Solved 400+ algorithmic problems on LeetCode/Codeforces, comfortable with DP and Graphs',
      },
      {
        turn: 3,
        questionContext: 'Production system experience',
        answer: 'Completed 6-month backend internship handling Kafka event ingestion and Redis caching clusters',
      },
      {
        turn: 4,
        questionContext: 'Placement goals',
        answer: 'Focus exclusively on advanced distributed system design, consensus protocols, and senior placement rounds',
      },
    ],
    expectedOutcomes: {
      topRoles: ['Backend & Cloud Architect', 'High-Performance Systems Engineer', 'Distributed Systems Engineer'],
      avoidRoles: ['Beginner HTML/CSS Developer'],
      expectedGaps: ['Distributed Consensus (Raft/Paxos)', 'System Observability (OpenTelemetry)', 'Advanced System Design'],
      shouldFlagContradiction: false,
      startLevel: 'Advanced',
    },
  },
};
