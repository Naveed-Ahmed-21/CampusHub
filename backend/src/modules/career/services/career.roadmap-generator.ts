import { z } from 'zod';
import { prisma } from '../../../config/database';
import { aiProvider } from '../../../shared/ai/ai.provider';
import { gitHubResourceService } from './career.github.service';
import { youTubeResourceService } from './career.youtube.service';
import { logger } from '../../../infrastructure/logger/logger';

const roadmapGenerationSchema = z.object({
  title: z.string(),
  category: z.string(),
  description: z.string(),
  estimatedMonths: z.number().min(1).max(24),
  phases: z.array(
    z.object({
      phaseNumber: z.number(),
      title: z.string(),
      weeks: z.number().min(1).max(12),
      description: z.string(),
      skills: z.array(z.string()).min(1),
      tasks: z.array(
        z.object({
          id: z.string(),
          title: z.string(),
          type: z.enum(['LEARN', 'PRACTICE', 'CHALLENGE']),
          durationMins: z.number().min(15).max(180),
        })
      ),
      project: z.object({
        title: z.string(),
        description: z.string(),
        difficulty: z.enum(['Beginner', 'Intermediate', 'Advanced']),
        techStack: z.array(z.string()),
        milestones: z.array(z.string()),
      }),
      quiz: z.object({
        title: z.string(),
        questions: z.array(
          z.object({
            question: z.string(),
            options: z.array(z.string()).min(2).max(4),
            correctIndex: z.number().min(0).max(3),
            explanation: z.string(),
          })
        ),
      }),
      completionCriteria: z.string(),
    })
  ).min(3).max(8),
  dependencies: z.array(
    z.object({
      sourceSkill: z.string(),
      targetSkill: z.string(),
      dependencyType: z.enum(['PREREQUISITE', 'ENHANCEMENT', 'COREQUISITE']),
    })
  ).min(2),
});

function distributeWeeks(phaseWeights: number[], totalWeeks: number): number[] {
  const n = phaseWeights.length;
  const targetPhases = Math.min(n, Math.max(2, totalWeeks));
  const weights = phaseWeights.slice(0, targetPhases);
  const sumWeights = weights.reduce((a, b) => a + b, 0);

  const result: number[] = new Array(targetPhases).fill(1);
  let remaining = totalWeeks - targetPhases;

  if (remaining > 0) {
    for (let i = 0; i < targetPhases; i++) {
      const extra =
        i === targetPhases - 1
          ? remaining
          : Math.round((weights[i] / sumWeights) * (totalWeeks - targetPhases));
      const add = Math.min(remaining, extra);
      result[i] += add;
      remaining -= add;
      if (remaining <= 0) break;
    }
  }
  return result;
}

export class CareerRoadmapGenerator {
  /**
   * Generates and persists an AI-tailored dependency-aware career roadmap for any department & career direction.
   */
  async generatePersonalizedRoadmap(params: {
    userId: string;
    targetRole: string;
    department?: string;
    level?: string;
    weeklyHours?: number;
    timelineWeeks?: number;
    goal?: string;
    preferredLanguage?: string;
    skillFocusAreas?: string[];
  }) {
    const level = params.level || 'Beginner';
    const weeklyHours = params.weeklyHours || 10;
    const language = params.preferredLanguage || 'English';
    const timelineWeeks = params.timelineWeeks && params.timelineWeeks > 0 ? params.timelineWeeks : 16;
    const estimatedMonths = Math.max(1, Math.round(timelineWeeks / 4));

    // 1. Prompt LLM to construct personalized curriculum graph
    const prompt = `You are the Principal Curriculum Architect at CampusHub University.
Generate a comprehensive, personalized, prerequisite-aware career roadmap.

Student Profile:
- Target Career Role: ${params.targetRole}
- College Department: ${params.department || 'Engineering'}
- Current Level: ${level}
- Target Timeline: Exactly ${timelineWeeks} Weeks (${estimatedMonths} Months)
- Weekly Study Hours: ${weeklyHours}
- Goal: ${params.goal || 'Campus Placement Readiness & Capstone Portfolio'}
- Preferred Learning Language: ${language}
${params.skillFocusAreas?.length ? `- Focus Skills: ${params.skillFocusAreas.join(', ')}` : ''}

Requirements:
1. The curriculum MUST span the ENTIRE duration of ${timelineWeeks} weeks. The sum of all phase "weeks" values MUST equal exactly ${timelineWeeks} weeks.
2. Divide the roadmap into 4 to 8 progressive chronological phases (e.g. 4-6 phases spanning 2-4 weeks each).
3. For each phase, provide specific skills (at least 2-3 per phase), actionable daily tasks (LEARN, PRACTICE, CHALLENGE), a practical mini-project, and a 2-question checkpoint quiz.
4. Explicitly define direct skill dependencies (which skill is a prerequisite for which next skill) to build a Directed Acyclic Graph (DAG).
5. Output ONLY valid JSON matching this schema:
{
  "title": "${params.targetRole}",
  "category": "e.g. Full-Stack Web Development / Embedded Systems / AI & Data Science / Cybersecurity",
  "description": "2-3 sentence overview of this personalized learning journey spanning ${timelineWeeks} weeks.",
  "estimatedMonths": ${estimatedMonths},
  "phases": [
    {
      "phaseNumber": 1,
      "title": "Phase 1 Title",
      "weeks": 3,
      "description": "...",
      "skills": ["Skill 1", "Skill 2"],
      "tasks": [
        { "id": "p1-t1", "title": "...", "type": "LEARN", "durationMins": 45 },
        { "id": "p1-t2", "title": "...", "type": "PRACTICE", "durationMins": 60 }
      ],
      "project": {
        "title": "...",
        "description": "...",
        "difficulty": "Beginner",
        "techStack": ["..."],
        "milestones": ["..."]
      },
      "quiz": {
        "title": "Phase 1 Checkpoint",
        "questions": [
          { "question": "...", "options": ["A", "B", "C", "D"], "correctIndex": 1, "explanation": "..." }
        ]
      },
      "completionCriteria": "..."
    }
  ],
  "dependencies": [
    { "sourceSkill": "Skill 1", "targetSkill": "Skill 2", "dependencyType": "PREREQUISITE" }
  ]
}`;

    let generated: z.infer<typeof roadmapGenerationSchema>;
    try {
      generated = await aiProvider.generateStructured(prompt, roadmapGenerationSchema);
      const totalGenWeeks = generated.phases.reduce((acc, p) => acc + p.weeks, 0);
      if (Math.abs(totalGenWeeks - timelineWeeks) > 1) {
        const weights = generated.phases.map((p) => p.weeks);
        const distributed = distributeWeeks(weights, timelineWeeks);
        generated.phases.forEach((p, idx) => {
          if (distributed[idx]) p.weeks = distributed[idx];
        });
        generated.estimatedMonths = estimatedMonths;
      }
    } catch (err) {
      logger.warn({ err }, 'Roadmap generation schema parse warning, generating domain fallback');
      generated = this.getDomainFallbackCurriculum(params.targetRole, level, timelineWeeks);
    }

    // 2. Fetch real verified GitHub and YouTube resources
    const allSkills = Array.from(new Set(generated.phases.flatMap((p) => p.skills)));
    const phase1 = generated.phases[0];
    const phase1Topic = phase1?.title || params.targetRole;
    const phase1Skill = phase1?.skills[0] || params.targetRole;

    const [githubRepos, phase1Videos] = await Promise.all([
      gitHubResourceService.searchRepositories(params.targetRole, 3),
      Promise.resolve(
        youTubeResourceService.resolveVideos(
          {
            topic: phase1Topic,
            skill: phase1Skill,
            targetRole: params.targetRole,
            preferredLanguage: language,
          },
          language,
          3
        )
      ),
    ]);

    // 3. Persist Roadmap in Database
    const slug = `${params.targetRole.toLowerCase().replace(/[^a-z0-9]+/g, '-')}-v1-${Date.now()}`;
    const roadmapPhasesFormatted = generated.phases.map((p) => ({
      phase_number: p.phaseNumber,
      title: p.title,
      weeks: p.weeks,
      description: p.description,
      objectives: [`Master ${p.skills.join(', ')}`],
      skills: p.skills,
      tasks: p.tasks.map((t) => ({
        id: t.id,
        title: t.title,
        type: t.type,
        duration_mins: t.durationMins,
        is_completed: false,
      })),
      project: {
        title: p.project.title,
        description: p.project.description,
        difficulty: p.project.difficulty,
        tech_stack: p.project.techStack,
        milestones: p.project.milestones,
      },
      quiz: {
        title: p.quiz.title,
        questions: p.quiz.questions.map((q) => ({
          question: q.question,
          options: q.options,
          correct_index: q.correctIndex,
          explanation: q.explanation,
        })),
      },
      completion_criteria: p.completionCriteria,
    }));

    const roadmap = await prisma.careerRoadmap.create({
      data: {
        user_id: params.userId,
        title: generated.title,
        slug,
        target_role: params.targetRole,
        category: generated.category,
        description: generated.description,
        level,
        estimated_months: generated.estimatedMonths,
        learning_language: language,
        phases_json: roadmapPhasesFormatted as any,
        status: 'ACTIVE',
      },
    });

    // 4. Create RoadmapNodes and LearningResources for each milestone skill
    let nodeIndex = 1;
    for (let i = 0; i < generated.phases.length; i++) {
      const p = generated.phases[i];
      const phaseSkills = p.skills && p.skills.length > 0 ? p.skills : [p.title];
      const hoursPerSkill = Math.max(2, Math.round((p.weeks * weeklyHours) / phaseSkills.length));

      for (let s = 0; s < phaseSkills.length; s++) {
        const skillName = phaseSkills[s];
        const node = await prisma.roadmapNode.create({
          data: {
            roadmap_id: roadmap.id,
            title: skillName,
            description: `${p.title}: ${p.description}`,
            order_index: nodeIndex++,
            estimated_hours: hoursPerSkill,
          },
        });

        // Attach primary verified documentation
        await prisma.learningResource.create({
          data: {
            roadmap_id: roadmap.id,
            node_id: node.id,
            title: `${skillName} Official Documentation`,
            type: 'DOCS',
            url: 'https://devdocs.io',
            verification_status: 'VERIFIED',
            difficulty: level,
            language: 'English',
          },
        });

        // Attach YouTube educational resources for this specific milestone
        const skillVideos =
          i === 0 && s === 0 && phase1Videos.length > 0
            ? phase1Videos
            : await youTubeResourceService.resolveVideos(
                {
                  topic: skillName,
                  skill: skillName,
                  targetRole: params.targetRole,
                  preferredLanguage: language,
                },
                language,
                2
              );

        for (const yt of skillVideos) {
          await prisma.learningResource.create({
            data: {
              roadmap_id: roadmap.id,
              node_id: node.id,
              title: yt.title,
              type: 'VIDEO',
              url: yt.url,
              channel_name: yt.channel,
              language: yt.language,
              duration_mins: 90,
              verification_status: 'VERIFIED',
              metadata: { views: yt.views, thumbnail: yt.thumbnailUrl },
            },
          });
        }

        // Attach GitHub repositories to the first node
        if (i === 0 && s === 0 && githubRepos.length > 0) {
          for (const repo of githubRepos) {
            await prisma.learningResource.create({
              data: {
                roadmap_id: roadmap.id,
                node_id: node.id,
                title: `${repo.fullName} (★ ${repo.stars.toLocaleString()})`,
                type: 'GITHUB',
                url: repo.url,
                github_stars: repo.stars,
                github_forks: repo.forks,
                language: repo.language,
                verification_status: 'VERIFIED',
                metadata: { whyUseful: repo.whyUseful, topics: repo.topics },
              },
            });
          }
        }
      }
    }

    // 5. Create SkillDependencies DAG
    for (const dep of generated.dependencies) {
      await prisma.skillDependency.upsert({
        where: {
          roadmap_id_source_skill_target_skill: {
            roadmap_id: roadmap.id,
            source_skill: dep.sourceSkill,
            target_skill: dep.targetSkill,
          },
        },
        update: {},
        create: {
          roadmap_id: roadmap.id,
          source_skill: dep.sourceSkill,
          target_skill: dep.targetSkill,
          dependency_type: dep.dependencyType,
          confidence: 1.0,
        },
      });
    }

    // 6. Initialize Student Skills in student_skills table
    for (const skillName of allSkills) {
      await prisma.studentSkill.upsert({
        where: {
          user_id_skill_name: {
            user_id: params.userId,
            skill_name: skillName,
          },
        },
        update: {},
        create: {
          user_id: params.userId,
          skill_name: skillName,
          category: generated.category,
          target_role: params.targetRole,
          proficiency_level: 'Beginner',
          confidence_score: 40,
        },
      });
    }

    // 7. Initialize UserRoadmapProgress
    await prisma.userRoadmapProgress.upsert({
      where: {
        user_id_roadmap_id: {
          user_id: params.userId,
          roadmap_id: roadmap.id,
        },
      },
      update: {
        is_active: true,
        target_role: params.targetRole,
      },
      create: {
        user_id: params.userId,
        roadmap_id: roadmap.id,
        is_active: true,
        target_role: params.targetRole,
        level,
        weekly_hours: weeklyHours,
        current_focus: generated.phases[0]?.title || 'Foundations',
        progress_percent: 0.0,
      },
    });

    return {
      id: roadmap.id,
      roadmapId: roadmap.id,
      title: roadmap.title,
      targetRole: roadmap.target_role,
      category: roadmap.category,
      description: roadmap.description,
      level: roadmap.level,
      estimatedMonths: roadmap.estimated_months,
      phasesCount: generated.phases.length,
      skillsCount: allSkills.length,
      dependenciesCount: generated.dependencies.length,
      phases_json: roadmapPhasesFormatted,
    };
  }

