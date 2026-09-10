import { VERIFIED_DOCUMENTATION_BOOKS, VerifiedDocumentBook } from './career.documentation-library';
export { VERIFIED_DOCUMENTATION_BOOKS, VerifiedDocumentBook };

export interface VerifiedResource {
  title: string;
  description: string;
  url: string;
  source: string;
  type: 'DOCUMENTATION' | 'VIDEO' | 'COURSE' | 'ARTICLE' | 'TUTORIAL' | 'PRACTICE' | 'GITHUB' | 'PROJECT';
  language: string;
  topic: string;
  difficulty: 'Beginner' | 'Intermediate' | 'Advanced';
  canonicalUrl: string;
  estimatedMinutes?: number;
}

export class ResourceResearcher {
  // 1. Curated official documentation directory (Priority 1)
  private static readonly OFFICIAL_DOCS: Record<string, VerifiedResource> = {
    flutter: {
      title: 'Flutter Official Documentation',
      description: 'The authoritative source for building cross-platform apps with Flutter and Dart.',
      url: 'https://docs.flutter.dev',
      source: 'Flutter Dev Team',
      type: 'DOCUMENTATION',
      language: 'English',
      topic: 'Flutter',
      difficulty: 'Beginner',
      canonicalUrl: 'https://docs.flutter.dev',
      estimatedMinutes: 30,
    },
    riverpod: {
      title: 'Riverpod Official Documentation & Guides',
      description: 'A reactive caching framework and state-management system for Flutter/Dart.',
      url: 'https://riverpod.dev',
      source: 'Riverpod',
      type: 'DOCUMENTATION',
      language: 'English',
      topic: 'State Management',
      difficulty: 'Intermediate',
      canonicalUrl: 'https://riverpod.dev',
      estimatedMinutes: 45,
    },
    dart: {
      title: 'Dart Language Tour & Async Programming',
      description: 'Deep dive into sound null safety, isolates, streams, and async-await patterns.',
      url: 'https://dart.dev/guides',
      source: 'Dart Team',
      type: 'DOCUMENTATION',
      language: 'English',
      topic: 'Dart',
      difficulty: 'Beginner',
      canonicalUrl: 'https://dart.dev/guides',
      estimatedMinutes: 25,
    },
    nodejs: {
      title: 'Node.js Official Documentation & Event Loop Internals',
      description: 'Comprehensive guides to non-blocking I/O, streams, clusters, and native modules.',
      url: 'https://nodejs.org/en/docs',
      source: 'OpenJS Foundation',
      type: 'DOCUMENTATION',
      language: 'English',
      topic: 'Backend',
      difficulty: 'Intermediate',
      canonicalUrl: 'https://nodejs.org/en/docs',
      estimatedMinutes: 40,
    },
    postgresql: {
      title: 'PostgreSQL Official Documentation',
      description: 'ACID compliance, B-tree indexes, EXPLAIN ANALYZE query planning, and JSONB operators.',
      url: 'https://www.postgresql.org/docs',
      source: 'PostgreSQL Global Development Group',
      type: 'DOCUMENTATION',
      language: 'English',
      topic: 'Databases',
      difficulty: 'Intermediate',
      canonicalUrl: 'https://www.postgresql.org/docs',
      estimatedMinutes: 35,
    },
    react: {
      title: 'React Official Documentation (react.dev)',
      description: 'Learn React with modern hooks, server components, and concurrent rendering.',
      url: 'https://react.dev',
      source: 'Meta Open Source',
      type: 'DOCUMENTATION',
      language: 'English',
      topic: 'Frontend',
      difficulty: 'Beginner',
      canonicalUrl: 'https://react.dev',
      estimatedMinutes: 30,
    },
    docker: {
      title: 'Docker Documentation & Container Best Practices',
      description: 'Multi-stage builds, volume mounting, container networking, and Docker Compose.',
      url: 'https://docs.docker.com',
      source: 'Docker Inc.',
      type: 'DOCUMENTATION',
      language: 'English',
      topic: 'DevOps',
      difficulty: 'Intermediate',
      canonicalUrl: 'https://docs.docker.com',
      estimatedMinutes: 30,
    },
    git: {
      title: 'Pro Git Book & Interactive Git Guide',
      description: 'Branching strategies, interactive rebase, cherry-pick, and commit discipline.',
      url: 'https://git-scm.com/doc',
      source: 'Git SCM',
      type: 'DOCUMENTATION',
      language: 'English',
      topic: 'Tools',
      difficulty: 'Beginner',
      canonicalUrl: 'https://git-scm.com/doc',
      estimatedMinutes: 20,
    },
  };

