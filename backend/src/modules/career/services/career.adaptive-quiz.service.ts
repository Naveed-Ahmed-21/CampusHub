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
  ).min(5).max(15),
});

export class AdaptiveQuizService {
  /**
   * Generates a context-aware quiz for a skill or roadmap node. Defaults to 10 questions.
   */
  async generateQuiz(params: {
    topic: string;
    targetRole?: string;
    numQuestions?: number;
    difficulty?: 'Beginner' | 'Intermediate' | 'Advanced';
  }): Promise<{ topic: string; questions: QuizQuestionItem[] }> {
    const count = params.numQuestions || 10;
    const diff = params.difficulty || 'Intermediate';

    const prompt = `You are an expert technical interviewer and educator at CampusHub.
Generate exactly ${count} distinct multiple-choice questions testing practical understanding of:
Topic: ${params.topic}
Target Role: ${params.targetRole || 'Engineering Student'}
Difficulty: ${diff}

Requirements:
- Emphasize real-world debugging, architecture, practical code understanding, and core concepts.
- Provide 4 clear options per question.
- Explicit concept name per question (e.g. "GPIO Interrupts", "Memory Safety", "REST Status Codes").
- Detailed explanation for why the correct answer is right.
- Questions must be deeply relevant to ${params.topic}.

Output valid JSON matching schema:
{
  "topic": "${params.topic}",
  "questions": [
    {
      "question": "Sample question text?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctIndex": 0,
      "explanation": "Detailed explanation.",
      "concept": "Specific Concept",
      "difficulty": "Intermediate"
    }
  ]
}`;

    try {
      const result = await aiProvider.generateStructured(prompt, quizGenerationSchema);
      if (result.questions && result.questions.length >= 5) {
        logger.info({ count: result.questions.length, topic: params.topic }, '[CAREER_QUIZ] AI successfully generated structured questions');
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
      }
    } catch (err) {
      logger.warn({ err, topic: params.topic }, 'Adaptive quiz AI generation fallback triggered');
    }

    return this.getFallbackQuiz(params.topic, count);
  }

