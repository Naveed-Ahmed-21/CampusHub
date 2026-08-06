import { prisma } from '../../config/database';
import { CreateWeeklyGoalDto, SubmitMiniProjectDto } from './career.types';

export class CareerRepository {
  // Roadmaps
  async getRoadmaps(category?: string, level?: string, search?: string) {
    const where: Record<string, unknown> = {};
    if (category) where.category = { equals: category, mode: 'insensitive' };
    if (level) where.level = { equals: level, mode: 'insensitive' };
    if (search) {
      where.OR = [
        { title: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
      ];
    }

    let roadmaps = await prisma.careerRoadmap.findMany({
      where: where as never,
      orderBy: { created_at: 'asc' },
      include: {
        nodes: {
          orderBy: { order_index: 'asc' },
          include: { resources: true },
        },
        _count: { select: { nodes: true, resources: true } },
      },
    });

    if (roadmaps.length === 0 && !category && !search) {
      await this.seedDefaultRoadmaps();
      roadmaps = await prisma.careerRoadmap.findMany({
        orderBy: { created_at: 'asc' },
        include: {
          nodes: {
            orderBy: { order_index: 'asc' },
            include: { resources: true },
          },
          _count: { select: { nodes: true, resources: true } },
        },
      });
    }

    return roadmaps;
  }

  async getRoadmapById(id: string) {
    return prisma.careerRoadmap.findUnique({
      where: { id },
      include: {
        nodes: {
          orderBy: { order_index: 'asc' },
          include: { resources: true },
        },
        resources: true,
      },
    });
  }

  // Progress Tracking
  async getUserRoadmapProgress(userId: string) {
    return prisma.userRoadmapProgress.findMany({
      where: { user_id: userId },
      include: {
        roadmap: {
          include: {
            _count: { select: { nodes: true } },
          },
        },
      },
    });
  }

  async getUserCompletedNodes(userId: string) {
    return prisma.userNodeProgress.findMany({
      where: { user_id: userId, is_completed: true },
      select: { node_id: true, completed_at: true },
    });
  }

  async toggleNodeProgress(userId: string, nodeId: string, isCompleted: boolean) {
    const node = await prisma.roadmapNode.findUnique({
      where: { id: nodeId },
      select: { id: true, roadmap_id: true },
    });

    if (!node) return null;

    if (isCompleted) {
      await prisma.userNodeProgress.upsert({
        where: { user_id_node_id: { user_id: userId, node_id: nodeId } },
        update: { is_completed: true, completed_at: new Date() },
        create: { user_id: userId, node_id: nodeId, is_completed: true },
      });
    } else {
      await prisma.userNodeProgress.deleteMany({
        where: { user_id: userId, node_id: nodeId },
      });
    }

    // Recalculate overall roadmap progress
    const allNodesCount = await prisma.roadmapNode.count({
      where: { roadmap_id: node.roadmap_id },
    });

    const completedNodesCount = await prisma.userNodeProgress.count({
      where: {
        user_id: userId,
        node: { roadmap_id: node.roadmap_id },
        is_completed: true,
      },
    });

    const percent = allNodesCount > 0 ? (completedNodesCount / allNodesCount) * 100 : 0;

    await prisma.userRoadmapProgress.upsert({
      where: { user_id_roadmap_id: { user_id: userId, roadmap_id: node.roadmap_id } },
      update: {
        completed_node_count: completedNodesCount,
        progress_percent: parseFloat(percent.toFixed(1)),
        updated_at: new Date(),
      },
      create: {
        user_id: userId,
        roadmap_id: node.roadmap_id,
        completed_node_count: completedNodesCount,
        progress_percent: parseFloat(percent.toFixed(1)),
      },
    });

    return { nodeId, isCompleted, completedNodesCount, totalNodes: allNodesCount, progressPercent: percent };
  }

  // Weekly Goals
  async getWeeklyGoals(userId: string) {
    return prisma.weeklyGoal.findMany({
      where: { user_id: userId },
      orderBy: { created_at: 'desc' },
    });
  }

  async createWeeklyGoal(userId: string, dto: CreateWeeklyGoalDto) {
    return prisma.weeklyGoal.create({
      data: {
        user_id: userId,
        title: dto.title,
        target_date: dto.target_date ? new Date(dto.target_date) : new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      },
    });
  }

  async toggleWeeklyGoal(goalId: string, userId: string, isCompleted: boolean) {
    return prisma.weeklyGoal.update({
      where: { id: goalId, user_id: userId },
      data: {
        is_completed: isCompleted,
        completed_at: isCompleted ? new Date() : null,
      },
    });
  }

  // Resume Tips
  async getResumeTips() {
    let tips = await prisma.resumeTip.findMany({
      orderBy: { created_at: 'asc' },
    });
    if (tips.length === 0) {
      await this.seedResumeTips();
      tips = await prisma.resumeTip.findMany({ orderBy: { created_at: 'asc' } });
    }
    return tips;
  }

  // Placement Prep
  async getPlacementPrepModules() {
    let modules = await prisma.placementPrepModule.findMany({
      orderBy: { created_at: 'asc' },
    });
    if (modules.length === 0) {
      await this.seedPlacementPrep();
      modules = await prisma.placementPrepModule.findMany({ orderBy: { created_at: 'asc' } });
    }
    return modules;
  }

  // Mini Projects & Submissions
  async getMiniProjects() {
    let projects = await prisma.miniProjectIdea.findMany({
      orderBy: { created_at: 'asc' },
      include: {
        _count: { select: { user_submissions: true } },
      },
    });

    if (projects.length === 0) {
      await this.seedMiniProjects();
      projects = await prisma.miniProjectIdea.findMany({
        orderBy: { created_at: 'asc' },
        include: { _count: { select: { user_submissions: true } } },
      });
    }

    return projects;
  }

  async getUserSubmissions(userId: string) {
    return prisma.userMiniProjectSubmission.findMany({
      where: { user_id: userId },
      include: {
        project: true,
      },
    });
  }

  async submitMiniProject(userId: string, dto: SubmitMiniProjectDto) {
    return prisma.userMiniProjectSubmission.upsert({
      where: { user_id_project_id: { user_id: userId, project_id: dto.project_id } },
      update: {
        repo_url: dto.repo_url,
        live_demo_url: dto.live_demo_url,
        status: 'COMPLETED',
        submitted_at: new Date(),
      },
      create: {
        user_id: userId,
        project_id: dto.project_id,
        repo_url: dto.repo_url,
        live_demo_url: dto.live_demo_url,
        status: 'COMPLETED',
      },
    });
  }

  // Seeding Helpers
  private async seedDefaultRoadmaps() {
    await prisma.careerRoadmap.create({
      data: {
        title: 'Software Development Engineer (SDE)',
        slug: 'sde-roadmap',
        category: 'Software Engineering',
        description: 'Complete path to crack SDE roles at product-based tech companies.',
        level: 'Intermediate',
        estimated_months: 6,
        icon_name: 'code',
        nodes: {
          create: [
            {
              title: 'Master Programming Language (C++ / Java / Python)',
              description: 'Focus on pointers, OOP principles, memory management, and STL/Collections.',
              order_index: 1,
              estimated_hours: 40,
              resources: {
                create: [
                  { title: 'Learn C++ for Competitive Programming', type: 'VIDEO', url: 'https://youtube.com' },
                  { title: 'Java OOP Fundamentals', type: 'DOCS', url: 'https://docs.oracle.com' },
                ],
              },
            },
            {
              title: 'Data Structures & Algorithms',
              description: 'Arrays, Linked Lists, Trees, Graphs, Dynamic Programming, Heap, Trie.',
              order_index: 2,
              estimated_hours: 80,
              resources: {
                create: [
                  { title: 'LeetCode Top 150 Interview Questions', type: 'PRACTICE', url: 'https://leetcode.com' },
                  { title: 'GeeksforGeeks DSA Sheet', type: 'ARTICLE', url: 'https://geeksforgeeks.org' },
                ],
              },
            },
            {
              title: 'System Design & Computer Fundamentals',
              description: 'OS, DBMS, Computer Networks, System Architecture & Scalability.',
              order_index: 3,
              estimated_hours: 50,
              resources: {
                create: [
                  { title: 'System Design Primer', type: 'DOCS', url: 'https://github.com/donnemartin/system-design-primer' },
                ],
              },
            },
          ],
        },
      },
    });

    await prisma.careerRoadmap.create({
      data: {
        title: 'Full Stack Web Developer',
        slug: 'fullstack-roadmap',
        category: 'Web Development',
        description: 'Master Frontend (React/Next.js), Backend (Node/Express), Databases, and Cloud.',
        level: 'Beginner',
        estimated_months: 4,
        icon_name: 'language',
        nodes: {
          create: [
            {
              title: 'Frontend Fundamentals (HTML, CSS, JS, React)',
              description: 'DOM, ES6+, Responsive Design, State Management, Riverpod/Redux.',
              order_index: 1,
              estimated_hours: 45,
            },
            {
              title: 'Backend & Database Design',
              description: 'Node.js, Express, PostgreSQL, Prisma ORM, REST API Security & JWT.',
              order_index: 2,
              estimated_hours: 50,
            },
          ],
        },
      },
    });
  }

  private async seedResumeTips() {
    await prisma.resumeTip.createMany({
      data: [
        {
          category: 'ATS Optimization',
          title: 'Format for Applicant Tracking Systems (ATS)',
          content: 'Use standard headings (Experience, Education, Projects). Avoid tables, graphics, or multi-column layouts that ATS parsers fail to index.',
          bullet_points: [
            'Use standard PDF or DOCX formats',
            'Include keywords from the job description',
            'Keep margins at 0.5 to 1 inch',
          ],
        },
        {
          category: 'Action Verbs',
          title: 'Use Strong Action Verbs for Bullet Points',
          content: 'Begin every bullet point with an impact verb (Architected, Developed, Engineered, Optimized, Reduced). Quantify metrics wherever possible.',
          bullet_points: [
            'Architected scalable backend service serving 10k+ requests',
            'Optimized database queries reducing API latency by 45%',
          ],
        },
      ],
    });
  }

  private async seedPlacementPrep() {
    await prisma.placementPrepModule.create({
      data: {
        title: 'Data Structures & Algorithms Cheat Sheet',
        category: 'DSA',
        description: 'Top patterns: Two Pointers, Sliding Window, Fast & Slow Pointers, BFS/DFS.',
        content_json: [
          { question: 'Reverse a Linked List', approach: 'Iterative with 3 pointers (prev, curr, next)' },
          { question: 'Two Sum Problem', approach: 'Use HashMap for O(N) lookup' },
        ],
      },
    });
  }

  private async seedMiniProjects() {
    await prisma.miniProjectIdea.create({
      data: {
        title: 'URL Shortener with Analytics Dashboard',
        difficulty: 'Intermediate',
        tech_stack: ['Node.js', 'Express', 'PostgreSQL', 'Redis', 'React'],
        problem_statement: 'Build a link shortener service that provides custom short links, click analytics, and rate limiting.',
        key_features: [
          'Generate unique 6-character short codes',
          'Track click count, location, and device headers',
          'Redis caching for high throughput',
        ],
        github_template_url: 'https://github.com/campushub/url-shortener-starter',
      },
    });
  }
}