  // 2. High-Quality Language-Specific YouTube Educational Content
  private static readonly YOUTUBE_LIBRARY: Record<string, Record<string, VerifiedResource[]>> = {
    Tamil: {
      flutter: [
        {
          title: 'Flutter Complete Tutorial in Tamil | Build Mobile Apps',
          description: 'Step-by-step beginner friendly Flutter journey in Tamil covering widgets, layout, and state.',
          url: 'https://www.youtube.com/results?search_query=flutter+tutorial+tamil',
          source: 'Error Makes Clever / Tutor Joes Tamil',
          type: 'VIDEO',
          language: 'Tamil',
          topic: 'Flutter',
          difficulty: 'Beginner',
          canonicalUrl: 'https://youtube.com/search?q=flutter+tamil',
          estimatedMinutes: 45,
        },
        {
          title: 'Riverpod & REST API Integration in Tamil',
          description: 'Hands-on tutorial building a real-world news app using Riverpod and Dio in Tamil.',
          url: 'https://www.youtube.com/results?search_query=flutter+riverpod+tamil',
          source: 'Tamil Hacks & Tech',
          type: 'VIDEO',
          language: 'Tamil',
          topic: 'State Management',
          difficulty: 'Intermediate',
          canonicalUrl: 'https://youtube.com/search?q=flutter+riverpod+tamil',
          estimatedMinutes: 50,
        },
      ],
      backend: [
        {
          title: 'Node.js & Express Full Course in Tamil',
          description: 'Learn asynchronous backend architecture, REST API design, and MongoDB/Postgres in Tamil.',
          url: 'https://www.youtube.com/results?search_query=nodejs+tutorial+tamil',
          source: 'Logic First Tamil',
          type: 'VIDEO',
          language: 'Tamil',
          topic: 'Backend',
          difficulty: 'Beginner',
          canonicalUrl: 'https://youtube.com/search?q=nodejs+tamil',
          estimatedMinutes: 60,
        },
      ],
      dsa: [
        {
          title: 'Data Structures & Algorithms in Tamil',
          description: 'Learn Arrays, Linked Lists, Trees, Graphs, and Dynamic Programming explained simply in Tamil.',
          url: 'https://www.youtube.com/results?search_query=dsa+in+tamil+logic+first',
          source: 'Logic First Tamil',
          type: 'VIDEO',
          language: 'Tamil',
          topic: 'DSA',
          difficulty: 'Intermediate',
          canonicalUrl: 'https://youtube.com/search?q=dsa+tamil',
          estimatedMinutes: 40,
        },
      ],
    },
    Hindi: {
      flutter: [
        {
          title: 'Complete Flutter & Dart Playlist in Hindi',
          description: 'Master Flutter UI, animations, state management, and Firebase in clear Hindi.',
          url: 'https://www.youtube.com/results?search_query=flutter+tutorial+in+hindi+thapa',
          source: 'Thapa Technical / CodeWithHarry',
          type: 'VIDEO',
          language: 'Hindi',
          topic: 'Flutter',
          difficulty: 'Beginner',
          canonicalUrl: 'https://youtube.com/search?q=flutter+hindi',
          estimatedMinutes: 45,
        },
        {
          title: 'Riverpod State Management Explained in Hindi',
          description: 'Deep dive into Riverpod providers, NotifierProvider, and AsyncNotifier in Hindi.',
          url: 'https://www.youtube.com/results?search_query=riverpod+flutter+hindi',
          source: 'Chai aur Code / Hitesh Choudhary',
          type: 'VIDEO',
          language: 'Hindi',
          topic: 'State Management',
          difficulty: 'Intermediate',
          canonicalUrl: 'https://youtube.com/search?q=riverpod+hindi',
          estimatedMinutes: 40,
        },
      ],
      backend: [
        {
          title: 'Chai aur Node.js Backend Series (Hindi)',
          description: 'Production-ready Node.js backend development with JWT, aggregation pipelines, and Cloudinary.',
          url: 'https://www.youtube.com/results?search_query=chai+aur+backend+hindi',
          source: 'Chai aur Code',
          type: 'VIDEO',
          language: 'Hindi',
          topic: 'Backend',
          difficulty: 'Intermediate',
          canonicalUrl: 'https://youtube.com/search?q=chai+aur+backend',
          estimatedMinutes: 65,
        },
      ],
      dsa: [
        {
          title: 'DSA Complete Sheet & Placement Preparation in Hindi',
          description: 'Solve top LeetCode patterns with Striver / Love Babbar / Apna College in Hindi.',
          url: 'https://www.youtube.com/results?search_query=dsa+course+in+hindi',
          source: 'take U forward (Striver) / CodeHelp',
          type: 'VIDEO',
          language: 'Hindi',
          topic: 'DSA',
          difficulty: 'Intermediate',
          canonicalUrl: 'https://youtube.com/search?q=dsa+hindi',
          estimatedMinutes: 60,
        },
      ],
    },
    English: {
      flutter: [
        {
          title: 'Flutter Official Widget of the Week Series',
          description: 'Short 2-minute deep dives into every Flutter core widget by Google engineers.',
          url: 'https://www.youtube.com/playlist?list=PLjxrf2q8roU23XGwz3Km7sQZFTdB996iG',
          source: 'Flutter Official YouTube',
          type: 'VIDEO',
          language: 'English',
          topic: 'Flutter',
          difficulty: 'Beginner',
          canonicalUrl: 'https://youtube.com/playlist?list=PLjxrf2q8roU23XGwz3Km7sQZFTdB996iG',
          estimatedMinutes: 20,
        },
        {
          title: 'Riverpod 2.0 Complete Architecture Walkthrough',
          description: 'Build enterprise-ready Flutter architectures with Code With Andrea.',
          url: 'https://www.youtube.com/results?search_query=code+with+andrea+riverpod+architecture',
          source: 'Code With Andrea',
          type: 'VIDEO',
          language: 'English',
          topic: 'State Management',
          difficulty: 'Advanced',
          canonicalUrl: 'https://youtube.com/search?q=code+with+andrea+riverpod',
          estimatedMinutes: 45,
        },
      ],
      backend: [
        {
          title: 'Node.js Full Course for Beginners',
          description: 'Learn Node.js, Express, MongoDB, and REST API deployment from FreeCodeCamp.',
          url: 'https://www.youtube.com/results?search_query=freecodecamp+node+js+course',
          source: 'freeCodeCamp.org',
          type: 'VIDEO',
          language: 'English',
          topic: 'Backend',
          difficulty: 'Beginner',
          canonicalUrl: 'https://youtube.com/search?q=freecodecamp+nodejs',
          estimatedMinutes: 60,
        },
      ],
      dsa: [
        {
          title: 'NeetCode 150 - LeetCode Roadmap & Patterns',
          description: 'Master Two Pointers, Sliding Window, Graphs, Trees, and Dynamic Programming with visual diagrams.',
          url: 'https://neetcode.io/practice',
          source: 'NeetCode',
          type: 'PRACTICE',
          language: 'English',
          topic: 'DSA',
          difficulty: 'Intermediate',
          canonicalUrl: 'https://neetcode.io/practice',
          estimatedMinutes: 45,
        },
      ],
    },
  };

