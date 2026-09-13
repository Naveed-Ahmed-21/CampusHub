import { prisma } from '../../config/database';
import { CreateWeeklyGoalDto, SubmitMiniProjectDto } from './career.types';
import { CareerDAGService } from './services/career.dag.service';

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

    return prisma.careerRoadmap.findMany({
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
  }

  // Get user's own created/enrolled roadmaps
  async getUserRoadmaps(userId: string) {
    // 1. Roadmaps directly authored by user
    const authoredRoadmaps = await prisma.careerRoadmap.findMany({
      where: {
        user_id: userId,
        status: { not: 'ARCHIVED' },
      },
      include: {
        nodes: {
          orderBy: { order_index: 'asc' },
          include: { resources: true },
        },
        user_progress: {
          where: { user_id: userId },
        },
        _count: { select: { nodes: true, resources: true } },
      },
      orderBy: { updated_at: 'desc' },
    });

    // 2. Roadmaps the user has progress on (including pre-seeded templates)
    const progressRecords = await prisma.userRoadmapProgress.findMany({
      where: {
        user_id: userId,
        status: { not: 'ARCHIVED' },
      },
      include: {
        roadmap: {
          include: {
            nodes: {
              orderBy: { order_index: 'asc' },
              include: { resources: true },
            },
            _count: { select: { nodes: true, resources: true } },
          },
        },
      },
      orderBy: { updated_at: 'desc' },
    });

    // Merge without duplicates
    const seenMap = new Map<string, any>();

    for (const r of authoredRoadmaps) {
      const prog = r.user_progress?.[0];
      seenMap.set(r.id, {
        id: r.id,
        title: r.title,
        targetRole: r.target_role || r.title,
        category: r.category,
        description: r.description,
        level: r.level,
        version: r.version,
        status: r.status,
        estimatedMonths: r.estimated_months,
        isActive: prog ? prog.is_active : false,
        progressPercent: prog ? prog.progress_percent : 0,
        currentFocus: prog?.current_focus || `Phase 1: Foundations`,
        todayGoal: prog?.today_goal || '',
        streakDays: prog?.streak_days || 1,
        quizScores: prog?.quiz_scores,
        dailyPlan: prog?.daily_plan,
        createdAt: r.created_at,
        updatedAt: r.updated_at,
        nodes: r.nodes,
        phasesJson: r.phases_json,
        skillGapsJson: r.skill_gaps_json,
        skillMapJson: r.skill_map_json,
      });
    }

    for (const p of progressRecords) {
      if (!seenMap.has(p.roadmap_id) && p.roadmap) {
        seenMap.set(p.roadmap_id, {
          id: p.roadmap.id,
          title: p.roadmap.title,
          targetRole: p.target_role || p.roadmap.title,
          category: p.roadmap.category,
          description: p.roadmap.description,
          level: p.level || p.roadmap.level,
          version: p.version,
          status: p.status,
          estimatedMonths: p.roadmap.estimated_months,
          isActive: p.is_active,
          progressPercent: p.progress_percent,
          currentFocus: p.current_focus || `Phase 1: Foundations`,
          todayGoal: p.today_goal || '',
          streakDays: p.streak_days || 1,
          quizScores: p.quiz_scores,
          dailyPlan: p.daily_plan,
          createdAt: p.roadmap.created_at,
          updatedAt: p.updated_at,
          nodes: p.roadmap.nodes,
          phasesJson: p.roadmap.phases_json,
          skillGapsJson: p.roadmap.skill_gaps_json,
          skillMapJson: p.roadmap.skill_map_json,
        });
      }
    }

    return Array.from(seenMap.values());
  }

  // Find existing roadmap for duplicate checking (Normalized role)
  async findExistingRoadmapForRole(userId: string, targetRole: string) {
    const norm = targetRole.trim().toLowerCase();

    // Check user's roadmaps first
    const existing = await prisma.careerRoadmap.findFirst({
      where: {
        user_id: userId,
        status: { not: 'ARCHIVED' },
        OR: [
          { target_role: { equals: targetRole, mode: 'insensitive' } },
          { title: { equals: targetRole, mode: 'insensitive' } },
          { slug: { contains: norm.replace(/[^a-z0-9]+/g, '-').slice(0, 20) } },
        ],
      },
      include: {
        user_progress: {
          where: { user_id: userId },
        },
      },
      orderBy: { version: 'desc' },
    });

    if (existing) {
      return existing;
    }

    // Check active user progress records
    const existingProgress = await prisma.userRoadmapProgress.findFirst({
      where: {
        user_id: userId,
        status: { not: 'ARCHIVED' },
        OR: [
          { target_role: { equals: targetRole, mode: 'insensitive' } },
          { roadmap: { title: { equals: targetRole, mode: 'insensitive' } } },
        ],
      },
      include: {
        roadmap: true,
      },
      orderBy: { updated_at: 'desc' },
    });

    return existingProgress?.roadmap || null;
  }

  // Create custom AI roadmap with versioning
  async createCustomRoadmap(
    userId: string,
    data: {
      title: string;
      targetRole: string;
      category: string;
      description: string;
      level: string;
      estimatedMonths: number;
      goal?: string;
      version: number;
      phasesJson: unknown;
      skillGapsJson: unknown;
      skillMapJson: unknown;
      weeklyHours: number;
      assessmentData?: unknown;
    }
  ) {
    // 1. Mark existing active roadmaps for this user inactive
    await prisma.userRoadmapProgress.updateMany({
      where: { user_id: userId },
      data: { is_active: false },
    });

    const slug = `${data.targetRole.toLowerCase().replace(/[^a-z0-9]+/g, '-')}-v${data.version}-${Date.now()}`;

    // 2. Create CareerRoadmap
    const roadmap = await prisma.careerRoadmap.create({
      data: {
        user_id: userId,
        title: data.title,
        slug,
        target_role: data.targetRole,
        category: data.category,
        description: data.description,
        level: data.level,
        estimated_months: data.estimatedMonths,
        goal: data.goal,
        version: data.version,
        status: 'ACTIVE',
        phases_json: JSON.parse(JSON.stringify(data.phasesJson)),
        skill_gaps_json: JSON.parse(JSON.stringify(data.skillGapsJson)),
        skill_map_json: JSON.parse(JSON.stringify(data.skillMapJson)),
      },
    });

    // 3. Create initial RoadmapNode entries for the phases
    const phases = data.phasesJson as any[];
    if (Array.isArray(phases)) {
      for (const phase of phases) {
        await prisma.roadmapNode.create({
          data: {
            roadmap_id: roadmap.id,
            title: phase.title || `Phase ${phase.phase_number}`,
            description: phase.description || '',
            order_index: phase.phase_number || 1,
            estimated_hours: (phase.weeks || 2) * (data.weeklyHours || 10),
            resources: {
              create: [
                {
                  title: `${phase.title} Overview & Docs`,
                  type: 'DOCS',
                  url: 'https://docs.campushub.edu',
                  is_free: true,
                },
                {
                  title: `${phase.title} Practical Challenge`,
                  type: 'PRACTICE',
                  url: 'https://practice.campushub.edu',
                  is_free: true,
                },
              ],
            },
          },
        });
      }
    }

    // 3b. Generate and persist SkillDependencies DAG
    try {
      const createdNodes = await prisma.roadmapNode.findMany({
        where: { roadmap_id: roadmap.id },
        orderBy: { order_index: 'asc' },
      });
      const dagNodes = createdNodes.map((n) => ({
        id: n.id,
        title: n.title,
        description: n.description || '',
        orderIndex: n.order_index,
      }));
      const dependencies = CareerDAGService.generateDependenciesForRoadmap(
        roadmap.id,
        dagNodes,
        data.phasesJson as any[],
        data.skillMapJson as any[]
      );
      if (dependencies.length > 0) {
        await CareerDAGService.persistDependencies(roadmap.id, dependencies);
      }
    } catch (dagErr) {
      // Safe fallback - roadmap remains intact
    }

    // 4. Initialize UserRoadmapProgress
    const firstPhaseTitle = phases?.[0]?.title || `Phase 1: Foundations of ${data.targetRole}`;
    const initialTodayGoal = `Master initial concepts of ${firstPhaseTitle}`;

    const progress = await prisma.userRoadmapProgress.create({
      data: {
        user_id: userId,
        roadmap_id: roadmap.id,
        is_active: true,
        version: data.version,
        status: 'ACTIVE',
        target_role: data.targetRole,
        level: data.level,
        weekly_hours: data.weeklyHours,
        current_focus: firstPhaseTitle,
        today_goal: initialTodayGoal,
        assessment_data: data.assessmentData ? JSON.parse(JSON.stringify(data.assessmentData)) : undefined,
        streak_days: 1,
        progress_percent: 0.0,
      },
      include: {
        roadmap: {
          include: {
            nodes: {
              orderBy: { order_index: 'asc' },
              include: { resources: true },
            },
          },
        },
      },
    });

    return { roadmap, progress };
  }

  async getRoadmapById(id: string, userId?: string) {
    return prisma.careerRoadmap.findUnique({
      where: { id },
      include: {
        nodes: {
          orderBy: { order_index: 'asc' },
          include: { resources: true },
        },
        resources: true,
        user_progress: userId ? { where: { user_id: userId } } : undefined,
      },
    });
  }

  async updateRoadmap(
    roadmapId: string,
    userId: string,
    data: {
      status?: string;
      title?: string;
      phasesJson?: unknown;
      skillGapsJson?: unknown;
      adaptiveData?: unknown;
    }
  ) {
    const updateData: Record<string, unknown> = {};
    if (data.status) updateData.status = data.status;
    if (data.title) updateData.title = data.title;
    if (data.phasesJson) updateData.phases_json = JSON.parse(JSON.stringify(data.phasesJson));
    if (data.skillGapsJson) updateData.skill_gaps_json = JSON.parse(JSON.stringify(data.skillGapsJson));
    if (data.adaptiveData) updateData.adaptive_data = JSON.parse(JSON.stringify(data.adaptiveData));

    // Update roadmap
    const updatedRoadmap = await prisma.careerRoadmap.update({
      where: { id: roadmapId },
      data: updateData,
    });

    // Sync progress status
    if (data.status) {
      await prisma.userRoadmapProgress.updateMany({
        where: { user_id: userId, roadmap_id: roadmapId },
        data: {
          status: data.status,
          is_active: data.status === 'ACTIVE',
          updated_at: new Date(),
        },
      });
    }

    return updatedRoadmap;
  }

  async deleteRoadmap(roadmapId: string, userId: string) {
    // Soft delete / archive or remove
    const roadmap = await prisma.careerRoadmap.findUnique({ where: { id: roadmapId } });
    if (!roadmap) return null;

    if (roadmap.user_id && roadmap.user_id !== userId) {
      throw new Error('Unauthorized to delete this roadmap');
    }

    return prisma.careerRoadmap.update({
      where: { id: roadmapId },
      data: { status: 'ARCHIVED' },
    });
  }

  async setActiveRoadmap(userId: string, roadmapId: string) {
    await prisma.userRoadmapProgress.updateMany({
      where: { user_id: userId },
      data: { is_active: false },
    });

    return prisma.userRoadmapProgress.upsert({
      where: { user_id_roadmap_id: { user_id: userId, roadmap_id: roadmapId } },
      update: { is_active: true, status: 'ACTIVE', updated_at: new Date() },
      create: {
        user_id: userId,
        roadmap_id: roadmapId,
        is_active: true,
        status: 'ACTIVE',
      },
      include: {
        roadmap: {
          include: {
            nodes: {
              orderBy: { order_index: 'asc' },
              include: { resources: true },
            },
          },
        },
      },
    });
  }

  async getUserRoadmapProgress(userId: string) {
    return prisma.userRoadmapProgress.findMany({
      where: { user_id: userId, status: { not: 'ARCHIVED' } },
      include: {
        roadmap: {
          include: {
            _count: { select: { nodes: true } },
          },
        },
      },
    });
  }

  async getUserRoadmapProgressByRoadmap(userId: string, roadmapId: string) {
    try {
      return await prisma.userRoadmapProgress.findUnique({
        where: { user_id_roadmap_id: { user_id: userId, roadmap_id: roadmapId } },
        include: { roadmap: true },
      });
    } catch (_) {
      return null;
    }
  }

  async getActiveUserRoadmap(userId: string) {
    return prisma.userRoadmapProgress.findFirst({
      where: { user_id: userId, is_active: true, status: 'ACTIVE' },
      include: {
        roadmap: {
          include: {
            nodes: {
              orderBy: { order_index: 'asc' },
              include: { resources: true },
            },
          },
        },
      },
      orderBy: { updated_at: 'desc' },
    });
  }

  async upsertActiveRoadmap(
    userId: string,
    roadmapId: string,
    data: {
      targetRole: string;
      level: string;
      weeklyHours: number;
      currentFocus?: string;
      todayGoal?: string;
      assessmentData?: unknown;
    },
  ) {
    // Mark any other roadmaps inactive
    await prisma.userRoadmapProgress.updateMany({
      where: { user_id: userId },
      data: { is_active: false },
    });

    return prisma.userRoadmapProgress.upsert({
      where: { user_id_roadmap_id: { user_id: userId, roadmap_id: roadmapId } },
      update: {
        is_active: true,
        status: 'ACTIVE',
        target_role: data.targetRole,
        level: data.level,
        weekly_hours: data.weeklyHours,
        current_focus: data.currentFocus,
        today_goal: data.todayGoal,
        assessment_data: data.assessmentData ? JSON.parse(JSON.stringify(data.assessmentData)) : undefined,
        updated_at: new Date(),
      },
      create: {
        user_id: userId,
        roadmap_id: roadmapId,
        is_active: true,
        status: 'ACTIVE',
        target_role: data.targetRole,
        level: data.level,
        weekly_hours: data.weeklyHours,
        current_focus: data.currentFocus,
        today_goal: data.todayGoal,
        assessment_data: data.assessmentData ? JSON.parse(JSON.stringify(data.assessmentData)) : undefined,
      },
      include: {
        roadmap: {
          include: {
            nodes: {
              orderBy: { order_index: 'asc' },
              include: { resources: true },
            },
          },
        },
      },
    });
  }

  async updateDailyTask(
    userId: string,
    roadmapId: string,
    taskId: string,
    isCompleted: boolean
  ) {
    const progress = await prisma.userRoadmapProgress.findUnique({
      where: { user_id_roadmap_id: { user_id: userId, roadmap_id: roadmapId } },
    });

    if (!progress) return null;

    const plan = (progress.daily_plan as any) || {};
    const tasks = (plan.tasks as any[]) || [];

    const targetTask = tasks.find((t) => t.id === taskId);
    if (targetTask) {
      targetTask.is_completed = isCompleted;
    }

    const completedCount = tasks.filter((t) => t.is_completed).length;
    const studyAdd = isCompleted ? (targetTask?.duration_mins || 20) : 0;

    return prisma.userRoadmapProgress.update({
      where: { user_id_roadmap_id: { user_id: userId, roadmap_id: roadmapId } },
      data: {
        daily_plan: JSON.parse(JSON.stringify(plan)),
        total_study_minutes: { increment: studyAdd },
        tasks_completed_count: { increment: isCompleted ? 1 : 0 },
        last_active_at: new Date(),
        updated_at: new Date(),
      },
    });
  }

  async saveDailyPlan(userId: string, roadmapId: string, dailyPlan: unknown) {
    return prisma.userRoadmapProgress.update({
      where: { user_id_roadmap_id: { user_id: userId, roadmap_id: roadmapId } },
      data: {
        daily_plan: JSON.parse(JSON.stringify(dailyPlan)),
        today_goal: (dailyPlan as any)?.today_goal,
        updated_at: new Date(),
      },
    });
  }

  async updateQuizScore(
    userId: string,
    roadmapId: string,
    phaseNumber: number,
    score: number,
    totalQuestions: number,
  ) {
    const existing = await prisma.userRoadmapProgress.findUnique({
      where: { user_id_roadmap_id: { user_id: userId, roadmap_id: roadmapId } },
    });

    const scoresObj = (existing?.quiz_scores as Record<string, unknown>) || {};
    scoresObj[`phase_${phaseNumber}`] = {
      score,
      total: totalQuestions,
      percentage: Math.round((score / totalQuestions) * 100),
      passed: score >= Math.ceil(totalQuestions * 0.6),
      completed_at: new Date().toISOString(),
    };

    return prisma.userRoadmapProgress.upsert({
      where: { user_id_roadmap_id: { user_id: userId, roadmap_id: roadmapId } },
      create: {
        user_id: userId,
        roadmap_id: roadmapId,
        quiz_scores: JSON.parse(JSON.stringify(scoresObj)),
        quizzes_completed_count: 1,
        is_active: true,
        last_active_at: new Date(),
      },
      update: {
        quiz_scores: JSON.parse(JSON.stringify(scoresObj)),
        quizzes_completed_count: { increment: 1 },
        last_active_at: new Date(),
        updated_at: new Date(),
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
        last_active_at: new Date(),
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

  // AI Interaction logging
  async logAIInteraction(userId: string, roadmapId: string | undefined, prompt: string, response: string, category: string = 'GENERAL') {
    return prisma.careerAIInteraction.create({
      data: {
        user_id: userId,
        roadmap_id: roadmapId,
        prompt,
        response,
        category,
      },
    });
  }

  // Mentor Sharing
  async createMentorShare(studentId: string, roadmapId: string, message: string, facultyId?: string) {
    let resolvedFacultyId = facultyId;

    if (!resolvedFacultyId) {
      // Find assigned faculty mentor
      const mentorship = await prisma.studentMentorship.findFirst({
        where: { student_id: studentId },
      });
      if (mentorship) {
        resolvedFacultyId = mentorship.faculty_id;
      }
    }

    if (!resolvedFacultyId) {
      // Find any department faculty as fallback
      const student = await prisma.user.findUnique({
        where: { id: studentId },
        select: { department_id: true, college_id: true },
      });

      const fallbackFaculty = await prisma.user.findFirst({
        where: {
          role: 'FACULTY',
          department_id: student?.department_id,
          college_id: student?.college_id,
        },
      });

      resolvedFacultyId = fallbackFaculty?.id;
    }

    if (!resolvedFacultyId) {
      throw new Error('No assigned faculty mentor found for your profile');
    }

    return prisma.careerMentorShare.create({
      data: {
        student_id: studentId,
        faculty_id: resolvedFacultyId,
        roadmap_id: roadmapId,
        message,
        status: 'PENDING',
      },
      include: {
        faculty: {
          select: { id: true, first_name: true, last_name: true, email: true },
        },
        roadmap: {
          select: { id: true, title: true, target_role: true },
        },
      },
    });
  }

  async getMenteeRoadmaps(facultyId: string) {
    const shares = await prisma.careerMentorShare.findMany({
      where: { faculty_id: facultyId },
      include: {
        student: {
          select: {
            id: true,
            first_name: true,
            last_name: true,
            email: true,
            avatar_url: true,
            department: { select: { name: true } },
          },
        },
        roadmap: true,
      },
      orderBy: { created_at: 'desc' },
    });

    return shares;
  }

  // Weekly Goals
  async getWeeklyGoals(userId: string) {
    return prisma.weeklyGoal.findMany({
      where: { user_id: userId },
      orderBy: { created_at: 'desc' },
    });
  }

  async createWeeklyGoal(userId: string, dto: CreateWeeklyGoalDto) {
    const rawDate = dto.target_date || (dto as any).targetDate;
    let parsedDate = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    if (rawDate) {
      const d = new Date(rawDate);
      if (!isNaN(d.getTime())) {
        parsedDate = d;
      }
    }

    return prisma.weeklyGoal.create({
      data: {
        user_id: userId,
        title: dto.title.trim(),
        target_date: parsedDate,
      },
    });
  }

  async updateWeeklyGoal(goalId: string, userId: string, data: { title?: string; target_date?: string | null; is_completed?: boolean }) {
    const updateData: Record<string, unknown> = {};
    if (data.title !== undefined) updateData.title = data.title.trim();
    if (data.target_date !== undefined && data.target_date !== null) {
      const d = new Date(data.target_date);
      if (!isNaN(d.getTime())) updateData.target_date = d;
    }
    if (data.is_completed !== undefined) {
      updateData.is_completed = data.is_completed;
      updateData.completed_at = data.is_completed ? new Date() : null;
    }

    return prisma.weeklyGoal.update({
      where: { id: goalId, user_id: userId },
      data: updateData,
    });
  }

  async deleteWeeklyGoal(goalId: string, userId: string) {
    return prisma.weeklyGoal.delete({
      where: { id: goalId, user_id: userId },
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
        target_role: 'Software Development Engineer (SDE)',
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
        target_role: 'Full Stack Web Developer',
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
