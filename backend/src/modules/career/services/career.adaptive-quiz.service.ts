import { z } from 'zod';
import { prisma } from '../../../config/database';
import { aiProvider } from '../../../shared/ai/ai.provider';
import { logger } from '../../../infrastructure/logger/logger';

export interface QuizQuestionItem {
  id: string;
  question: string;
  options: string[];
  correctIndex: number;
  explanation: string;
  concept: string;
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced';
}

export interface QuizEvaluationResult {
  score: number;
  totalQuestions: number;
  percentage: number;
  passed: boolean;
  strongTopics: string[];
  needPractice: string[];
  reviewAgain: string[];
  aiInsight: string;
  recommendedActions: string[];
}

const quizGenerationSchema = z.object({
  topic: z.string(),
  questions: z.array(
    z.object({
      question: z.string().min(5),
      options: z.array(z.string()).min(2).max(4),
      correctIndex: z.number().min(0).max(3),
      explanation: z.string(),
      concept: z.string(),
      difficulty: z.enum(['Beginner', 'Intermediate', 'Advanced']),
    })
  ).min(3).max(10),
});

export class AdaptiveQuizService {
  /**
   * Generates a context-aware quiz for a skill or roadmap node.
   */
  async generateQuiz(params: {
    topic: string;
    targetRole?: string;
    numQuestions?: number;
    difficulty?: 'Beginner' | 'Intermediate' | 'Advanced';
  }): Promise<{ topic: string; questions: QuizQuestionItem[] }> {
    const count = params.numQuestions || 5;
    const diff = params.difficulty || 'Intermediate';

    const prompt = `You are an expert technical interviewer and educator at CampusHub.
Generate ${count} multiple-choice questions testing practical understanding of:
Topic: ${params.topic}
Target Role: ${params.targetRole || 'Software / Hardware Engineer'}
Difficulty: ${diff}

Requirements:
- Emphasize real-world debugging, architecture, code understanding, and core concepts.
- 4 clear options per question.
- Explicit concept name per question (e.g. "GPIO Interrupts", "Memory Safety", "REST Status Codes").
- Detailed explanation for why the correct answer is right.

Output valid JSON matching schema:
{
  "topic": "${params.topic}",
  "questions": [
    {
      "question": "What is the primary purpose of a GPIO pin in a microcontroller?",
      "options": ["To store data", "To connect with external devices and sensors", "To increase clock speed", "To manage memory"],
      "correctIndex": 1,
      "explanation": "GPIO pins allow the microcontroller to interact with external devices like LEDs, sensors, and buttons.",
      "concept": "GPIO Hardware",
      "difficulty": "Beginner"
    }
  ]
}`;

    try {
      const result = await aiProvider.generateStructured(prompt, quizGenerationSchema);
      return {
        topic: result.topic,
        questions: result.questions.map((q, idx) => ({
          id: `q-${idx + 1}`,
          question: q.question,
          options: q.options,
          correctIndex: q.correctIndex,
          explanation: q.explanation,
          concept: q.concept,
          difficulty: q.difficulty,
        })),
      };
    } catch (err) {
      logger.warn({ err }, 'Adaptive quiz generation fallback');
      return this.getFallbackQuiz(params.topic, count);
    }
  }

  /**
   * Evaluates submitted answers, analyzes strengths/weaknesses, updates student_skills and records QuizAttempt.
   */
  async evaluateQuiz(params: {
    userId: string;
    roadmapId?: string;
    topic: string;
    phaseNumber?: number;
    questions: QuizQuestionItem[];
    userAnswers: Record<number, number>; // questionIndex -> selectedOptionIndex
  }): Promise<QuizEvaluationResult> {
    let correctCount = 0;
    const strongTopics: string[] = [];
    const needPractice: string[] = [];
    const reviewAgain: string[] = [];

    params.questions.forEach((q, idx) => {
      const selected = params.userAnswers[idx];
      const isCorrect = selected === q.correctIndex;
      if (isCorrect) {
        correctCount++;
        strongTopics.push(q.concept);
      } else {
        needPractice.push(q.concept);
        if (q.difficulty === 'Beginner') {
          reviewAgain.push(q.concept);
        }
      }
    });

    const total = params.questions.length;
    const percentage = total > 0 ? Math.round((correctCount / total) * 100) : 0;
    const passed = percentage >= 70;

    const aiInsight = passed
      ? `You understand core ${params.topic} concepts well (${correctCount}/${total}). Keep building practical evidence.`
      : `Identified knowledge gaps in ${needPractice.slice(0, 2).join(' and ') || params.topic}. Practice recommended before proceeding.`;

    const recommendedActions: string[] = [];
    if (needPractice.length > 0) {
      recommendedActions.push(`Review key concepts: ${needPractice.slice(0, 2).join(', ')}`);
    }
    recommendedActions.push(`Complete hands-on practice challenge for ${params.topic}`);
    recommendedActions.push('Retake assessment in 2 days to verify knowledge retention');

    // 1. Record QuizAttempt
    await prisma.quizAttempt.create({
      data: {
        user_id: params.userId,
        roadmap_id: params.roadmapId || null,
        phase_number: params.phaseNumber || 1,
        topic: params.topic,
        score: correctCount,
        total_questions: total,
        percentage,
        passed,
        feedback_json: {
          strongTopics: Array.from(new Set(strongTopics)),
          needPractice: Array.from(new Set(needPractice)),
          reviewAgain: Array.from(new Set(reviewAgain)),
          aiInsight,
          recommendedActions,
        },
      },
    });

    // 2. Update StudentSkill and record SkillEvidence
    const skill = await prisma.studentSkill.findFirst({
      where: { user_id: params.userId, skill_name: { contains: params.topic, mode: 'insensitive' } },
    });

    if (skill) {
      const newConfidence = Math.min(100, Math.max(10, skill.confidence_score + (passed ? 10 : -5)));
      const newLevel = newConfidence >= 80 ? 'Advanced' : newConfidence >= 60 ? 'Developing' : 'Beginner';

      await prisma.studentSkill.update({
        where: { id: skill.id },
        data: {
          confidence_score: newConfidence,
          proficiency_level: newLevel,
          evidence_count: { increment: 1 },
          last_assessed_at: new Date(),
        },
      });

      await prisma.skillEvidence.create({
        data: {
          student_skill_id: skill.id,
          evidence_type: 'QUIZ',
          score: percentage,
          notes: `Completed ${params.topic} quiz: scored ${percentage}%. ${aiInsight}`,
        },
      });
    }

    return {
      score: correctCount,
      totalQuestions: total,
      percentage,
      passed,
      strongTopics: Array.from(new Set(strongTopics)),
      needPractice: Array.from(new Set(needPractice)),
      reviewAgain: Array.from(new Set(reviewAgain)),
      aiInsight,
      recommendedActions,
    };
  }