  /**
   * Primary entry point for research:
   * Slices by topic, user's preferred language, and level, with 0 invented URLs and strict deduplication.
   */
  static searchResources(params: {
    topic: string;
    language?: string;
    level?: string;
    targetRole?: string;
  }): VerifiedResource[] {
    const topicLower = params.topic.toLowerCase();
    const lang = (params.language || 'English').trim();
    const matched: VerifiedResource[] = [];
    const seenUrls = new Set<string>();

    // 1. Official Docs Matching (Highest Priority)
    for (const [key, doc] of Object.entries(this.OFFICIAL_DOCS)) {
      if (topicLower.includes(key) || (params.targetRole && params.targetRole.toLowerCase().includes(key))) {
        if (!seenUrls.has(doc.canonicalUrl)) {
          matched.push(doc);
          seenUrls.add(doc.canonicalUrl);
        }
      }
    }

    // Always include Flutter / Dart docs if relevant
    if (topicLower.includes('flutter') || topicLower.includes('widget') || topicLower.includes('state')) {
      if (!seenUrls.has(this.OFFICIAL_DOCS.flutter.canonicalUrl)) {
        matched.push(this.OFFICIAL_DOCS.flutter);
        seenUrls.add(this.OFFICIAL_DOCS.flutter.canonicalUrl);
      }
      if (topicLower.includes('riverpod') && !seenUrls.has(this.OFFICIAL_DOCS.riverpod.canonicalUrl)) {
        matched.push(this.OFFICIAL_DOCS.riverpod);
        seenUrls.add(this.OFFICIAL_DOCS.riverpod.canonicalUrl);
      }
    }

    // 2. YouTube Language-Specific Matching
    const selectedLangLibrary = this.YOUTUBE_LIBRARY[lang] || this.YOUTUBE_LIBRARY['English'];
    for (const [categoryKey, videoList] of Object.entries(selectedLangLibrary)) {
      if (
        topicLower.includes(categoryKey) ||
        (params.targetRole && params.targetRole.toLowerCase().includes(categoryKey))
      ) {
        for (const vid of videoList) {
          if (!seenUrls.has(vid.canonicalUrl)) {
            matched.push(vid);
            seenUrls.add(vid.canonicalUrl);
          }
        }
      }
    }

    // 3. Fallback to English high-quality resources if language library had fewer than 2 items
    if (matched.length < 3 && lang !== 'English') {
      const englishLib = this.YOUTUBE_LIBRARY['English'];
      for (const [categoryKey, videoList] of Object.entries(englishLib)) {
        if (topicLower.includes(categoryKey) || (params.targetRole && params.targetRole.toLowerCase().includes(categoryKey))) {
          for (const vid of videoList) {
            if (!seenUrls.has(vid.canonicalUrl)) {
              matched.push(vid);
              seenUrls.add(vid.canonicalUrl);
            }
          }
        }
      }
    }

    // 4. Always add an interactive Hands-on Practice resource
    if (topicLower.includes('flutter') || topicLower.includes('dart')) {
      const practiceItem: VerifiedResource = {
        title: 'DartPad Interactive In-Browser Practice',
        description: 'Experiment with Dart syntax, Flutter layouts, and custom state without installing SDK.',
        url: 'https://dartpad.dev',
        source: 'Dart Team',
        type: 'PRACTICE',
        language: 'English',
        topic: 'Hands-on Practice',
        difficulty: 'Beginner',
        canonicalUrl: 'https://dartpad.dev',
        estimatedMinutes: 20,
      };
      if (!seenUrls.has(practiceItem.canonicalUrl)) {
        matched.push(practiceItem);
        seenUrls.add(practiceItem.canonicalUrl);
      }
    }

    return matched;
  }

  static getVerifiedDocuments(): VerifiedDocumentBook[] {
    return VERIFIED_DOCUMENTATION_BOOKS;
  }

  static getVerifiedDocumentById(docId: string): VerifiedDocumentBook | null {
    return VERIFIED_DOCUMENTATION_BOOKS.find((b) => b.id === docId) || null;
  }
}

