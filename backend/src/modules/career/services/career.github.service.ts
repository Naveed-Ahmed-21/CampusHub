import { logger } from '../../../infrastructure/logger/logger';

export interface GitHubRepositoryItem {
  name: string;
  owner: string;
  fullName: string;
  description: string;
  stars: number;
  forks: number;
  language: string;
  url: string;
  whyUseful: string;
  topics: string[];
}

export class GitHubResourceService {
  private static cache: Map<string, { data: GitHubRepositoryItem[]; expiresAt: number }> = new Map();
  private static readonly CACHE_TTL_MS = 12 * 60 * 60 * 1000; // 12 hours

  // Verified repository baseline for high-yield engineering domains
  private static readonly VERIFIED_REPOSITORIES: Record<string, GitHubRepositoryItem[]> = {
    'iot': [
      {
        name: 'esp-idf',
        owner: 'espressif',
        fullName: 'espressif/esp-idf',
        description: 'Espressif IoT Development Framework for ESP32 and ESP32-S/C series.',
        stars: 13500,
        forks: 7200,
        language: 'C',
        url: 'https://github.com/espressif/esp-idf',
        whyUseful: 'Official production-grade SDK for building IoT firmware, Wi-Fi/BLE communication, and RTOS tasks on ESP32.',
        topics: ['iot', 'esp32', 'freertos', 'embedded', 'c'],
      },
      {
        name: 'Arduino',
        owner: 'arduino',
        fullName: 'arduino/Arduino',
        description: 'Open-source electronics prototyping platform enabling users to create interactive electronic objects.',
        stars: 14200,
        forks: 9000,
        language: 'Java',
        url: 'https://github.com/arduino/Arduino',
        whyUseful: 'Standard ecosystem for rapid microcontroller prototyping, sensor interfacing, and actuator control.',
        topics: ['arduino', 'embedded', 'microcontroller', 'sensors'],
      },
      {
        name: 'paho.mqtt.c',
        owner: 'eclipse',
        fullName: 'eclipse/paho.mqtt.c',
        description: 'Eclipse Paho C client library for MQTT for IoT applications.',
        stars: 3100,
        forks: 1800,
        language: 'C',
        url: 'https://github.com/eclipse/paho.mqtt.c',
        whyUseful: 'Industry standard messaging client for lightweight telemetry transport between IoT devices and cloud brokers.',
        topics: ['mqtt', 'iot', 'networking', 'telemetry'],
      },
    ],
    'embedded': [
      {
        name: 'FreeRTOS-Kernel',
        owner: 'FreeRTOS',
        fullName: 'FreeRTOS/FreeRTOS-Kernel',
        description: 'FreeRTOS kernel files and ports for real-time microcontrollers.',
        stars: 7600,
        forks: 3400,
        language: 'C',
        url: 'https://github.com/FreeRTOS/FreeRTOS-Kernel',
        whyUseful: 'De facto real-time operating system kernel for microcontrollers requiring preemptive scheduling and low jitter.',
        topics: ['rtos', 'freertos', 'embedded', 'microcontroller'],
      },
    ],
    'flutter': [
      {
        name: 'flutter',
        owner: 'flutter',
        fullName: 'flutter/flutter',
        description: 'Flutter makes it easy and fast to build beautiful apps for mobile and beyond.',
        stars: 168000,
        forks: 27000,
        language: 'Dart',
        url: 'https://github.com/flutter/flutter',
        whyUseful: 'Core SDK codebase with framework widgets, engine bindings, and production architecture examples.',
        topics: ['flutter', 'dart', 'mobile', 'cross-platform'],
      },
      {
        name: 'riverpod',
        owner: 'rrousselGit',
        fullName: 'rrousselGit/riverpod',
        description: 'A reactive caching and state-management framework for Dart and Flutter.',
        stars: 5800,
        forks: 850,
        language: 'Dart',
        url: 'https://github.com/rrousselGit/riverpod',
        whyUseful: 'Production state-management framework providing compile-time safety, auto-dispose, and reactive dependency caching.',
        topics: ['flutter', 'state-management', 'dart', 'riverpod'],
      },
    ],
    'backend': [
      {
        name: 'node',
        owner: 'nodejs',
        fullName: 'nodejs/node',
        description: 'Node.js JavaScript runtime built on Chrome\'s V8 JavaScript engine.',
        stars: 108000,
        forks: 31000,
        language: 'JavaScript',
        url: 'https://github.com/nodejs/node',
        whyUseful: 'Official Node.js runtime repository to understand event loops, libuv asynchronous I/O, and buffer internals.',
        topics: ['nodejs', 'backend', 'javascript', 'v8'],
      },
      {
        name: 'nest',
        owner: 'nestjs',
        fullName: 'nestjs/nest',
        description: 'A progressive Node.js framework for building efficient, reliable and scalable server-side applications.',
        stars: 67000,
        forks: 7500,
        language: 'TypeScript',
        url: 'https://github.com/nestjs/nest',
        whyUseful: 'Enterprise modular backend architecture utilizing dependency injection, guards, interceptors, and microservices.',
        topics: ['nodejs', 'typescript', 'backend', 'architecture'],
      },
    ],
    'dsa': [
      {
        name: 'javascript-algorithms',
        owner: 'trekhleb',
        fullName: 'trekhleb/javascript-algorithms',
        description: 'Algorithms and data structures implemented in JavaScript with explanations and further reading links.',
        stars: 188000,
        forks: 30000,
        language: 'JavaScript',
        url: 'https://github.com/trekhleb/javascript-algorithms',
        whyUseful: 'Crystal-clear algorithmic patterns, complexity explanations, and test suites for top placement patterns.',
        topics: ['algorithms', 'data-structures', 'interview-prep'],
      },
      {
        name: 'system-design-primer',
        owner: 'donnemartin',
        fullName: 'donnemartin/system-design-primer',
        description: 'Learn how to design large-scale systems. Prep for the system design interview.',
        stars: 280000,
        forks: 46000,
        language: 'Python',
        url: 'https://github.com/donnemartin/system-design-primer',
        whyUseful: 'Comprehensive architecture guide covering caching, load balancing, sharding, replication, and CAP theorem.',
        topics: ['system-design', 'architecture', 'scalability', 'distributed-systems'],
      },
    ],
    'cpp': [
      {
        name: 'CppCoreGuidelines',
        owner: 'isocpp',
        fullName: 'isocpp/CppCoreGuidelines',
        description: 'The C++ Core Guidelines are a set of tried-and-true guidelines, rules, and best practices about coding in C++.',
        stars: 42000,
        forks: 5500,
        language: 'C++',
        url: 'https://github.com/isocpp/CppCoreGuidelines',
        whyUseful: 'Definitive rules by Bjarne Stroustrup and Herb Sutter on modern resource safety, RAII, and smart pointers.',
        topics: ['cpp', 'best-practices', 'guidelines', 'modern-cpp'],
      },
    ],
    'robotics': [
      {
        name: 'ros2',
        owner: 'ros2',
        fullName: 'ros2/ros2',
        description: 'The Robot Operating System (ROS) is a set of software libraries and tools for building robot applications.',
        stars: 4300,
        forks: 1100,
        language: 'C++',
        url: 'https://github.com/ros2/ros2',
        whyUseful: 'Industry standard distributed middleware for robotics communication, sensor pipelines, and autonomous navigation.',
        topics: ['robotics', 'ros2', 'autonomous', 'cplusplus'],
      },
    ],
  };