  private getDomainFallbackCurriculum(
    targetRole: string,
    level: string,
    timelineWeeks: number = 16
  ): z.infer<typeof roadmapGenerationSchema> {
    const roleLower = targetRole.toLowerCase();
    const estimatedMonths = Math.max(1, Math.round(timelineWeeks / 4));

    if (
      roleLower.includes('cyber') ||
      roleLower.includes('security') ||
      roleLower.includes('devsecops') ||
      roleLower.includes('penetration')
    ) {
      const weeks = distributeWeeks([3, 3, 3, 3, 2, 2], timelineWeeks);
      return {
        title: targetRole,
        category: 'Cybersecurity & DevSecOps',
        description: `Comprehensive ${timelineWeeks}-week cybersecurity curriculum covering networking fundamentals, Linux defense, offensive pen-testing, and automated DevSecOps pipelines.`,
        estimatedMonths,
        phases: [
          {
            phaseNumber: 1,
            title: 'Networking & Linux Security Foundations',
            weeks: weeks[0],
            description: 'Master OSI / TCP/IP packet flows, Linux permission models, iptables firewalls, and command-line reconnaissance.',
            skills: ['TCP/IP & OSI Protocols', 'Linux Security & Hardening', 'Wireshark & Packet Analysis'],
            tasks: [
              { id: 'sec-p1-t1', title: 'TCP/IP Handshake and Packet Analysis with Wireshark', type: 'LEARN', durationMins: 45 },
              { id: 'sec-p1-t2', title: 'Linux File Permissions, SUID Bits and Hardening', type: 'PRACTICE', durationMins: 60 },
              { id: 'sec-p1-t3', title: 'Port Scanning and Service Enumeration with Nmap', type: 'CHALLENGE', durationMins: 75 },
            ],
            project: {
              title: 'Network Traffic & Port Audit Scanner',
              description: 'Build a Python script using scapy/socket to scan open ports and detect suspicious network traffic patterns.',
              difficulty: 'Beginner',
              techStack: ['Python', 'Linux', 'Scapy', 'Bash'],
              milestones: ['Port scanning engine', 'Banner grabbing', 'Audit report generation'],
            },
            quiz: {
              title: 'Network & Linux Security Checkpoint',
              questions: [
                {
                  question: 'Which tool is industry-standard for packet capture and deep network protocol inspection?',
                  options: ['Wireshark', 'Docker', 'Vite', 'Postman'],
                  correctIndex: 0,
                  explanation: 'Wireshark is the premier open-source packet analyzer used globally for network security auditing.',
                },
              ],
            },
            completionCriteria: 'Pass network checkpoint and submit port audit scanner.',
          },
          {
            phaseNumber: 2,
            title: 'Threat Reconnaissance & Network Defense',
            weeks: weeks[1],
            description: 'Learn offensive reconnaissance, network enumeration, and defensive firewall configuration.',
            skills: ['Nmap Network Scanning', 'Firewall Configurations & iptables', 'Intrusion Detection Systems'],
            tasks: [
              { id: 'sec-p2-t1', title: 'Advanced Nmap Scripting Engine (NSE) Scans', type: 'LEARN', durationMins: 45 },
              { id: 'sec-p2-t2', title: 'Configuring iptables and UFW Firewalls', type: 'PRACTICE', durationMins: 60 },
            ],
            project: {
              title: 'Automated Vulnerability Recon Tool',
              description: 'Script automated subnet reconnaissance and flag outdated network services.',
              difficulty: 'Intermediate',
              techStack: ['Python', 'Nmap', 'Bash'],
              milestones: ['Subnet discovery', 'Service fingerprinting', 'JSON reporting'],
            },
            quiz: {
              title: 'Reconnaissance Checkpoint',
              questions: [
                {
                  question: 'Which Nmap scan flag performs SYN stealth scanning without completing TCP 3-way handshakes?',
                  options: ['-sS', '-sT', '-sU', '-sP'],
                  correctIndex: 0,
                  explanation: 'The -sS flag initiates SYN stealth scanning, which tears down before completing full handshake.',
                },
              ],
            },
            completionCriteria: 'Complete automated recon script with service fingerprinting.',
          },
          {
            phaseNumber: 3,
            title: 'Web Application Security & OWASP Top 10',
            weeks: weeks[2],
            description: 'Identify and remediate web vulnerabilities including SQL Injection, Cross-Site Scripting (XSS), and Broken Access Controls.',
            skills: ['OWASP Top 10', 'Burp Suite Interception', 'Web Vulnerability Assessment'],
            tasks: [
              { id: 'sec-p3-t1', title: 'OWASP Top 10 Deep Dive: Injection & Broken Auth', type: 'LEARN', durationMins: 45 },
              { id: 'sec-p3-t2', title: 'Intercepting and Modifying HTTP Requests with Burp Suite', type: 'PRACTICE', durationMins: 60 },
            ],
            project: {
              title: 'Vulnerable Lab Pen-Test Report',
              description: 'Perform a comprehensive black-box vulnerability assessment on a simulated lab environment and produce a remediation report.',
              difficulty: 'Intermediate',
              techStack: ['Burp Suite', 'OWASP ZAP', 'SQLMap'],
              milestones: ['Vulnerability discovery', 'Proof of Concept exploitation', 'Remediation guide'],
            },
            quiz: {
              title: 'Web Security Checkpoint',
              questions: [
                {
                  question: 'What is the primary defense against SQL Injection vulnerabilities in modern web applications?',
                  options: ['Parameterized Queries / Prepared Statements', 'Client-side Regex validation', 'Hiding database port', 'Restarting server daily'],
                  correctIndex: 0,
                  explanation: 'Parameterized queries guarantee user input is treated strictly as data, never as executable SQL code.',
                },
              ],
            },
            completionCriteria: 'Submit verified pen-test report with remediation actions.',
          },
          {
            phaseNumber: 4,
            title: 'Offensive Penetration Testing & Exploitation',
            weeks: weeks[3],
            description: 'Master Metasploit, privilege escalation, credential harvesting, and offensive exploitation frameworks.',
            skills: ['Metasploit Framework', 'Privilege Escalation', 'Exploit Development Basics'],
            tasks: [
              { id: 'sec-p4-t1', title: 'Metasploit Modules, Payloads and Meterpreter', type: 'LEARN', durationMins: 45 },
              { id: 'sec-p4-t2', title: 'Linux & Windows Local Privilege Escalation Vectors', type: 'PRACTICE', durationMins: 60 },
            ],
            project: {
              title: 'CTF Challenge Laboratory Exploitation',
              description: 'Root target CTF machines and write formal executive and technical reports.',
              difficulty: 'Advanced',
              techStack: ['Kali Linux', 'Metasploit', 'LinPEAS', 'John the Ripper'],
              milestones: ['Initial foothold', 'Internal enumeration', 'Root privilege escalation'],
            },
            quiz: {
              title: 'Pen-Testing Checkpoint',
              questions: [
                {
                  question: 'What is the function of Meterpreter in Metasploit?',
                  options: ['An advanced, dynamically extensible payload that executes in-memory', 'A password dictionary', 'A firewall daemon', 'A web browser extension'],
                  correctIndex: 0,
                  explanation: 'Meterpreter is an in-memory post-exploitation payload that avoids disk-based antivirus detection.',
                },
              ],
            },
            completionCriteria: 'Capture flags on test lab and document exploitation steps.',
          },
          {
            phaseNumber: 5,
            title: 'Cloud Security & DevSecOps Automation',
            weeks: weeks[4],
            description: 'Integrate SAST/DAST security scanning into CI/CD pipelines and configure Docker container hardening.',
            skills: ['DevSecOps Pipelines', 'SAST & DAST Scanning', 'Docker Container Hardening'],
            tasks: [
              { id: 'sec-p5-t1', title: 'Automating Static Code Analysis (SonarQube / Trivy)', type: 'LEARN', durationMins: 45 },
              { id: 'sec-p5-t2', title: 'Hardening Dockerfiles & Scanning Container Images', type: 'PRACTICE', durationMins: 60 },
            ],
            project: {
              title: 'Hardened DevSecOps Pipeline',
              description: 'GitHub Actions pipeline that automatically blocks deployments if secrets, high-severity CVEs, or vulnerable libraries are detected.',
              difficulty: 'Advanced',
              techStack: ['GitHub Actions', 'Trivy', 'Docker', 'Gitleaks'],
              milestones: ['Secret scanning', 'Vulnerability gate', 'Automated security report'],
            },
            quiz: {
              title: 'DevSecOps Checkpoint',
              questions: [
                {
                  question: 'What is the philosophy of "Shift Left" in DevSecOps?',
                  options: ['Integrating security early in development rather than at deployment', 'Using older frameworks', 'Skipping code reviews', 'Deploying only to left-hand servers'],
                  correctIndex: 0,
                  explanation: 'Shift Left embeds security scans, audits, and compliance into early development and commit phases.',
                },
              ],
            },
            completionCriteria: 'Pass DevSecOps checkpoint and demonstrate zero-CVE pipeline.',
          },
          {
            phaseNumber: 6,
            title: 'Incident Response & SIEM Security Monitoring',
            weeks: weeks[5],
            description: 'Monitor enterprise infrastructure with SIEM tools (ELK/Splunk), detect active intrusions, and orchestrate incident responses.',
            skills: ['SIEM & Log Monitoring', 'Incident Response Playbooks', 'Threat Hunting & Forensics'],
            tasks: [
              { id: 'sec-p6-t1', title: 'SIEM Ingestion, Dashboards and Alerting (Elastic / Splunk)', type: 'LEARN', durationMins: 45 },
              { id: 'sec-p6-t2', title: 'Triage Simulated Ransomware / Data Exfiltration Incidents', type: 'PRACTICE', durationMins: 60 },
            ],
            project: {
              title: 'Enterprise Security Operations Capstone',
              description: 'Configure a full SOC monitoring pipeline ingesting auth logs and triggering real-time anomaly alerts.',
              difficulty: 'Advanced',
              techStack: ['Elasticsearch', 'Kibana', 'Suricata', 'Python'],
              milestones: ['Log pipeline setup', 'Detection rules creation', 'Incident post-mortem report'],
            },
            quiz: {
              title: 'Incident Response Checkpoint',
              questions: [
                {
                  question: 'In NIST incident response guidelines, what is the immediate phase after Detection & Analysis?',
                  options: ['Containment, Eradication & Recovery', 'Post-Incident Activity', 'Preparation', 'Public Press Conference'],
                  correctIndex: 0,
                  explanation: 'Once a threat is detected and analyzed, Containment, Eradication, and Recovery are enacted immediately.',
                },
              ],
            },
            completionCriteria: 'Deliver fully configured SIEM monitoring stack and incident report.',
          },
        ],
        dependencies: [
          { sourceSkill: 'TCP/IP & OSI Protocols', targetSkill: 'Linux Security & Hardening', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Linux Security & Hardening', targetSkill: 'Wireshark & Packet Analysis', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Wireshark & Packet Analysis', targetSkill: 'Nmap Network Scanning', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Nmap Network Scanning', targetSkill: 'Firewall Configurations & iptables', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Firewall Configurations & iptables', targetSkill: 'OWASP Top 10', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'OWASP Top 10', targetSkill: 'Burp Suite Interception', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Burp Suite Interception', targetSkill: 'Metasploit Framework', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Metasploit Framework', targetSkill: 'Privilege Escalation', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Privilege Escalation', targetSkill: 'DevSecOps Pipelines', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'DevSecOps Pipelines', targetSkill: 'Docker Container Hardening', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Docker Container Hardening', targetSkill: 'SIEM & Log Monitoring', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'SIEM & Log Monitoring', targetSkill: 'Threat Hunting & Forensics', dependencyType: 'PREREQUISITE' },
        ],
      };
    }

    if (
      roleLower.includes('ai') ||
      roleLower.includes('machine learning') ||
      roleLower.includes('data science') ||
      roleLower.includes('data scientist')
    ) {
      const weeks = distributeWeeks([3, 3, 3, 3, 2, 2], timelineWeeks);
      return {
        title: targetRole,
        category: 'Artificial Intelligence & Data Science',
        description: `Comprehensive ${timelineWeeks}-week AI curriculum covering mathematical foundations, Python data engineering, neural network architectures, and production LLM agent deployment.`,
        estimatedMonths,
        phases: [
          {
            phaseNumber: 1,
            title: 'Python for Data Science & Math Foundations',
            weeks: weeks[0],
            description: 'Master vectorized array processing with NumPy, tabular data manipulation with Pandas, and linear algebra & statistics.',
            skills: ['Python Data Stack', 'NumPy Vectorized Arrays', 'Linear Algebra & Statistics'],
            tasks: [
              { id: 'ai-p1-t1', title: 'Vectorized Matrix Operations with NumPy', type: 'LEARN', durationMins: 45 },
              { id: 'ai-p1-t2', title: 'Data Cleaning, Imputation and Wrangling with Pandas', type: 'PRACTICE', durationMins: 60 },
              { id: 'ai-p1-t3', title: 'Exploratory Data Analysis (EDA) on Real Datasets', type: 'CHALLENGE', durationMins: 75 },
            ],
            project: {
              title: 'Campus Analytics EDA Dashboard',
              description: 'Perform end-to-end exploratory analysis on campus performance data with statistical visualizations.',
              difficulty: 'Beginner',
              techStack: ['Python', 'Pandas', 'Matplotlib', 'Seaborn'],
              milestones: ['Data ingestion', 'Missing value imputation', 'Correlation matrix heatmap'],
            },
            quiz: {
              title: 'Data Foundations Checkpoint',
              questions: [
                {
                  question: 'Why are NumPy vectorized operations significantly faster than standard Python loops?',
                  options: ['NumPy executes compiled C code with contiguous memory buffers', 'NumPy runs on quantum chips', 'Python loops have syntax errors', 'NumPy skips math calculations'],
                  correctIndex: 0,
                  explanation: 'NumPy leverages optimized C/Fortran vector libraries (BLAS/LAPACK) and contiguous array memory layout.',
                },
              ],
            },
            completionCriteria: 'Pass data foundations quiz and submit EDA dashboard.',
          },
          {
            phaseNumber: 2,
            title: 'Exploratory Data Analysis & Feature Engineering',
            weeks: weeks[1],
            description: 'Advanced data wrangling, outlier detection, scaling, categorical encoding, and statistical hypotheses testing.',
            skills: ['Pandas DataFrames', 'Data Cleaning & Imputation', 'Feature Engineering & Encoders'],
            tasks: [
              { id: 'ai-p2-t1', title: 'Feature Encoders: One-Hot, Target Encoding and MinMax Scaling', type: 'LEARN', durationMins: 45 },
              { id: 'ai-p2-t2', title: 'Outlier Detection and Skewness Correction', type: 'PRACTICE', durationMins: 60 },
            ],
            project: {
              title: 'Automated Feature Preprocessing Pipeline',
              description: 'Reusable Scikit-learn Pipeline that handles missing data, scaling, and categorical encoding without data leakage.',
              difficulty: 'Intermediate',
              techStack: ['Python', 'Scikit-Learn', 'Pandas'],
              milestones: ['ColumnTransformer setup', 'Custom transformer classes', 'Pipeline serialization'],
            },
            quiz: {
              title: 'Feature Engineering Checkpoint',
              questions: [
                {
                  question: 'Why must feature scaling be fit strictly on the training set and not the entire dataset?',
                  options: ['To prevent data leakage from the test set into the model training phase', 'To save disk space', 'Scaling fails on test sets', 'Scikit-Learn throws an error'],
                  correctIndex: 0,
                  explanation: 'Fitting scalers on test data introduces data leakage, giving unrealistically optimistic validation metrics.',
                },
              ],
            },
            completionCriteria: 'Build verified ColumnTransformer pipeline with unit tests.',
          },
          {
            phaseNumber: 3,
            title: 'Machine Learning Models & Cross-Validation',
            weeks: weeks[2],
            description: 'Train and validate predictive regression and classification models using Scikit-Learn and XGBoost.',
            skills: ['Scikit-Learn Algorithms', 'Cross-Validation & Hyperparameter Tuning', 'Ensemble Methods & XGBoost'],
            tasks: [
              { id: 'ai-p3-t1', title: 'Supervised Learning: Decision Trees, Random Forests & XGBoost', type: 'LEARN', durationMins: 45 },
              { id: 'ai-p3-t2', title: 'Cross-Validation, Hyperparameter Tuning & ROC-AUC Curves', type: 'PRACTICE', durationMins: 60 },
            ],
            project: {
              title: 'Student Placement Prediction Engine',
              description: 'Train an ensemble classification pipeline predicting student campus placement probability from academic & skill indicators.',
              difficulty: 'Intermediate',
              techStack: ['Python', 'Scikit-Learn', 'XGBoost', 'Joblib'],
              milestones: ['Pipeline creation', 'Hyperparameter tuning with GridSearchCV', 'Model serialization'],
            },
            quiz: {
              title: 'Machine Learning Checkpoint',
              questions: [
                {
                  question: 'What is the primary indicator that a machine learning model is severely overfitting?',
                  options: ['Near-perfect training score but significantly lower validation score', 'Both train and validation loss are zero', 'Model training takes 1 second', 'Loss function value stays at 100'],
                  correctIndex: 0,
                  explanation: 'Overfitting occurs when a model memorizes the training data nuances but fails to generalize to unseen validation data.',
                },
              ],
            },
            completionCriteria: 'Achieve >85% F1-score on held-out test data and serialize pipeline.',
          },
          {
            phaseNumber: 4,
            title: 'Deep Learning & Neural Networks',
            weeks: weeks[3],
            description: 'Master feedforward networks, backpropagation, convolutional neural networks (CNNs), and transfer learning using PyTorch.',
            skills: ['PyTorch Foundations', 'CNNs & Computer Vision', 'Transfer Learning'],
            tasks: [
              { id: 'ai-p4-t1', title: 'PyTorch Tensors, Autograd, and Loss Backpropagation', type: 'LEARN', durationMins: 45 },
              { id: 'ai-p4-t2', title: 'Building Convolutional Networks and Transfer Learning (ResNet)', type: 'PRACTICE', durationMins: 60 },
            ],
            project: {
              title: 'Campus Document & ID Classifier',
              description: 'Deep learning image classifier using pretrained ResNet to sort student identity and certificate documents.',
              difficulty: 'Advanced',
              techStack: ['PyTorch', 'Torchvision', 'Python'],
              milestones: ['DataLoader setup', 'Fine-tuning ResNet layers', 'Evaluation on test split'],
            },
            quiz: {
              title: 'Deep Learning Checkpoint',
              questions: [
                {
                  question: 'What problem does Batch Normalization primarily address in deep neural networks?',
                  options: ['Internal covariate shift and vanishing/exploding gradients during training', 'Computer overheating', 'Image brightness reduction', 'Reducing dataset size'],
                  correctIndex: 0,
                  explanation: 'Batch Normalization stabilizes gradient propagation across deep layers by standardizing activations.',
                },
              ],
            },
            completionCriteria: 'Train CNN model achieving >90% top-1 accuracy on image validation set.',
          },
          {
            phaseNumber: 5,
            title: 'Generative AI, LLMs & Retrieval-Augmented Generation',
            weeks: weeks[4],
            description: 'Build production Retrieval-Augmented Generation (RAG) applications using open-source embeddings, vector databases, and FastAPI.',
            skills: ['LLM Orchestration (LangChain)', 'Embeddings & Vector Databases (ChromaDB)', 'FastAPI Model Serving'],
            tasks: [
              { id: 'ai-p5-t1', title: 'Embeddings, Cosine Similarity & Vector Databases (Chroma / Pinecone)', type: 'LEARN', durationMins: 45 },
              { id: 'ai-p5-t2', title: 'Building Multi-Document RAG Pipelines with LangChain / LlamaIndex', type: 'PRACTICE', durationMins: 60 },
            ],
            project: {
              title: 'Campus Document QA AI Assistant',
              description: 'Deploy a high-performance FastAPI service that answers queries over college syllabus PDFs using embeddings and vector search.',
              difficulty: 'Advanced',
              techStack: ['Python', 'FastAPI', 'ChromaDB', 'LangChain', 'Docker'],
              milestones: ['PDF chunking & embedding', 'Similarity search endpoint', 'Streaming LLM responses'],
            },
            quiz: {
              title: 'Generative AI Checkpoint',
              questions: [
                {
                  question: 'What is the core benefit of Retrieval-Augmented Generation (RAG)?',
                  options: ['Grounds LLM responses in private or real-time documents to eliminate hallucinations', 'Replaces CPU with GPU', 'Translates code to binary', 'Allows models to train without internet'],
                  correctIndex: 0,
                  explanation: 'RAG retrieves relevant context chunks dynamically from external knowledge bases and inserts them into the model prompt.',
                },
              ],
            },
            completionCriteria: 'Pass GenAI quiz and deploy functional RAG microservice.',
          },
          {
            phaseNumber: 6,
            title: 'Production MLOps & Capstone Portfolio',
            weeks: weeks[5],
            description: 'Deploy, monitor, and scale AI microservices with Docker, Prometheus model telemetry, and CI/CD pipelines.',
            skills: ['Model Serialization & Deployment', 'Dockerized AI Inference', 'AI Capstone Project'],
            tasks: [
              { id: 'ai-p6-t1', title: 'Containerizing AI Workloads with NVIDIA Docker / ONNX Runtime', type: 'LEARN', durationMins: 45 },
              { id: 'ai-p6-t2', title: 'Model Drift Detection and Latency Profiling', type: 'PRACTICE', durationMins: 60 },
            ],
            project: {
              title: 'End-to-End Enterprise AI Platform Capstone',
              description: 'Deploy multi-modal AI system combining predictive tabular model and conversational RAG interface with health monitoring.',
              difficulty: 'Advanced',
              techStack: ['Docker', 'FastAPI', 'Prometheus', 'Streamlit', 'GitHub Actions'],
              milestones: ['Multi-model inference server', 'Streamlit UI integration', 'Automated latency benchmarks'],
            },
            quiz: {
              title: 'MLOps Checkpoint',
              questions: [
                {
                  question: 'What is data drift in machine learning production deployments?',
                  options: ['Changes in the statistical distribution of input data over time degrading model performance', 'Hard drive corruption', 'GPU failure', 'Deleting test files'],
                  correctIndex: 0,
                  explanation: 'Data drift occurs when incoming inference data distributions deviate from the distribution used during training.',
                },
              ],
            },
            completionCriteria: 'Demonstrate live containerized AI inference endpoint with automated health telemetry.',
          },
        ],
        dependencies: [
          { sourceSkill: 'Python Data Stack', targetSkill: 'NumPy Vectorized Arrays', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'NumPy Vectorized Arrays', targetSkill: 'Linear Algebra & Statistics', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Linear Algebra & Statistics', targetSkill: 'Pandas DataFrames', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Pandas DataFrames', targetSkill: 'Data Cleaning & Imputation', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Data Cleaning & Imputation', targetSkill: 'Feature Engineering & Encoders', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Feature Engineering & Encoders', targetSkill: 'Scikit-Learn Algorithms', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Scikit-Learn Algorithms', targetSkill: 'Cross-Validation & Hyperparameter Tuning', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Cross-Validation & Hyperparameter Tuning', targetSkill: 'PyTorch Foundations', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'PyTorch Foundations', targetSkill: 'CNNs & Computer Vision', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'CNNs & Computer Vision', targetSkill: 'LLM Orchestration (LangChain)', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'LLM Orchestration (LangChain)', targetSkill: 'Embeddings & Vector Databases (ChromaDB)', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Embeddings & Vector Databases (ChromaDB)', targetSkill: 'FastAPI Model Serving', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'FastAPI Model Serving', targetSkill: 'AI Capstone Project', dependencyType: 'PREREQUISITE' },
        ],
      };
    }

    if (
      roleLower.includes('mobile') ||
      roleLower.includes('flutter') ||
      roleLower.includes('android') ||
      roleLower.includes('ios')
    ) {
      const weeks = distributeWeeks([3, 3, 3, 3, 2, 2], timelineWeeks);
      return {
        title: targetRole,
        category: 'Cross-Platform Mobile Engineering',
        description: `Comprehensive ${timelineWeeks}-week mobile curriculum covering Flutter UI engineering, state management, offline database sync, platform channels, and production release.`,
        estimatedMonths,
        phases: [
          {
            phaseNumber: 1,
            title: 'Dart Language & Sound Null Safety',
            weeks: weeks[0],
            description: 'Master Dart OOP, sound null safety, async/await, records, pattern matching, and streams.',
            skills: ['Dart Language Fundamentals', 'Dart OOP & Mixins', 'Async Programming & Streams'],
            tasks: [
              { id: 'mob-p1-t1', title: 'Sound Null Safety, Records & Pattern Matching in Dart', type: 'LEARN', durationMins: 45 },
              { id: 'mob-p1-t2', title: 'Dart Collections, Generics, and Functional Operators', type: 'PRACTICE', durationMins: 60 },
            ],
            project: {
              title: 'Dart CLI Financial & Expense Calculator',
              description: 'Build an object-oriented command-line financial management tool using Dart streams and generics.',
              difficulty: 'Beginner',
              techStack: ['Dart SDK', 'Async Streams'],
              milestones: ['OOP domain models', 'Stream controller pipeline', 'Unit test coverage'],
            },
            quiz: {
              title: 'Dart Language Checkpoint',
              questions: [
                {
                  question: 'In Dart null safety, what does the "!" operator assert?',
                  options: ['Asserts that the expression is guaranteed non-null, throwing runtime error if null', 'Negates boolean', 'Declares a variable', 'Imports package'],
                  correctIndex: 0,
                  explanation: 'The null assertion operator (!) casts a nullable type to non-nullable, throwing an exception if null.',
                },
              ],
            },
            completionCriteria: 'Pass Dart quiz and demonstrate null-safe CLI tool.',
          },
          {
            phaseNumber: 2,
            title: 'Flutter UI Architecture & Widget Trees',
            weeks: weeks[1],
            description: 'Master widget trees, adaptive layouts, Material 3 theming, CustomPainters, and slivers.',
            skills: ['Stateless & Stateful Widgets', 'Responsive Layouts & Slivers', 'Material 3 Theming & Animations'],
            tasks: [
              { id: 'mob-p2-t1', title: 'Widget Lifecycle and Composition Tree Optimization', type: 'LEARN', durationMins: 45 },
              { id: 'mob-p2-t2', title: 'Building Adaptive Glassmorphic UI Layouts', type: 'PRACTICE', durationMins: 60 },
            ],
            project: {
              title: 'Campus Social Feed & Events App',
              description: 'Build a multi-screen Flutter mobile application with slivers, animations, and custom theme switches.',
              difficulty: 'Beginner',
              techStack: ['Flutter', 'Dart', 'Material 3'],
              milestones: ['Custom themes', 'SliverAppBar scrolling', 'Responsive layouts'],
            },
            quiz: {
              title: 'Flutter UI Foundations Checkpoint',
              questions: [
                {
                  question: 'What is the difference between a StatelessWidget and a StatefulWidget in Flutter?',
                  options: ['StatefulWidget can mutate its internal State over time, causing rebuilds; StatelessWidget is immutable', 'StatelessWidget has no UI', 'StatefulWidget only runs on iOS', 'StatelessWidget cannot have colors'],
                  correctIndex: 0,
                  explanation: 'StatefulWidget maintains persistent mutable State across widget lifecycles.',
                },
              ],
            },
            completionCriteria: 'Build responsive multi-screen layout and pass widget lifecycle checkpoint.',
          },
          {
            phaseNumber: 3,
            title: 'State Management with Riverpod',
            weeks: weeks[2],
            description: 'Architect scalable mobile applications using Riverpod, immutable state models, and separation of concerns.',
            skills: ['Riverpod Providers & Notifiers', 'AsyncValue & Error Boundaries', 'Code Architecture & Separation of Concerns'],
            tasks: [
              { id: 'mob-p3-t1', title: 'Riverpod Notifiers, AsyncValue and Dependency Injection', type: 'LEARN', durationMins: 45 },
              { id: 'mob-p3-t2', title: 'Refactoring Imperative UI to Reactive Riverpod Providers', type: 'PRACTICE', durationMins: 60 },
            ],
            project: {
              title: 'Campus Task & Project Management App',
              description: 'Interactive app managing complex asynchronous state, filtering, and tag search with Riverpod.',
              difficulty: 'Intermediate',
              techStack: ['Flutter', 'Riverpod 2.0', 'Freezed'],
              milestones: ['State notifiers', 'Optimistic UI updates', 'Error boundary handling'],
            },
            quiz: {
              title: 'Mobile State Management Checkpoint',
              questions: [
                {
                  question: 'In Riverpod, what does AsyncValue guard against?',
                  options: ['Uncaught async exceptions, loading states, and data races', 'Compiler syntax errors', 'Battery drain', 'Memory leaks from animations'],
                  correctIndex: 0,
                  explanation: 'AsyncValue cleanly models data, loading, and error states for asynchronous data streams.',
                },
              ],
            },
            completionCriteria: 'Pass Riverpod quiz and implement reactive state architecture.',
          },
          {
            phaseNumber: 4,
            title: 'Networking, REST APIs & Offline Persistence',
            weeks: weeks[3],
            description: 'Integrate Dio HTTP client, JWT token refresh, interceptors, and local SQLite/Hive database synchronization.',
            skills: ['Dio HTTP Client & Interceptors', 'Offline Storage with SQLite / Hive', 'Local Cache Synchronization'],
            tasks: [
              { id: 'mob-p4-t1', title: 'HTTP Interceptors, JWT Token Refresh and Error Handling', type: 'LEARN', durationMins: 45 },
              { id: 'mob-p4-t2', title: 'Local SQLite CRUD and Bidirectional Sync Engine', type: 'PRACTICE', durationMins: 60 },
            ],
            project: {
              title: 'Offline-First Attendance & Notes Tracker',
              description: 'Production-ready mobile app syncing local SQLite database with remote REST backend.',
              difficulty: 'Intermediate',
              techStack: ['Flutter', 'Riverpod', 'Dio', 'SQLite'],
              milestones: ['State models', 'Offline caching', 'Auto-sync on reconnect'],
            },
            quiz: {
              title: 'Networking & Offline Storage Checkpoint',
              questions: [
                {
                  question: 'Why should JWT refresh token operations be handled inside a Dio interceptor?',
                  options: ['To automatically catch 401s and retry failed requests transparently to the UI layer', 'To speed up mobile battery', 'To prevent animations from pausing', 'To translate JSON'],
                  correctIndex: 0,
                  explanation: 'Interceptors cleanly abstract token renewal and automatic retry mechanisms away from UI code.',
                },
              ],
            },
            completionCriteria: 'Demonstrate offline persistence and error-resilient API communication.',
          },
          {
            phaseNumber: 5,
            title: 'Native Features & Platform Channels',
            weeks: weeks[4],
            description: 'Leverage device sensors, camera, geolocation, local push notifications, and platform channels.',
            skills: ['Camera & Geolocation Services', 'Platform Channels & Native Code', 'Push Notifications (FCM)'],
            tasks: [
              { id: 'mob-p5-t1', title: 'Camera Capture and Geolocation Coordinate Tracking', type: 'LEARN', durationMins: 45 },
              { id: 'mob-p5-t2', title: 'Writing Kotlin/Swift Native Platform Channel Handlers', type: 'PRACTICE', durationMins: 60 },
            ],
            project: {
              title: 'Geo-Tagged Campus Photo Reporter',
              description: 'Mobile app capturing photos with EXIF metadata, GPS tags, and offline queueing.',
              difficulty: 'Advanced',
              techStack: ['Flutter', 'MethodChannel', 'Geolocator', 'Camera'],
              milestones: ['Camera controller', 'Native platform channel', 'Location-tagged uploads'],
            },
            quiz: {
              title: 'Native Integration Checkpoint',
              questions: [
                {
                  question: 'What is the purpose of MethodChannel in Flutter?',
                  options: ['Enables bidirectional message passing between Flutter Dart code and native iOS/Android host code', 'Plays video streams', 'Manages HTTP requests', 'Draws canvas graphics'],
                  correctIndex: 0,
                  explanation: 'MethodChannel enables asynchronous invocation of native platform APIs from Dart code.',
                },
              ],
            },
            completionCriteria: 'Execute native platform channel call and pass device integration quiz.',
          },
          {
            phaseNumber: 6,
            title: 'Testing, CI/CD & App Store Deployment',
            weeks: weeks[5],
            description: 'Write comprehensive widget and integration tests, configure Fastlane and GitHub Actions, and release production APK/AAB.',
            skills: ['Unit, Widget & Integration Tests', 'Fastlane & GitHub Actions CI/CD', 'Production Mobile Capstone App'],
            tasks: [
              { id: 'mob-p6-t1', title: 'Writing Mockito Unit Tests and Widget Tester pumpWidget Tests', type: 'LEARN', durationMins: 45 },
              { id: 'mob-p6-t2', title: 'Automated GitHub Actions Build & Keystore Signing', type: 'PRACTICE', durationMins: 60 },
            ],
            project: {
              title: 'Production Mobile Capstone App',
              description: 'Release-ready Flutter application with 80%+ test coverage, automated CI/CD pipeline, and signed release APK.',
              difficulty: 'Advanced',
              techStack: ['Flutter', 'Fastlane', 'GitHub Actions', 'Mockito'],
              milestones: ['Automated test suite', 'CI release pipeline', 'Signed release build verification'],
            },
            quiz: {
              title: 'Release Engineering Checkpoint',
              questions: [
                {
                  question: 'In Flutter widget testing, what is the purpose of tester.pumpAndSettle()?',
                  options: ['Repeatedly pumps frames until there are no more scheduled animations or timers', 'Reinstalls Flutter SDK', 'Cleans disk storage', 'Deletes test files'],
                  correctIndex: 0,
                  explanation: 'pumpAndSettle() continues pumping the widget tree until all transitions, animations, and microtasks conclude.',
                },
              ],
            },
            completionCriteria: 'Deliver tested release APK with verified GitHub Actions deployment workflow.',
          },
        ],
        dependencies: [
          { sourceSkill: 'Dart Language Fundamentals', targetSkill: 'Dart OOP & Mixins', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Dart OOP & Mixins', targetSkill: 'Stateless & Stateful Widgets', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Stateless & Stateful Widgets', targetSkill: 'Responsive Layouts & Slivers', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Responsive Layouts & Slivers', targetSkill: 'Riverpod Providers & Notifiers', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Riverpod Providers & Notifiers', targetSkill: 'AsyncValue & Error Boundaries', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'AsyncValue & Error Boundaries', targetSkill: 'Dio HTTP Client & Interceptors', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Dio HTTP Client & Interceptors', targetSkill: 'Offline Storage with SQLite / Hive', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Offline Storage with SQLite / Hive', targetSkill: 'Camera & Geolocation Services', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Camera & Geolocation Services', targetSkill: 'Platform Channels & Native Code', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Platform Channels & Native Code', targetSkill: 'Unit, Widget & Integration Tests', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Unit, Widget & Integration Tests', targetSkill: 'Production Mobile Capstone App', dependencyType: 'PREREQUISITE' },
        ],
      };
    }

    if (roleLower.includes('iot') || roleLower.includes('embedded')) {
      const weeks = distributeWeeks([3, 3, 3, 3, 2, 2], timelineWeeks);
      return {
        title: targetRole,
        category: 'IoT & Embedded Systems',
        description: `Comprehensive ${timelineWeeks}-week curriculum connecting microcontroller hardware, sensors, RTOS firmware, and cloud IoT telemetry.`,
        estimatedMonths,
        phases: [
          {
            phaseNumber: 1,
            title: 'Embedded C Programming & Memory Architecture',
            weeks: weeks[0],
            description: 'Master low-level memory layout, bitwise manipulation, pointers, and hardware registers.',
            skills: ['Embedded C Fundamentals', 'Pointers & Register Manipulation', 'Bitwise Operators & Ring Buffers'],
            tasks: [
              { id: 'iot-p1-t1', title: 'Pointers and Dynamic Memory Allocation in C', type: 'LEARN', durationMins: 45 },
              { id: 'iot-p1-t2', title: 'Bitmasking and Register Manipulation Practice', type: 'PRACTICE', durationMins: 60 },
              { id: 'iot-p1-t3', title: 'Implement a Ring Buffer in C', type: 'CHALLENGE', durationMins: 75 },
            ],
            project: {
              title: 'Memory-Safe Circular Buffer',
              description: 'Implement a zero-allocation circular queue for high-frequency sensor streams.',
              difficulty: 'Beginner',
              techStack: ['C', 'GCC', 'Make'],
              milestones: ['Buffer allocation', 'FIFO enqueue/dequeue', 'Overflow handling'],
            },
            quiz: {
              title: 'C Embedded Fundamentals',
              questions: [
                {
                  question: 'What is the primary danger of using dynamic malloc() inside an embedded interrupt service routine (ISR)?',
                  options: ['Heap fragmentation and non-deterministic latency', 'CPU clock slows down', 'Registers are wiped', 'Compiler warning only'],
                  correctIndex: 0,
                  explanation: 'malloc() is non-deterministic and can cause heap fragmentation, leading to fatal crashes inside time-critical ISRs.',
                },
              ],
            },
            completionCriteria: 'Pass C memory quiz and submit working circular buffer.',
          },
          {
            phaseNumber: 2,
            title: 'Microcontrollers (Arduino / ESP32)',
            weeks: weeks[1],
            description: 'Architect firmware on ESP32 dual-core Xtensa microcontrollers with GPIO, ADC, PWM, and I2C/SPI sensors.',
            skills: ['ESP32 Dual-Core Architecture', 'GPIO, Timers & Hardware Interrupts', 'Analog-to-Digital Conversion (ADC)'],
            tasks: [
              { id: 'iot-p2-t1', title: 'ESP32 Architecture and Pinout Configuration', type: 'LEARN', durationMins: 45 },
              { id: 'iot-p2-t2', title: 'Interfacing OLED Display & Temperature Sensor via I2C', type: 'PRACTICE', durationMins: 60 },
              { id: 'iot-p2-t3', title: 'Hardware Interrupt Debouncing Challenge', type: 'CHALLENGE', durationMins: 90 },
            ],
            project: {
              title: 'Weather Monitoring Station',
              description: 'Real-time telemetry weather monitor reading BME280 sensor values and rendering on OLED.',
              difficulty: 'Intermediate',
              techStack: ['ESP32', 'C++', 'I2C', 'FreeRTOS'],
              milestones: ['Sensor reading', 'OLED display driver', 'Threshold alerting'],
            },
            quiz: {
              title: 'ESP32 & Microcontroller Architecture',
              questions: [
                {
                  question: 'What is the main purpose of a GPIO (General Purpose Input/Output) pin on a microcontroller?',
                  options: ['To connect with external devices and sensors', 'To store data permanently', 'To speed up CPU clock', 'To manage RAM'],
                  correctIndex: 0,
                  explanation: 'GPIO pins permit the microcontroller to read signals from sensors and drive actuators like LEDs and relays.',
                },
              ],
            },
            completionCriteria: 'Build working hardware sensor reader and pass GPIO checkpoint.',
          },
          {
            phaseNumber: 3,
            title: 'Serial Communication & Sensor Protocols',
            weeks: weeks[2],
            description: 'Master hardware communication standards: I2C multi-drop buses, high-speed SPI transactions, and UART debugging.',
            skills: ['I2C & SPI Bus Protocols', 'UART Serial Communication', 'Sensor Interfacing & Telemetry'],
            tasks: [
              { id: 'iot-p3-t1', title: 'Mastering I2C Clock Stretching and Addressing', type: 'LEARN', durationMins: 45 },
              { id: 'iot-p3-t2', title: 'SPI DMA High-Frequency Data Streaming', type: 'PRACTICE', durationMins: 60 },
            ],
            project: {
              title: 'Multi-Sensor Data Logger',
              description: 'Hardware logger reading multiple I2C and SPI sensors and logging to SD card via SPI bus.',
              difficulty: 'Intermediate',
              techStack: ['ESP32', 'SPI', 'I2C', 'SD Card Module'],
              milestones: ['Bus initialization', 'Concurrent sensor sampling', 'CSV log write'],
            },
            quiz: {
              title: 'Bus Protocols Checkpoint',
              questions: [
                {
                  question: 'Which serial protocol uses Master-Out-Slave-In (MOSI) and Master-In-Slave-Out (MISO) lines?',
                  options: ['SPI (Serial Peripheral Interface)', 'I2C', 'UART', 'CAN Bus'],
                  correctIndex: 0,
                  explanation: 'SPI uses dedicated MOSI, MISO, SCK, and CS lines for full-duplex synchronous data transmission.',
                },
              ],
            },
            completionCriteria: 'Complete multi-sensor reader with zero bus contention.',
          },
          {
            phaseNumber: 4,
            title: 'Real-Time Operating Systems (FreeRTOS)',
            weeks: weeks[3],
            description: 'Design preemptive multitasking firmware using FreeRTOS tasks, priority scheduling, queues, and binary/counting semaphores.',
            skills: ['FreeRTOS Task Scheduling & Priorities', 'Queues, Semaphores & Mutexes', 'Interrupt Service Routine Safety'],
            tasks: [
              { id: 'iot-p4-t1', title: 'Task Priorities, Context Switching and vTaskDelayUntil', type: 'LEARN', durationMins: 45 },
              { id: 'iot-p4-t2', title: 'Inter-Task Communication with Queues and Mutex Guards', type: 'PRACTICE', durationMins: 60 },
            ],
            project: {
              title: 'Dual-Core Industrial Motor Controller',
              description: 'FreeRTOS application dedicating Core 0 to high-speed sensor interrupts and Core 1 to network telemetry.',
              difficulty: 'Advanced',
              techStack: ['ESP32', 'FreeRTOS', 'C++'],
              milestones: ['Task partitioning', 'Thread-safe queue passing', 'Deadlock prevention'],
            },
            quiz: {
              title: 'FreeRTOS Multitasking Checkpoint',
              questions: [
                {
                  question: 'What critical bug occurs when a lower-priority task holds a mutex needed by a high-priority task?',
                  options: ['Priority Inversion', 'Buffer Overflow', 'Syntax Error', 'Clock Drift'],
                  correctIndex: 0,
                  explanation: 'Priority Inversion occurs when a high-priority task is blocked waiting for a resource held by a low-priority task.',
                },
              ],
            },
            completionCriteria: 'Deliver deadlock-free FreeRTOS multi-tasking firmware.',
          },
          {
            phaseNumber: 5,
            title: 'IoT Protocols (MQTT & WebSockets)',
            weeks: weeks[4],
            description: 'Implement publish/subscribe telemetry over MQTT to AWS IoT / HiveMQ with Wi-Fi reconnection.',
            skills: ['Wi-Fi Sockets & HTTP Clients', 'MQTT Broker Architecture & QoS', 'JSON Telemetry'],
            tasks: [
              { id: 'iot-p5-t1', title: 'MQTT Broker Architecture and QoS Levels', type: 'LEARN', durationMins: 45 },
              { id: 'iot-p5-t2', title: 'Publishing Sensor Telemetry to MQTT Broker', type: 'PRACTICE', durationMins: 60 },
            ],
            project: {
              title: 'Smart Home Automation Node',
              description: 'ESP32 relay controller receiving remote MQTT commands to switch home appliances.',
              difficulty: 'Intermediate',
              techStack: ['ESP32', 'MQTT', 'Mosquitto', 'C++'],
              milestones: ['MQTT connection', 'Subscribing to topics', 'Relay state control'],
            },
            quiz: {
              title: 'MQTT & Telemetry Checkpoint',
              questions: [
                {
                  question: 'Why is MQTT preferred over HTTP for battery-powered IoT devices?',
                  options: ['MQTT has a minimal 2-byte header and uses lightweight publish/subscribe', 'HTTP is encrypted by default', 'MQTT supports 4K video', 'HTTP cannot send numbers'],
                  correctIndex: 0,
                  explanation: 'MQTT packet overhead is tiny (as low as 2 bytes) and uses persistent TCP connections, saving vital battery life.',
                },
              ],
            },
            completionCriteria: 'Transmit live telemetry stream over MQTT with zero dropouts.',
          },
          {
            phaseNumber: 6,
            title: 'Hardware Security, Low-Power & Capstone',
            weeks: weeks[5],
            description: 'Implement deep sleep power optimization, cryptographically secure OTA firmware updates, and deploy an IoT edge device.',
            skills: ['Deep Sleep & Power Management', 'Secure Boot & OTA Firmware Updates', 'IoT Edge Capstone Device'],
            tasks: [
              { id: 'iot-p6-t1', title: 'ULP Coprocessor, Deep Sleep States and Wakeup Stubs', type: 'LEARN', durationMins: 45 },
              { id: 'iot-p6-t2', title: 'HTTPS Over-The-Air (OTA) Firmware Flashing', type: 'PRACTICE', durationMins: 60 },
            ],
            project: {
              title: 'Ultra-Low-Power Remote Environmental Sensor',
              description: 'Solar-powered ESP32 station running on deep sleep, waking every 15 minutes to sample and publish telemetry.',
              difficulty: 'Advanced',
              techStack: ['ESP32', 'FreeRTOS', 'MQTT', 'OTA'],
              milestones: ['Power consumption audit (<15uA)', 'Secure OTA update server', 'Cloud dashboard telemetry'],
            },
            quiz: {
              title: 'IoT Security & Power Checkpoint',
              questions: [
                {
                  question: 'How does Secure Boot protect an embedded IoT device?',
                  options: ['Verifies digital signatures on firmware binaries before executing code on startup', 'Cleans flash memory daily', 'Blocks all radio waves', 'Turns off Wi-Fi'],
                  correctIndex: 0,
                  explanation: 'Secure Boot ensures that only cryptographically signed, trusted firmware binaries can run on the hardware.',
                },
              ],
            },
            completionCriteria: 'Deliver working ultra-low-power IoT device with verified OTA update mechanism.',
          },
        ],
        dependencies: [
          { sourceSkill: 'Embedded C Fundamentals', targetSkill: 'Pointers & Register Manipulation', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Pointers & Register Manipulation', targetSkill: 'Bitwise Operators & Ring Buffers', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Bitwise Operators & Ring Buffers', targetSkill: 'ESP32 Dual-Core Architecture', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'ESP32 Dual-Core Architecture', targetSkill: 'GPIO, Timers & Hardware Interrupts', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'GPIO, Timers & Hardware Interrupts', targetSkill: 'I2C & SPI Bus Protocols', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'I2C & SPI Bus Protocols', targetSkill: 'Sensor Interfacing & Telemetry', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Sensor Interfacing & Telemetry', targetSkill: 'FreeRTOS Task Scheduling & Priorities', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'FreeRTOS Task Scheduling & Priorities', targetSkill: 'Queues, Semaphores & Mutexes', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Queues, Semaphores & Mutexes', targetSkill: 'Wi-Fi Sockets & HTTP Clients', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'Wi-Fi Sockets & HTTP Clients', targetSkill: 'MQTT Broker Architecture & QoS', dependencyType: 'PREREQUISITE' },
          { sourceSkill: 'MQTT Broker Architecture & QoS', targetSkill: 'IoT Edge Capstone Device', dependencyType: 'PREREQUISITE' },
        ],
      };
    }

    // Default: Modern Full-Stack & Software Engineering
    const weeks = distributeWeeks([3, 3, 3, 3, 2, 2], timelineWeeks);
    return {
      title: targetRole,
      category: 'Full-Stack Web Development',
      description: `Comprehensive ${timelineWeeks}-week full-stack web engineering curriculum covering modern HTML/CSS, asynchronous JavaScript, React frontend architecture, Node.js REST services, relational database design, and cloud deployments.`,
      estimatedMonths,
      phases: [
        {
          phaseNumber: 1,
          title: 'Web Foundations & Modern CSS',
          weeks: weeks[0],
          description: 'Master semantic HTML5 markup, modern CSS styling, Flexbox layouts, CSS Grid systems, and responsive design for all screen sizes.',
          skills: ['HTML5 & Semantic Markup', 'Modern CSS & Flexbox', 'CSS Grid & Responsive Design'],
          tasks: [
            { id: 'fs-p1-t1', title: 'Semantic HTML5 Elements, Forms and Accessibility (a11y)', type: 'LEARN', durationMins: 45 },
            { id: 'fs-p1-t2', title: 'Responsive Flexbox and Grid Layout Mastery', type: 'PRACTICE', durationMins: 60 },
            { id: 'fs-p1-t3', title: 'Build a Mobile-First Responsive Landing Page', type: 'CHALLENGE', durationMins: 75 },
          ],
          project: {
            title: 'Modern Developer Portfolio & Showcase',
            description: 'Build a responsive, accessible developer portfolio website with interactive navigation and CSS animations.',
            difficulty: 'Beginner',
            techStack: ['HTML5', 'CSS3', 'Git', 'GitHub Pages'],
            milestones: ['Wireframe & structure', 'CSS styling & responsiveness', 'Deployment to GitHub Pages'],
          },
          quiz: {
            title: 'Web Foundations Checkpoint',
            questions: [
              {
                question: 'Which CSS layout model is primarily designed for one-dimensional layouts (row OR column)?',
                options: ['CSS Flexbox', 'CSS Grid', 'Float layouts', 'Absolute positioning'],
                correctIndex: 0,
                explanation: 'Flexbox is explicitly optimized for 1D layouts (rows or columns), whereas CSS Grid excels at 2D layouts (rows and columns simultaneously).',
              },
            ],
          },
          completionCriteria: 'Pass web fundamentals quiz and deploy responsive portfolio.',
        },
        {
          phaseNumber: 2,
          title: 'Modern JavaScript (ES6+) & DOM Engineering',
          weeks: weeks[1],
          description: 'Deep dive into asynchronous JavaScript, Promises, async/await, closures, prototypes, event delegation, and browser DOM manipulation.',
          skills: ['JavaScript ES6+ Syntax', 'Async Programming & Fetch APIs', 'DOM Manipulation & Events'],
          tasks: [
            { id: 'fs-p2-t1', title: 'Arrow Functions, Destructuring, Spread, and Array Methods (map, filter, reduce)', type: 'LEARN', durationMins: 45 },
            { id: 'fs-p2-t2', title: 'Async/Await, Promises, and Fetching Remote REST Data', type: 'PRACTICE', durationMins: 60 },
            { id: 'fs-p2-t3', title: 'Event Delegation and Dynamic DOM Tree Rendering', type: 'CHALLENGE', durationMins: 75 },
          ],
          project: {
            title: 'Dynamic Weather & Forecast Dashboard',
            description: 'Interactive web app consuming live weather APIs, rendering responsive forecast cards with debounced search.',
            difficulty: 'Beginner',
            techStack: ['JavaScript', 'HTML5', 'CSS3', 'OpenWeatherMap API'],
            milestones: ['API client implementation', 'Dynamic card rendering', 'Error state handling'],
          },
          quiz: {
            title: 'JavaScript Asynchronous Checkpoint',
            questions: [
              {
                question: 'What does the JavaScript event loop do when an async promise resolves?',
                options: ['Places the callback into the microtask queue to run before the next macro task', 'Immediately interrupts synchronous code execution', 'Reruns the entire script from start', 'Blocks all subsequent user clicks'],
                correctIndex: 0,
                explanation: 'Promise callbacks resolve into the microtask queue, which has higher priority than the macrotask queue in the event loop.',
              },
            ],
          },
          completionCriteria: 'Build working API data dashboard and pass async JS checkpoint.',
        },
        {
          phaseNumber: 3,
          title: 'Frontend Architecture with React.js',
          weeks: weeks[2],
          description: 'Architect scalable single-page applications using React functional components, hooks (useState, useEffect, useMemo), and client routing.',
          skills: ['React Components & JSX', 'React Hooks & State Management', 'React Router & API Integration'],
          tasks: [
            { id: 'fs-p3-t1', title: 'Component Decomposition, Props, and JSX Syntax', type: 'LEARN', durationMins: 45 },
            { id: 'fs-p3-t2', title: 'Mastering useState, useEffect, and Custom Hooks', type: 'PRACTICE', durationMins: 60 },
            { id: 'fs-p3-t3', title: 'Client-side Routing and Protected Routes with React Router v6', type: 'CHALLENGE', durationMins: 75 },
          ],
          project: {
            title: 'Campus Course Explorer & Enrollment SPA',
            description: 'Full single-page application with search filters, dynamic routing, and cart/enrollment state management.',
            difficulty: 'Intermediate',
            techStack: ['React', 'TypeScript', 'Vite', 'Tailwind CSS'],
            milestones: ['Component design system', 'Custom filtering hook', 'Persistent enrollment cart'],
          },
          quiz: {
            title: 'React Architecture Checkpoint',
            questions: [
              {
                question: 'Why should state in React never be mutated directly (e.g. state.push())?',
                options: ['Direct mutation prevents React from detecting shallow changes and scheduling re-renders', 'JavaScript throws a syntax error', 'It slows down internet speed', 'React only allows const variables'],
                correctIndex: 0,
                explanation: 'React compares state references (Object.is); mutating objects directly without new references breaks change detection.',
              },
            ],
          },
          completionCriteria: 'Pass React component quiz and deploy responsive SPA.',
        },
        {
          phaseNumber: 4,
          title: 'Scalable Backend Services & REST APIs',
          weeks: weeks[3],
          description: 'Design production backend APIs using Node.js and Express, middleware architecture, JWT authentication, and input validation.',
          skills: ['Node.js & Express.js', 'RESTful API Architecture', 'JWT Authentication & Security'],
          tasks: [
            { id: 'fs-p4-t1', title: 'Express Routing, Controllers, and Centralized Error Handling', type: 'LEARN', durationMins: 45 },
            { id: 'fs-p4-t2', title: 'JWT Authentication, Password Hashing (bcrypt), and Protected Middleware', type: 'PRACTICE', durationMins: 60 },
            { id: 'fs-p4-t3', title: 'Rate Limiting, CORS, and Helmet Security Headers', type: 'CHALLENGE', durationMins: 75 },
          ],
          project: {
            title: 'Campus Marketplace REST API',
            description: 'High-throughput Node/Express REST API with user registration, token refresh, and product listing endpoints.',
            difficulty: 'Intermediate',
            techStack: ['Node.js', 'Express', 'JWT', 'Bcrypt', 'Zod'],
            milestones: ['Auth flow & middleware', 'CRUD endpoints with validation', 'Automated Postman test suite'],
          },
          quiz: {
            title: 'Backend Architecture Checkpoint',
            questions: [
              {
                question: 'Which HTTP status code should be returned when a request lacks valid authentication credentials?',
                options: ['401 Unauthorized', '403 Forbidden', '404 Not Found', '500 Server Error'],
                correctIndex: 0,
                explanation: 'HTTP 401 indicates that authentication is required and has failed or has not yet been provided.',
              },
            ],
          },
          completionCriteria: 'Pass API security quiz and deliver tested REST endpoints.',
        },
        {
          phaseNumber: 5,
          title: 'Database Engineering & Relational Modeling',
          weeks: weeks[4],
          description: 'Architect reliable relational data models with PostgreSQL, manage schema migrations with Prisma ORM, and write ACID-compliant transactions.',
          skills: ['PostgreSQL & Relational Design', 'Prisma ORM & Data Migrations', 'Database Transactions & Indexing'],
          tasks: [
            { id: 'fs-p5-t1', title: 'Relational Schemas: Primary Keys, Foreign Keys, 1-to-N, and N-to-M Relations', type: 'LEARN', durationMins: 45 },
            { id: 'fs-p5-t2', title: 'Prisma Client: Queries, Nested Relations, and Atomic Transactions', type: 'PRACTICE', durationMins: 60 },
          ],
          project: {
            title: 'Database Schema & Transactional Order Engine',
            description: 'Design robust PostgreSQL schema with Prisma supporting concurrent orders, inventory decrements, and ACID safety.',
            difficulty: 'Intermediate',
            techStack: ['PostgreSQL', 'Prisma ORM', 'TypeScript'],
            milestones: ['Prisma schema definition', 'Migration execution', 'ACID transaction tests'],
          },
          quiz: {
            title: 'Database Engineering Checkpoint',
            questions: [
              {
                question: 'What does the "I" in ACID database transactions stand for?',
                options: ['Isolation: concurrent transactions do not interfere with each other', 'Iteration: queries repeat until successful', 'Indexing: all tables require B-Trees', 'Integration: APIs connect to cloud'],
                correctIndex: 0,
                explanation: 'Isolation ensures that concurrent execution of transactions leaves the database in the same state as if executed sequentially.',
              },
            ],
          },
          completionCriteria: 'Pass relational database quiz and execute zero-error Prisma migration.',
        },
        {
          phaseNumber: 6,
          title: 'Cloud Deployment, DevOps & Capstone Portfolio',
          weeks: weeks[5],
          description: 'Containerize client and server applications with Docker, configure CI/CD deployment pipelines, and deploy a production full-stack capstone project.',
          skills: ['Docker Containerization', 'CI/CD Pipelines & Cloud Deploy', 'Full-Stack Capstone Project'],
          tasks: [
            { id: 'fs-p6-t1', title: 'Multi-stage Dockerfiles and Docker Compose Setup', type: 'LEARN', durationMins: 45 },
            { id: 'fs-p6-t2', title: 'GitHub Actions Workflow for Automated Testing and Cloud Deployment', type: 'PRACTICE', durationMins: 60 },
          ],
          project: {
            title: 'Production Full-Stack Capstone Platform',
            description: 'Deploy full-stack web application connecting React frontend, Express API, PostgreSQL database, and automated CI/CD pipeline.',
            difficulty: 'Advanced',
            techStack: ['React', 'Node.js', 'PostgreSQL', 'Docker', 'GitHub Actions'],
            milestones: ['End-to-end integration', 'Docker Compose deployment', 'Live cloud URL verification'],
          },
          quiz: {
            title: 'Deployment Checkpoint',
            questions: [
              {
                question: 'What is the primary benefit of multi-stage Docker builds for web applications?',
                options: ['Dramatically reduces final production container image size by discarding build dependencies', 'Runs frontend on two servers at once', 'Bypasses database authentication', 'Translates JavaScript into C++'],
                correctIndex: 0,
                explanation: 'Multi-stage builds leave compiler tools and heavy node_modules behind, producing tiny, secure production container images.',
              },
            ],
          },
          completionCriteria: 'Pass cloud checkpoint and showcase live deployed capstone URL.',
        },
      ],
      dependencies: [
        { sourceSkill: 'HTML5 & Semantic Markup', targetSkill: 'Modern CSS & Flexbox', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'Modern CSS & Flexbox', targetSkill: 'CSS Grid & Responsive Design', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'CSS Grid & Responsive Design', targetSkill: 'JavaScript ES6+ Syntax', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'JavaScript ES6+ Syntax', targetSkill: 'Async Programming & Fetch APIs', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'Async Programming & Fetch APIs', targetSkill: 'DOM Manipulation & Events', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'DOM Manipulation & Events', targetSkill: 'React Components & JSX', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'React Components & JSX', targetSkill: 'React Hooks & State Management', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'React Hooks & State Management', targetSkill: 'React Router & API Integration', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'React Router & API Integration', targetSkill: 'Node.js & Express.js', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'Node.js & Express.js', targetSkill: 'RESTful API Architecture', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'RESTful API Architecture', targetSkill: 'JWT Authentication & Security', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'JWT Authentication & Security', targetSkill: 'PostgreSQL & Relational Design', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'PostgreSQL & Relational Design', targetSkill: 'Prisma ORM & Data Migrations', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'Prisma ORM & Data Migrations', targetSkill: 'Docker Containerization', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'Docker Containerization', targetSkill: 'CI/CD Pipelines & Cloud Deploy', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'CI/CD Pipelines & Cloud Deploy', targetSkill: 'Full-Stack Capstone Project', dependencyType: 'PREREQUISITE' },
      ],
    };
  }

  static async generateRoadmap(
    userId: string,
    params: {
      targetRole: string;
      department?: string;
      currentLevel?: string;
      hoursPerWeek?: number;
      timelineWeeks?: number;
      primaryGoal?: string;
      preferredLanguage?: string;
      skillFocusAreas?: string[];
    }
  ) {
    return careerRoadmapGenerator.generatePersonalizedRoadmap({
      userId,
      targetRole: params.targetRole,
      department: params.department,
      level: params.currentLevel,
      weeklyHours: params.hoursPerWeek,
      timelineWeeks: params.timelineWeeks,
      goal: params.primaryGoal,
      preferredLanguage: params.preferredLanguage,
      skillFocusAreas: params.skillFocusAreas,
    });
  }
}

export const careerRoadmapGenerator = new CareerRoadmapGenerator();
