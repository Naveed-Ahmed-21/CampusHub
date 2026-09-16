import { PrismaClient, Role } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding Comprehensive Academics & Faculty Resources...');

  // 1. Get or find Faculty and Student users
  const faculty = await prisma.user.findUnique({
    where: { email: 'faculty@campushub.edu' },
    include: { college: true, department: true },
  });

  if (!faculty) {
    console.error('❌ Faculty user not found! Please ensure database is initialized.');
    return;
  }

  const student = await prisma.user.findUnique({
    where: { email: 'student@campushub.edu' },
  });

  const collegeId = faculty.college_id;
  const deptCse = faculty.department_id
    ? await prisma.department.findUnique({ where: { id: faculty.department_id } })
    : await prisma.department.findFirst({ where: { college_id: collegeId, code: 'CSE' } });

  const deptIt = await prisma.department.findFirst({
    where: { college_id: collegeId, code: 'IT' },
  });

  // 2. Upsert Faculty Profile
  const facultyProfile = await prisma.facultyProfile.upsert({
    where: { user_id: faculty.id },
    update: {
      designation: 'Associate Professor & Academic Coordinator',
      qualification: 'Ph.D. in Computer Science (MIT), M.Tech in Distributed Systems',
      department_name: deptCse?.name || 'Computer Science and Engineering',
      specialization: 'Distributed Systems, Cloud Computing, Kubernetes & Microservices',
      bio: 'Dr. Robert Taylor has over 14 years of teaching and research experience in large-scale distributed computing, cloud resilience, and container orchestration. He advises undergraduate capstones and leads the Campus Cloud Systems Lab.',
      office_room: 'Tech Block B, Room 304',
      office_hours: 'Mon & Wed: 2:00 PM - 4:30 PM, Fri: 10:00 AM - 12:00 PM',
      expertise: [
        'Cloud Computing',
        'Distributed Systems',
        'Kubernetes & Docker',
        'Microservice Architectures',
        'Computer Networks',
        'Database Internals',
      ],
      publications: [
        {
          title: 'Resilient Microservice Orchestration with Predictive Auto-scaling in Edge-Cloud Clusters',
          venue: 'IEEE Transactions on Cloud Computing, 2024',
          link: 'https://doi.org/10.1109/TCC.2024.01',
        },
        {
          title: 'Benchmarking Container Migration Overhead in Heterogeneous Hypervisor Environments',
          venue: 'ACM SIGOPS Operating Systems Review, 2023',
          link: 'https://doi.org/10.1145/sigops.2023.08',
        },
      ],
      linkedin_url: 'https://linkedin.com/in/robert-taylor-campushub',
      google_scholar: 'https://scholar.google.com/citations?user=robert_taylor_ch',
    },
    create: {
      user_id: faculty.id,
      designation: 'Associate Professor & Academic Coordinator',
      qualification: 'Ph.D. in Computer Science (MIT), M.Tech in Distributed Systems',
      department_name: deptCse?.name || 'Computer Science and Engineering',
      specialization: 'Distributed Systems, Cloud Computing, Kubernetes & Microservices',
      bio: 'Dr. Robert Taylor has over 14 years of teaching and research experience in large-scale distributed computing, cloud resilience, and container orchestration. He advises undergraduate capstones and leads the Campus Cloud Systems Lab.',
      office_room: 'Tech Block B, Room 304',
      office_hours: 'Mon & Wed: 2:00 PM - 4:30 PM, Fri: 10:00 AM - 12:00 PM',
      expertise: [
        'Cloud Computing',
        'Distributed Systems',
        'Kubernetes & Docker',
        'Microservice Architectures',
        'Computer Networks',
        'Database Internals',
      ],
      publications: [
        {
          title: 'Resilient Microservice Orchestration with Predictive Auto-scaling in Edge-Cloud Clusters',
          venue: 'IEEE Transactions on Cloud Computing, 2024',
          link: 'https://doi.org/10.1109/TCC.2024.01',
        },
        {
          title: 'Benchmarking Container Migration Overhead in Heterogeneous Hypervisor Environments',
          venue: 'ACM SIGOPS Operating Systems Review, 2023',
          link: 'https://doi.org/10.1145/sigops.2023.08',
        },
      ],
      linkedin_url: 'https://linkedin.com/in/robert-taylor-campushub',
      google_scholar: 'https://scholar.google.com/citations?user=robert_taylor_ch',
    },
  });
  console.log(`✅ Faculty Profile configured for Dr. Robert Taylor (${facultyProfile.designation})`);

  // 3. Define Standard Academic Curriculum Subjects
  const subjectsData = [
    {
      code: 'CS335',
      name: 'Cloud Computing & Distributed Systems',
      semester: 'Semester 5',
      section: 'A',
      credits: 4,
      departmentId: deptCse?.id,
      description: 'Comprehensive study of cloud computing architectures, virtualization, container orchestration with Kubernetes, distributed storage systems, serverless patterns, and multi-region fault tolerance.',
      resources: [
        {
          unit: 'Unit 1',
          topic: 'Cloud Computing Foundations & Hypervisor Architecture',
          title: 'Unit 1 Lecture Handout: Cloud Principles & Type-1/2 Hypervisors.pdf',
          description: 'Detailed overview of NIST cloud characteristics, utility computing history, virtualization layer, VT-x CPU virtualization, and memory ballooning.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs335/unit1_cloud_foundations.pdf',
          fileType: 'PDF',
          resourceType: 'NOTES',
          downloadCount: 142,
          viewCount: 388,
        },
        {
          unit: 'Unit 1',
          topic: 'Hardware Virtualization & VM Migration',
          title: 'Unit 1 Slides: Virtual Machines vs Hardware Emulation.pptx',
          description: 'Slide deck presented in Week 1-2 lectures covering xen hypervisors, KVM kernel module, and live VM memory dirty tracking.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs335/unit1_virtualization_slides.pptx',
          fileType: 'PPT',
          resourceType: 'PRESENTATION',
          downloadCount: 96,
          viewCount: 245,
        },
        {
          unit: 'Unit 1',
          topic: 'Distributed Systems & Cloud Architecture Intro',
          title: 'MIT 6.824: Distributed Systems & Cloud Architecture Foundations',
          description: 'Recommended MIT OpenCourseWare reference lecture on RPCs, network transparency, and concurrency models.',
          fileUrl: 'https://www.youtube.com/watch?v=cQP8WApzIQQ',
          fileType: 'VIDEO',
          resourceType: 'YOUTUBE',
          downloadCount: 31,
          viewCount: 512,
        },
        {
          unit: 'Unit 2',
          topic: 'Service Models & Cloud SLAs',
          title: 'Unit 2 Notes: IaaS, PaaS, SaaS Architectures & SLA Formulations.pdf',
          description: 'Comparative study of compute instance pricing models, storage durability percentages, 99.99% uptime mathematics, and penalties.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs335/unit2_service_models_sla.pdf',
          fileType: 'PDF',
          resourceType: 'NOTES',
          downloadCount: 118,
          viewCount: 290,
        },
        {
          unit: 'Unit 2',
          topic: 'Cloud Reference Architectures',
          title: 'AWS & GCP Well-Architected Framework Reference Guide.pdf',
          description: 'Design principles for reliability, security, cost optimization, operational excellence, and performance efficiency.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs335/unit2_well_architected_guide.pdf',
          fileType: 'PDF',
          resourceType: 'REFERENCE_BOOK',
          downloadCount: 84,
          viewCount: 175,
        },
        {
          unit: 'Unit 3',
          topic: 'Docker Containerization & Linux Namespaces',
          title: 'Unit 3 Notes: Linux Namespaces, Cgroups & Container Internals.pdf',
          description: 'In-depth notes on pid, net, ipc, mnt namespaces, control groups memory limits, copy-on-write overlay2 storage driver, and rootless containers.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs335/unit3_docker_internals.pdf',
          fileType: 'PDF',
          resourceType: 'NOTES',
          downloadCount: 165,
          viewCount: 420,
        },
        {
          unit: 'Unit 3',
          topic: 'Microservices & Containerization Lab',
          title: 'Multi-Tier Cloud Microservice Starter Code Repository',
          description: 'Official course repository with 3-tier node/redis/postgres services, Dockerfile multistage builds, and docker-compose.yml configuration.',
          fileUrl: 'https://github.com/campushub-academic/cloud-microservices-lab',
          fileType: 'CODE',
          resourceType: 'GITHUB',
          downloadCount: 77,
          viewCount: 310,
        },
        {
          unit: 'Unit 3',
          topic: 'Docker Hands-On Lab Walkthrough',
          title: 'Video Lecture: Writing Production Dockerfiles & Layer Caching',
          description: 'Recorded lecture demonstrating alpine base images, security scanning with Trivy, non-root user setup, and healthchecks.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs335/unit3_dockerfile_lecture.mp4',
          fileType: 'VIDEO',
          resourceType: 'VIDEO',
          downloadCount: 45,
          viewCount: 280,
        },
        {
          unit: 'Unit 4',
          topic: 'Kubernetes Cluster Architecture & Orchestration',
          title: 'Unit 4 Handout: Kubernetes Control Plane & Worker Node Mechanics.pdf',
          description: 'Etcd consensus, kube-apiserver, kube-scheduler, kube-controller-manager, kubelet, and kube-proxy operational blueprints.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs335/unit4_kubernetes_architecture.pdf',
          fileType: 'PDF',
          resourceType: 'NOTES',
          downloadCount: 190,
          viewCount: 460,
        },
        {
          unit: 'Unit 4',
          topic: 'Kubernetes Scaling & Horizontal Pod Autoscaling (HPA)',
          title: 'Unit 4 Lab Assignment: Autoscaling Web Services under Synthetic Load.pdf',
          description: 'Hands-on assignment: Deploy nginx with metrics-server, configure HPA for 50% CPU target, generate load with ApacheBench, submit yaml and grafana graphs.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs335/unit4_assignment_autoscaling.pdf',
          fileType: 'PDF',
          resourceType: 'ASSIGNMENT',
          downloadCount: 215,
          viewCount: 530,
        },
        {
          unit: 'Unit 5',
          topic: 'Cloud Storage Systems & Object Store Mechanics',
          title: 'Unit 5 Notes: Distributed Storage (Ceph, S3, GlusterFS) & IAM Security.pdf',
          description: 'Consistent hashing, replication rings, CRUSH algorithm in Ceph, S3 multipart uploads, IAM role-based policies, and envelope encryption with KMS.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs335/unit5_distributed_storage.pdf',
          fileType: 'PDF',
          resourceType: 'NOTES',
          downloadCount: 130,
          viewCount: 320,
        },
        {
          unit: 'Unit 5',
          topic: 'Comprehensive Exam Preparation',
          title: 'CS335 End-Semester Model Question Bank & Solved Proofs.pdf',
          description: 'Complete 10-year question bank with detailed answers, CAP theorem proofs, Paxos step-by-step traces, and sample architecture design questions.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs335/cs335_question_bank_solved.pdf',
          fileType: 'PDF',
          resourceType: 'QUESTION_BANK',
          downloadCount: 310,
          viewCount: 780,
        },
      ],
      announcements: [
        {
          title: 'Unit 4 Hands-On Kubernetes Assignment Published',
          content: 'The Lab Assignment for Horizontal Pod Autoscaling has been posted under Unit 4. Please complete it and push your git repo before next Friday 11:59 PM.',
        },
        {
          title: 'Mid-Term Exam Syllabus & Extra Office Hours',
          content: 'Mid-term exams will cover Units 1 through 3. I will hold extended office hours on Thursday from 2 PM to 5 PM in Room 304 for any doubt clearances.',
        },
      ],
    },
    {
      code: 'CS301',
      name: 'Data Structures & Algorithms',
      semester: 'Semester 3',
      section: 'A',
      credits: 4,
      departmentId: deptCse?.id,
      description: 'Foundations of computer science: algorithmic analysis, recurrence relations, dynamic arrays, balanced search trees, heaps, graph traversals, and dynamic programming.',
      resources: [
        {
          unit: 'Unit 1',
          topic: 'Asymptotic Analysis & Recurrences',
          title: 'Unit 1 Notes: Big-O, Master Theorem & Amortized Analysis.pdf',
          description: 'Formal proofs for time and space complexities, substitution method, recursion trees, and dynamic table doubling amortization.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs301/unit1_asymptotic_analysis.pdf',
          fileType: 'PDF',
          resourceType: 'NOTES',
          downloadCount: 220,
          viewCount: 640,
        },
        {
          unit: 'Unit 2',
          topic: 'Balanced Trees: AVL & Red-Black Trees',
          title: 'Unit 2 Slides: Tree Rotations, Color Invariants & Balancing.pdf',
          description: 'Single/double rotations, insertion/deletion fixups in Red-Black trees with step-by-step visual proofs.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs301/unit2_balanced_trees.pdf',
          fileType: 'PDF',
          resourceType: 'PRESENTATION',
          downloadCount: 185,
          viewCount: 490,
        },
        {
          unit: 'Unit 3',
          topic: 'Graph Algorithms & Shortest Paths',
          title: 'Unit 3 Handout: Dijkstra, Bellman-Ford & Floyd-Warshall.pdf',
          description: 'Implementation details, priority queue optimizations, negative weight cycle detection, and DAG topological sorting.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs301/unit3_graph_algorithms.pdf',
          fileType: 'PDF',
          resourceType: 'NOTES',
          downloadCount: 260,
          viewCount: 710,
        },
        {
          unit: 'Unit 4',
          topic: 'Dynamic Programming & Memoization',
          title: 'Unit 4 DP Masterclass: Knapsack, LCS & Matrix Chain Multiplication.pdf',
          description: 'Optimal substructure, overlapping subproblems, state definitions, transitions, and space-optimized table iterations.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs301/unit4_dynamic_programming.pdf',
          fileType: 'PDF',
          resourceType: 'NOTES',
          downloadCount: 295,
          viewCount: 850,
        },
        {
          unit: 'Unit 5',
          topic: 'NP-Completeness & Approximation Algorithms',
          title: 'CS301 Question Bank with Solved LeetCode Hard Patterns.pdf',
          description: 'Comprehensive preparation bank covering 75 curated algorithm problems with asymptotic proofs.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs301/cs301_solved_question_bank.pdf',
          fileType: 'PDF',
          resourceType: 'QUESTION_BANK',
          downloadCount: 340,
          viewCount: 920,
        },
      ],
      announcements: [
        {
          title: 'Lab 4 Graph Algorithms Benchmark Submission Due',
          content: 'Please ensure your Dijkstra and A* graph benchmark implementations are committed to your GitHub classroom by Monday morning.',
        },
      ],
    },
    {
      code: 'CS402',
      name: 'Database Management Systems',
      semester: 'Semester 4',
      section: 'A',
      credits: 4,
      departmentId: deptCse?.id,
      description: 'Relational algebra, relational calculus, SQL optimization, B+ Tree indexing, ACID transactions, write-ahead logging (WAL), and distributed query execution.',
      resources: [
        {
          unit: 'Unit 1',
          topic: 'Relational Model & Relational Algebra',
          title: 'Unit 1 Notes: Relational Model, Tuples & Algebraic Operators.pdf',
          description: 'Formal relational algebra operations: select, project, cross product, joins, division, and tuple relational calculus.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs402/unit1_relational_algebra.pdf',
          fileType: 'PDF',
          resourceType: 'NOTES',
          downloadCount: 150,
          viewCount: 410,
        },
        {
          unit: 'Unit 2',
          topic: 'Normalization & Functional Dependencies',
          title: 'Unit 2 Handout: 1NF through BCNF, Armstrongs Axioms & Lossless Joins.pdf',
          description: 'Canonical covers, dependency preserving decompositions, 3NF synthesis algorithm, and BCNF test proofs.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs402/unit2_normalization_bcnf.pdf',
          fileType: 'PDF',
          resourceType: 'NOTES',
          downloadCount: 190,
          viewCount: 520,
        },
        {
          unit: 'Unit 3',
          topic: 'Storage & B+ Tree Index Internals',
          title: 'Unit 3 Slides: Page Layout, Slotted Pages & B+ Tree Node Splitting.pdf',
          description: 'Internal database file layout, buffer pool LRU-K replacement, B+ tree leaf chaining, and concurrent latch crabbing.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs402/unit3_bplus_tree_indexing.pdf',
          fileType: 'PDF',
          resourceType: 'PRESENTATION',
          downloadCount: 175,
          viewCount: 480,
        },
        {
          unit: 'Unit 4',
          topic: 'Transactions & Concurrency Control',
          title: 'Unit 4 Notes: ACID Properties, 2PL, Strict 2PL & MVCC.pdf',
          description: 'Conflict serializability, precedence graphs, phantom reads, multi-version concurrency control in PostgreSQL, and deadlock detection.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs402/unit4_concurrency_control.pdf',
          fileType: 'PDF',
          resourceType: 'NOTES',
          downloadCount: 210,
          viewCount: 590,
        },
        {
          unit: 'Unit 5',
          topic: 'Crash Recovery & WAL Logging',
          title: 'CS402 Model Exam Questions & ARIES Recovery Walkthrough.pdf',
          description: 'Analysis, Redo, Undo phases in ARIES crash recovery with dirty page tables and transaction tables.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs402/cs402_aries_recovery_bank.pdf',
          fileType: 'PDF',
          resourceType: 'QUESTION_BANK',
          downloadCount: 230,
          viewCount: 610,
        },
      ],
      announcements: [
        {
          title: 'SQL Optimizer Lab Assignment Posted',
          content: 'Examine PostgreSQL EXPLAIN ANALYZE queries on 1-million row datasets. Assignment guidelines are available on the subject hub.',
        },
      ],
    },
    {
      code: 'CS501',
      name: 'Computer Networks & Internet Protocols',
      semester: 'Semester 5',
      section: 'A',
      credits: 3,
      departmentId: deptCse?.id,
      description: 'OSI/TCP-IP models, socket programming, reliable transport (TCP congestion control Reno/Cubic), BGP routing, DNS, and TLS 1.3 cryptographic handshakes.',
      resources: [
        {
          unit: 'Unit 1',
          topic: 'Physical & Data Link Layers',
          title: 'Unit 1 Notes: Framing, Error Detection (CRC-32) & CSMA/CD.pdf',
          description: 'Ethernet framing, sliding window protocols, Go-Back-N, Selective Repeat, and MAC layer arbitration.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs501/unit1_datalink_framing.pdf',
          fileType: 'PDF',
          resourceType: 'NOTES',
          downloadCount: 135,
          viewCount: 390,
        },
        {
          unit: 'Unit 2',
          topic: 'Network Layer & IP Routing',
          title: 'Unit 2 Notes: IPv4/IPv6 Addressing, Subnetting & OSPF Dijkstra.pdf',
          description: 'CIDR calculations, NAT traversal, link-state vs distance vector routing, and autonomous systems BGP peering.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs501/unit2_ip_routing_ospf.pdf',
          fileType: 'PDF',
          resourceType: 'NOTES',
          downloadCount: 180,
          viewCount: 460,
        },
        {
          unit: 'Unit 3',
          topic: 'Transport Layer & TCP Congestion Control',
          title: 'Unit 3 Handout: TCP 3-Way Handshake, Flow Control & AIMD.pdf',
          description: 'Slow start, congestion avoidance, fast retransmit, fast recovery, TCP Tahoe vs Reno, and BBR bandwidth estimation.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs501/unit3_tcp_congestion.pdf',
          fileType: 'PDF',
          resourceType: 'NOTES',
          downloadCount: 240,
          viewCount: 620,
        },
      ],
      announcements: [],
    },
    {
      code: 'IT302',
      name: 'Web Technologies & Full Stack Architecture',
      semester: 'Semester 5',
      section: 'A',
      credits: 3,
      departmentId: deptIt?.id,
      description: 'Modern full-stack web engineering: HTTP/2 & HTTP/3 protocols, asynchronous runtime in Node.js, component lifecycle, state management, REST & GraphQL APIs, and JWT security.',
      resources: [
        {
          unit: 'Unit 1',
          topic: 'HTTP Protocol Internals & DOM Tree',
          title: 'Unit 1 Handout: HTTP/1.1 vs HTTP/2 Multiplexing & Browser Render Tree.pdf',
          description: 'TCP head-of-line blocking, binary framing layer, HPACK header compression, server push, and CSSOM render tree construction.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/it302/unit1_http_protocols.pdf',
          fileType: 'PDF',
          resourceType: 'NOTES',
          downloadCount: 160,
          viewCount: 430,
        },
        {
          unit: 'Unit 2',
          topic: 'Asynchronous JavaScript & Event Loop',
          title: 'Unit 2 Slides: Node.js Libuv Event Loop, Microtasks & Macrotasks.pptx',
          description: 'Timers, pending callbacks, poll, check, close phases in Libuv, process.nextTick vs Promise.then priority.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/it302/unit2_event_loop.pptx',
          fileType: 'PPT',
          resourceType: 'PRESENTATION',
          downloadCount: 145,
          viewCount: 395,
        },
        {
          unit: 'Unit 3',
          topic: 'REST API Design & Authentication',
          title: 'Production RESTful API Architecture with Express & JWT Codebase',
          description: 'GitHub starter template featuring RBAC middleware, refresh tokens, zod validation, and rate limiting.',
          fileUrl: 'https://github.com/campushub-academic/express-ts-clean-architecture',
          fileType: 'CODE',
          resourceType: 'GITHUB',
          downloadCount: 195,
          viewCount: 540,
        },
      ],
      announcements: [],
    },
    {
      code: 'CS601',
      name: 'Operating Systems & System Programming',
      semester: 'Semester 6',
      section: 'A',
      credits: 4,
      departmentId: deptCse?.id,
      description: 'Kernel abstractions: process scheduling, synchronization primitives (mutexes, semaphores, monitors), virtual memory paging, disk I/O scheduling, and POSIX system calls.',
      resources: [
        {
          unit: 'Unit 1',
          topic: 'Process Management & Context Switching',
          title: 'Unit 1 Notes: PCB Structure, Fork-Exec Model & Context Switch Cost.pdf',
          description: 'Hardware registers save/restore, CPU cache invalidation, fork copy-on-write semantics, and zombie processes.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs601/unit1_process_management.pdf',
          fileType: 'PDF',
          resourceType: 'NOTES',
          downloadCount: 175,
          viewCount: 480,
        },
        {
          unit: 'Unit 2',
          topic: 'Process Synchronization & Classical Problems',
          title: 'Unit 2 Notes: Dining Philosophers, Readers-Writers & Semaphores.pdf',
          description: 'Peterson algorithm proof, atomic test-and-set, futex system calls, priority inversion, and priority inheritance.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs601/unit2_synchronization.pdf',
          fileType: 'PDF',
          resourceType: 'NOTES',
          downloadCount: 220,
          viewCount: 590,
        },
      ],
      announcements: [],
    },
    {
      code: 'CS701',
      name: 'Artificial Intelligence & Machine Learning',
      semester: 'Semester 7',
      section: 'A',
      credits: 4,
      departmentId: deptCse?.id,
      description: 'Supervised and unsupervised learning: gradient descent optimization, backpropagation, decision trees, support vector machines, clustering, and transformer neural networks.',
      resources: [
        {
          unit: 'Unit 1',
          topic: 'Linear Models & Gradient Descent',
          title: 'Unit 1 Notes: Linear Regression, Cost Functions & Stochastic Gradient Descent.pdf',
          description: 'Convex optimization, learning rate schedules, L1 Lasso and L2 Ridge regularization mathematical derivations.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs701/unit1_gradient_descent.pdf',
          fileType: 'PDF',
          resourceType: 'NOTES',
          downloadCount: 260,
          viewCount: 710,
        },
        {
          unit: 'Unit 2',
          topic: 'Neural Networks & Backpropagation',
          title: 'Unit 2 Handout: Chain Rule, Computation Graphs & Activation Functions.pdf',
          description: 'Detailed walkthrough of matrix gradients, vanishing/exploding gradient solutions, ReLU, GELU, and Adam optimizer math.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/cs701/unit2_backpropagation.pdf',
          fileType: 'PDF',
          resourceType: 'NOTES',
          downloadCount: 310,
          viewCount: 840,
        },
      ],
      announcements: [],
    },
    {
      code: 'IT405',
      name: 'Cybersecurity & Applied Cryptography',
      semester: 'Semester 6',
      section: 'A',
      credits: 3,
      departmentId: deptIt?.id,
      description: 'Symmetric & asymmetric encryption (AES, RSA, ECC), cryptographic hash functions, digital signatures, public key infrastructure (PKI), OWASP Top 10 vulnerabilities, and penetration testing.',
      resources: [
        {
          unit: 'Unit 1',
          topic: 'Symmetric & Asymmetric Ciphers',
          title: 'Unit 1 Notes: AES Block Cipher Modes & RSA Prime Factorization.pdf',
          description: 'ECB, CBC, GCM authenticated encryption, Euler totient theorem, modular exponentiation, and side-channel resistance.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/it405/unit1_cryptography_ciphers.pdf',
          fileType: 'PDF',
          resourceType: 'NOTES',
          downloadCount: 140,
          viewCount: 420,
        },
        {
          unit: 'Unit 2',
          topic: 'Web Security & OWASP Top 10',
          title: 'Unit 2 Handout: SQL Injection, XSS, CSRF & Security Headers.pdf',
          description: 'Defense in depth: parameterized queries, Content Security Policy (CSP), SameSite cookies, and CORS preflight checks.',
          fileUrl: 'https://ik.imagekit.io/campushub/academic/it405/unit2_owasp_security.pdf',
          fileType: 'PDF',
          resourceType: 'NOTES',
          downloadCount: 190,
          viewCount: 560,
        },
      ],
      announcements: [],
    },
  ];

  for (const sub of subjectsData) {
    // Upsert subject by college_id, code, semester, section
    const subject = await prisma.subject.upsert({
      where: {
        college_id_code_semester_section: {
          college_id: collegeId,
          code: sub.code,
          semester: sub.semester,
          section: sub.section,
        },
      },
      update: {
        name: sub.name,
        faculty_id: faculty.id,
        department_id: sub.departmentId || deptCse?.id || null,
        credits: sub.credits,
        description: sub.description,
      },
      create: {
        college_id: collegeId,
        faculty_id: faculty.id,
        department_id: sub.departmentId || deptCse?.id || null,
        code: sub.code,
        name: sub.name,
        semester: sub.semester,
        section: sub.section,
        credits: sub.credits,
        description: sub.description,
      },
    });

    console.log(`📚 Subject Configured: [${subject.code}] ${subject.name}`);

    // Create Faculty-Subject assignment
    await prisma.facultySubject.upsert({
      where: {
        faculty_id_subject_id: {
          faculty_id: faculty.id,
          subject_id: subject.id,
        },
      },
      update: { role: 'PRIMARY' },
      create: {
        faculty_id: faculty.id,
        subject_id: subject.id,
        role: 'PRIMARY',
      },
    });

    // Clean old resources and recreate rich structured resources for this subject
    await prisma.subjectResource.deleteMany({
      where: { subject_id: subject.id },
    });

    for (const r of sub.resources) {
      await prisma.subjectResource.create({
        data: {
          subject_id: subject.id,
          uploaded_by_id: faculty.id,
          title: r.title,
          description: r.description,
          file_url: r.fileUrl,
          file_type: r.fileType,
          unit: r.unit,
          topic: r.topic,
          resource_type: r.resourceType,
          visibility: 'PUBLIC',
          academic_year: '2024-2025',
          download_count: r.downloadCount,
          view_count: r.viewCount,
        },
      });
    }

    // Clean old announcements and create fresh ones
    await prisma.subjectAnnouncement.deleteMany({
      where: { subject_id: subject.id },
    });

    for (const a of sub.announcements) {
      await prisma.subjectAnnouncement.create({
        data: {
          subject_id: subject.id,
          faculty_id: faculty.id,
          title: a.title,
          content: a.content,
        },
      });
    }

    // If student exists, enroll student in key subjects (CS335, CS301, CS402)
    if (student && ['CS335', 'CS301', 'CS402'].includes(sub.code)) {
      await prisma.subjectEnrollment.upsert({
        where: {
          subject_id_student_id: {
            subject_id: subject.id,
            student_id: student.id,
          },
        },
        update: {},
        create: {
          subject_id: subject.id,
          student_id: student.id,
        },
      });
      console.log(`   🎓 Enrolled Alex Vance (student) into ${subject.code}`);
    }
  }

  console.log('🎉 Academics database seeding complete!');
}

main()
  .catch((e) => {
    console.error('❌ Error during academics seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