  /**
   * Searches and ranks verified GitHub repositories for a given technical topic/skill.
   */
  async searchRepositories(topic: string, limit: number = 4): Promise<GitHubRepositoryItem[]> {
    const normalizedKey = topic.trim().toLowerCase();

    // 1. Check in-memory cache
    const cached = GitHubResourceService.cache.get(normalizedKey);
    if (cached && cached.expiresAt > Date.now()) {
      return cached.data.slice(0, limit);
    }

    // 2. Attempt GitHub Public Search API
    try {
      const headers: Record<string, string> = {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'CampusHub-AI-Career-Workspace',
      };
      if (process.env.GITHUB_TOKEN) {
        headers['Authorization'] = `token ${process.env.GITHUB_TOKEN}`;
      }

      const query = `${encodeURIComponent(topic)} stars:>500`;
      const res = await fetch(`https://api.github.com/search/repositories?q=${query}&sort=stars&order=desc&per_page=${limit}`, {
        headers,
        signal: AbortSignal.timeout(4000), // 4 second timeout
      });

      if (res.ok) {
        const data = (await res.json()) as any;
        if (Array.isArray(data.items) && data.items.length > 0) {
          const mapped: GitHubRepositoryItem[] = data.items.map((repo: any) => ({
            name: repo.name,
            owner: repo.owner?.login || '',
            fullName: repo.full_name,
            description: repo.description || 'Open source engineering repository.',
            stars: repo.stargazers_count || 0,
            forks: repo.forks_count || 0,
            language: repo.language || 'Code',
            url: repo.html_url,
            whyUseful: `Popular ${repo.language || 'engineering'} codebase demonstrating production architecture and design patterns for ${topic}.`,
            topics: Array.isArray(repo.topics) ? repo.topics.slice(0, 5) : [],
          }));

          GitHubResourceService.cache.set(normalizedKey, {
            data: mapped,
            expiresAt: Date.now() + GitHubResourceService.CACHE_TTL_MS,
          });

          return mapped.slice(0, limit);
        }
      }
    } catch (err) {
      logger.warn({ err, topic }, 'GitHub API search fallback triggered');
    }

    // 3. Resilient fallback to verified curated library
    const fallbackResults = this.getCuratedFallback(normalizedKey);
    GitHubResourceService.cache.set(normalizedKey, {
      data: fallbackResults,
      expiresAt: Date.now() + GitHubResourceService.CACHE_TTL_MS,
    });

    return fallbackResults.slice(0, limit);
  }

  private getCuratedFallback(key: string): GitHubRepositoryItem[] {
    for (const [domainKey, repos] of Object.entries(GitHubResourceService.VERIFIED_REPOSITORIES)) {
      if (key.includes(domainKey) || domainKey.includes(key)) {
        return repos;
      }
    }
    // Default fallback to systems/algorithms
    return GitHubResourceService.VERIFIED_REPOSITORIES['dsa'];
  }

  static async searchRepositories(topic: string, limit: number = 4, _language?: string): Promise<GitHubRepositoryItem[]> {
    return gitHubResourceService.searchRepositories(topic, limit);
  }
}

export const gitHubResourceService = new GitHubResourceService();
export const CareerGitHubService = GitHubResourceService;
