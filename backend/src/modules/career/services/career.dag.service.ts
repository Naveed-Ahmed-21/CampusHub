import { prisma } from '../../../config/database';
import { logger } from '../../../infrastructure/logger/logger';

export interface DAGNode {
  id: string;
  title: string;
  description?: string;
  estimatedHours?: number;
  orderIndex?: number;
  isCompleted?: boolean;
}

export interface DAGEdge {
  id?: string;
  sourceSkill: string;
  targetSkill: string;
  dependencyType: 'PREREQUISITE' | 'ENHANCEMENT' | 'COREQUISITE';
  confidence?: number;
}

export interface DAGValidationResult {
  isValid: boolean;
  isDAG: boolean;
  topologicalOrder: string[];
  cycles: string[][];
  duplicateEdges: DAGEdge[];
  invalidEdges: Array<{ edge: DAGEdge; reason: string }>;
  orphanNodeIds: string[];
  errors: string[];
}

export class CareerDAGService {
  /**
   * Validates graph structure according to strict DAG invariants:
   * - No self dependencies (A -> A)
   * - No duplicate edges
   * - Valid node/skill references
   * - No circular dependencies (Kahn's algorithm & DFS 3-coloring cycle detection)
   * - Topological sort linear ordering
   * - Orphan / disconnected node reporting
   */
  static validateDAG(nodes: DAGNode[], edges: DAGEdge[]): DAGValidationResult {
    const errors: string[] = [];
    const invalidEdges: Array<{ edge: DAGEdge; reason: string }> = [];
    const duplicateEdges: DAGEdge[] = [];
    const cycles: string[][] = [];

    // 1. Edge Invariant Checks: Self-dependency & Duplicate detection
    const seenEdges = new Set<string>();
    const sanitizedEdges: DAGEdge[] = [];

    for (const edge of edges) {
      const src = edge.sourceSkill.trim();
      const tgt = edge.targetSkill.trim();

      // Check self-dependency
      if (src.toLowerCase() === tgt.toLowerCase()) {
        errors.push(`Self-dependency detected: Skill "${src}" cannot depend on itself.`);
        invalidEdges.push({ edge, reason: 'Self-dependency (A -> A)' });
        continue;
      }

      // Check duplicates
      const edgeKey = `${src.toLowerCase()}->${tgt.toLowerCase()}`;
      if (seenEdges.has(edgeKey)) {
        duplicateEdges.push(edge);
        errors.push(`Duplicate edge detected: "${src}" -> "${tgt}" already exists.`);
        continue;
      }
      seenEdges.add(edgeKey);

      sanitizedEdges.push(edge);
    }

    // 2. Build Adjacency List & In-degree map
    const adj = new Map<string, string[]>();
    const inDegree = new Map<string, number>();
    const allVertices = new Set<string>();

    for (const node of nodes) {
      const key = node.title.trim();
      allVertices.add(key);
      if (!adj.has(key)) adj.set(key, []);
      if (!inDegree.has(key)) inDegree.set(key, 0);
    }

    for (const edge of sanitizedEdges) {
      const src = edge.sourceSkill.trim();
      const tgt = edge.targetSkill.trim();

      allVertices.add(src);
      allVertices.add(tgt);

      if (!adj.has(src)) adj.set(src, []);
      if (!adj.has(tgt)) adj.set(tgt, []);

      adj.get(src)!.push(tgt);
      inDegree.set(tgt, (inDegree.get(tgt) || 0) + 1);
      if (!inDegree.has(src)) inDegree.set(src, 0);
    }

    // 3. Cycle Detection: DFS 3-Coloring (White=0, Gray=1, Black=2)
    const color = new Map<string, number>();
    for (const v of allVertices) color.set(v, 0);

    const parent = new Map<string, string | null>();

    const dfsCycle = (u: string, currentPath: string[]) => {
      color.set(u, 1); // Gray
      currentPath.push(u);

      const neighbors = adj.get(u) || [];
      for (const v of neighbors) {
        if (color.get(v) === 1) {
          // Cycle found! Extract cycle path
          const cycleStartIndex = currentPath.indexOf(v);
          if (cycleStartIndex !== -1) {
            const cyclePath = [...currentPath.slice(cycleStartIndex), v];
            cycles.push(cyclePath);
            errors.push(`Circular dependency detected: ${cyclePath.join(' -> ')}`);
          }
        } else if (color.get(v) === 0) {
          parent.set(v, u);
          dfsCycle(v, currentPath);
        }
      }

      currentPath.pop();
      color.set(u, 2); // Black
    };

    for (const v of allVertices) {
      if (color.get(v) === 0) {
        dfsCycle(v, []);
      }
    }

    // 4. Topological Sort via Kahn's Algorithm
    const queue: string[] = [];
    const inDegreeCopy = new Map<string, number>(inDegree);

    for (const [v, deg] of inDegreeCopy.entries()) {
      if (deg === 0) queue.push(v);
    }

    const topologicalOrder: string[] = [];
    while (queue.length > 0) {
      const u = queue.shift()!;
      topologicalOrder.push(u);

      const neighbors = adj.get(u) || [];
      for (const v of neighbors) {
        const newDeg = (inDegreeCopy.get(v) || 0) - 1;
        inDegreeCopy.set(v, newDeg);
        if (newDeg === 0) {
          queue.push(v);
        }
      }
    }

    const isAcyclic = topologicalOrder.length === allVertices.size && cycles.length === 0;

    // 5. Orphan Detection (nodes with in-degree 0 and out-degree 0 when graph has edges)
    const orphanNodeIds: string[] = [];
    if (sanitizedEdges.length > 0) {
      for (const node of nodes) {
        const title = node.title.trim();
        const hasIncoming = (inDegree.get(title) || 0) > 0;
        const hasOutgoing = (adj.get(title) || []).length > 0;
        if (!hasIncoming && !hasOutgoing) {
          orphanNodeIds.push(node.id);
        }
      }
    }

    const isValid = isAcyclic && errors.length === 0;

    return {
      isValid,
      isDAG: isAcyclic,
      topologicalOrder,
      cycles,
      duplicateEdges,
      invalidEdges,
      orphanNodeIds,
      errors,
    };
  }

