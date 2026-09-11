import { z } from 'zod';
import { prisma } from '../../../config/database';
import { aiProvider } from '../../../shared/ai/ai.provider';
import { gitHubResourceService } from './career.github.service';
import { youTubeResourceService } from './career.youtube.service';
import { logger } from '../../../infrastructure/logger/logger';

const roadmapGenerationSchema = z.object({
  title: z.string(),
  category: z.string(),
  description: z.string(),
  estimatedMonths: z.number().min(1).max(24),
  phases: z.array(
    z.object({
      phaseNumber: z.number(),
      title: z.string(),
      weeks: z.number().min(1).max(12),
      description: z.string(),
      skills: z.array(z.string()).min(1),
      tasks: z.array(
        z.object({
          id: z.string(),
          title: z.string(),
          type: z.enum(['LEARN', 'PRACTICE', 'CHALLENGE']),
          durationMins: z.number().min(15).max(180),
        })
      ),
      project: z.object({
        title: z.string(),
        description: z.string(),
        difficulty: z.enum(['Beginner', 'Intermediate', 'Advanced']),
        techStack: z.array(z.string()),
        milestones: z.array(z.string()),
      }),
      quiz: z.object({
        title: z.string(),
        questions: z.array(
          z.object({
            question: z.string(),
            options: z.array(z.string()).min(2).max(4),
            correctIndex: z.number().min(0).max(3),
            explanation: z.string(),
          })
        ),
      }),
      completionCriteria: z.string(),
    })
  ).min(3).max(8),
  dependencies: z.array(
    z.object({
      sourceSkill: z.string(),
      targetSkill: z.string(),
      dependencyType: z.enum(['PREREQUISITE', 'ENHANCEMENT', 'COREQUISITE']),
    })
  ).min(2),
});