  private getFallbackQuiz(topic: string, count: number): { topic: string; questions: QuizQuestionItem[] } {
    const isHardware = topic.toLowerCase().includes('microcontroller') || topic.toLowerCase().includes('esp32') || topic.toLowerCase().includes('iot');

    if (isHardware) {
      return {
        topic,
        questions: [
          {
            id: 'q-1',
            question: 'What is the main purpose of a GPIO (General Purpose Input/Output) pin in a microcontroller?',
            options: ['To store data permanently', 'To connect with external devices like sensors and LEDs', 'To increase CPU clock speed', 'To manage RAM memory'],
            correctIndex: 1,
            explanation: 'GPIO pins allow the microcontroller to interact with external devices like LEDs, sensors, and buttons.',
            concept: 'GPIO Hardware',
            difficulty: 'Beginner' as const,
          },
          {
            id: 'q-2',
            question: 'Which serial communication protocol uses two wires: SDA (Serial Data) and SCL (Serial Clock)?',
            options: ['SPI', 'UART', 'I2C', 'CAN Bus'],
            correctIndex: 2,
            explanation: 'I2C uses two bidirectional open-drain lines: Serial Data (SDA) and Serial Clock (SCL).',
            concept: 'I2C Protocol',
            difficulty: 'Intermediate' as const,
          },
          {
            id: 'q-3',
            question: 'In an embedded C program, what does the "volatile" keyword inform the compiler?',
            options: [
              'The variable should be stored in fast CPU cache',
              'The variable value may change at any time outside the current code (e.g. by hardware/ISR) and must not be cached in a register',
              'The variable cannot be modified after initialization',
              'The variable is thread-safe automatically',
            ],
            correctIndex: 1,
            explanation: 'volatile tells the compiler that the value of the variable may change unexpectedly, preventing the optimizer from caching it.',
            concept: 'C Memory Model',
            difficulty: 'Advanced' as const,
          },
        ].slice(0, count),
      };
    }

    return {
      topic,
      questions: [
        {
          id: 'q-1',
          question: 'What is the primary function of an HTTP GET request in a RESTful API?',
          options: ['To create a new server resource', 'To retrieve data representation from the server', 'To delete a record', 'To update credentials'],
          correctIndex: 1,
          explanation: 'GET is safe and idempotent, intended exclusively for retrieving server resources.',
          concept: 'HTTP Methods',
          difficulty: 'Beginner' as const,
        },
        {
          id: 'q-2',
          question: 'Which HTTP status code should a server return when authentication credentials are missing or invalid?',
          options: ['200 OK', '401 Unauthorized', '403 Forbidden', '500 Internal Error'],
          correctIndex: 1,
          explanation: '401 Unauthorized indicates authentication is required and has failed or has not yet been provided.',
          concept: 'HTTP Status Codes',
          difficulty: 'Intermediate' as const,
        },
      ].slice(0, count),
    };
  }

  static async generateAdaptiveQuiz(
    _userId: string,
    params: {
      topic: string;
      phaseNumber?: number;
      roadmapId?: string;
      skillName?: string;
      targetDifficulty?: string;
    }
  ) {
    return adaptiveQuizService.generateQuiz({
      topic: params.topic,
      difficulty: (params.targetDifficulty as any) || 'Intermediate',
    });
  }

  static async submitAndEvaluateQuiz(
    userId: string,
    params: {
      roadmapId?: string;
      phaseNumber?: number;
      topic: string;
      skillName?: string;
      answers: Record<number, number>;
      questions: QuizQuestionItem[];
      timeSpentSeconds?: number;
    }
  ) {
    return adaptiveQuizService.evaluateQuiz({
      userId,
      roadmapId: params.roadmapId,
      topic: params.topic,
      phaseNumber: params.phaseNumber,
      questions: params.questions,
      userAnswers: params.answers,
    });
  }
}

export const adaptiveQuizService = new AdaptiveQuizService();
export const CareerAdaptiveQuizService = AdaptiveQuizService;
