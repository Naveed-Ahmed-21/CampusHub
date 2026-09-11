export interface YouTubeResourceItem {
  id: string;
  title: string;
  channel: string;
  language: string;
  duration: string;
  views: string;
  url: string;
  thumbnailUrl: string;
  isVerified: boolean;
  topic: string;
}

export class YouTubeResourceService {
  private static readonly CURATED_CHANNELS: Record<string, YouTubeResourceItem[]> = {
    'iot': [
      {
        id: 'yt-esp32-1',
        title: 'ESP32 Full Course for Beginners - IoT & Microcontroller Projects',
        channel: 'Tech With Tim',
        language: 'English',
        duration: '2h 45m',
        views: '4.2M views',
        url: 'https://www.youtube.com/watch?v=k_D7p_w-NnU',
        thumbnailUrl: 'https://img.youtube.com/vi/k_D7p_w-NnU/hqdefault.jpg',
        isVerified: true,
        topic: 'Microcontrollers (Arduino/ESP32)',
      },
      {
        id: 'yt-esp32-2',
        title: 'ESP32 Microcontroller Programming in Tamil (GPIO, Sensors, MQTT)',
        channel: 'Let\'s Make Engineering Simple',
        language: 'Tamil',
        duration: '1h 30m',
        views: '320K views',
        url: 'https://www.youtube.com/watch?v=Gk7N0Y4XQ1E',
        thumbnailUrl: 'https://img.youtube.com/vi/Gk7N0Y4XQ1E/hqdefault.jpg',
        isVerified: true,
        topic: 'Microcontrollers (Arduino/ESP32)',
      },
      {
        id: 'yt-esp32-3',
        title: 'Complete IoT & ESP32 Tutorial in Hindi - Sensors & Cloud Connection',
        channel: 'Edureka Hindi',
        language: 'Hindi',
        duration: '2h 10m',
        views: '650K views',
        url: 'https://www.youtube.com/watch?v=Fj2F7eXv9pQ',
        thumbnailUrl: 'https://img.youtube.com/vi/Fj2F7eXv9pQ/hqdefault.jpg',
        isVerified: true,
        topic: 'IoT & Embedded Systems',
      },
    ],
    'flutter': [
      {
        id: 'yt-flt-1',
        title: 'Flutter Crash Course for Beginners 2026',
        channel: 'freeCodeCamp.org',
        language: 'English',
        duration: '3h 15m',
        views: '2.8M views',
        url: 'https://www.youtube.com/watch?v=pTJJsmejUOQ',
        thumbnailUrl: 'https://img.youtube.com/vi/pTJJsmejUOQ/hqdefault.jpg',
        isVerified: true,
        topic: 'Flutter & Dart',
      },
      {
        id: 'yt-flt-2',
        title: 'Flutter Full Course in Tamil - Clean Architecture & Riverpod',
        channel: 'Error Makes Clever Academy',
        language: 'Tamil',
        duration: '2h 20m',
        views: '410K views',
        url: 'https://www.youtube.com/watch?v=1xipgS59OVw',
        thumbnailUrl: 'https://img.youtube.com/vi/1xipgS59OVw/hqdefault.jpg',
        isVerified: true,
        topic: 'Flutter State Management',
      },
      {
        id: 'yt-flt-3',
        title: 'Flutter in Hindi - Complete Beginner to Advanced Mastery',
        channel: 'Thapa Technical',
        language: 'Hindi',
        duration: '4h 05m',
        views: '1.9M views',
        url: 'https://www.youtube.com/watch?v=GLSG_Wh_YWc',
        thumbnailUrl: 'https://img.youtube.com/vi/GLSG_Wh_YWc/hqdefault.jpg',
        isVerified: true,
        topic: 'Mobile Engineering',
      },
    ],
    'backend': [
      {
        id: 'yt-node-1',
        title: 'Node.js and Express.js Full Course (Building Scalable REST APIs)',
        channel: 'freeCodeCamp.org',
        language: 'English',
        duration: '8h 20m',
        views: '3.9M views',
        url: 'https://www.youtube.com/watch?v=Oe421EPjeBE',
        thumbnailUrl: 'https://img.youtube.com/vi/Oe421EPjeBE/hqdefault.jpg',
        isVerified: true,
        topic: 'REST APIs & Node.js',
      },
      {
        id: 'yt-node-2',
        title: 'Chai aur Backend - Production Node.js & Database Architecture',
        channel: 'Chai aur Code',
        language: 'Hindi',
        duration: '12h 45m',
        views: '2.1M views',
        url: 'https://www.youtube.com/watch?v=7fjOw8ApZ1I',
        thumbnailUrl: 'https://img.youtube.com/vi/7fjOw8ApZ1I/hqdefault.jpg',
        isVerified: true,
        topic: 'Backend & Authentication',
      },
    ],
    'dsa': [
      {
        id: 'yt-dsa-1',
        title: 'Data Structures and Algorithms in Tamil - Logic First',
        channel: 'Logic First Tamil',
        language: 'Tamil',
        duration: '6h 10m',
        views: '1.4M views',
        url: 'https://www.youtube.com/watch?v=4_9t5vK9QzU',
        thumbnailUrl: 'https://img.youtube.com/vi/4_9t5vK9QzU/hqdefault.jpg',
        isVerified: true,
        topic: 'DSA & Placement Prep',
      },
      {
        id: 'yt-dsa-2',
        title: 'Complete C++ DSA Course for FAANG Interviews',
        channel: 'freeCodeCamp.org',
        language: 'English',
        duration: '10h 30m',
        views: '5.2M views',
        url: 'https://www.youtube.com/watch?v=8hly31xKli0',
        thumbnailUrl: 'https://img.youtube.com/vi/8hly31xKli0/hqdefault.jpg',
        isVerified: true,
        topic: 'Competitive Programming & DSA',
      },
    ],
  };

  /**
   * Resolves verified YouTube resources prioritized by user's preferred language.
   */
  resolveVideos(topic: string, preferredLanguage: string = 'English', limit: number = 3): YouTubeResourceItem[] {
    const key = topic.toLowerCase();
    let matches: YouTubeResourceItem[] = [];

    for (const [domainKey, videos] of Object.entries(YouTubeResourceService.CURATED_CHANNELS)) {
      if (key.includes(domainKey) || domainKey.includes(key)) {
        matches = [...videos];
        break;
      }
    }

    if (matches.length === 0) {
      matches = [
        ...YouTubeResourceService.CURATED_CHANNELS['dsa'],
        ...YouTubeResourceService.CURATED_CHANNELS['backend'],
      ];
    }

    // Rank by preferred language match first
    const langNormalized = preferredLanguage.trim().toLowerCase();
    const sorted = matches.sort((a, b) => {
      const aMatch = a.language.toLowerCase() === langNormalized ? 1 : 0;
      const bMatch = b.language.toLowerCase() === langNormalized ? 1 : 0;
      return bMatch - aMatch;
    });

    return sorted.slice(0, limit);
  }

  static getEducationalVideos(topic: string, preferredLanguage: string = 'English', limit: number = 3): YouTubeResourceItem[] {
    return youTubeResourceService.resolveVideos(topic, preferredLanguage, limit);
  }
}

export const youTubeResourceService = new YouTubeResourceService();
export const CareerYouTubeService = YouTubeResourceService;