  /**
   * Dynamically generates meaningful, validated prerequisite dependency edges
   * based on the roadmap's actual phases, target role, and skills.
   */
  static generateDependenciesForRoadmap(
    roadmapId: string,
    nodes: DAGNode[],
    phasesJson?: any[],
    skillMapJson?: any[]
  ): DAGEdge[] {
    const dependencies: DAGEdge[] = [];

    // Approach A: If skillMap with explicit depends_on is present in roadmap
    if (Array.isArray(skillMapJson) && skillMapJson.length > 1) {
      const idToName = new Map<string, string>();
      for (const sk of skillMapJson) {
        if (sk.id && sk.name) idToName.set(sk.id, sk.name);
      }

      for (const sk of skillMapJson) {
        const target = sk.name;
        if (Array.isArray(sk.depends_on)) {
          for (const depId of sk.depends_on) {
            const source = idToName.get(depId) || depId;
            if (source && target && source !== target) {
              dependencies.push({
                sourceSkill: source,
                targetSkill: target,
                dependencyType: 'PREREQUISITE',
                confidence: 1.0,
              });
            }
          }
        }
      }
    }

    // Approach B: If phases array has rich skills or tasks
    if (dependencies.length === 0 && Array.isArray(phasesJson) && phasesJson.length > 1) {
      // Create inter-phase prerequisites linking successive phases
      for (let i = 0; i < phasesJson.length - 1; i++) {
        const currPhase = phasesJson[i];
        const nextPhase = phasesJson[i + 1];

        const currSkills: string[] = currPhase.skills || [currPhase.title];
        const nextSkills: string[] = nextPhase.skills || [nextPhase.title];

        // Primary prerequisite: anchor skill of Phase i -> anchor skill of Phase i+1
        const src = currSkills[0] || currPhase.title;
        const tgt = nextSkills[0] || nextPhase.title;

        if (src && tgt && src !== tgt) {
          dependencies.push({
            sourceSkill: src,
            targetSkill: tgt,
            dependencyType: 'PREREQUISITE',
            confidence: 1.0,
          });
        }

        // Secondary cross-skill prerequisite if multiple skills exist
        if (currSkills.length > 1 && nextSkills.length > 1) {
          const src2 = currSkills[1];
          const tgt2 = nextSkills[1];
          if (src2 && tgt2 && src2 !== tgt2 && src2 !== src && tgt2 !== tgt) {
            dependencies.push({
              sourceSkill: src2,
              targetSkill: tgt2,
              dependencyType: 'ENHANCEMENT',
              confidence: 0.9,
            });
          }
        }
      }
    }

    // Approach C: Connect consecutive RoadmapNodes directly
    if (dependencies.length === 0 && nodes.length > 1) {
      const sortedNodes = [...nodes].sort((a, b) => (a.orderIndex || 0) - (b.orderIndex || 0));
      for (let i = 0; i < sortedNodes.length - 1; i++) {
        dependencies.push({
          sourceSkill: sortedNodes[i].title,
          targetSkill: sortedNodes[i + 1].title,
          dependencyType: 'PREREQUISITE',
          confidence: 1.0,
        });
      }
    }

    // Validate generated dependencies to guarantee a clean DAG
    const validation = this.validateDAG(nodes, dependencies);
    if (!validation.isDAG) {
      logger.warn({ cycles: validation.cycles }, 'Generated dependencies formed a cycle; sanitizing to linear DAG');
      return this.pruneCyclesToFormDAG(nodes, dependencies);
    }

    return dependencies;
  }