  /**
   * Evaluates submitted answers, analyzes strengths/weaknesses, updates student_skills,
   * records QuizAttempt, and synchronizes node progress.
   */
  async evaluateQuiz(params: {
    userId: string;
    roadmapId?: string;
    topic: string;
    phaseNumber?: number;
    questions: QuizQuestionItem[];
    userAnswers: Record<number, number>;
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
      ? `Strong mastery of ${params.topic} (${correctCount}/${total}). You have met the checkpoint criteria.`
      : `Identified knowledge gaps in ${needPractice.slice(0, 2).join(' and ') || params.topic}. Review recommendations before retaking.`;

    const recommendedActions: string[] = [];
    if (needPractice.length > 0) {
      recommendedActions.push(`Review weak concepts: ${Array.from(new Set(needPractice)).slice(0, 2).join(', ')}`);
    }
    if (!passed) {
      recommendedActions.push(`Retake ${params.topic} assessment after reviewing video & documentation`);
    } else {
      recommendedActions.push(`Proceed to hands-on project milestones for this roadmap milestone`);
      recommendedActions.push(`Start technical interview practice module grounded in this skill`);
    }

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
    let skill = await prisma.studentSkill.findFirst({
      where: {
        user_id: params.userId,
        skill_name: { contains: params.topic.split(' ')[0] || params.topic, mode: 'insensitive' },
      },
    });

    if (!skill) {
      skill = await prisma.studentSkill.create({
        data: {
          user_id: params.userId,
          skill_name: params.topic,
          proficiency_level: passed ? 'Developing' : 'Beginner',
          confidence_score: passed ? 75 : 45,
          evidence_count: 1,
          last_assessed_at: new Date(),
        },
      });
    } else {
      const newConfidence = Math.min(100, Math.max(15, skill.confidence_score + (passed ? 12 : -6)));
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
    }

    await prisma.skillEvidence.create({
      data: {
        student_skill_id: skill.id,
        evidence_type: 'QUIZ',
        score: percentage,
        notes: `Completed 10-question ${params.topic} adaptive quiz: ${correctCount}/${total} (${percentage}%). ${aiInsight}`,
      },
    });

    // 3. If passed and roadmapId is present, auto-update UserNodeProgress
    if (passed && params.roadmapId) {
      try {
        const node = await prisma.roadmapNode.findFirst({
          where: {
            roadmap_id: params.roadmapId,
            title: { contains: params.topic, mode: 'insensitive' },
          },
        });

        if (node) {
          await prisma.userNodeProgress.upsert({
            where: { user_id_node_id: { user_id: params.userId, node_id: node.id } },
            create: { user_id: params.userId, node_id: node.id, is_completed: true },
            update: { is_completed: true, completed_at: new Date() },
          });

          // Recalculate roadmap progress
          const totalNodes = await prisma.roadmapNode.count({ where: { roadmap_id: params.roadmapId } });
          const completedNodes = await prisma.userNodeProgress.count({
            where: {
              user_id: params.userId,
              is_completed: true,
              node: { roadmap_id: params.roadmapId },
            },
          });

          const progressPercent = totalNodes > 0 ? (completedNodes / totalNodes) * 100 : 0;
          await prisma.userRoadmapProgress.updateMany({
            where: { user_id: params.userId, roadmap_id: params.roadmapId },
            data: {
              completed_node_count: completedNodes,
              progress_percent: progressPercent,
              last_active_at: new Date(),
            },
          });
        }
      } catch (err) {
        logger.warn({ err }, 'Error auto-syncing roadmap node progress after quiz pass');
      }
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

  /**
   * Generates comprehensive 10-question verified quiz banks for major engineering domains
   */
  getFallbackQuiz(topic: string, count: number = 10): { topic: string; questions: QuizQuestionItem[] } {
    const key = topic.toLowerCase();

    // 1. IoT & Microcontrollers (ESP32, GPIO, RTOS)
    if (key.includes('microcontroller') || key.includes('esp32') || key.includes('iot') || key.includes('embedded') || key.includes('gpio') || key.includes('sensor')) {
      const pool: QuizQuestionItem[] = [
        {
          id: 'q-1',
          question: 'What is the primary architectural function of a GPIO (General Purpose Input/Output) pin on the ESP32?',
          options: ['To permanently store program binary files', 'To interface digitally with external sensors, switches, and actuators', 'To accelerate dual-core CPU clock frequency', 'To handle dynamic RAM memory allocation'],
          correctIndex: 1,
          explanation: 'GPIO pins configure pins as input or output to read digital signals or control hardware circuits.',
          concept: 'GPIO Pin Architecture',
          difficulty: 'Beginner',
        },
        {
          id: 'q-2',
          question: 'What happens to an input GPIO pin left floating without a pull-up or pull-down resistor?',
          options: ['It reliably defaults to digital HIGH (1)', 'It acts as an antenna picking up electromagnetic noise, resulting in unpredictable reading oscillations', 'The ESP32 initiates a kernel panic and resets', 'The pin permanently burns out due to excessive current'],
          correctIndex: 1,
          explanation: 'A floating pin has undefined voltage state. Internal or external pull-up/pull-down resistors ensure a determinate default logic level.',
          concept: 'Pull-up & Pull-down Resistors',
          difficulty: 'Beginner',
        },
        {
          id: 'q-3',
          question: 'In an embedded C/C++ program on ESP32, what does the "volatile" keyword prevent the compiler optimizer from doing?',
          options: ['Placing the variable in Flash memory', 'Caching the variable in a CPU register instead of reading from memory on every access', 'Allocating memory on the stack', 'Allowing the variable to be shared between functions'],
          correctIndex: 1,
          explanation: 'Hardware registers and variables updated inside Interrupt Service Routines (ISRs) can change outside code flow; volatile forces fresh memory reads.',
          concept: 'Volatile Memory Qualifier',
          difficulty: 'Intermediate',
        },
        {
          id: 'q-4',
          question: 'Which synchronous serial protocol uses two open-drain bidirectional lines: SDA (Serial Data) and SCL (Serial Clock)?',
          options: ['SPI', 'UART', 'I2C', 'CAN Bus'],
          correctIndex: 2,
          explanation: 'I2C requires only two lines and supports multiple master and slave devices addressed over the bus.',
          concept: 'I2C Bus Protocol',
          difficulty: 'Beginner',
        },
        {
          id: 'q-5',
          question: 'Why must execution time inside an Interrupt Service Routine (ISR) be kept as short as possible?',
          options: ['To avoid battery drain only', 'To prevent blocking other system interrupts and avoiding FreeRTOS watchdog timer resets', 'Because ISRs cannot execute more than 10 lines of assembly', 'To save flash memory space'],
          correctIndex: 1,
          explanation: 'Long-running ISRs block nested or equal priority interrupts, causing packet loss and triggering watchdog panics.',
          concept: 'Interrupt Service Routines (ISR)',
          difficulty: 'Intermediate',
        },
        {
          id: 'q-6',
          question: 'What is the fundamental difference between SPI and I2C protocols regarding data transfer throughput?',
          options: ['I2C is much faster than SPI because it has fewer wires', 'SPI is full-duplex with dedicated MOSI/MISO lines capable of much higher clock speeds than I2C', 'SPI requires external pull-up resistors on every line', 'I2C supports full-duplex multi-megabyte streaming while SPI is half-duplex'],
          correctIndex: 1,
          explanation: 'SPI supports high-speed full-duplex transfers often exceeding 20MHz, whereas standard I2C typically runs at 100kHz or 400kHz.',
          concept: 'SPI vs I2C Throughput',
          difficulty: 'Intermediate',
        },
        {
          id: 'q-7',
          question: 'How does the FreeRTOS preemptive scheduler determine which task executes when multiple tasks are ready?',
          options: ['It uses alphabetical ordering of task names', 'It executes the ready task with the highest assigned numerical priority', 'It executes tasks in the exact chronological order they were created', 'It runs all tasks synchronously on a single CPU cycle'],
          correctIndex: 1,
          explanation: 'FreeRTOS uses priority-based preemptive scheduling; the highest priority task ready to run always preempts lower priority tasks.',
          concept: 'FreeRTOS Task Scheduling',
          difficulty: 'Intermediate',
        },
        {
          id: 'q-8',
          question: 'Which MQTT Quality of Service (QoS) level guarantees that a telemetry message is delivered exactly once without duplicates?',
          options: ['QoS 0 (At most once)', 'QoS 1 (At least once)', 'QoS 2 (Exactly once)', 'QoS 3 (Guaranteed streaming)'],
          correctIndex: 2,
          explanation: 'QoS 2 uses a four-step handshake (PUBLISH, PUBREC, PUBREL, PUBCOMP) guaranteeing delivery exactly once.',
          concept: 'MQTT Protocol QoS Levels',
          difficulty: 'Intermediate',
        },
        {
          id: 'q-9',
          question: 'When reading an analog sensor through the ESP32 ADC, what is the nominal digital resolution of the built-in SAR ADC?',
          options: ['8-bit (0–255)', '10-bit (0–1023)', '12-bit (0–4095)', '16-bit (0–65535)'],
          correctIndex: 2,
          explanation: 'The ESP32 features 12-bit SAR ADCs yielding digital integer readings from 0 to 4095 across the configured attenuation range.',
          concept: 'ADC Sampling & Resolution',
          difficulty: 'Beginner',
        },
        {
          id: 'q-10',
          question: 'How do you prevent race conditions when two concurrent FreeRTOS tasks read and write to the same peripheral bus?',
          options: ['Increase the CPU clock frequency to 240MHz', 'Protect the shared resource using a Mutex (Mutual Exclusion Semaphore)', 'Declare all peripheral registers as static const', 'Disable all Wi-Fi and Bluetooth radios'],
          correctIndex: 1,
          explanation: 'Mutexes provide mutually exclusive locking and implement priority inheritance to prevent priority inversion.',
          concept: 'FreeRTOS Mutex & Concurrency',
          difficulty: 'Advanced',
        },
      ];
      return { topic, questions: pool.slice(0, count) };
    }

    // 2. Cybersecurity & DevSecOps
    if (key.includes('cyber') || key.includes('security') || key.includes('owasp') || key.includes('nmap') || key.includes('pentest') || key.includes('devsecops')) {
      const pool: QuizQuestionItem[] = [
        {
          id: 'q-1',
          question: 'What is the most effective industry defense against SQL Injection (SQLi) vulnerabilities?',
          options: ['Parameterized queries and prepared statements', 'Regex filtering on the client side only', 'Changing database port numbers', 'Restarting the database nightly'],
          correctIndex: 0,
          explanation: 'Parameterized queries ensure user input is treated strictly as data parameters, preventing arbitrary SQL execution.',
          concept: 'SQL Injection Defense',
          difficulty: 'Beginner',
        },
        {
          id: 'q-2',
          question: 'Which tool is universally used by security engineers for deep packet capture and protocol analysis?',
          options: ['Wireshark', 'Postman', 'Docker', 'Webpack'],
          correctIndex: 0,
          explanation: 'Wireshark is the standard packet analysis tool used to inspect network traffic and troubleshoot protocol issues.',
          concept: 'Network Protocol Analysis',
          difficulty: 'Beginner',
        },
        {
          id: 'q-3',
          question: 'What does the "Shift Left" philosophy emphasize in modern DevSecOps pipelines?',
          options: ['Integrating security testing early in the software development lifecycle', 'Moving databases to left-hand cloud data centers', 'Delaying security audits until production release', 'Running code reviews only on frontend modules'],
          correctIndex: 0,
          explanation: 'Shift Left incorporates automated security testing (SAST, DAST, secret scanning) into the earliest coding and commit phases.',
          concept: 'DevSecOps Automation',
          difficulty: 'Intermediate',
        },
        {
          id: 'q-4',
          question: 'What is the primary difference between Stored XSS and Reflected XSS?',
          options: ['Stored XSS persists in the database and impacts multiple users; Reflected XSS is reflected immediately off a malicious URL', 'Stored XSS only executes on mobile browsers', 'Reflected XSS bypasses HTTPS entirely', 'Stored XSS does not use JavaScript'],
          correctIndex: 0,
          explanation: 'Stored XSS permanently stores the malicious payload in database storage, whereas Reflected XSS is reflected in the immediate server response.',
          concept: 'Cross-Site Scripting (XSS)',
          difficulty: 'Intermediate',
        },
        {
          id: 'q-5',
          question: 'How does the SameSite=Strict cookie attribute protect web applications against Cross-Site Request Forgery (CSRF)?',
          options: ['It encrypts the entire HTTP body using AES-256', 'It prevents the browser from sending the cookie in any cross-site request context', 'It changes the user password automatically', 'It prevents client-side JavaScript from reading document.cookie'],
          correctIndex: 1,
          explanation: 'SameSite=Strict ensures cookies are only sent when navigating within the original site context, neutralizing cross-origin forged requests.',
          concept: 'CSRF Defense & Cookie Security',
          difficulty: 'Intermediate',
        },
        {
          id: 'q-6',
          question: 'In modern JWT authentication architectures, what is the best practice for storing refresh tokens on mobile/web clients?',
          options: ['Plain local storage without encryption', 'In an HTTP-only, secure, SameSite cookie or OS secure keychain/keystore', 'In a public Git repository', 'In plain URL query parameters'],
          correctIndex: 1,
          explanation: 'Secure OS keychains (or HTTP-only cookies) prevent malicious JavaScript from exfiltrating sensitive refresh tokens.',
          concept: 'JWT Token Security',
          difficulty: 'Intermediate',
        },
        {
          id: 'q-7',
          question: 'What is the primary security risk of running Docker containers with the "--privileged" flag in production?',
          options: ['The container consumes twice as much disk space', 'The container process gains root access to the host kernel, enabling container breakouts', 'Docker daemon stops accepting network connections', 'The container cannot expose any TCP ports'],
          correctIndex: 1,
          explanation: '--privileged disables container isolation capabilities, giving the container full device access to the underlying host.',
          concept: 'Container Hardening & Isolation',
          difficulty: 'Advanced',
        },
        {
          id: 'q-8',
          question: 'During network penetration testing, which Nmap scan flag initiates a TCP SYN stealth scan without completing the 3-way handshake?',
          options: ['-sS', '-sT', '-sU', '-sP'],
          correctIndex: 0,
          explanation: '-sS sends a SYN packet and awaits SYN/ACK. Upon reply, it immediately sends RST instead of ACK, leaving the connection unestablished.',
          concept: 'Nmap Port Scanning',
          difficulty: 'Intermediate',
        },
        {
          id: 'q-9',
          question: 'What is the core tenet of the "Zero Trust" security model?',
          options: ['Trust every internal network request behind the firewall', 'Never trust, always verify: authenticate and authorize every transaction regardless of origin', 'Disable all cryptographic certificates', 'Rely solely on perimeter firewalls'],
          correctIndex: 1,
          explanation: 'Zero Trust assumes breaches are inevitable and requires strict micro-segmentation, continuous identity verification, and least privilege.',
          concept: 'Zero Trust Architecture',
          difficulty: 'Beginner',
        },
        {
          id: 'q-10',
          question: 'How does Public Key Cryptography (Asymmetric Encryption) establish mutual confidentiality and authentication in TLS 1.3?',
          options: ['By using the same single password on both client and server', 'By using a public key for encryption and a mathematically linked private key for decryption', 'By hashing data with MD5 checksums', 'By compressing data packets over UDP'],
          correctIndex: 1,
          explanation: 'Asymmetric encryption uses keypairs to perform key exchange (e.g. ECDHE), ensuring symmetric session keys are securely negotiated.',
          concept: 'Cryptography & TLS',
          difficulty: 'Advanced',
        },
      ];
      return { topic, questions: pool.slice(0, count) };
    }

    // 3. AI & Data Science
    if (key.includes('ai') || key.includes('machine learning') || key.includes('data science') || key.includes('data') || key.includes('pandas') || key.includes('model')) {
      const pool: QuizQuestionItem[] = [
        {
          id: 'q-1',
          question: 'What is the primary symptom indicating that a machine learning model is severely overfitting?',
          options: ['High accuracy on training data but significantly worse accuracy on validation data', 'Training loss and validation loss are both near zero', 'Model takes less than one second to train', 'The learning rate is too low'],
          correctIndex: 0,
          explanation: 'Overfitting occurs when a model memorizes noise in the training set and fails to generalize to unseen validation data.',
          concept: 'Model Generalization & Overfitting',
          difficulty: 'Beginner',
        },
        {
          id: 'q-2',
          question: 'What is the core architectural advantage of Retrieval-Augmented Generation (RAG)?',
          options: ['It provides external verifiable context to the LLM to prevent hallucinations and ground responses', 'It removes the need for vector embeddings', 'It trains the model from scratch every request', 'It reduces neural network layers to zero'],
          correctIndex: 0,
          explanation: 'RAG retrieves relevant domain documents dynamically and injects them into the prompt, grounding the model in factual data.',
          concept: 'RAG Architecture & Grounding',
          difficulty: 'Intermediate',
        },
        {
          id: 'q-3',
          question: 'In Pandas, what is the primary difference between .loc[] and .iloc[] indexing?',
          options: ['.loc uses label-based indexing, whereas .iloc uses integer position-based indexing', '.loc is for columns only, .iloc is for rows only', '.loc is deprecated in Pandas 2.0', 'They are completely identical aliases'],
          correctIndex: 0,
          explanation: '.loc indexes by row/column labels, while .iloc strictly indexes by 0-based integer positional coordinates.',
          concept: 'Pandas Indexing Semantics',
          difficulty: 'Beginner',
        },
        {
          id: 'q-4',
          question: 'Why is feature scaling (e.g. StandardScaler or MinMaxScaler) critical before training gradient-descent based algorithms?',
          options: ['It prevents features with large numeric scales from dominating gradients and delaying convergence', 'It automatically imputes missing null values', 'It converts categorical strings into one-hot vectors', 'It reduces the total number of dataset rows'],
          correctIndex: 0,
          explanation: 'Features on differing scales cause elongated gradient descent contours, resulting in slow or unstable optimization.',
          concept: 'Feature Engineering & Scaling',
          difficulty: 'Intermediate',
        },
        {
          id: 'q-5',
          question: 'In an imbalanced classification problem (e.g. 99% benign, 1% fraudulent), why is Accuracy a misleading performance metric?',
          options: ['A naive model predicting only "benign" achieves 99% accuracy while detecting zero fraud cases', 'Accuracy cannot be calculated on binary labels', 'Accuracy is only for regression tasks', 'Accuracy values exceed 100% on imbalanced data'],
          correctIndex: 0,
          explanation: 'On imbalanced datasets, high accuracy can mask complete failure to detect the minority positive class. Precision, Recall, and F1 are required.',
          concept: 'Classification Evaluation Metrics',
          difficulty: 'Intermediate',
        },
        {
          id: 'q-6',
          question: 'What is the mathematical purpose of Cosine Similarity in vector search databases (e.g. Pinecone, ChromaDB)?',
          options: ['To measure the angle difference between high-dimensional dense embeddings irrespective of magnitude', 'To calculate the Euclidean distance in 2D pixels', 'To multiply two matrices without loss of precision', 'To encrypt vector embeddings'],
          correctIndex: 0,
          explanation: 'Cosine similarity computes the normalized dot product of two vectors, measuring directional semantic alignment.',
          concept: 'Vector Embeddings & Similarity',
          difficulty: 'Intermediate',
        },
        {
          id: 'q-7',
          question: 'How does k-Fold Cross-Validation provide a more robust estimate of model performance compared to a single train-test split?',
          options: ['By iteratively training and evaluating on k distinct folds so every data sample is used in test validation', 'By quadrupling the number of training samples artificially', 'By training k completely different neural network architectures', 'By eliminating the need for validation loss curves'],
          correctIndex: 0,
          explanation: 'k-Fold cross-validation averages performance across k validation subsets, reducing variance associated with a single arbitrary split.',
          concept: 'Cross-Validation Strategies',
          difficulty: 'Intermediate',
        },
        {
          id: 'q-8',
          question: 'What is the vanishing gradient problem in deep neural networks, and how do residual connections (ResNet) solve it?',
          options: ['Gradients become exponentially small as backpropagation traverses early layers; skip connections allow gradients to flow directly', 'Weights become infinite; skip connections divide weights by zero', 'Neurons stop firing; skip connections turn off activation functions', 'Data is lost in GPU memory; skip connections duplicate the dataset'],
          correctIndex: 0,
          explanation: 'Skip connections add input identity to layer output, creating direct gradient highways that prevent vanishing gradients during backpropagation.',
          concept: 'Deep Neural Network Optimization',
          difficulty: 'Advanced',
        },
        {
          id: 'q-9',
          question: 'What is the primary role of the temperature parameter during Large Language Model (LLM) text generation?',
          options: ['It controls CPU core temperature', 'It scales the softmax logit distribution, balancing predictability (low temperature) vs diversity (high temperature)', 'It sets the maximum token length of generated output', 'It adjusts the context window buffer size'],
          correctIndex: 1,
          explanation: 'Lower temperature sharpens the probability distribution around the most likely token; higher temperature flattens it, introducing variety.',
          concept: 'LLM Generation Parameters',
          difficulty: 'Beginner',
        },
        {
          id: 'q-10',
          question: 'In Scikit-Learn pipelines, why is it essential to fit transformers (e.g. imputers, scalers) ONLY on the training split?',
          options: ['To prevent data leakage from the test/validation set into the model training pipeline', 'Because Scikit-Learn throws an error if fit() is called twice', 'To speed up training by 50%', 'Because test data cannot contain numbers'],
          correctIndex: 0,
          explanation: 'Fitting transformers on test data leaks statistical distribution parameters (mean, variance) from the test set, giving overly optimistic test metrics.',
          concept: 'Data Leakage Prevention',
          difficulty: 'Advanced',
        },
      ];
      return { topic, questions: pool.slice(0, count) };
    }

    // 4. Flutter & Mobile Engineering
    if (key.includes('flutter') || key.includes('dart') || key.includes('mobile')) {
      const pool: QuizQuestionItem[] = [
        {
          id: 'q-1',
          question: 'In Flutter, what fundamental distinction separates a StatefulWidget from a StatelessWidget?',
          options: ['StatefulWidget maintains a mutable State object that survives rebuilds and triggers setState', 'StatelessWidget cannot display any text or images', 'StatefulWidget can only be rendered on Android devices', 'StatelessWidget runs in a separate CPU isolate'],
          correctIndex: 0,
          explanation: 'StatefulWidget creates a State object which holds mutable state across widget tree rebuilds.',
          concept: 'Widget Tree Lifecycle',
          difficulty: 'Beginner',
        },
        {
          id: 'q-2',
          question: 'How does Riverpod AsyncValue improve asynchronous UI rendering in production Flutter applications?',
          options: ['It models data, loading, and error states explicitly to prevent unhandled asynchronous crashes', 'It automatically converts JSON to SQL tables', 'It forces all network requests to run synchronously', 'It disables widget animations'],
          correctIndex: 0,
          explanation: 'AsyncValue provides pattern-matching (.when) over loading, error, and data states for async operations.',
          concept: 'Riverpod State Management',
          difficulty: 'Intermediate',
        },
        {
          id: 'q-3',
          question: 'How should long-running CPU calculations (e.g. image parsing, crypto) be executed in Flutter without causing UI frame drops (jank)?',
          options: ['Offload the calculation to a background Dart isolate using compute() or Isolate.spawn()', 'Execute the loop inside build() with a short delay', 'Wrap the calculation in a Future.delayed(Duration.zero)', 'Disable hardware acceleration in MaterialApp'],
          correctIndex: 0,
          explanation: 'Dart is single-threaded per isolate; heavy CPU computations must run in a separate background isolate to keep the UI at 60/120fps.',
          concept: 'Dart Concurrency & Isolates',
          difficulty: 'Advanced',
        },
        {
          id: 'q-4',
          question: 'What is the purpose of the const constructor on Flutter widgets when composing widget trees?',
          options: ['It tells the Flutter engine to cache the widget instance and skip rebuilding it during tree passes', 'It forces the widget to be immutable at compile time only', 'It prevents the widget from being clicked', 'It makes the widget visible in light mode only'],
          correctIndex: 0,
          explanation: 'Const widgets are instantiated once at compile time; Flutter skips rebuilding const subtree nodes when parent widgets rebuild.',
          concept: 'Widget Rebuild Optimization',
          difficulty: 'Beginner',
        },
        {
          id: 'q-5',
          question: 'Why should BuildContext never be accessed across an asynchronous gap without checking "if (!mounted) return"?',
          options: ['The widget may have been unmounted/disposed from the element tree while the async task awaited, causing a crash', 'BuildContext is deleted every 5 seconds', 'BuildContext cannot be used after any Future', 'Dart garbage collector collects BuildContext immediately'],
          correctIndex: 0,
          explanation: 'If a user navigates away before an HTTP request returns, referencing the stale context throws a deactivated element exception.',
          concept: 'BuildContext & Mounted Lifecycle',
          difficulty: 'Intermediate',
        },
        {
          id: 'q-6',
          question: 'In Flutter Riverpod, why should autoDispose be used on state providers tied to specific screens?',
          options: ['It automatically disposes provider state when no longer listened to, preventing memory leaks', 'It deletes the user database', 'It forces garbage collection on every frame', 'It restricts provider access to one file'],
          correctIndex: 0,
          explanation: 'autoDispose ensures that when a screen unmounts, transient state, subscriptions, and cached responses are freed from memory.',
          concept: 'Riverpod Lifecycle Management',
          difficulty: 'Intermediate',
        },
        {
          id: 'q-7',
          question: 'What is the role of Keys (e.g. ValueKey, GlobalKey) when modifying collections in stateful widget lists?',
          options: ['They preserve widget state by helping the framework match widgets to their corresponding element nodes across list mutations', 'They act as database primary keys', 'They are strictly for automated integration testing', 'They encrypt widget attributes'],
          correctIndex: 0,
          explanation: 'Keys provide unique identity across list reordering, ensuring existing state objects attach to the correct widget elements.',
          concept: 'Flutter Keys & Element Trees',
          difficulty: 'Intermediate',
        },
        {
          id: 'q-8',
          question: 'When implementing offline-first architecture in Flutter, how should local cache synchronization be structured?',
          options: ['Cache network responses locally (e.g. SQLite/Hive/SecureStorage) and render from local cache while fetching fresh data in the background', 'Block the UI until 5G connection is established', 'Store all data in RAM static variables', 'Disable all offline capability'],
          correctIndex: 0,
          explanation: 'Offline-first systems serve local cached records immediately for instant UI rendering, synchronizing delta updates asynchronously.',
          concept: 'Offline Cache & Sync Architecture',
          difficulty: 'Intermediate',
        },
        {
          id: 'q-9',
          question: 'How do Dio Interceptors enhance production Flutter network layers?',
          options: ['They provide centralized hooks for injecting auth headers, logging requests, and automatic token refresh on 401 errors', 'They compress image files before display', 'They replace HTTP with WebSockets automatically', 'They translate strings to foreign languages'],
          correctIndex: 0,
          explanation: 'Interceptors intercept onRequest, onResponse, and onError globally, enabling centralized token rotation and error handling.',
          concept: 'Dio HTTP Interceptors',
          difficulty: 'Intermediate',
        },
        {
          id: 'q-10',
          question: 'How does Flutter communicate with native Android (Kotlin) and iOS (Swift) platform APIs?',
          options: ['Through MethodChannels and PlatformChannels passing serialized binary messages', 'Through raw HTTP localhost sockets', 'By compiling Dart directly to Swift', 'By embedding a hidden WebView'],
          correctIndex: 0,
          explanation: 'MethodChannels use asynchronous binary message passing between the Dart VM and the host native platform engine.',
          concept: 'Platform Channels & Native Interop',
          difficulty: 'Advanced',
        },
      ];
      return { topic, questions: pool.slice(0, count) };
    }

    // 5. Backend, Systems & Cloud Default
    const defaultPool: QuizQuestionItem[] = [
      {
        id: 'q-1',
        question: 'What is the primary function of an HTTP GET request in a RESTful API?',
        options: ['To retrieve data representation from the server safely without side-effects', 'To create a new server resource record', 'To delete a database table', 'To authenticate user credentials'],
        correctIndex: 0,
        explanation: 'GET is safe and idempotent, intended exclusively for retrieving server resources without modifying server state.',
        concept: 'HTTP Methods & Idempotency',
        difficulty: 'Beginner',
      },
      {
        id: 'q-2',
        question: 'Which HTTP status code should a server return when authentication credentials are missing or invalid?',
        options: ['401 Unauthorized', '200 OK', '403 Forbidden', '500 Internal Server Error'],
        correctIndex: 0,
        explanation: '401 Unauthorized signifies that the request lacks valid authentication credentials for the target resource.',
        concept: 'HTTP Status Codes',
        difficulty: 'Beginner',
      },
      {
        id: 'q-3',
        question: 'What is the primary purpose of creating a B-Tree index on a database table column?',
        options: ['To significantly speed up SELECT queries filtering or joining on that column by avoiding full table scans', 'To encrypt the data stored in the column', 'To prevent any rows from being deleted', 'To automatically format text to uppercase'],
        correctIndex: 0,
        explanation: 'Indexes create balanced tree search structures that reduce query lookup time complexity from O(N) to O(log N).',
        concept: 'Database Indexing',
        difficulty: 'Intermediate',
      },
      {
        id: 'q-4',
        question: 'What does the "Atomicity" property guarantee in ACID database transactions?',
        options: ['All operations in the transaction succeed together, or all fail and are rolled back completely', 'Data is stored at the atomic particle level', 'Queries execute in zero milliseconds', 'Tables cannot have foreign keys'],
        correctIndex: 0,
        explanation: 'Atomicity ensures that a multi-step transaction is treated as a single indivisible unit: all changes commit, or none do.',
        concept: 'ACID Transaction Properties',
        difficulty: 'Intermediate',
      },
      {
        id: 'q-5',
        question: 'Why are database connection pools used in production backend architectures instead of opening a new TCP connection per query?',
        options: ['Creating and tearing down database TCP handshakes and TLS connections is expensive and degrades throughput', 'Databases only allow one single TCP connection globally', 'Connection pools encrypt all SQL statements', 'Connection pools remove the need for SQL queries'],
        correctIndex: 0,
        explanation: 'Connection pooling reuses established connections, reducing latency and protecting database socket limits.',
        concept: 'Connection Pooling',
        difficulty: 'Intermediate',
      },
      {
        id: 'q-6',
        question: 'In distributed caching with Redis, what is the "Cache Stampede" (thundering herd) problem and how is it mitigated?',
        options: ['When a popular key expires, thousands of concurrent requests simultaneously hit the database; mitigated using mutex locks or probabilistic early expiration', 'Redis runs out of disk space', 'Network wires disconnect physically', 'Redis converts strings into integers'],
        correctIndex: 0,
        explanation: 'Cache stampedes overwhelm databases on key expiration; locking or probabilistic early refreshing prevents concurrent recomputation.',
        concept: 'Distributed Caching Strategies',
        difficulty: 'Advanced',
      },
      {
        id: 'q-7',
        question: 'What is the N+1 query problem when querying relational databases through an ORM like Prisma or Hibernate?',
        options: ['Executing 1 query to fetch parents, and then N separate queries to fetch children instead of a single JOIN', 'A query that takes N+1 seconds to run', 'A syntax error on line N+1', 'A query that returns N+1 rows'],
        correctIndex: 0,
        explanation: 'N+1 queries degrade performance drastically. Using eager loading or batching (include/JOIN) resolves child data in 1–2 queries.',
        concept: 'ORM Performance & N+1 Problem',
        difficulty: 'Intermediate',
      },
      {
        id: 'q-8',
        question: 'How do multi-stage Docker builds reduce the final production container image size?',
        options: ['By compiling code in a build stage with SDK tools and copying only the final binary into a minimal runtime image (e.g. Alpine/Distroless)', 'By compressing images with ZIP format', 'By deleting all node_modules', 'By running containers without an operating system'],
        correctIndex: 0,
        explanation: 'Multi-stage builds separate build dependencies from the runtime image, cutting image sizes from gigabytes down to megabytes.',
        concept: 'Docker Multi-stage Builds',
        difficulty: 'Intermediate',
      },
      {
        id: 'q-9',
        question: 'What is the difference between horizontal scaling and vertical scaling in server architecture?',
        options: ['Horizontal scaling adds more machine instances; vertical scaling upgrades CPU/RAM on existing machines', 'Horizontal scaling is for databases only', 'Vertical scaling moves servers to the cloud', 'Horizontal scaling requires turning off servers at night'],
        correctIndex: 0,
        explanation: 'Horizontal scaling achieves high availability and elasticity by distributing traffic across multiple instances.',
        concept: 'System Scalability Principles',
        difficulty: 'Beginner',
      },
      {
        id: 'q-10',
        question: 'Why should Cross-Origin Resource Sharing (CORS) headers be strictly configured on production API servers?',
        options: ['To restrict unauthorized web browser origins from reading sensitive API responses on behalf of authenticated users', 'To force mobile apps to use HTTPS', 'To increase Wi-Fi signal strength', 'To format server responses as XML'],
        correctIndex: 0,
        explanation: 'CORS prevents malicious websites from executing cross-origin requests and reading protected server responses in user browser sessions.',
        concept: 'CORS & Web Security',
        difficulty: 'Intermediate',
      },
    ];

    return { topic, questions: defaultPool.slice(0, count) };
  }

  static async generateAdaptiveQuiz(
    _userId: string,
    params: {
      topic: string;
      phaseNumber?: number;
      roadmapId?: string;
      skillName?: string;
      targetDifficulty?: string;
      numQuestions?: number;
    }
  ) {
    const targetCount = params.numQuestions || 10;

    if (params.roadmapId) {
      try {
        const roadmap = await prisma.careerRoadmap.findUnique({
          where: { id: params.roadmapId },
          select: { phases_json: true },
        });
        const phases = (roadmap?.phases_json as any[]) || [];
        const phase = phases.find(
          (p) => p.phase_number === (params.phaseNumber || 1) || p.phaseNumber === (params.phaseNumber || 1)
        );

        const phaseQuestions = phase?.quiz?.questions;
        if (Array.isArray(phaseQuestions) && phaseQuestions.length >= targetCount) {
          return {
            topic: phase.title || params.topic,
            questions: phaseQuestions.slice(0, targetCount).map((q: any, idx: number) => ({
              id: `q-${idx + 1}`,
              question: q.question,
              options: q.options,
              correctIndex: q.correct_index ?? q.correctIndex ?? 0,
              explanation: q.explanation || 'Verified checkpoint concept.',
              concept: phase.skills?.[idx] || params.topic,
              difficulty: 'Intermediate' as const,
            })),
          };
        } else if (Array.isArray(phaseQuestions) && phaseQuestions.length > 0) {
          // Backfill to reach targetCount so the student receives a full 10-question quiz!
          const mappedPhaseQ: QuizQuestionItem[] = phaseQuestions.map((q: any, idx: number) => ({
            id: `q-${idx + 1}`,
            question: q.question,
            options: q.options,
            correctIndex: q.correct_index ?? q.correctIndex ?? 0,
            explanation: q.explanation || 'Verified checkpoint concept.',
            concept: phase.skills?.[idx] || params.topic,
            difficulty: 'Intermediate' as const,
          }));

          const fallback = adaptiveQuizService.getFallbackQuiz(phase.title || params.topic, targetCount);
          const needed = targetCount - mappedPhaseQ.length;
          const additional = fallback.questions
            .filter((fq) => !mappedPhaseQ.some((pq) => pq.question === fq.question))
            .slice(0, needed)
            .map((q, idx) => ({ ...q, id: `q-${mappedPhaseQ.length + idx + 1}` }));

          return {
            topic: phase.title || params.topic,
            questions: [...mappedPhaseQ, ...additional],
          };
        }
      } catch {
        // Fall back to dynamic generator
      }
    }

    return adaptiveQuizService.generateQuiz({
      topic: params.topic,
      numQuestions: targetCount,
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
