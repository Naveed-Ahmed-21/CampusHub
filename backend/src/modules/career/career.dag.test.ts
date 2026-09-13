import { CareerDAGService, DAGNode, DAGEdge } from './services/career.dag.service';
import { CareerPathfinderService } from './services/career.pathfinder.service';
import { CareerService } from './career.service';
import { prisma } from '../../config/database';
import { aiProvider } from '../../shared/ai/ai.provider';

describe('Career DAG Engine & Semantic Intelligence Tests', () => {
  describe('CareerDAGService - Invariant & Graph Validation', () => {
    const sampleNodes: DAGNode[] = [
      { id: '1', title: 'HTML/CSS', orderIndex: 1 },
      { id: '2', title: 'JavaScript', orderIndex: 2 },
      { id: '3', title: 'React', orderIndex: 3 },
      { id: '4', title: 'Node.js', orderIndex: 4 },
      { id: '5', title: 'Full Stack Capstone', orderIndex: 5 },
    ];

    it('validates a correct linear DAG and produces correct topological order', () => {
      const edges: DAGEdge[] = [
        { sourceSkill: 'HTML/CSS', targetSkill: 'JavaScript', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'JavaScript', targetSkill: 'React', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'React', targetSkill: 'Full Stack Capstone', dependencyType: 'PREREQUISITE' },
      ];

      const result = CareerDAGService.validateDAG(sampleNodes, edges);
      expect(result.isValid).toBe(true);
      expect(result.isDAG).toBe(true);
      expect(result.errors.length).toBe(0);
      expect(result.cycles.length).toBe(0);

      // Topological sorting should have HTML/CSS before JavaScript before React
      const htmlIdx = result.topologicalOrder.indexOf('HTML/CSS');
      const jsIdx = result.topologicalOrder.indexOf('JavaScript');
      const reactIdx = result.topologicalOrder.indexOf('React');
      expect(htmlIdx).toBeLessThan(jsIdx);
      expect(jsIdx).toBeLessThan(reactIdx);
    });

    it('detects and rejects self-dependencies (A -> A)', () => {
      const edges: DAGEdge[] = [
        { sourceSkill: 'JavaScript', targetSkill: 'JavaScript', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'HTML/CSS', targetSkill: 'JavaScript', dependencyType: 'PREREQUISITE' },
      ];

      const result = CareerDAGService.validateDAG(sampleNodes, edges);
      expect(result.isValid).toBe(false);
      expect(result.errors.some((e) => e.includes('Self-dependency'))).toBe(true);
      expect(result.invalidEdges.length).toBeGreaterThan(0);
    });

    it('detects duplicate edges and flags them', () => {
      const edges: DAGEdge[] = [
        { sourceSkill: 'HTML/CSS', targetSkill: 'JavaScript', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'HTML/CSS', targetSkill: 'JavaScript', dependencyType: 'PREREQUISITE' },
      ];

      const result = CareerDAGService.validateDAG(sampleNodes, edges);
      expect(result.isValid).toBe(false);
      expect(result.duplicateEdges.length).toBe(1);
      expect(result.errors.some((e) => e.includes('Duplicate edge'))).toBe(true);
    });

    it('detects cycles (A -> B -> C -> A) using Kahn and DFS cycle detection', () => {
      const cyclicEdges: DAGEdge[] = [
        { sourceSkill: 'HTML/CSS', targetSkill: 'JavaScript', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'JavaScript', targetSkill: 'React', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'React', targetSkill: 'HTML/CSS', dependencyType: 'PREREQUISITE' },
      ];

      const result = CareerDAGService.validateDAG(sampleNodes, cyclicEdges);
      expect(result.isDAG).toBe(false);
      expect(result.cycles.length).toBeGreaterThan(0);
      expect(result.errors.some((e) => e.includes('Circular dependency'))).toBe(true);
    });

    it('prunes cycles to produce a valid DAG', () => {
      const cyclicEdges: DAGEdge[] = [
        { sourceSkill: 'HTML/CSS', targetSkill: 'JavaScript', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'JavaScript', targetSkill: 'React', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'React', targetSkill: 'HTML/CSS', dependencyType: 'PREREQUISITE' }, // Back-edge causing cycle
      ];

      const pruned = CareerDAGService.pruneCyclesToFormDAG(sampleNodes, cyclicEdges);
      const postValidation = CareerDAGService.validateDAG(sampleNodes, pruned);
      expect(postValidation.isDAG).toBe(true);
      expect(pruned.length).toBe(2);
    });

    it('generates dependencies from phases or nodes when none exist', () => {
      const phases = [
        { phase_number: 1, title: 'Web Primitives', skills: ['HTML', 'CSS'] },
        { phase_number: 2, title: 'Interactive Logic', skills: ['JavaScript'] },
        { phase_number: 3, title: 'Component Frameworks', skills: ['React'] },
      ];

      const generated = CareerDAGService.generateDependenciesForRoadmap('test-roadmap-id', sampleNodes, phases);
      expect(generated.length).toBeGreaterThan(0);
      const validation = CareerDAGService.validateDAG(sampleNodes, generated);
      expect(validation.isDAG).toBe(true);
      expect(validation.cycles.length).toBe(0);
    });
  });

  describe('CareerPathfinderService - Semantic Contradiction & Hypotheses', () => {
    it('computes active career hypotheses ranking by confidence', () => {
      const history = [
        { question: 'What do you want to build?', answer: 'Full stack web applications with React and Node.js' },
        { question: 'What database experience do you have?', answer: 'PostgreSQL APIs and REST endpoints' },
      ];

      const pathfinder = new CareerPathfinderService();
      const hypotheses = (pathfinder as any).computeActiveCareerHypotheses('Computer Science', history);
      expect(hypotheses.length).toBeGreaterThan(0);
      expect(hypotheses[0].career).toContain('Web');
      expect(hypotheses[0].confidence).toBeGreaterThanOrEqual(0.6);
    });

    it('detects semantic contradiction via AI structured analysis', async () => {
      const spy = jest.spyOn(aiProvider, 'generateStructured').mockResolvedValueOnce({
        hasContradiction: true,
        contradictionDescription: 'Expressed strong interest in backend earlier but now indicated dislike.',
        conflictingThemes: ['Backend', 'Server-side dislike'],
        suggestedClarification: 'Would you prefer focusing on frontend or client apps?',
      });

      const pathfinder = new CareerPathfinderService();
      const history = [
        { question: 'What domain interests you?', answer: 'Distributed backend architecture and cloud APIs' },
      ];

      const contradiction = await (pathfinder as any).detectSemanticContradiction(
        'What tech stack do you prefer?',
        'I dislike server-side programming and hate backend databases',
        history
      );

      expect(contradiction.hasContradiction).toBe(true);
      expect(contradiction.description).toContain('backend');
      expect(contradiction.suggestedClarification).toContain('frontend');
      spy.mockRestore();
    });

    it('detects semantic contradiction on opposing backend preferences via fallback polarity analyzer', async () => {
      const spy = jest.spyOn(aiProvider, 'generateStructured').mockRejectedValueOnce(new Error('AI unavailable'));

      const pathfinder = new CareerPathfinderService();
      const history = [
        { question: 'What domain interests you?', answer: 'Distributed backend architecture and cloud APIs' },
      ];

      const contradiction = await (pathfinder as any).detectSemanticContradiction(
        'What tech stack do you prefer?',
        'I dislike server-side programming and hate backend databases',
        history
      );

      expect(contradiction.hasContradiction).toBe(true);
      expect(contradiction.description).toBeDefined();
      expect(contradiction.description).toContain('backend');
      spy.mockRestore();
    });
  });

  describe('Quiz Intelligence & Dynamic Roadmap Adaptation', () => {
    let careerService: CareerService;
    const mockUserId = '11111111-2222-3333-4444-555555555555';
    const mockRoadmapId = '8132aead-2a44-47ad-91fb-9754ef845fb3';

    beforeEach(() => {
      careerService = new CareerService({
        updateQuizScore: jest.fn().mockResolvedValue({}),
      } as any);
    });

    it('Test A: High score (>=70%) marks passed=true, boosts confidence score and creates skill evidence', async () => {
      jest.spyOn(prisma.quizAttempt, 'create').mockResolvedValue({ id: 'qa-1' } as any);
      jest.spyOn(prisma.studentSkill, 'findUnique').mockResolvedValue({
        id: 'sk-1',
        confidence_score: 50,
      } as any);
      const upsertSpy = jest.spyOn(prisma.studentSkill, 'upsert').mockResolvedValue({
        id: 'sk-1',
        confidence_score: 65,
      } as any);
      const evidenceSpy = jest.spyOn(prisma.skillEvidence, 'create').mockResolvedValue({ id: 'ev-1' } as any);

      const result = await careerService.submitQuiz(mockUserId, {
        phase_number: 1,
        role: 'Full-Stack',
        roadmap_id: mockRoadmapId,
        answers: { 0: 1, 1: 2, 2: 2 }, // All 3 correct
      });

      expect(result.passed).toBe(true);
      expect(result.percentage).toBe(100);
      expect(result.roadmapAdapted).toBe(false);
      expect(upsertSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          update: expect.objectContaining({
            confidence_score: 65,
          }),
        })
      );
      expect(evidenceSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            evidence_type: 'QUIZ',
            score: 100,
          }),
        })
      );
    });

    it('Test B: Low score (<50%) marks passed=false, adapts roadmap and logs roadmapChange reinforcement', async () => {
      jest.spyOn(prisma.quizAttempt, 'create').mockResolvedValue({ id: 'qa-2' } as any);
      jest.spyOn(prisma.studentSkill, 'findUnique').mockResolvedValue({
        id: 'sk-1',
        confidence_score: 50,
      } as any);
      jest.spyOn(prisma.studentSkill, 'upsert').mockResolvedValue({
        id: 'sk-1',
        confidence_score: 40,
      } as any);
      jest.spyOn(prisma.skillEvidence, 'create').mockResolvedValue({ id: 'ev-2' } as any);
      jest.spyOn(careerService, 'adaptRoadmap').mockResolvedValue({} as any);
      const changeSpy = jest.spyOn(prisma.roadmapChange, 'create').mockResolvedValue({ id: 'rc-1' } as any);

      const result = await careerService.submitQuiz(mockUserId, {
        phase_number: 1,
        role: 'Full-Stack',
        roadmap_id: mockRoadmapId,
        answers: { 0: 0, 1: 0, 2: 0 }, // All incorrect
      });

      expect(result.passed).toBe(false);
      expect(result.percentage).toBe(0);
      expect(result.roadmapAdapted).toBe(true);
      expect(changeSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            roadmap_id: mockRoadmapId,
            user_id: mockUserId,
            title: expect.stringContaining('Reinforced Phase 1'),
          }),
        })
      );
    });
  });
});


