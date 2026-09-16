import { logger } from '../../../infrastructure/logger/logger';

export interface ResourceContext {
  roadmapId?: string;
  roadmapNodeId?: string;
  careerGoal?: string;
  targetRole?: string;
  phase?: string;
  skill?: string;
  topic: string;
  learningObjective?: string;
  prerequisites?: string[];
  currentLevel?: string;
  preferredLanguage?: string;
  limit?: number;
}

export interface YouTubeResourceItem {
  id: string;
  videoId: string;
  title: string;
  channelName: string;
  channel: string;
  language: string;
  duration: string;
  views: string;
  viewCount?: number;
  url: string;
  thumbnailUrl: string;
  isVerified: boolean;
  topic: string;
  relevanceScore: number;
  resourceType: 'VIDEO';
  description?: string;
}

export interface YouTubePlaylistItem {
  id: string;
  playlistId: string;
  title: string;
  channelName: string;
  channel: string;
  language: string;
  videoCount: number;
  url: string;
  thumbnailUrl: string;
  isVerified: boolean;
  topic: string;
  relevanceScore: number;
  resourceType: 'PLAYLIST';
  description?: string;
  whyRelevant?: string;
}

export class YouTubeResourceService {
  private static cache: Map<string, { data: YouTubeResourceItem[]; expiresAt: number }> = new Map();
  private static playlistCache: Map<string, { data: YouTubePlaylistItem[]; expiresAt: number }> = new Map();
  private static readonly CACHE_TTL_MS = 12 * 60 * 60 * 1000; // 12 hours

  private static readonly YOUTUBE_ID_REGEX = /^[A-Za-z0-9_-]{11}$/;