export class CareerRoadmapGenerator {
  /**
   * Generates and persists an AI-tailored dependency-aware career roadmap for any department & career direction.
   */
  async generatePersonalizedRoadmap(params: {
    userId: string;
    targetRole: string;
    department?: string;
    level?: string;
    weeklyHours?: number;
    goal?: string;
    preferredLanguage?: string;
  }) {
    const level = params.level || 'Beginner';
    const weeklyHours = params.weeklyHours || 10;
    const language = params.preferredLanguage || 'English';

    // 1. Prompt LLM to construct personalized curriculum graph
    const prompt = `You are the Principal Curriculum Architect at CampusHub University.
Generate a comprehensive, personalized, prerequisite-aware career roadmap.

Student Profile:
- Target Career Role: ${params.targetRole}
- College Department: ${params.department || 'Engineering'}
- Current Level: ${level}
- Weekly Study Hours: ${weeklyHours}
- Goal: ${params.goal || 'Campus Placement Readiness & Capstone Portfolio'}
- Preferred Learning Language: ${language}

Requirements:
1. Divide the roadmap into 4 to 7 progressive chronological phases (from foundations to real-world capstone).
2. For each phase, provide specific skills, actionable daily tasks (LEARN, PRACTICE, CHALLENGE), a practical mini-project, and a 2-question checkpoint quiz.
3. Explicitly define direct skill dependencies (which skill is a prerequisite for which next skill) to build a Directed Acyclic Graph (DAG).
4. Output ONLY valid JSON matching this schema:
{
  "title": "${params.targetRole}",
  "category": "e.g. Embedded Systems / Web / AI / Civil Tech",
  "description": "2-3 sentence overview of this personalized learning journey.",
  "estimatedMonths": 4,
  "phases": [
    {
      "phaseNumber": 1,
      "title": "Phase 1 Title",
      "weeks": 2,
      "description": "...",
      "skills": ["Skill 1", "Skill 2"],
      "tasks": [
        { "id": "p1-t1", "title": "...", "type": "LEARN", "durationMins": 45 },
        { "id": "p1-t2", "title": "...", "type": "PRACTICE", "durationMins": 60 }
      ],
      "project": {
        "title": "...",
        "description": "...",
        "difficulty": "Beginner",
        "techStack": ["..."],
        "milestones": ["..."]
      },
      "quiz": {
        "title": "Phase 1 Checkpoint",
        "questions": [
          { "question": "...", "options": ["A", "B", "C", "D"], "correctIndex": 1, "explanation": "..." }
        ]
      },
      "completionCriteria": "..."
    }
  ],
  "dependencies": [
    { "sourceSkill": "Skill 1", "targetSkill": "Skill 2", "dependencyType": "PREREQUISITE" }
  ]
}`;

    let generated: z.infer<typeof roadmapGenerationSchema>;
    try {
      generated = await aiProvider.generateStructured(prompt, roadmapGenerationSchema);
    } catch (err) {
      logger.warn({ err }, 'Roadmap generation schema parse warning, generating domain fallback');
      generated = this.getDomainFallbackCurriculum(params.targetRole, level);
    }

    // 2. Fetch real verified GitHub and YouTube resources for all skills
    const allSkills = Array.from(new Set(generated.phases.flatMap((p) => p.skills)));
    const primarySkill = allSkills[0] || params.targetRole;

    const [githubRepos, youtubeVideos] = await Promise.all([
      gitHubResourceService.searchRepositories(primarySkill, 3),
      Promise.resolve(youTubeResourceService.resolveVideos(primarySkill, language, 3)),
    ]);

    // 3. Persist Roadmap in Database
    const slug = `${params.targetRole.toLowerCase().replace(/[^a-z0-9]+/g, '-')}-v1-${Date.now()}`;
    const roadmapPhasesFormatted = generated.phases.map((p) => ({
      phase_number: p.phaseNumber,
      title: p.title,
      weeks: p.weeks,
      description: p.description,
      objectives: [`Master ${p.skills.join(', ')}`],
      skills: p.skills,
      tasks: p.tasks.map((t) => ({
        id: t.id,
        title: t.title,
        type: t.type,
        duration_mins: t.durationMins,
        is_completed: false,
      })),
      project: {
        title: p.project.title,
        description: p.project.description,
        difficulty: p.project.difficulty,
        tech_stack: p.project.techStack,
        milestones: p.project.milestones,
      },
      quiz: {
        title: p.quiz.title,
        questions: p.quiz.questions.map((q) => ({
          question: q.question,
          options: q.options,
          correct_index: q.correctIndex,
          explanation: q.explanation,
        })),
      },
      completion_criteria: p.completionCriteria,
    }));

    const roadmap = await prisma.careerRoadmap.create({
      data: {
        user_id: params.userId,
        title: generated.title,
        slug,
        target_role: params.targetRole,
        category: generated.category,
        description: generated.description,
        level,
        estimated_months: generated.estimatedMonths,
        learning_language: language,
        phases_json: roadmapPhasesFormatted as any,
        status: 'ACTIVE',
      },
    });

    // 4. Create RoadmapNodes and LearningResources
    for (let i = 0; i < generated.phases.length; i++) {
      const p = generated.phases[i];
      const node = await prisma.roadmapNode.create({
        data: {
          roadmap_id: roadmap.id,
          title: p.title,
          description: p.description,
          order_index: i + 1,
          estimated_hours: p.weeks * weeklyHours,
        },
      });

      // Attach primary verified documentation
      await prisma.learningResource.create({
        data: {
          roadmap_id: roadmap.id,
          node_id: node.id,
          title: `${p.skills[0] || p.title} Official Documentation`,
          type: 'DOCS',
          url: 'https://devdocs.io',
          verification_status: 'VERIFIED',
          difficulty: level,
          language: 'English',
        },
      });

      // Attach YouTube educational resources for phase
      if (i === 0 && youtubeVideos.length > 0) {
        for (const yt of youtubeVideos) {
          await prisma.learningResource.create({
            data: {
              roadmap_id: roadmap.id,
              node_id: node.id,
              title: yt.title,
              type: 'VIDEO',
              url: yt.url,
              channel_name: yt.channel,
              language: yt.language,
              duration_mins: 120,
              verification_status: 'VERIFIED',
              metadata: { views: yt.views, thumbnail: yt.thumbnailUrl },
            },
          });
        }
      }

      // Attach GitHub repositories for phase
      if (i === 0 && githubRepos.length > 0) {
        for (const repo of githubRepos) {
          await prisma.learningResource.create({
            data: {
              roadmap_id: roadmap.id,
              node_id: node.id,
              title: `${repo.fullName} (★ ${repo.stars.toLocaleString()})`,
              type: 'GITHUB',
              url: repo.url,
              github_stars: repo.stars,
              github_forks: repo.forks,
              language: repo.language,
              verification_status: 'VERIFIED',
              metadata: { whyUseful: repo.whyUseful, topics: repo.topics },
            },
          });
        }
      }
    }

    // 5. Create SkillDependencies DAG
    for (const dep of generated.dependencies) {
      await prisma.skillDependency.upsert({
        where: {
          roadmap_id_source_skill_target_skill: {
            roadmap_id: roadmap.id,
            source_skill: dep.sourceSkill,
            target_skill: dep.targetSkill,
          },
        },
        update: {},
        create: {
          roadmap_id: roadmap.id,
          source_skill: dep.sourceSkill,
          target_skill: dep.targetSkill,
          dependency_type: dep.dependencyType,
          confidence: 1.0,
        },
      });
    }

    // 6. Initialize Student Skills in student_skills table
    for (const skillName of allSkills) {
      await prisma.studentSkill.upsert({
        where: {
          user_id_skill_name: {
            user_id: params.userId,
            skill_name: skillName,
          },
        },
        update: {},
        create: {
          user_id: params.userId,
          skill_name: skillName,
          category: generated.category,
          target_role: params.targetRole,
          proficiency_level: 'Beginner',
          confidence_score: 40,
        },
      });
    }

    // 7. Initialize UserRoadmapProgress
    await prisma.userRoadmapProgress.upsert({
      where: {
        user_id_roadmap_id: {
          user_id: params.userId,
          roadmap_id: roadmap.id,
        },
      },
      update: {
        is_active: true,
        target_role: params.targetRole,
      },
      create: {
        user_id: params.userId,
        roadmap_id: roadmap.id,
        is_active: true,
        target_role: params.targetRole,
        level,
        weekly_hours: weeklyHours,
        current_focus: generated.phases[0]?.title || 'Foundations',
        progress_percent: 0.0,
      },
    });

    return {
      roadmapId: roadmap.id,
      title: roadmap.title,
      targetRole: roadmap.target_role,
      phasesCount: generated.phases.length,
      skillsCount: allSkills.length,
      dependenciesCount: generated.dependencies.length,
    };
  }

