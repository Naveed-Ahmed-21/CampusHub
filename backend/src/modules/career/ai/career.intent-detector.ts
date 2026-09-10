export type CareerAIIntent =
  | 'LEARNING_QUESTION'
  | 'ROADMAP_QUESTION'
  | 'CAREER_ADVICE'
  | 'SKILL_QUESTION'
  | 'RESOURCE_REQUEST'
  | 'PROJECT_REQUEST'
  | 'QUIZ_REQUEST'
  | 'INTERVIEW_REQUEST'
  | 'PROGRESS_QUESTION'
  | 'CONFUSION'
  | 'TECHNICAL_DOUBT'
  | 'GENERAL_CAMPUSHUB_HELP'
  | 'OFF_TOPIC';

export class CareerIntentDetector {
  static detectIntent(message: string): { intent: CareerAIIntent; confidence: number; isOffTopic: boolean } {
    const text = message.trim().toLowerCase();

    // 1. Off-Topic Check
    const offTopicKeywords = [
      'who won',
      'cricket',
      'football',
      'match',
      'score of the match',
      'joke',
      'tell me a joke',
      'weather',
      'movie',
      'song',
      'dating',
      'politics',
      'president',
      'election',
      'horoscope',
    ];
    if (offTopicKeywords.some((k) => text.includes(k))) {
      return { intent: 'OFF_TOPIC', confidence: 0.98, isOffTopic: true };
    }

    // 2. Interview Simulation Intent
    if (
      text.includes('interview') ||
      text.includes('mock interview') ||
      text.includes('simulate') ||
      text.includes('eva interview') ||
      text.includes('behavioral question')
    ) {
      return { intent: 'INTERVIEW_REQUEST', confidence: 0.95, isOffTopic: false };
    }

    // 3. Quiz Intent
    if (
      text.includes('quiz') ||
      text.includes('test me') ||
      text.includes('test what i learned') ||
      text.includes('mcq') ||
      text.includes('assessment')
    ) {
      return { intent: 'QUIZ_REQUEST', confidence: 0.94, isOffTopic: false };
    }

    // 4. Resource & YouTube Request
    if (
      text.includes('resource') ||
      text.includes('youtube') ||
      text.includes('tutorial') ||
      text.includes('docs') ||
      text.includes('documentation') ||
      text.includes('videos') ||
      text.includes('book') ||
      text.includes('where can i learn') ||
      text.includes('course')
    ) {
      return { intent: 'RESOURCE_REQUEST', confidence: 0.93, isOffTopic: false };
    }

    // 5. Project Request
    if (
      text.includes('project') ||
      text.includes('build something') ||
      text.includes('portfolio project') ||
      text.includes('mini project') ||
      text.includes('capstone')
    ) {
      return { intent: 'PROJECT_REQUEST', confidence: 0.92, isOffTopic: false };
    }

    // 6. Confusion & Direction
    if (
      text.includes("i'm confused") ||
      text.includes('im confused') ||
      text.includes('not sure') ||
      text.includes("don't know what to learn") ||
      text.includes('starting from zero') ||
      text.includes('where to start') ||
      text.includes('stuck')
    ) {
      return { intent: 'CONFUSION', confidence: 0.95, isOffTopic: false };
    }

    // 7. Progress & Timeline Adjustment
    if (
      text.includes('progress') ||
      text.includes('only have one hour') ||
      text.includes('only have 1 hour') ||
      text.includes('change deadline') ||
      text.includes('my streak') ||
      text.includes('how far am i') ||
      text.includes('completed today')
    ) {
      return { intent: 'PROGRESS_QUESTION', confidence: 0.91, isOffTopic: false };
    }

    // 8. Roadmap Questions & "What to learn next"
    if (
      text.includes('roadmap') ||
      text.includes('what should i learn next') ||
      text.includes('what next') ||
      text.includes('next step') ||
      text.includes('next topic') ||
      text.includes('phase')
    ) {
      return { intent: 'ROADMAP_QUESTION', confidence: 0.93, isOffTopic: false };
    }

    // 9. Technical Doubt & Errors
    if (
      text.includes('why is my') ||
      text.includes('error') ||
      text.includes('bug') ||
      text.includes('exception') ||
      text.includes('401') ||
      text.includes('500') ||
      text.includes('not working') ||
      text.includes('failed to compile') ||
      text.includes('syntax error')
    ) {
      return { intent: 'TECHNICAL_DOUBT', confidence: 0.92, isOffTopic: false };
    }

    // 10. Skill Question
    if (
      text.includes('skill') ||
      text.includes('weak area') ||
      text.includes('improve') ||
      text.includes('gap') ||
      text.includes('mastery')
    ) {
      return { intent: 'SKILL_QUESTION', confidence: 0.88, isOffTopic: false };
    }

    // 11. Career Advice
    if (
      text.includes('job') ||
      text.includes('placement') ||
      text.includes('career') ||
      text.includes('salary') ||
      text.includes('market demand') ||
      text.includes('resume') ||
      text.includes('internship')
    ) {
      return { intent: 'CAREER_ADVICE', confidence: 0.89, isOffTopic: false };
    }

    // 12. General Learning Question (Default for tech concepts: Riverpod, Bloc, Docker, etc.)
    return { intent: 'LEARNING_QUESTION', confidence: 0.85, isOffTopic: false };
  }
}