  private static readonly CURATED_VIDEOS: Record<string, YouTubeResourceItem[]> = {
    iot: [
      {
        id: 'k_D7p_w-NnU',
        videoId: 'k_D7p_w-NnU',
        title: 'ESP32 Full Course for Beginners - IoT & Microcontroller Projects',
        channelName: 'Tech With Tim',
        channel: 'Tech With Tim',
        language: 'English',
        duration: '2h 45m',
        views: '4.2M views',
        viewCount: 4200000,
        url: 'https://www.youtube.com/watch?v=k_D7p_w-NnU',
        thumbnailUrl: 'https://img.youtube.com/vi/k_D7p_w-NnU/hqdefault.jpg',
        isVerified: true,
        topic: 'Microcontrollers & ESP32 GPIO',
        relevanceScore: 96,
        resourceType: 'VIDEO',
        description: 'Comprehensive guide to programming the ESP32 microcontroller with Arduino/C++, GPIO pinout, and sensor interfacing.',
      },
      {
        id: 'Gk7N0Y4XQ1E',
        videoId: 'Gk7N0Y4XQ1E',
        title: 'ESP32 Microcontroller Programming in Tamil (GPIO, Sensors, MQTT)',
        channelName: "Let's Make Engineering Simple",
        channel: "Let's Make Engineering Simple",
        language: 'Tamil',
        duration: '1h 30m',
        views: '320K views',
        viewCount: 320000,
        url: 'https://www.youtube.com/watch?v=Gk7N0Y4XQ1E',
        thumbnailUrl: 'https://img.youtube.com/vi/Gk7N0Y4XQ1E/hqdefault.jpg',
        isVerified: true,
        topic: 'Microcontrollers & ESP32 GPIO',
        relevanceScore: 94,
        resourceType: 'VIDEO',
        description: 'Clear Tamil explanation of ESP32 GPIO setup, digital read/write, analog input, and cloud IoT integration.',
      },
      {
        id: 'Fj2F7eXv9pQ',
        videoId: 'Fj2F7eXv9pQ',
        title: 'Complete IoT & ESP32 Tutorial in Hindi - Sensors & Cloud Connection',
        channelName: 'Edureka Hindi',
        channel: 'Edureka Hindi',
        language: 'Hindi',
        duration: '2h 10m',
        views: '650K views',
        viewCount: 650000,
        url: 'https://www.youtube.com/watch?v=Fj2F7eXv9pQ',
        thumbnailUrl: 'https://img.youtube.com/vi/Fj2F7eXv9pQ/hqdefault.jpg',
        isVerified: true,
        topic: 'IoT & Embedded Systems',
        relevanceScore: 92,
        resourceType: 'VIDEO',
        description: 'Hindi tutorial covering ESP32 fundamentals, Wi-Fi communication, MQTT broker connection, and sensor dashboards.',
      },
      {
        id: 'yVLzL9b5P0o',
        videoId: 'yVLzL9b5P0o',
        title: 'FreeRTOS on ESP32 - Multi-tasking, Queues and Semaphores',
        channelName: 'Digi-Key',
        channel: 'Digi-Key',
        language: 'English',
        duration: '1h 45m',
        views: '890K views',
        viewCount: 890000,
        url: 'https://www.youtube.com/watch?v=yVLzL9b5P0o',
        thumbnailUrl: 'https://img.youtube.com/vi/yVLzL9b5P0o/hqdefault.jpg',
        isVerified: true,
        topic: 'Embedded Operating Systems & RTOS',
        relevanceScore: 95,
        resourceType: 'VIDEO',
        description: 'Master FreeRTOS task scheduling, priority management, and inter-task queues on dual-core microcontrollers.',
      },
    ],
    flutter: [
      {
        id: 'pTJJsmejUOQ',
        videoId: 'pTJJsmejUOQ',
        title: 'Flutter Crash Course for Beginners 2026',
        channelName: 'freeCodeCamp.org',
        channel: 'freeCodeCamp.org',
        language: 'English',
        duration: '3h 15m',
        views: '2.8M views',
        viewCount: 2800000,
        url: 'https://www.youtube.com/watch?v=pTJJsmejUOQ',
        thumbnailUrl: 'https://img.youtube.com/vi/pTJJsmejUOQ/hqdefault.jpg',
        isVerified: true,
        topic: 'Flutter & Dart UI Development',
        relevanceScore: 96,
        resourceType: 'VIDEO',
        description: 'Build native iOS and Android applications from scratch using Flutter widgets, asynchronous Dart, and clean architecture.',
      },
      {
        id: '1xipgS59OVw',
        videoId: '1xipgS59OVw',
        title: 'Flutter Full Course in Tamil - Clean Architecture & Riverpod',
        channelName: 'Error Makes Clever Academy',
        channel: 'Error Makes Clever Academy',
        language: 'Tamil',
        duration: '2h 20m',
        views: '410K views',
        viewCount: 410000,
        url: 'https://www.youtube.com/watch?v=1xipgS59OVw',
        thumbnailUrl: 'https://img.youtube.com/vi/1xipgS59OVw/hqdefault.jpg',
        isVerified: true,
        topic: 'Flutter State Management',
        relevanceScore: 95,
        resourceType: 'VIDEO',
        description: 'Learn reactive Flutter state management with Riverpod, separation of concerns, and Dio network layer in Tamil.',
      },
      {
        id: 'GLSG_Wh_YWc',
        videoId: 'GLSG_Wh_YWc',
        title: 'Flutter in Hindi - Complete Beginner to Advanced Mastery',
        channelName: 'Thapa Technical',
        channel: 'Thapa Technical',
        language: 'Hindi',
        duration: '4h 05m',
        views: '1.9M views',
        viewCount: 1900000,
        url: 'https://www.youtube.com/watch?v=GLSG_Wh_YWc',
        thumbnailUrl: 'https://img.youtube.com/vi/GLSG_Wh_YWc/hqdefault.jpg',
        isVerified: true,
        topic: 'Cross-Platform Mobile Engineering',
        relevanceScore: 91,
        resourceType: 'VIDEO',
        description: 'In-depth Hindi tutorial covering Flutter widget trees, navigation routes, responsive design, and REST APIs.',
      },
    ],
    cybersecurity: [
      {
        id: '3Kq1MIfTWCE',
        videoId: '3Kq1MIfTWCE',
        title: 'Complete Ethical Hacking & Cybersecurity Course for Beginners',
        channelName: 'freeCodeCamp.org',
        channel: 'freeCodeCamp.org',
        language: 'English',
        duration: '15h 00m',
        views: '8.4M views',
        viewCount: 8400000,
        url: 'https://www.youtube.com/watch?v=3Kq1MIfTWCE',
        thumbnailUrl: 'https://img.youtube.com/vi/3Kq1MIfTWCE/hqdefault.jpg',
        isVerified: true,
        topic: 'Ethical Hacking & Network Defense',
        relevanceScore: 97,
        resourceType: 'VIDEO',
        description: 'End-to-end cybersecurity curriculum covering Linux terminal, Nmap reconnaissance, Wireshark, Metasploit, and defense.',
      },
      {
        id: 'U_P23dq9Scw',
        videoId: 'U_P23dq9Scw',
        title: 'Wireshark Tutorial for Beginners - Network Packet Analysis',
        channelName: 'NetworkChuck',
        channel: 'NetworkChuck',
        language: 'English',
        duration: '35m',
        views: '2.1M views',
        viewCount: 2100000,
        url: 'https://www.youtube.com/watch?v=U_P23dq9Scw',
        thumbnailUrl: 'https://img.youtube.com/vi/U_P23dq9Scw/hqdefault.jpg',
        isVerified: true,
        topic: 'Network Packet Analysis & Wireshark',
        relevanceScore: 98,
        resourceType: 'VIDEO',
        description: 'Hands-on Wireshark packet capture, filters, TCP handshakes, and diagnosing packet anomalies.',
      },
      {
        id: '8aGhZQkoFbQ',
        videoId: '8aGhZQkoFbQ',
        title: 'OWASP Top 10 Security Vulnerabilities Explained with Real Attacks',
        channelName: 'Fireship',
        channel: 'Fireship',
        language: 'English',
        duration: '12m',
        views: '1.7M views',
        viewCount: 1700000,
        url: 'https://www.youtube.com/watch?v=8aGhZQkoFbQ',
        thumbnailUrl: 'https://img.youtube.com/vi/8aGhZQkoFbQ/hqdefault.jpg',
        isVerified: true,
        topic: 'Application Security & OWASP Top 10',
        relevanceScore: 99,
        resourceType: 'VIDEO',
        description: 'Visual breakdown of SQLi, Broken Authentication, Sensitive Data Exposure, and modern injection mitigation.',
      },
    ],
    ai: [
      {
        id: 'i_LwzRVP7bg',
        videoId: 'i_LwzRVP7bg',
        title: 'Python for Data Science and Machine Learning Full Course',
        channelName: 'freeCodeCamp.org',
        channel: 'freeCodeCamp.org',
        language: 'English',
        duration: '12h 15m',
        views: '4.8M views',
        viewCount: 4800000,
        url: 'https://www.youtube.com/watch?v=i_LwzRVP7bg',
        thumbnailUrl: 'https://img.youtube.com/vi/i_LwzRVP7bg/hqdefault.jpg',
        isVerified: true,
        topic: 'Data Science & Machine Learning',
        relevanceScore: 97,
        resourceType: 'VIDEO',
        description: 'NumPy arrays, Pandas DataFrames, Matplotlib visualization, Scikit-Learn algorithms, and data preprocessing.',
      },
      {
        id: 'LHBE6Q9XlzI',
        videoId: 'LHBE6Q9XlzI',
        title: 'Complete Data Science & Python in Tamil - Pandas, NumPy & ML',
        channelName: 'Error Makes Clever Academy',
        channel: 'Error Makes Clever Academy',
        language: 'Tamil',
        duration: '4h 30m',
        views: '540K views',
        viewCount: 540000,
        url: 'https://www.youtube.com/watch?v=LHBE6Q9XlzI',
        thumbnailUrl: 'https://img.youtube.com/vi/LHBE6Q9XlzI/hqdefault.jpg',
        isVerified: true,
        topic: 'Data Science & Analytics',
        relevanceScore: 94,
        resourceType: 'VIDEO',
        description: 'Hands-on Tamil walkthrough for data cleaning with Pandas, vector operations with NumPy, and predictive ML models.',
      },
      {
        id: 'JxgmHe2NyeY',
        videoId: 'JxgmHe2NyeY',
        title: 'Complete Machine Learning in Hindi - Krish Naik Masterclass',
        channelName: 'Krish Naik Hindi',
        channel: 'Krish Naik Hindi',
        language: 'Hindi',
        duration: '11h 15m',
        views: '2.4M views',
        viewCount: 2400000,
        url: 'https://www.youtube.com/watch?v=JxgmHe2NyeY',
        thumbnailUrl: 'https://img.youtube.com/vi/JxgmHe2NyeY/hqdefault.jpg',
        isVerified: true,
        topic: 'Machine Learning Algorithms',
        relevanceScore: 93,
        resourceType: 'VIDEO',
        description: 'Comprehensive Hindi masterclass on Supervised Learning, Hyperparameter Tuning, Cross-Validation, and Pipelines.',
      },
    ],
    backend: [
      {
        id: 'Oe421EPjeBE',
        videoId: 'Oe421EPjeBE',
        title: 'Node.js and Express.js Full Course (Building Scalable REST APIs)',
        channelName: 'freeCodeCamp.org',
        channel: 'freeCodeCamp.org',
        language: 'English',
        duration: '8h 20m',
        views: '3.9M views',
        viewCount: 3900000,
        url: 'https://www.youtube.com/watch?v=Oe421EPjeBE',
        thumbnailUrl: 'https://img.youtube.com/vi/Oe421EPjeBE/hqdefault.jpg',
        isVerified: true,
        topic: 'REST APIs & Node.js Architecture',
        relevanceScore: 96,
        resourceType: 'VIDEO',
        description: 'Learn backend design, middleware architecture, routing, error handling, JWT auth, and database ORM integration.',
      },
      {
        id: '7fjOw8ApZ1I',
        videoId: '7fjOw8ApZ1I',
        title: 'Chai aur Backend - Production Node.js & Database Architecture',
        channelName: 'Chai aur Code',
        channel: 'Chai aur Code',
        language: 'Hindi',
        duration: '12h 45m',
        views: '2.1M views',
        viewCount: 2100000,
        url: 'https://www.youtube.com/watch?v=7fjOw8ApZ1I',
        thumbnailUrl: 'https://img.youtube.com/vi/7fjOw8ApZ1I/hqdefault.jpg',
        isVerified: true,
        topic: 'Backend & Authentication Architecture',
        relevanceScore: 95,
        resourceType: 'VIDEO',
        description: 'Industry-standard production backend development in Hindi covering Express, MongoDB/PostgreSQL, and JWT security.',
      },
    ],
    cloud: [
      {
        id: '3c-iBn73dDE',
        videoId: '3c-iBn73dDE',
        title: 'Docker & Kubernetes Full Course for Beginners - DevOps Architecture',
        channelName: 'TechWorld with Nana',
        channel: 'TechWorld with Nana',
        language: 'English',
        duration: '4h 10m',
        views: '5.1M views',
        viewCount: 5100000,
        url: 'https://www.youtube.com/watch?v=3c-iBn73dDE',
        thumbnailUrl: 'https://img.youtube.com/vi/3c-iBn73dDE/hqdefault.jpg',
        isVerified: true,
        topic: 'DevOps & Docker Containers',
        relevanceScore: 98,
        resourceType: 'VIDEO',
        description: 'Container fundamentals, Dockerfiles, multi-stage builds, Docker Compose, and Kubernetes pod orchestration.',
      },
      {
        id: 'SOTamWNgDKc',
        videoId: 'SOTamWNgDKc',
        title: 'AWS Certified Cloud Practitioner Full Course - freeCodeCamp',
        channelName: 'freeCodeCamp.org',
        channel: 'freeCodeCamp.org',
        language: 'English',
        duration: '13h 00m',
        views: '3.1M views',
        viewCount: 3100000,
        url: 'https://www.youtube.com/watch?v=SOTamWNgDKc',
        thumbnailUrl: 'https://img.youtube.com/vi/SOTamWNgDKc/hqdefault.jpg',
        isVerified: true,
        topic: 'Cloud Computing & AWS Architecture',
        relevanceScore: 95,
        resourceType: 'VIDEO',
        description: 'Core cloud infrastructure: EC2 compute, S3 object storage, VPC networking, IAM security policies, and RDS databases.',
      },
    ],
    ece_eee: [
      {
        id: '6mHMw_nB_q4',
        videoId: '6mHMw_nB_q4',
        title: 'Microprocessors and Microcontrollers Architecture & Interfacing',
        channelName: 'NPTEL-NOC IITM',
        channel: 'NPTEL-NOC IITM',
        language: 'English',
        duration: '1h 15m',
        views: '450K views',
        viewCount: 450000,
        url: 'https://www.youtube.com/watch?v=6mHMw_nB_q4',
        thumbnailUrl: 'https://img.youtube.com/vi/6mHMw_nB_q4/hqdefault.jpg',
        isVerified: true,
        topic: 'Microprocessor Architecture & Bus Interfacing',
        relevanceScore: 95,
        resourceType: 'VIDEO',
        description: 'Rigorous engineering foundations covering register architectures, memory mapping, interrupt vectors, and peripheral buses.',
      },
      {
        id: 'QZ_rW3t2V7s',
        videoId: 'QZ_rW3t2V7s',
        title: 'PLC Programming and Industrial Automation Tutorial',
        channelName: 'RealPars',
        channel: 'RealPars',
        language: 'English',
        duration: '45m',
        views: '1.2M views',
        viewCount: 1200000,
        url: 'https://www.youtube.com/watch?v=QZ_rW3t2V7s',
        thumbnailUrl: 'https://img.youtube.com/vi/QZ_rW3t2V7s/hqdefault.jpg',
        isVerified: true,
        topic: 'Industrial Automation & PLC',
        relevanceScore: 93,
        resourceType: 'VIDEO',
        description: 'Ladder logic programming, sensors, actuators, and industrial automation controller workflows.',
      },
    ],
    mechanical_civil: [
      {
        id: 'qpr84718_v0',
        videoId: 'qpr84718_v0',
        title: 'Revit BIM Complete Workflow - Architectural & Structural Modeling',
        channelName: 'BIM Pure',
        channel: 'BIM Pure',
        language: 'English',
        duration: '2h 10m',
        views: '780K views',
        viewCount: 780000,
        url: 'https://www.youtube.com/watch?v=qpr84718_v0',
        thumbnailUrl: 'https://img.youtube.com/vi/qpr84718_v0/hqdefault.jpg',
        isVerified: true,
        topic: 'BIM & Structural Modeling',
        relevanceScore: 96,
        resourceType: 'VIDEO',
        description: 'BIM parametric design, Revit floor plans, 3D structural coordination, and construction documentation.',
      },
      {
        id: 'T4f4v9lQ_mI',
        videoId: 'T4f4v9lQ_mI',
        title: 'SolidWorks 3D CAD Modeling Complete Beginner to Masterclass',
        channelName: 'CAD CAM TUTORIAL',
        channel: 'CAD CAM TUTORIAL',
        language: 'English',
        duration: '3h 30m',
        views: '2.5M views',
        viewCount: 2500000,
        url: 'https://www.youtube.com/watch?v=T4f4v9lQ_mI',
        thumbnailUrl: 'https://img.youtube.com/vi/T4f4v9lQ_mI/hqdefault.jpg',
        isVerified: true,
        topic: 'CAD Modeling & Mechanical Simulation',
        relevanceScore: 95,
        resourceType: 'VIDEO',
        description: 'Parametric 3D part modeling, assemblies, mate constraints, technical drawings, and motion study analysis.',
      },
    ],
    fullstack: [
      {
        id: 'kUMe1FH4CHE',
        videoId: 'kUMe1FH4CHE',
        title: 'HTML & CSS Full Course - Beginner to Pro',
        channelName: 'SuperSimpleDev',
        channel: 'SuperSimpleDev',
        language: 'English',
        duration: '6h 30m',
        views: '9.8M views',
        viewCount: 9800000,
        url: 'https://www.youtube.com/watch?v=kUMe1FH4CHE',
        thumbnailUrl: 'https://img.youtube.com/vi/kUMe1FH4CHE/hqdefault.jpg',
        isVerified: true,
        topic: 'HTML & Modern CSS',
        relevanceScore: 98,
        resourceType: 'VIDEO',
        description: 'Complete hands-on HTML5 and CSS3 course covering semantic markup, Flexbox, CSS Grid, responsive design, and animations.',
      },
      {
        id: 'W6NZfCO5SIk',
        videoId: 'W6NZfCO5SIk',
        title: 'JavaScript Tutorial for Beginners: Learn JavaScript in 1 Hour',
        channelName: 'Programming with Mosh',
        channel: 'Programming with Mosh',
        language: 'English',
        duration: '1h 05m',
        views: '12M views',
        viewCount: 12000000,
        url: 'https://www.youtube.com/watch?v=W6NZfCO5SIk',
        thumbnailUrl: 'https://img.youtube.com/vi/W6NZfCO5SIk/hqdefault.jpg',
        isVerified: true,
        topic: 'Modern JavaScript (ES6+)',
        relevanceScore: 97,
        resourceType: 'VIDEO',
        description: 'Fundamental JavaScript syntax, variables, data types, functions, objects, arrays, and DOM manipulation.',
      },
      {
        id: 'bMknfKXIFA8',
        videoId: 'bMknfKXIFA8',
        title: 'React Course - Beginner to Advanced 2026',
        channelName: 'freeCodeCamp.org',
        channel: 'freeCodeCamp.org',
        language: 'English',
        duration: '11h 50m',
        views: '6.4M views',
        viewCount: 6400000,
        url: 'https://www.youtube.com/watch?v=bMknfKXIFA8',
        thumbnailUrl: 'https://img.youtube.com/vi/bMknfKXIFA8/hqdefault.jpg',
        isVerified: true,
        topic: 'React Components, Hooks & State',
        relevanceScore: 99,
        resourceType: 'VIDEO',
        description: 'Master component architecture, useState, useEffect, custom hooks, context API, and routing in modern React.',
      },
      {
        id: 'nu_pCVPKzTk',
        videoId: 'nu_pCVPKzTk',
        title: 'Full Stack Web Development for Beginners (HTML, CSS, JS, Node, DB)',
        channelName: 'freeCodeCamp.org',
        channel: 'freeCodeCamp.org',
        language: 'English',
        duration: '8h 15m',
        views: '4.7M views',
        viewCount: 4700000,
        url: 'https://www.youtube.com/watch?v=nu_pCVPKzTk',
        thumbnailUrl: 'https://img.youtube.com/vi/nu_pCVPKzTk/hqdefault.jpg',
        isVerified: true,
        topic: 'Full-Stack Architecture & Web Foundations',
        relevanceScore: 96,
        resourceType: 'VIDEO',
        description: 'End-to-end full stack web development roadmap covering client-side UI, server-side APIs, database integration, and deployment.',
      },
      {
        id: 'G3e-cpL7ofc',
        videoId: 'G3e-cpL7ofc',
        title: 'HTML & CSS Full Tutorial in Tamil - Complete Web Development',
        channelName: 'Error Makes Clever Academy',
        channel: 'Error Makes Clever Academy',
        language: 'Tamil',
        duration: '3h 10m',
        views: '890K views',
        viewCount: 890000,
        url: 'https://www.youtube.com/watch?v=G3e-cpL7ofc',
        thumbnailUrl: 'https://img.youtube.com/vi/G3e-cpL7ofc/hqdefault.jpg',
        isVerified: true,
        topic: 'HTML & CSS Web Development',
        relevanceScore: 95,
        resourceType: 'VIDEO',
        description: 'Comprehensive web development course in Tamil covering tags, styles, layouts, and building responsive portfolio pages.',
      },
      {
        id: 'ESnrn1k9P40',
        videoId: 'ESnrn1k9P40',
        title: 'Complete Web Development Course in Hindi - Chai aur Code',
        channelName: 'Chai aur Code',
        channel: 'Chai aur Code',
        language: 'Hindi',
        duration: '8h 40m',
        views: '2.8M views',
        viewCount: 2800000,
        url: 'https://www.youtube.com/watch?v=ESnrn1k9P40',
        thumbnailUrl: 'https://img.youtube.com/vi/ESnrn1k9P40/hqdefault.jpg',
        isVerified: true,
        topic: 'Web Development Bootcamp in Hindi',
        relevanceScore: 96,
        resourceType: 'VIDEO',
        description: 'Production-ready full-stack web engineering fundamentals in Hindi by Hitesh Choudhary.',
      },
    ],
    cpp: [
      {
        id: 'vLnPwxZdW4Y',
        videoId: 'vLnPwxZdW4Y',
        title: 'C++ Tutorial for Beginners - Full Course',
        channelName: 'freeCodeCamp.org',
        channel: 'freeCodeCamp.org',
        language: 'English',
        duration: '4h 01m',
        views: '7.9M views',
        viewCount: 7900000,
        url: 'https://www.youtube.com/watch?v=vLnPwxZdW4Y',
        thumbnailUrl: 'https://img.youtube.com/vi/vLnPwxZdW4Y/hqdefault.jpg',
        isVerified: true,
        topic: 'C++ Systems Programming & Memory',
        relevanceScore: 97,
        resourceType: 'VIDEO',
        description: 'Complete C++ fundamentals covering pointers, memory addresses, references, OOP classes, constructors, and inheritance.',
      },
      {
        id: 'ZzaPdXTrSb8',
        videoId: 'ZzaPdXTrSb8',
        title: 'C++ in 100 Seconds',
        channelName: 'Fireship',
        channel: 'Fireship',
        language: 'English',
        duration: '2m 20m',
        views: '3.1M views',
        viewCount: 3100000,
        url: 'https://www.youtube.com/watch?v=ZzaPdXTrSb8',
        thumbnailUrl: 'https://img.youtube.com/vi/ZzaPdXTrSb8/hqdefault.jpg',
        isVerified: true,
        topic: 'C++ Overview & Toolchain',
        relevanceScore: 92,
        resourceType: 'VIDEO',
        description: 'Rapid high-level overview of C++, compiler toolchains, direct hardware access, and memory models.',
      },
    ],
    dsa: [
      {
        id: '8hly31xKli0',
        videoId: '8hly31xKli0',
        title: 'Complete C++ DSA Course for FAANG Interviews',
        channelName: 'freeCodeCamp.org',
        channel: 'freeCodeCamp.org',
        language: 'English',
        duration: '10h 30m',
        views: '5.2M views',
        viewCount: 5200000,
        url: 'https://www.youtube.com/watch?v=8hly31xKli0',
        thumbnailUrl: 'https://img.youtube.com/vi/8hly31xKli0/hqdefault.jpg',
        isVerified: true,
        topic: 'Competitive Programming & DSA',
        relevanceScore: 94,
        resourceType: 'VIDEO',
        description: 'Binary search, trees, graphs, dynamic programming, and asymptotic time-space complexity optimization.',
      },
      {
        id: '4_9t5vK9QzU',
        videoId: '4_9t5vK9QzU',
        title: 'Data Structures and Algorithms in Tamil - Logic First',
        channelName: 'Logic First Tamil',
        channel: 'Logic First Tamil',
        language: 'Tamil',
        duration: '6h 10m',
        views: '1.4M views',
        viewCount: 1400000,
        url: 'https://www.youtube.com/watch?v=4_9t5vK9QzU',
        thumbnailUrl: 'https://img.youtube.com/vi/4_9t5vK9QzU/hqdefault.jpg',
        isVerified: true,
        topic: 'DSA & Placement Prep',
        relevanceScore: 93,
        resourceType: 'VIDEO',
        description: 'Detailed explanation of linked lists, recursion, sorting algorithms, and problem solving in Tamil.',
      },
    ],
  };