  /**
   * Prunes edges that cause cycles to guarantee a strict DAG
   */
  static pruneCyclesToFormDAG(nodes: DAGNode[], edges: DAGEdge[]): DAGEdge[] {
    const safeEdges: DAGEdge[] = [];
    for (const edge of edges) {
      const candidate = [...safeEdges, edge];
      const check = this.validateDAG(nodes, candidate);
      if (check.isDAG && check.errors.length === 0) {
        safeEdges.push(edge);
      }
    }
    return safeEdges;
  }

  /**
   * Persists validated dependencies into the database for a roadmap
   */
  static async persistDependencies(roadmapId: string, dependencies: DAGEdge[]): Promise<void> {
    for (const dep of dependencies) {
      await prisma.skillDependency.upsert({
        where: {
          roadmap_id_source_skill_target_skill: {
            roadmap_id: roadmapId,
            source_skill: dep.sourceSkill,
            target_skill: dep.targetSkill,
          },
        },
        update: {
          dependency_type: dep.dependencyType,
          confidence: dep.confidence ?? 1.0,
        },
        create: {
          roadmap_id: roadmapId,
          source_skill: dep.sourceSkill,
          target_skill: dep.targetSkill,
          dependency_type: dep.dependencyType,
          confidence: dep.confidence ?? 1.0,
        },
      });
    }
  }

  /**
   * Auto-heals roadmaps: if a roadmap in the DB has 0 dependencies,
   * generates, validates, and persists them immediately.
   */
  static async autoHealRoadmapDependencies(roadmapId: string): Promise<DAGEdge[]> {
    const roadmap = await prisma.careerRoadmap.findUnique({
      where: { id: roadmapId },
      include: {
        nodes: { orderBy: { order_index: 'asc' } },
        skill_dependencies: true,
      },
    });

    if (!roadmap) return [];

    if (roadmap.skill_dependencies.length > 0) {
      return roadmap.skill_dependencies.map((d) => ({
        id: d.id,
        sourceSkill: d.source_skill,
        targetSkill: d.target_skill,
        dependencyType: d.dependency_type as any,
        confidence: d.confidence,
      }));
    }

    // Generate dependencies dynamically
    const nodes: DAGNode[] = roadmap.nodes.map((n) => ({
      id: n.id,
      title: n.title,
      description: n.description || '',
      estimatedHours: n.estimated_hours || 4,
      orderIndex: n.order_index,
    }));

    const generated = this.generateDependenciesForRoadmap(
      roadmapId,
      nodes,
      roadmap.phases_json as any[],
      roadmap.skill_map_json as any[]
    );

    if (generated.length > 0) {
      await this.persistDependencies(roadmapId, generated);
    }

    return generated;
  }
}