  private getDomainFallbackCurriculum(targetRole: string, level: string): z.infer<typeof roadmapGenerationSchema> {
    const roleLower = targetRole.toLowerCase();

    if (roleLower.includes('iot') || roleLower.includes('embedded')) {
      return {
        title: targetRole,
        category: 'IoT & Embedded Systems',
        description: 'Comprehensive curriculum connecting microcontroller hardware, sensors, RTOS firmware, and cloud IoT telemetry.',
        estimatedMonths: 4,
        phases: [
          {
            phaseNumber: 1,
            title: 'Foundations & C Programming',
            weeks: 2,
            description: 'Master low-level memory layout, bitwise manipulation, pointers, and hardware registers.',
            skills: ['C Programming', 'Pointers & Memory', 'Bitwise Operations'],
            tasks: [
              { id: 'iot-p1-t1', title: 'Pointers and Dynamic Memory Allocation in C', type: 'LEARN', durationMins: 45 },
              { id: 'iot-p1-t2', title: 'Bitmasking and Register Manipulation Practice', type: 'PRACTICE', durationMins: 60 },
              { id: 'iot-p1-t3', title: 'Implement a Ring Buffer in C', type: 'CHALLENGE', durationMins: 75 },
            ],
            project: {
              title: 'Memory-Safe Circular Buffer',
              description: 'Implement a zero-allocation circular queue for high-frequency sensor streams.',
              difficulty: 'Beginner',
              techStack: ['C', 'GCC', 'Make'],
              milestones: ['Buffer allocation', 'FIFO enqueue/dequeue', 'Overflow handling'],
            },
            quiz: {
              title: 'C Embedded Fundamentals',
              questions: [
                {
                  question: 'What is the primary danger of using dynamic malloc() inside an embedded interrupt service routine (ISR)?',
                  options: ['Heap fragmentation and non-deterministic latency', 'CPU clock slows down', 'Registers are wiped', 'Compiler warning only'],
                  correctIndex: 0,
                  explanation: 'malloc() is non-deterministic and can cause heap fragmentation, leading to fatal crashes inside time-critical ISRs.',
                },
              ],
            },
            completionCriteria: 'Pass C memory quiz and submit working circular buffer.',
          },
          {
            phaseNumber: 2,
            title: 'Microcontrollers (Arduino / ESP32)',
            weeks: 3,
            description: 'Architect firmware on ESP32 dual-core Xtensa microcontrollers with GPIO, ADC, PWM, and I2C/SPI sensors.',
            skills: ['ESP32', 'GPIO & Interrupts', 'I2C / SPI Protocols'],
            tasks: [
              { id: 'iot-p2-t1', title: 'ESP32 Architecture and Pinout Configuration', type: 'LEARN', durationMins: 45 },
              { id: 'iot-p2-t2', title: 'Interfacing OLED Display & Temperature Sensor via I2C', type: 'PRACTICE', durationMins: 60 },
              { id: 'iot-p2-t3', title: 'Hardware Interrupt Debouncing Challenge', type: 'CHALLENGE', durationMins: 90 },
            ],
            project: {
              title: 'Weather Monitoring Station',
              description: 'Real-time telemetry weather monitor reading BME280 sensor values and rendering on OLED.',
              difficulty: 'Intermediate',
              techStack: ['ESP32', 'C++', 'I2C', 'FreeRTOS'],
              milestones: ['Sensor reading', 'OLED display driver', 'Threshold alerting'],
            },
            quiz: {
              title: 'ESP32 & Microcontroller Architecture',
              questions: [
                {
                  question: 'What is the main purpose of a GPIO (General Purpose Input/Output) pin on a microcontroller?',
                  options: ['To store data permanently', 'To connect with external devices and sensors', 'To speed up CPU clock', 'To manage RAM'],
                  correctIndex: 1,
                  explanation: 'GPIO pins permit the microcontroller to read signals from sensors and drive actuators like LEDs and relays.',
                },
              ],
            },
            completionCriteria: 'Build working hardware sensor reader and pass GPIO checkpoint.',
          },
          {
            phaseNumber: 3,
            title: 'IoT Protocols (MQTT & WebSockets)',
            weeks: 3,
            description: 'Implement publish/subscribe telemetry over MQTT to AWS IoT / HiveMQ with Wi-Fi reconnection.',
            skills: ['MQTT', 'Wi-Fi & Networking', 'JSON Telemetry'],
            tasks: [
              { id: 'iot-p3-t1', title: 'MQTT Broker Architecture and QoS Levels', type: 'LEARN', durationMins: 45 },
              { id: 'iot-p3-t2', title: 'Publishing Sensor Telemetry to MQTT Broker', type: 'PRACTICE', durationMins: 60 },
            ],
            project: {
              title: 'Smart Home Automation Node',
              description: 'ESP32 relay controller receiving remote MQTT commands to switch home appliances.',
              difficulty: 'Intermediate',
              techStack: ['ESP32', 'MQTT', 'Mosquitto', 'C++'],
              milestones: ['MQTT connection', 'Subscribing to topics', 'Relay state control'],
            },
            quiz: {
              title: 'MQTT & Telemetry Checkpoint',
              questions: [
                {
                  question: 'Why is MQTT preferred over HTTP for battery-powered IoT devices?',
                  options: ['MQTT has a minimal 2-byte header and uses lightweight publish/subscribe', 'HTTP is encrypted by default', 'MQTT supports 4K video', 'HTTP cannot send numbers'],
                  correctIndex: 0,
                  explanation: 'MQTT packet overhead is tiny (as low as 2 bytes) and uses persistent TCP connections, saving vital battery life.',
                },
              ],
            },
            completionCriteria: 'Transmit live telemetry stream over MQTT with zero dropouts.',
          },
        ],
        dependencies: [
          { sourceSkill: 'C Programming', targetSkill: 'ESP32', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'ESP32', targetSkill: 'GPIO & Interrupts', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'GPIO & Interrupts', targetSkill: 'MQTT', dependencyType: 'PREREQUISITE' },
        ],
      };
    }

    // Default Full-Stack Software Engineer
    return {
      title: targetRole,
      category: 'Software Engineering',
      description: 'End-to-end full-stack software development covering frontend client apps, scalable backend APIs, databases, and deployment.',
      estimatedMonths: 4,
      phases: [
        {
          phaseNumber: 1,
          title: 'Programming Foundations & Algorithms',
          weeks: 2,
          description: 'Core programming constructs, data structures, and algorithmic complexity.',
          skills: ['Data Structures', 'Git & GitHub', 'Clean Code'],
          tasks: [
            { id: 'sw-p1-t1', title: 'Time and Space Complexity Analysis (Big O)', type: 'LEARN', durationMins: 45 },
            { id: 'sw-p1-t2', title: 'Implement Stacks and Queues', type: 'PRACTICE', durationMins: 60 },
          ],
          project: {
            title: 'CLI Task Manager with Git Sync',
            description: 'Command line task tracker utilizing persistent file storage and data structures.',
            difficulty: 'Beginner',
            techStack: ['TypeScript', 'Node.js'],
            milestones: ['CRUD commands', 'File storage', 'Unit tests'],
          },
          quiz: {
            title: 'Foundations Quiz',
            questions: [
              {
                question: 'What is the average time complexity to look up a key in a Hash Table?',
                options: ['O(1)', 'O(log N)', 'O(N)', 'O(N^2)'],
                correctIndex: 0,
                explanation: 'Hash tables offer O(1) constant average lookup time through hashing.',
              },
            ],
          },
          completionCriteria: 'Pass Big O quiz and submit CLI project.',
        },
        {
          phaseNumber: 2,
          title: 'Backend Architecture & REST APIs',
          weeks: 3,
          description: 'Design and build high-throughput RESTful services with authentication and database transactions.',
          skills: ['Node.js', 'REST APIs', 'SQL / PostgreSQL', 'Authentication'],
          tasks: [
            { id: 'sw-p2-t1', title: 'HTTP Methods, Status Codes and REST Principles', type: 'LEARN', durationMins: 45 },
            { id: 'sw-p2-t2', title: 'Building JWT Authentication Middleware', type: 'PRACTICE', durationMins: 60 },
          ],
          project: {
            title: 'E-Commerce REST API Engine',
            description: 'Scalable backend API with JWT authentication, role guards, and PostgreSQL relations.',
            difficulty: 'Intermediate',
            techStack: ['Node.js', 'Express', 'PostgreSQL', 'Prisma'],
            milestones: ['Auth endpoints', 'Product catalog', 'Cart transactions'],
          },
          quiz: {
            title: 'API Architecture Quiz',
            questions: [
              {
                question: 'Which HTTP status code should be returned when a client sends a request without valid authentication credentials?',
                options: ['200 OK', '401 Unauthorized', '403 Forbidden', '500 Server Error'],
                correctIndex: 1,
                explanation: 'HTTP 401 Unauthorized indicates the request requires user authentication.',
              },
            ],
          },
          completionCriteria: 'Build complete REST API with test coverage.',
        },
      ],
      dependencies: [
        { sourceSkill: 'Data Structures', targetSkill: 'Node.js', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'Node.js', targetSkill: 'REST APIs', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'REST APIs', targetSkill: 'Authentication', dependencyType: 'PREREQUISITE' },
      ],
    };
  }

  static async generateRoadmap(
    userId: string,
    params: {
      targetRole: string;
      department?: string;
      currentLevel?: string;
      hoursPerWeek?: number;
      timelineWeeks?: number;
      primaryGoal?: string;
      preferredLanguage?: string;
      skillFocusAreas?: string[];
    }
  ) {
    return careerRoadmapGenerator.generatePersonalizedRoadmap({
      userId,
      targetRole: params.targetRole,
      department: params.department,
      level: params.currentLevel,
      weeklyHours: params.hoursPerWeek,
      goal: params.primaryGoal,
      preferredLanguage: params.preferredLanguage,
    });
  }
}

export const careerRoadmapGenerator = new CareerRoadmapGenerator();