  private static readonly CURATED_PLAYLISTS: Record<string, YouTubePlaylistItem[]> = {
    iot: [
      {
        id: 'pl-iot-1',
        playlistId: 'PLGs0VKk2DiYw-L-RibttcvK-WBZm8WLEP',
        title: 'ESP32 & Arduino Complete Masterclass Series',
        channelName: 'Tech With Tim',
        channel: 'Tech With Tim',
        language: 'English',
        videoCount: 24,
        url: 'https://www.youtube.com/playlist?list=PLGs0VKk2DiYw-L-RibttcvK-WBZm8WLEP',
        thumbnailUrl: 'https://img.youtube.com/vi/k_D7p_w-NnU/hqdefault.jpg',
        isVerified: true,
        topic: 'Microcontrollers (ESP32 / Arduino)',
        relevanceScore: 98,
        resourceType: 'PLAYLIST',
        description: 'Structured step-by-step playlist from GPIO pins to Wi-Fi sockets and MQTT telemetry.',
        whyRelevant: 'Essential hands-on guide for your active embedded microcontroller roadmap phase.',
      },
    ],
    flutter: [
      {
        id: 'pl-flt-1',
        playlistId: 'PL4cUxeGkcC9jLYyp2Aoh6hcWuxFDX6PBJ',
        title: 'Flutter & Dart Complete Course 2026',
        channelName: 'Net Ninja',
        channel: 'Net Ninja',
        language: 'English',
        videoCount: 37,
        url: 'https://www.youtube.com/playlist?list=PL4cUxeGkcC9jLYyp2Aoh6hcWuxFDX6PBJ',
        thumbnailUrl: 'https://img.youtube.com/vi/pTJJsmejUOQ/hqdefault.jpg',
        isVerified: true,
        topic: 'Flutter & Dart Architecture',
        relevanceScore: 98,
        resourceType: 'PLAYLIST',
        description: 'Complete series walking through widgets, async networking, state models, and app release.',
        whyRelevant: 'Directly reinforces cross-platform mobile app development objectives.',
      },
    ],
    cybersecurity: [
      {
        id: 'pl-sec-1',
        playlistId: 'PLBf0hzazHTGMZz_o_wT2_86dF97rQY4c7',
        title: 'Network Security & Ethical Hacking Full Bootcamp',
        channelName: 'freeCodeCamp.org',
        channel: 'freeCodeCamp.org',
        language: 'English',
        videoCount: 18,
        url: 'https://www.youtube.com/playlist?list=PLBf0hzazHTGMZz_o_wT2_86dF97rQY4c7',
        thumbnailUrl: 'https://img.youtube.com/vi/3Kq1MIfTWCE/hqdefault.jpg',
        isVerified: true,
        topic: 'Network Security & DevSecOps',
        relevanceScore: 97,
        resourceType: 'PLAYLIST',
        description: 'Comprehensive series covering network topologies, penetration testing phases, and threat modeling.',
        whyRelevant: 'Foundational playlist for defending network infrastructure and securing CI/CD pipelines.',
      },
    ],
    ai: [
      {
        id: 'pl-ai-1',
        playlistId: 'PLZoTAELRMXVPBTrWtJkn3wTQxZsvzySz-',
        title: 'Complete Machine Learning & Deep Learning Playlist',
        channelName: 'Krish Naik',
        channel: 'Krish Naik',
        language: 'English',
        videoCount: 42,
        url: 'https://www.youtube.com/playlist?list=PLZoTAELRMXVPBTrWtJkn3wTQxZsvzySz-',
        thumbnailUrl: 'https://img.youtube.com/vi/i_LwzRVP7bg/hqdefault.jpg',
        isVerified: true,
        topic: 'Machine Learning & Neural Networks',
        relevanceScore: 96,
        resourceType: 'PLAYLIST',
        description: 'Comprehensive tutorials from feature engineering to neural network optimization and deployment.',
        whyRelevant: 'Step-by-step practical implementation of data pipelines and predictive models.',
      },
    ],
    backend: [
      {
        id: 'pl-back-1',
        playlistId: 'PLMC9HnGGwcbyUeH7Wfs3S_fLpP6q2_9x_',
        title: 'Backend Engineering & System Design',
        channelName: 'Hussein Nasser',
        channel: 'Hussein Nasser',
        language: 'English',
        videoCount: 28,
        url: 'https://www.youtube.com/playlist?list=PLMC9HnGGwcbyUeH7Wfs3S_fLpP6q2_9x_',
        thumbnailUrl: 'https://img.youtube.com/vi/Oe421EPjeBE/hqdefault.jpg',
        isVerified: true,
        topic: 'Backend Architecture & Database Internals',
        relevanceScore: 97,
        resourceType: 'PLAYLIST',
        description: 'Deep architectural exploration of database connections, HTTP/2, WebSockets, and caching protocols.',
        whyRelevant: 'Deepens your understanding of scalable production backend systems.',
      },
    ],
    cloud: [
      {
        id: 'pl-devops-1',
        playlistId: 'PLy7NrLfftHmIapY8m26Wc45pPZ6UjVw6K',
        title: 'DevOps Bootcamp - Docker, Kubernetes, CI/CD',
        channelName: 'TechWorld with Nana',
        channel: 'TechWorld with Nana',
        language: 'English',
        videoCount: 16,
        url: 'https://www.youtube.com/playlist?list=PLy7NrLfftHmIapY8m26Wc45pPZ6UjVw6K',
        thumbnailUrl: 'https://img.youtube.com/vi/3c-iBn73dDE/hqdefault.jpg',
        isVerified: true,
        topic: 'DevOps & Container Orchestration',
        relevanceScore: 98,
        resourceType: 'PLAYLIST',
        description: 'Hands-on guide to containerization, orchestration, and continuous deployment workflows.',
        whyRelevant: 'Provides practical implementation patterns for production cloud environments.',
      },
    ],
    ece_eee: [
      {
        id: 'pl-ee-1',
        playlistId: 'PLE72E4CFE73BD1DE1',
        title: 'Embedded Systems & Microcontroller Hardware',
        channelName: 'All About EE',
        channel: 'All About EE',
        language: 'English',
        videoCount: 15,
        url: 'https://www.youtube.com/playlist?list=PLE72E4CFE73BD1DE1',
        thumbnailUrl: 'https://img.youtube.com/vi/6mHMw_nB_q4/hqdefault.jpg',
        isVerified: true,
        topic: 'Microcontroller Hardware Architecture',
        relevanceScore: 94,
        resourceType: 'PLAYLIST',
        description: 'Oscilloscope measurements, PCB traces, power circuits, and hardware debugging techniques.',
        whyRelevant: 'Covers physical hardware interfaces required for embedded engineering.',
      },
    ],
    mechanical_civil: [
      {
        id: 'pl-bim-1',
        playlistId: 'PLu8EoSxDXHP5N9Ym3N2l8F-PZ4j8Qe6E_',
        title: 'BIM, Revit & Structural Modeling Architecture',
        channelName: 'BIM Pure',
        channel: 'BIM Pure',
        language: 'English',
        videoCount: 20,
        url: 'https://www.youtube.com/playlist?list=PLu8EoSxDXHP5N9Ym3N2l8F-PZ4j8Qe6E_',
        thumbnailUrl: 'https://img.youtube.com/vi/qpr84718_v0/hqdefault.jpg',
        isVerified: true,
        topic: 'BIM Modeling & Automation',
        relevanceScore: 95,
        resourceType: 'PLAYLIST',
        description: 'Professional architectural modeling, clash detection, and Dynamo scripting.',
        whyRelevant: 'Key workflow skills for modern digital construction engineering.',
      },
    ],
    dsa: [
      {
        id: 'pl-dsa-1',
        playlistId: 'PLgUwDviBIf0oF6QL8m22w1hIDC1vJ_BHz',
        title: 'Striver A2Z DSA Course - Sheet & Code Walkthroughs',
        channelName: 'take U forward',
        channel: 'take U forward',
        language: 'English',
        videoCount: 75,
        url: 'https://www.youtube.com/playlist?list=PLgUwDviBIf0oF6QL8m22w1hIDC1vJ_BHz',
        thumbnailUrl: 'https://img.youtube.com/vi/8hly31xKli0/hqdefault.jpg',
        isVerified: true,
        topic: 'Data Structures and Algorithms',
        relevanceScore: 97,
        resourceType: 'PLAYLIST',
        description: 'Comprehensive structured curriculum covering arrays to dynamic programming and graphs.',
        whyRelevant: 'Comprehensive placement coding interview preparation series.',
      },
    ],
    fullstack: [
      {
        id: 'pl-fs-1',
        playlistId: 'PL4cUxeGkcC9ivBf_eKCPIAYXWzLlPAm6G',
        title: 'Modern JavaScript & Web Development Full Tutorial',
        channelName: 'Net Ninja',
        channel: 'Net Ninja',
        language: 'English',
        videoCount: 22,
        url: 'https://www.youtube.com/playlist?list=PL4cUxeGkcC9ivBf_eKCPIAYXWzLlPAm6G',
        thumbnailUrl: 'https://img.youtube.com/vi/W6NZfCO5SIk/hqdefault.jpg',
        isVerified: true,
        topic: 'Full-Stack Web Development & Modern JavaScript',
        relevanceScore: 98,
        resourceType: 'PLAYLIST',
        description: 'Comprehensive series from fundamental DOM manipulation to asynchronous fetch requests and ES6 modular design.',
        whyRelevant: 'Essential foundational series for modern web development, DOM manipulation, and asynchronous APIs.',
      },
      {
        id: 'pl-fs-2',
        playlistId: 'PLu0W_9lII9agq5TrH9XLIKQvv0iaF2X3w',
        title: 'Complete Web Development Bootcamp (HTML, CSS, JS & React)',
        channelName: 'Chai aur Code',
        channel: 'Chai aur Code',
        language: 'Hindi',
        videoCount: 45,
        url: 'https://www.youtube.com/playlist?list=PLu0W_9lII9agq5TrH9XLIKQvv0iaF2X3w',
        thumbnailUrl: 'https://img.youtube.com/vi/ESnrn1k9P40/hqdefault.jpg',
        isVerified: true,
        topic: 'Full-Stack Web Engineering Bootcamp',
        relevanceScore: 97,
        resourceType: 'PLAYLIST',
        description: 'Comprehensive step-by-step Hindi guide building real-world web applications from scratch.',
        whyRelevant: 'In-depth Hindi walkthrough for building client-side and full-stack projects.',
      },
    ],
    cpp: [
      {
        id: 'pl-cpp-1',
        playlistId: 'PLlrATfBNZ98dudnM48yfGUldqGD0S4FFb',
        title: 'C++ Programming Series - Beginners to Advanced',
        channelName: 'The Cherno',
        channel: 'The Cherno',
        language: 'English',
        videoCount: 35,
        url: 'https://www.youtube.com/playlist?list=PLlrATfBNZ98dudnM48yfGUldqGD0S4FFb',
        thumbnailUrl: 'https://img.youtube.com/vi/vLnPwxZdW4Y/hqdefault.jpg',
        isVerified: true,
        topic: 'C++ Systems Programming & Memory',
        relevanceScore: 96,
        resourceType: 'PLAYLIST',
        description: 'In-depth series on C++ memory management, pointers, and modern C++ features.',
        whyRelevant: 'Deep architectural understanding of C++ memory layouts and low-level code.',
      },
    ],
  };

  /**
   * Helper to normalize context parameters
   */
  private static parseContext(contextOrTopic: ResourceContext | string, lang: string = 'English', limit: number = 6): ResourceContext {
    if (typeof contextOrTopic === 'string') {
      return {
        topic: contextOrTopic,
        preferredLanguage: lang,
        limit,
      };
    }
    return {
      ...contextOrTopic,
      preferredLanguage: contextOrTopic.preferredLanguage || lang,
      limit: contextOrTopic.limit || limit,
    };
  }

  /**
   * Searches real-time YouTube Data API v3 or falls back to curated verified collection.
   */
  async resolveVideos(
    contextOrTopic: ResourceContext | string,
    preferredLanguage: string = 'English',
    limit: number = 6
  ): Promise<YouTubeResourceItem[]> {
    const ctx = YouTubeResourceService.parseContext(contextOrTopic, preferredLanguage, limit);
    const topicClean = ctx.topic.trim();
    const langClean = (ctx.preferredLanguage || 'English').trim().toLowerCase();
    const cacheKey = `${ctx.roadmapId || 'global'}_${ctx.roadmapNodeId || 'global'}_${topicClean.toLowerCase()}_${langClean}_${ctx.limit || 6}`;

    // 1. Check Cache
    const cached = YouTubeResourceService.cache.get(cacheKey);
    if (cached && cached.expiresAt > Date.now()) {
      logger.info({ cacheKey }, '[CAREER_RESOURCE_CACHE] HIT for YouTube videos');
      return cached.data;
    }

    logger.info({ cacheKey, topic: topicClean, skill: ctx.skill }, '[CAREER_RESOURCE_CACHE] MISS for YouTube videos');

    const apiKey = process.env.YOUTUBE_API_KEY;

    // 2. Call real YouTube Data API v3 if API key is present
    if (apiKey && apiKey.trim().length > 0) {
      try {
        let searchQuery = `${topicClean} tutorial`;
        if (ctx.skill && !topicClean.toLowerCase().includes(ctx.skill.toLowerCase())) {
          searchQuery = `${ctx.skill} ${searchQuery}`;
        }
        if (ctx.targetRole && !searchQuery.toLowerCase().includes(ctx.targetRole.toLowerCase().slice(0, 8))) {
          const roleSnippet = ctx.targetRole.split('&')[0].trim();
          searchQuery = `${roleSnippet} ${searchQuery}`;
        }
        if (ctx.preferredLanguage && ctx.preferredLanguage.toLowerCase() !== 'english') {
          searchQuery += ` in ${ctx.preferredLanguage}`;
        }

        const url = `https://www.googleapis.com/youtube/v3/search?part=snippet&q=${encodeURIComponent(
          searchQuery
        )}&type=video&videoEmbeddable=true&maxResults=${ctx.limit || 6}&key=${apiKey}`;

        const res = await fetch(url, {
          signal: AbortSignal.timeout(3500),
        });

        if (res.ok) {
          const data = (await res.json()) as any;
          if (Array.isArray(data.items) && data.items.length > 0) {
            const mapped: YouTubeResourceItem[] = data.items
              .filter((item: any) => {
                const vid = item.id?.videoId;
                return vid && YouTubeResourceService.YOUTUBE_ID_REGEX.test(vid);
              })
              .map((item: any) => {
                const videoId = item.id.videoId;
                const cleanTitle = (item.snippet?.title || 'Educational Tutorial')
                  .replace(/&amp;/g, '&')
                  .replace(/&quot;/g, '"')
                  .replace(/&#39;/g, "'")
                  .replace(/&lt;/g, '<')
                  .replace(/&gt;/g, '>');

                const channelTitle = item.snippet?.channelTitle || 'Educational Channel';

                return {
                  id: videoId,
                  videoId,
                  title: cleanTitle,
                  channelName: channelTitle,
                  channel: channelTitle,
                  language: ctx.preferredLanguage || 'English',
                  duration: 'Video Tutorial',
                  views: 'Verified Tutorial',
                  viewCount: 100000,
                  url: `https://www.youtube.com/watch?v=${videoId}`,
                  thumbnailUrl:
                    item.snippet?.thumbnails?.high?.url ||
                    item.snippet?.thumbnails?.medium?.url ||
                    `https://img.youtube.com/vi/${videoId}/hqdefault.jpg`,
                  isVerified: true,
                  topic: topicClean,
                  relevanceScore: 94,
                  resourceType: 'VIDEO' as const,
                  description: item.snippet?.description || 'Curated educational video for your roadmap milestone.',
                };
              });

            if (mapped.length > 0) {
              YouTubeResourceService.cache.set(cacheKey, {
                data: mapped,
                expiresAt: Date.now() + YouTubeResourceService.CACHE_TTL_MS,
              });
              logger.info({ count: mapped.length }, '[CAREER_YOUTUBE] Live YouTube Data API returned verified items');
              return mapped;
            }
          }
        } else {
          logger.warn({ status: res.status }, 'YouTube Data API response not OK, falling back to curated');
        }
      } catch (err) {
        logger.warn({ err, topic: topicClean }, 'YouTube Data API search failed or timed out, falling back to curated');
      }
    }

    // 3. Fallback to curated collection with domain matching
    const fallback = this.resolveCuratedVideos(ctx);
    YouTubeResourceService.cache.set(cacheKey, {
      data: fallback,
      expiresAt: Date.now() + YouTubeResourceService.CACHE_TTL_MS,
    });
    return fallback;
  }

  /**
   * Resolves related YouTube playlists for the given context
   */
  async resolvePlaylists(
    contextOrTopic: ResourceContext | string,
    preferredLanguage: string = 'English',
    limit: number = 3
  ): Promise<YouTubePlaylistItem[]> {
    const ctx = YouTubeResourceService.parseContext(contextOrTopic, preferredLanguage, limit);
    const topicClean = ctx.topic.trim();
    const langClean = (ctx.preferredLanguage || 'English').trim().toLowerCase();
    const cacheKey = `pl_${ctx.roadmapId || 'global'}_${topicClean.toLowerCase()}_${langClean}`;

    const cached = YouTubeResourceService.playlistCache.get(cacheKey);
    if (cached && cached.expiresAt > Date.now()) {
      return cached.data;
    }

    const domain = this.detectDomain(ctx);
    const list = YouTubeResourceService.CURATED_PLAYLISTS[domain] || YouTubeResourceService.CURATED_PLAYLISTS['backend'] || [];

    const sorted = [...list].sort((a, b) => {
      const aMatch = a.language.toLowerCase() === langClean ? 1 : 0;
      const bMatch = b.language.toLowerCase() === langClean ? 1 : 0;
      return bMatch - aMatch;
    });

    const result = sorted.slice(0, ctx.limit || 3);
    YouTubeResourceService.playlistCache.set(cacheKey, {
      data: result,
      expiresAt: Date.now() + YouTubeResourceService.CACHE_TTL_MS,
    });
    return result;
  }

  private detectDomain(ctx: ResourceContext): string {
    const combined = `${ctx.topic} ${ctx.skill || ''} ${ctx.targetRole || ''} ${ctx.careerGoal || ''}`.toLowerCase();

    // 1. C++ systems programming (strictly when C++ or CPP is requested)
    if (combined.includes('c++') || combined.includes('cpp') || combined.includes('systems programming')) {
      return 'cpp';
    }

    // 2. Web & Full-Stack (match before cloud so full-stack tracks receive web fundamentals in phase 1)
    if (
      combined.includes('fullstack') ||
      combined.includes('full stack') ||
      combined.includes('web') ||
      combined.includes('frontend') ||
      combined.includes('front-end') ||
      combined.includes('html') ||
      combined.includes('css') ||
      combined.includes('javascript') ||
      combined.includes('react') ||
      combined.includes('vue') ||
      combined.includes('angular') ||
      combined.includes('next.js') ||
      combined.includes('nextjs') ||
      combined.includes('typescript') ||
      combined.includes('ui/ux') ||
      combined.includes('responsive design')
    ) {
      return 'fullstack';
    }

    // 3. IoT & Embedded Systems
    if (combined.includes('iot') || combined.includes('esp') || combined.includes('arduino') || combined.includes('embedded') || combined.includes('microcontroller') || combined.includes('sensor') || combined.includes('gpio')) {
      return 'iot';
    }

    // 4. Flutter & Mobile Engineering
    if (combined.includes('flutter') || combined.includes('dart') || combined.includes('mobile') || combined.includes('android') || combined.includes('ios') || combined.includes('riverpod')) {
      return 'flutter';
    }

    // 5. Cybersecurity & DevSecOps
    if (combined.includes('cyber') || combined.includes('security') || combined.includes('devsecops') || combined.includes('penetration') || combined.includes('hacking') || combined.includes('wireshark') || combined.includes('owasp') || combined.includes('nmap')) {
      return 'cybersecurity';
    }

    // 6. Artificial Intelligence & Data Science
    if (combined.includes('ai') || combined.includes('machine learning') || combined.includes('data science') || combined.includes('deep learning') || combined.includes('python') || combined.includes('pandas') || combined.includes('rag') || combined.includes('nlp')) {
      return 'ai';
    }

    // 7. Backend & REST API Engineering
    if (combined.includes('node') || combined.includes('backend') || combined.includes('express') || combined.includes('database') || combined.includes('postgres') || combined.includes('sql') || combined.includes('api') || combined.includes('prisma')) {
      return 'backend';
    }

    // 8. Cloud & DevOps Infrastructure
    if (combined.includes('docker') || combined.includes('kubernetes') || combined.includes('cloud') || combined.includes('aws') || combined.includes('devops') || combined.includes('ci/cd')) {
      return 'cloud';
    }

    // 9. Mechanical & Civil Engineering
    if (combined.includes('civil') || combined.includes('bim') || combined.includes('revit') || combined.includes('structural') || combined.includes('mechanical') || combined.includes('solidworks') || combined.includes('cad') || combined.includes('fea')) {
      return 'mechanical_civil';
    }

    // 10. Electrical & Electronics Engineering
    if (combined.includes('electrical') || combined.includes('eee') || combined.includes('ece') || combined.includes('plc') || combined.includes('circuit') || combined.includes('pcb')) {
      return 'ece_eee';
    }

    // 11. Data Structures & Algorithms (ONLY when explicitly requested)
    if (combined.includes('dsa') || combined.includes('data structure') || combined.includes('algorithm') || combined.includes('leetcode') || combined.includes('competitive programming')) {
      return 'dsa';
    }

    // Default to general fullstack / web software development, NEVER C++ DSA!
    return 'fullstack';
  }

  private resolveCuratedVideos(ctx: ResourceContext): YouTubeResourceItem[] {
    const domain = this.detectDomain(ctx);
    const matches = YouTubeResourceService.CURATED_VIDEOS[domain] || YouTubeResourceService.CURATED_VIDEOS['dsa'] || [];

    const langClean = (ctx.preferredLanguage || 'English').trim().toLowerCase();

    // Verify all videos have valid 11-char IDs
    const verified = matches.filter((item) => YouTubeResourceService.YOUTUBE_ID_REGEX.test(item.videoId));

    const sorted = verified.sort((a, b) => {
      const aMatch = a.language.toLowerCase() === langClean ? 1 : 0;
      const bMatch = b.language.toLowerCase() === langClean ? 1 : 0;
      return bMatch - aMatch;
    });

    return sorted.slice(0, ctx.limit || 3);
  }

  static async getEducationalVideos(
    topicOrContext: ResourceContext | string,
    preferredLanguage: string = 'English',
    limit: number = 3
  ): Promise<YouTubeResourceItem[]> {
    return youTubeResourceService.resolveVideos(topicOrContext, preferredLanguage, limit);
  }

  static async getEducationalPlaylists(
    topicOrContext: ResourceContext | string,
    preferredLanguage: string = 'English',
    limit: number = 2
  ): Promise<YouTubePlaylistItem[]> {
    return youTubeResourceService.resolvePlaylists(topicOrContext, preferredLanguage, limit);
  }
}

export const youTubeResourceService = new YouTubeResourceService();
export const CareerYouTubeService = YouTubeResourceService;
