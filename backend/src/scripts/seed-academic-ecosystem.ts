import { prisma } from '../config/database';

export async function seedAcademicEcosystem() {
  console.log('🌱 Starting Academic Ecosystem Master Data Seed...');

  // 1. Get College & Active Academic Year / Term
  const college = await prisma.college.findFirst({
    where: { code: 'CHIT' },
  }) || await prisma.college.findFirst();

  if (!college) {
    throw new Error('No college found in database');
  }

  const collegeId = college.id;

  let activeYear = await prisma.academicYear.findFirst({
    where: { college_id: collegeId, year_name: '2026-27' },
    include: { terms: true },
  });

  if (!activeYear) {
    activeYear = await prisma.academicYear.create({
      data: {
        college_id: collegeId,
        year_name: '2026-27',
        start_date: new Date('2026-06-01'),
        end_date: new Date('2027-05-31'),
        is_active: true,
        terms: {
          create: [
            {
              name: 'Semester 1',
              term_type: 'ODD',
              semester_number: 1,
              start_date: new Date('2026-06-01'),
              end_date: new Date('2026-12-31'),
              status: 'ACTIVE',
            },
            {
              name: 'Semester 2',
              term_type: 'EVEN',
              semester_number: 2,
              start_date: new Date('2027-01-01'),
              end_date: new Date('2027-05-31'),
              status: 'UPCOMING',
            },
          ],
        },
      },
      include: { terms: true },
    });
  }

  const activeTerm = activeYear.terms.find((t) => t.term_type === 'ODD' && t.status === 'ACTIVE') || activeYear.terms[0];

  // 2. Departments
  const cseDept = await prisma.department.findFirst({
    where: { college_id: collegeId, code: 'CSE' },
  });

  if (!cseDept) {
    throw new Error('CSE department not found');
  }

  const itDept = await prisma.department.findFirst({
    where: { college_id: collegeId, code: 'IT' },
  });

  // 3. Programs
  let cseProgram = await prisma.academicProgram.findFirst({
    where: { college_id: collegeId, department_id: cseDept.id },
  });

  if (!cseProgram) {
    cseProgram = await prisma.academicProgram.create({
      data: {
        college_id: collegeId,
        department_id: cseDept.id,
        name: 'B.Tech in Computer Science and Engineering',
        code: 'BTECH_CSE',
        degree_type: 'UNDERGRADUATE',
        total_semesters: 8,
        is_active: true,
      },
    });
  }

  let itProgram: any = null;
  if (itDept) {
    itProgram = await prisma.academicProgram.findFirst({
      where: { college_id: collegeId, department_id: itDept.id },
    });
    if (!itProgram) {
      itProgram = await prisma.academicProgram.create({
        data: {
          college_id: collegeId,
          department_id: itDept.id,
          name: 'B.Tech in Information Technology',
          code: 'BTECH_IT',
          degree_type: 'UNDERGRADUATE',
          total_semesters: 8,
          is_active: true,
        },
      });
    }
  }

  // 4. Rooms
  const roomAD23 = await prisma.room.upsert({
    where: {
      college_id_code: {
        college_id: collegeId,
        code: 'AD23',
      },
    },
    update: {
      name: 'Lecture Hall AD23',
      building: 'Academic Block A',
      floor: 2,
      capacity: 65,
      room_type: 'LECTURE_HALL',
      is_active: true,
    },
    create: {
      college_id: collegeId,
      code: 'AD23',
      name: 'Lecture Hall AD23',
      building: 'Academic Block A',
      floor: 2,
      capacity: 65,
      room_type: 'LECTURE_HALL',
      is_active: true,
    },
  });

  const roomCSLab1 = await prisma.room.upsert({
    where: {
      college_id_code: {
        college_id: collegeId,
        code: 'CS-LAB1',
      },
    },
    update: {
      name: 'Advanced Computing Lab 1',
      building: 'Academic Block A',
      floor: 1,
      capacity: 45,
      room_type: 'LAB',
      is_active: true,
    },
    create: {
      college_id: collegeId,
      code: 'CS-LAB1',
      name: 'Advanced Computing Lab 1',
      building: 'Academic Block A',
      floor: 1,
      capacity: 45,
      room_type: 'LAB',
      is_active: true,
    },
  });

  const roomSeminar1 = await prisma.room.upsert({
    where: {
      college_id_code: {
        college_id: collegeId,
        code: 'SEMINAR-1',
      },
    },
    update: {
      name: 'Department Seminar Hall',
      building: 'Academic Block A',
      floor: 3,
      capacity: 120,
      room_type: 'SEMINAR_HALL',
      is_active: true,
    },
    create: {
      college_id: collegeId,
      code: 'SEMINAR-1',
      name: 'Department Seminar Hall',
      building: 'Academic Block A',
      floor: 3,
      capacity: 120,
      room_type: 'SEMINAR_HALL',
      is_active: true,
    },
  });

  // 5. Faculty & Student Users
  const facultyTaylor = await prisma.user.findFirst({
    where: { email: 'faculty@campushub.edu' },
  });

  if (!facultyTaylor) {
    throw new Error('Faculty Dr. Robert Taylor not found');
  }

  const studentAlex = await prisma.user.findFirst({
    where: { email: 'student@campushub.edu' },
  });

  if (!studentAlex) {
    throw new Error('Student Alex Vance not found');
  }

  // 6. Academic Classes (Sections for Sem 1, 2, 3, 4, 5, 6, 7, 8)
  const classIVCSEA = await prisma.academicClass.upsert({
    where: {
      college_id_department_id_year_of_study_semester_section: {
        college_id: collegeId,
        department_id: cseDept.id,
        year_of_study: 4,
        semester: 7,
        section: 'A',
      },
    },
    update: {
      name: 'IV CSE - A',
      program_id: cseProgram.id,
      class_advisor_id: facultyTaylor.id,
      room_id: roomAD23.id,
    },
    create: {
      college_id: collegeId,
      department_id: cseDept.id,
      program_id: cseProgram.id,
      name: 'IV CSE - A',
      year_of_study: 4,
      semester: 7,
      section: 'A',
      class_advisor_id: facultyTaylor.id,
      room_id: roomAD23.id,
    },
  });

  await prisma.academicClass.upsert({
    where: {
      college_id_department_id_year_of_study_semester_section: {
        college_id: collegeId,
        department_id: cseDept.id,
        year_of_study: 4,
        semester: 7,
        section: 'B',
      },
    },
    update: {
      name: 'IV CSE - B',
      program_id: cseProgram.id,
      room_id: roomAD23.id,
    },
    create: {
      college_id: collegeId,
      department_id: cseDept.id,
      program_id: cseProgram.id,
      name: 'IV CSE - B',
      year_of_study: 4,
      semester: 7,
      section: 'B',
      room_id: roomAD23.id,
    },
  });

  // Sem 5 (Year 3)
  await prisma.academicClass.upsert({
    where: {
      college_id_department_id_year_of_study_semester_section: {
        college_id: collegeId,
        department_id: cseDept.id,
        year_of_study: 3,
        semester: 5,
        section: 'A',
      },
    },
    update: { name: 'III CSE - A', program_id: cseProgram.id },
    create: {
      college_id: collegeId,
      department_id: cseDept.id,
      program_id: cseProgram.id,
      name: 'III CSE - A',
      year_of_study: 3,
      semester: 5,
      section: 'A',
    },
  });

  // Sem 3 (Year 2)
  await prisma.academicClass.upsert({
    where: {
      college_id_department_id_year_of_study_semester_section: {
        college_id: collegeId,
        department_id: cseDept.id,
        year_of_study: 2,
        semester: 3,
        section: 'A',
      },
    },
    update: { name: 'II CSE - A', program_id: cseProgram.id },
    create: {
      college_id: collegeId,
      department_id: cseDept.id,
      program_id: cseProgram.id,
      name: 'II CSE - A',
      year_of_study: 2,
      semester: 3,
      section: 'A',
    },
  });

  // Sem 1 (Year 1 - Sections A & B)
  await prisma.academicClass.upsert({
    where: {
      college_id_department_id_year_of_study_semester_section: {
        college_id: collegeId,
        department_id: cseDept.id,
        year_of_study: 1,
        semester: 1,
        section: 'A',
      },
    },
    update: { name: 'I CSE - A', program_id: cseProgram.id },
    create: {
      college_id: collegeId,
      department_id: cseDept.id,
      program_id: cseProgram.id,
      name: 'I CSE - A',
      year_of_study: 1,
      semester: 1,
      section: 'A',
    },
  });

  await prisma.academicClass.upsert({
    where: {
      college_id_department_id_year_of_study_semester_section: {
        college_id: collegeId,
        department_id: cseDept.id,
        year_of_study: 1,
        semester: 1,
        section: 'B',
      },
    },
    update: { name: 'I CSE - B', program_id: cseProgram.id },
    create: {
      college_id: collegeId,
      department_id: cseDept.id,
      program_id: cseProgram.id,
      name: 'I CSE - B',
      year_of_study: 1,
      semester: 1,
      section: 'B',
    },
  });

  // 7. Authentic Subjects for Semester 7 (IV Year)
  const sem7SubjectsData = [
    {
      code: 'CS3381',
      name: 'DATA SCIENCE',
      semester: 'Semester 7',
      section: 'A',
      credits: 4,
      hours_per_week: 4,
      subject_type: 'CORE',
      description: 'Foundations of Data Science, Machine Learning pipelines, statistical modeling, and Big Data analytics.',
    },
    {
      code: 'CS335',
      name: 'CLOUD COMPUTING',
      semester: 'Semester 7',
      section: 'A',
      credits: 3,
      hours_per_week: 3,
      subject_type: 'CORE',
      description: 'Distributed cloud architectures, virtualization, containerization with Docker & Kubernetes, and serverless compute.',
    },
    {
      code: 'CS341',
      name: 'DATA WAREHOUSING & MINING',
      semester: 'Semester 7',
      section: 'A',
      credits: 3,
      hours_per_week: 3,
      subject_type: 'CORE',
      description: 'Multidimensional data modeling, OLAP cubes, association rule mining, clustering algorithms, and business intelligence.',
    },
    {
      code: 'CS356',
      name: 'OBJECT ORIENTED SOFTWARE ENGINEERING',
      semester: 'Semester 7',
      section: 'A',
      credits: 3,
      hours_per_week: 3,
      subject_type: 'CORE',
      description: 'Agile methodologies, UML design patterns, architectural software engineering, and automated testing frameworks.',
    },
    {
      code: 'PRW',
      name: 'PROJECT REPORT WRITING',
      semester: 'Semester 7',
      section: 'A',
      credits: 2,
      hours_per_week: 2,
      subject_type: 'PROJECT',
      description: 'Capstone project formulation, technical documentation, literature survey, and research publication writing.',
    },
    {
      code: 'PT101',
      name: 'PLACEMENT TRAINING',
      semester: 'Semester 7',
      section: 'A',
      credits: 1,
      hours_per_week: 2,
      subject_type: 'PRACTICAL',
      description: 'Advanced algorithms, Data Structure coding rounds, System Design interviews, and mock technical evaluations.',
    },
  ];

  const createdSubjects: Record<string, any> = {};

  for (const sData of sem7SubjectsData) {
    const sub = await prisma.subject.upsert({
      where: {
        college_id_code_semester_section: {
          college_id: collegeId,
          code: sData.code,
          semester: sData.semester,
          section: sData.section,
        },
      },
      update: {
        name: sData.name,
        faculty_id: facultyTaylor.id,
        department_id: cseDept.id,
        credits: sData.credits,
        hours_per_week: sData.hours_per_week,
        subject_type: sData.subject_type,
        description: sData.description,
        academic_year: activeYear.year_name,
        academic_term_id: activeTerm.id,
      },
      create: {
        college_id: collegeId,
        department_id: cseDept.id,
        faculty_id: facultyTaylor.id,
        code: sData.code,
        name: sData.name,
        semester: sData.semester,
        section: sData.section,
        credits: sData.credits,
        hours_per_week: sData.hours_per_week,
        subject_type: sData.subject_type,
        description: sData.description,
        academic_year: activeYear.year_name,
        academic_term_id: activeTerm.id,
      },
    });

    createdSubjects[sData.code] = sub;

    // Faculty Subject Assignment
    await prisma.facultySubjectAssignment.upsert({
      where: {
        faculty_id_subject_id_academic_term_id_section: {
          faculty_id: facultyTaylor.id,
          subject_id: sub.id,
          academic_term_id: activeTerm.id,
          section: 'A',
        },
      },
      update: { role: 'PRIMARY_INSTRUCTOR', is_primary: true },
      create: {
        faculty_id: facultyTaylor.id,
        subject_id: sub.id,
        academic_term_id: activeTerm.id,
        section: 'A',
        role: 'PRIMARY_INSTRUCTOR',
        is_primary: true,
      },
    });

    // Student Enrollment for Alex Vance
    await prisma.subjectEnrollment.upsert({
      where: {
        subject_id_student_id: {
          subject_id: sub.id,
          student_id: studentAlex.id,
        },
      },
      update: {
        academic_term_id: activeTerm.id,
        section: 'A',
        status: 'ACTIVE',
      },
      create: {
        subject_id: sub.id,
        student_id: studentAlex.id,
        academic_term_id: activeTerm.id,
        section: 'A',
        status: 'ACTIVE',
      },
    });
  }

  // 8. Timetable Schedule (FacultySchedule) for Monday to Friday
  // Clean existing schedules for this class/faculty to prevent duplicate slots
  await prisma.facultySchedule.deleteMany({
    where: {
      faculty_id: facultyTaylor.id,
      academic_term_id: activeTerm.id,
      section: 'A',
    },
  });

  const timetableEntries = [
    // MONDAY
    { day: 'MONDAY', start: '08:45 AM', end: '09:35 AM', code: 'CS3381', type: 'THEORY', topic: 'Statistical Learning & Inference', room: roomAD23.id, venue: 'AD23' },
    { day: 'MONDAY', start: '09:35 AM', end: '10:25 AM', code: 'CS335',  type: 'THEORY', topic: 'Virtualization & Hypervisors', room: roomAD23.id, venue: 'AD23' },
    { day: 'MONDAY', start: '10:40 AM', end: '11:30 AM', code: 'CS341',  type: 'THEORY', topic: 'Star & Snowflake Schemas', room: roomAD23.id, venue: 'AD23' },
    { day: 'MONDAY', start: '11:30 AM', end: '12:20 PM', code: 'CS356',  type: 'THEORY', topic: 'SOLID Design Principles', room: roomAD23.id, venue: 'AD23' },
    { day: 'MONDAY', start: '01:10 PM', end: '02:50 PM', code: 'CS3381', type: 'LAB',    topic: 'Pandas & Scikit-Learn Pipeline Lab', room: roomCSLab1.id, venue: 'CS-LAB1' },
    { day: 'MONDAY', start: '03:00 PM', end: '04:30 PM', code: 'PT101',  type: 'THEORY', topic: 'Dynamic Programming & LeetCode Hard', room: roomSeminar1.id, venue: 'SEMINAR-1' },

    // TUESDAY
    { day: 'TUESDAY', start: '08:45 AM', end: '09:35 AM', code: 'CS335',  type: 'THEORY', topic: 'AWS IAM & VPC Architectures', room: roomAD23.id, venue: 'AD23' },
    { day: 'TUESDAY', start: '09:35 AM', end: '10:25 AM', code: 'CS3381', type: 'THEORY', topic: 'Supervised Regression Models', room: roomAD23.id, venue: 'AD23' },
    { day: 'TUESDAY', start: '10:40 AM', end: '11:30 AM', code: 'CS356',  type: 'THEORY', topic: 'Behavioral UML & Sequence Diagrams', room: roomAD23.id, venue: 'AD23' },
    { day: 'TUESDAY', start: '11:30 AM', end: '12:20 PM', code: 'CS341',  type: 'THEORY', topic: 'ETL Pipelines & Apache Airflow', room: roomAD23.id, venue: 'AD23' },
    { day: 'TUESDAY', start: '01:10 PM', end: '02:50 PM', code: 'PRW',    type: 'PRACTICAL', topic: 'IEEE Format Literature Review', room: roomAD23.id, venue: 'AD23' },
    { day: 'TUESDAY', start: '03:00 PM', end: '03:45 PM', code: 'CS3381', type: 'THEORY', topic: 'Tutorial / Problem Solving Hour', room: roomAD23.id, venue: 'AD23' },

    // WEDNESDAY
    { day: 'WEDNESDAY', start: '08:45 AM', end: '09:35 AM', code: 'CS341',  type: 'THEORY', topic: 'Data Cleansing & Normalization', room: roomAD23.id, venue: 'AD23' },
    { day: 'WEDNESDAY', start: '09:35 AM', end: '10:25 AM', code: 'CS356',  type: 'THEORY', topic: 'Creational Design Patterns', room: roomAD23.id, venue: 'AD23' },
    { day: 'WEDNESDAY', start: '10:40 AM', end: '11:30 AM', code: 'CS3381', type: 'THEORY', topic: 'Classification & Decision Trees', room: roomAD23.id, venue: 'AD23' },
    { day: 'WEDNESDAY', start: '11:30 AM', end: '12:20 PM', code: 'CS335',  type: 'THEORY', topic: 'Microservices & Containerization', room: roomAD23.id, venue: 'AD23' },
    { day: 'WEDNESDAY', start: '01:10 PM', end: '02:00 PM', code: 'PT101',  type: 'THEORY', topic: 'System Design: Distributed Cache', room: roomSeminar1.id, venue: 'SEMINAR-1' },
    { day: 'WEDNESDAY', start: '02:00 PM', end: '03:45 PM', code: 'CS335',  type: 'LAB',    topic: 'Docker Compose & Kubernetes Deployment', room: roomCSLab1.id, venue: 'CS-LAB1' },

    // THURSDAY
    { day: 'THURSDAY', start: '08:45 AM', end: '09:35 AM', code: 'CS356',  type: 'THEORY', topic: 'Structural Design Patterns', room: roomAD23.id, venue: 'AD23' },
    { day: 'THURSDAY', start: '09:35 AM', end: '10:25 AM', code: 'CS341',  type: 'THEORY', topic: 'Association Rule Mining & Apriori', room: roomAD23.id, venue: 'AD23' },
    { day: 'THURSDAY', start: '10:40 AM', end: '11:30 AM', code: 'CS335',  type: 'THEORY', topic: 'Serverless Cloud Architectures', room: roomAD23.id, venue: 'AD23' },
    { day: 'THURSDAY', start: '11:30 AM', end: '12:20 PM', code: 'CS3381', type: 'THEORY', topic: 'Clustering: K-Means & Hierarchical', room: roomAD23.id, venue: 'AD23' },
    { day: 'THURSDAY', start: '01:10 PM', end: '02:50 PM', code: 'PRW',    type: 'PRACTICAL', topic: 'Methodology Drafting & Review', room: roomAD23.id, venue: 'AD23' },

    // FRIDAY
    { day: 'FRIDAY', start: '08:45 AM', end: '09:35 AM', code: 'CS3381', type: 'THEORY', topic: 'Ensemble Learning & Random Forests', room: roomAD23.id, venue: 'AD23' },
    { day: 'FRIDAY', start: '09:35 AM', end: '10:25 AM', code: 'CS335',  type: 'THEORY', topic: 'Cloud Security & Compliance', room: roomAD23.id, venue: 'AD23' },
    { day: 'FRIDAY', start: '10:40 AM', end: '11:30 AM', code: 'CS341',  type: 'THEORY', topic: 'OLAP vs OLTP Performance Optimization', room: roomAD23.id, venue: 'AD23' },
    { day: 'FRIDAY', start: '11:30 AM', end: '12:20 PM', code: 'CS356',  type: 'THEORY', topic: 'CI/CD Pipelines & DevSecOps', room: roomAD23.id, venue: 'AD23' },
    { day: 'FRIDAY', start: '01:10 PM', end: '02:00 PM', code: 'PT101',  type: 'THEORY', topic: 'HR & Technical Mock Assessment', room: roomSeminar1.id, venue: 'SEMINAR-1' },
    { day: 'FRIDAY', start: '02:00 PM', end: '03:45 PM', code: 'CS3381', type: 'THEORY', topic: 'Class Advisor Interaction / Mentoring', room: roomAD23.id, venue: 'AD23' },
  ];

  for (const slot of timetableEntries) {
    const sub = createdSubjects[slot.code];
    await prisma.facultySchedule.create({
      data: {
        faculty_id: facultyTaylor.id,
        subject_id: sub?.id,
        academic_term_id: activeTerm.id,
        class_id: classIVCSEA.id,
        room_id: slot.room,
        subject_code: slot.code,
        subject_name: sub?.name || slot.code,
        room_or_venue: slot.venue,
        start_time: slot.start,
        end_time: slot.end,
        semester: 'Semester 7',
        section: 'A',
        day_of_week: slot.day,
        topic: slot.topic,
        session_type: slot.type,
        status: 'SCHEDULED',
      },
    });
  }

  // 9. Academic Resources for CS3381 and CS335
  const dsSub = createdSubjects['CS3381'];
  if (dsSub) {
    const resCount = await prisma.subjectResource.count({ where: { subject_id: dsSub.id } });
    if (resCount === 0) {
      await prisma.subjectResource.createMany({
        data: [
          {
            subject_id: dsSub.id,
            uploaded_by_id: facultyTaylor.id,
            academic_term_id: activeTerm.id,
            academic_year: activeYear.year_name,
            title: 'Unit 1: Foundations of Data Science & Python Ecosystem',
            description: 'Comprehensive lecture slides and Jupyter notebook demonstrations on NumPy, Pandas, and Exploratory Data Analysis.',
            file_url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
            file_type: 'application/pdf',
            unit: 'Unit 1',
            topic: 'Exploratory Data Analysis',
            resource_type: 'NOTES',
            visibility: 'PUBLIC',
          },
          {
            subject_id: dsSub.id,
            uploaded_by_id: facultyTaylor.id,
            academic_term_id: activeTerm.id,
            academic_year: activeYear.year_name,
            title: 'Unit 2: Statistical Modeling & Supervised ML Classifiers',
            description: 'Mathematics behind Linear Regression, Logistic Regression, Decision Trees, and Evaluation Metrics (ROC-AUC, Precision, Recall).',
            file_url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
            file_type: 'application/pdf',
            unit: 'Unit 2',
            topic: 'Machine Learning Classifiers',
            resource_type: 'NOTES',
            visibility: 'PUBLIC',
          },
          {
            subject_id: dsSub.id,
            uploaded_by_id: facultyTaylor.id,
            academic_term_id: activeTerm.id,
            academic_year: activeYear.year_name,
            title: 'CS3381 Official Curriculum & Lab Manual (2026-27)',
            description: 'Official Anna University / Autonomous Syllabus breakdown and mandatory practical laboratory assignments.',
            file_url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
            file_type: 'application/pdf',
            unit: 'Syllabus',
            topic: 'Curriculum & Lab Manual',
            resource_type: 'SYLLABUS',
            visibility: 'PUBLIC',
          },
        ],
      });
    }
  }

  // 10. Assignments
  if (dsSub) {
    const asgCount = await prisma.subjectAssignment.count({ where: { subject_id: dsSub.id } });
    if (asgCount === 0) {
      const asg1 = await prisma.subjectAssignment.create({
        data: {
          subject_id: dsSub.id,
          faculty_id: facultyTaylor.id,
          academic_term_id: activeTerm.id,
          section: 'A',
          title: 'Assignment 1: Exploratory Data Analysis on Housing Dataset',
          description: 'Perform statistical cleaning, missing value imputation, and feature engineering using Seaborn and Pandas. Submit your documented Jupyter Notebook (.ipynb).',
          unit: 'Unit 1',
          topic: 'Feature Engineering & EDA',
          max_marks: 25,
          due_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
          submission_type: 'FILE',
        },
      });

      // Submit for Alex Vance
      await prisma.assignmentSubmission.create({
        data: {
          assignment_id: asg1.id,
          student_id: studentAlex.id,
          submission_type: 'LINK',
          link_url: 'https://github.com/alexvance/ds-assignment-1',
          status: 'EVALUATED',
          marks: 23.5,
          feedback: 'Outstanding data visualization and clear reasoning on outlier removal.',
          submitted_at: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
          graded_at: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
          graded_by_id: facultyTaylor.id,
        },
      });

      await prisma.subjectAssignment.create({
        data: {
          subject_id: dsSub.id,
          faculty_id: facultyTaylor.id,
          academic_term_id: activeTerm.id,
          section: 'A',
          title: 'Assignment 2: Supervised Classification with XGBoost & Hyperparameter Tuning',
          description: 'Implement a cross-validated XGBoost model on the credit scoring dataset. Compare F1-score against baseline Decision Tree.',
          unit: 'Unit 2',
          topic: 'Gradient Boosting Classifiers',
          max_marks: 30,
          due_at: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
          submission_type: 'FILE',
        },
      });
    }
  }

  // 11. Assessments
  if (dsSub) {
    const assessCount = await prisma.subjectAssessment.count({ where: { subject_id: dsSub.id } });
    if (assessCount === 0) {
      const assessment1 = await prisma.subjectAssessment.create({
        data: {
          subject_id: dsSub.id,
          faculty_id: facultyTaylor.id,
          academic_term_id: activeTerm.id,
          section: 'A',
          title: 'Continuous Assessment Test 1 (CAT-1)',
          assessment_type: 'INTERNAL_EXAM',
          total_marks: 50,
          passing_marks: 20,
          scheduled_at: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000),
          status: 'COMPLETED',
        },
      });

      await prisma.studentAssessmentResult.create({
        data: {
          assessment_id: assessment1.id,
          subject_id: dsSub.id,
          student_id: studentAlex.id,
          marks_obtained: 46.5,
          grade: 'O',
          remarks: 'Top score in section. Exceptional mastery of probability theory and feature scaling.',
          status: 'EVALUATED',
          evaluated_by_id: facultyTaylor.id,
        },
      });

      await prisma.subjectAssessment.create({
        data: {
          subject_id: dsSub.id,
          faculty_id: facultyTaylor.id,
          academic_term_id: activeTerm.id,
          section: 'A',
          title: 'Continuous Assessment Test 2 (CAT-2)',
          assessment_type: 'INTERNAL_EXAM',
          total_marks: 50,
          passing_marks: 20,
          scheduled_at: new Date(Date.now() + 20 * 24 * 60 * 60 * 1000),
          status: 'SCHEDULED',
        },
      });
    }
  }

  // 12. Attendance Sessions & Records
  if (dsSub) {
    const sessionCount = await prisma.subjectAttendanceSession.count({ where: { subject_id: dsSub.id } });
    if (sessionCount === 0) {
      // Create 5 completed sessions with Alex Vance PRESENT
      const dates = [
        new Date(Date.now() - 14 * 24 * 60 * 60 * 1000),
        new Date(Date.now() - 11 * 24 * 60 * 60 * 1000),
        new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
        new Date(Date.now() - 4 * 24 * 60 * 60 * 1000),
        new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
      ];

      for (let i = 0; i < dates.length; i++) {
        const d = dates[i];
        const session = await prisma.subjectAttendanceSession.create({
          data: {
            subject_id: dsSub.id,
            faculty_id: facultyTaylor.id,
            academic_term_id: activeTerm.id,
            section: 'A',
            session_date: d,
            start_time: '08:45 AM',
            end_time: '09:35 AM',
            topic: `Unit 1 Session ${i + 1}: Data Science Principles`,
            status: 'LOCKED',
            total_students: 1,
            present_count: 1,
          },
        });

        await prisma.studentAttendanceRecord.create({
          data: {
            session_id: session.id,
            subject_id: dsSub.id,
            student_id: studentAlex.id,
            status: 'PRESENT',
            marked_by_id: facultyTaylor.id,
          },
        });
      }
    }
  }

  // 13. Subject Announcements
  if (dsSub) {
    const annCount = await prisma.subjectAnnouncement.count({ where: { subject_id: dsSub.id } });
    if (annCount === 0) {
      await prisma.subjectAnnouncement.create({
        data: {
          subject_id: dsSub.id,
          faculty_id: facultyTaylor.id,
          title: 'Welcome to CS3381 Data Science (Odd Semester 2026-27)',
          content: 'Dear IV CSE Section A students, classes begin in Room AD23 starting this week. Please review the syllabus in the Resources tab and prepare your Python 3.11 environment.',
        },
      });
    }
  }

  // 14. CS335 Cloud Computing Resources, Assignments, Assessments & Attendance
  const cloudSub = createdSubjects['CS335'];
  if (cloudSub) {
    const ccResCount = await prisma.subjectResource.count({ where: { subject_id: cloudSub.id } });
    if (ccResCount === 0) {
      await prisma.subjectResource.createMany({
        data: [
          {
            subject_id: cloudSub.id,
            uploaded_by_id: facultyTaylor.id,
            academic_term_id: activeTerm.id,
            academic_year: activeYear.year_name,
            title: 'Unit 1: Cloud Architecture, Virtualization & Hypervisors',
            description: 'Core concepts of Type-1 and Type-2 Hypervisors, KVM, Xen, and AWS EC2 Virtualization.',
            file_url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
            file_type: 'application/pdf',
            unit: 'Unit 1',
            topic: 'Cloud Architectures',
            resource_type: 'NOTES',
            visibility: 'PUBLIC',
          },
          {
            subject_id: cloudSub.id,
            uploaded_by_id: facultyTaylor.id,
            academic_term_id: activeTerm.id,
            academic_year: activeYear.year_name,
            title: 'Unit 2: Containerization with Docker & Kubernetes',
            description: 'Building OCI container images, Docker compose multi-service orchestration, Pod lifecycle and Services.',
            file_url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
            file_type: 'application/pdf',
            unit: 'Unit 2',
            topic: 'Kubernetes & Containers',
            resource_type: 'NOTES',
            visibility: 'PUBLIC',
          },
        ],
      });
    }

    const ccAsgCount = await prisma.subjectAssignment.count({ where: { subject_id: cloudSub.id } });
    if (ccAsgCount === 0) {
      const ccAsg1 = await prisma.subjectAssignment.create({
        data: {
          subject_id: cloudSub.id,
          faculty_id: facultyTaylor.id,
          academic_term_id: activeTerm.id,
          section: 'A',
          title: 'Assignment 1: Deploying Multi-Tier Web App on Kubernetes',
          description: 'Deploy a NodeJS REST API with Redis cache and Postgres DB onto local Minikube cluster using Helm charts.',
          unit: 'Unit 2',
          topic: 'Helm & Kubernetes Orchestration',
          max_marks: 25,
          due_at: new Date(Date.now() + 10 * 24 * 60 * 60 * 1000),
          submission_type: 'LINK',
        },
      });

      await prisma.assignmentSubmission.create({
        data: {
          assignment_id: ccAsg1.id,
          student_id: studentAlex.id,
          submission_type: 'LINK',
          link_url: 'https://github.com/alexvance/cloud-helm-deploy',
          status: 'EVALUATED',
          marks: 24.0,
          feedback: 'Clean Helm charts, proper secret handling and resource limits.',
          submitted_at: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
          graded_at: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
          graded_by_id: facultyTaylor.id,
        },
      });
    }

    const ccAssessCount = await prisma.subjectAssessment.count({ where: { subject_id: cloudSub.id } });
    if (ccAssessCount === 0) {
      const ccAssess1 = await prisma.subjectAssessment.create({
        data: {
          subject_id: cloudSub.id,
          faculty_id: facultyTaylor.id,
          academic_term_id: activeTerm.id,
          section: 'A',
          title: 'Continuous Assessment Test 1 (CAT-1)',
          assessment_type: 'INTERNAL_EXAM',
          total_marks: 50,
          passing_marks: 20,
          scheduled_at: new Date(Date.now() - 8 * 24 * 60 * 60 * 1000),
          status: 'COMPLETED',
        },
      });

      await prisma.studentAssessmentResult.create({
        data: {
          assessment_id: ccAssess1.id,
          subject_id: cloudSub.id,
          student_id: studentAlex.id,
          marks_obtained: 47.0,
          grade: 'O',
          remarks: 'Excellent architecture diagrams and clear AWS VPC security explanations.',
          status: 'EVALUATED',
          evaluated_by_id: facultyTaylor.id,
        },
      });
    }

    const ccSessCount = await prisma.subjectAttendanceSession.count({ where: { subject_id: cloudSub.id } });
    if (ccSessCount === 0) {
      for (let i = 1; i <= 4; i++) {
        const d = new Date(Date.now() - (i * 3) * 24 * 60 * 60 * 1000);
        const session = await prisma.subjectAttendanceSession.create({
          data: {
            subject_id: cloudSub.id,
            faculty_id: facultyTaylor.id,
            academic_term_id: activeTerm.id,
            section: 'A',
            session_date: d,
            start_time: '09:35 AM',
            end_time: '10:25 AM',
            topic: `Cloud Architecture Session ${i}`,
            status: 'LOCKED',
            total_students: 1,
            present_count: 1,
          },
        });

        await prisma.studentAttendanceRecord.create({
          data: {
            session_id: session.id,
            subject_id: cloudSub.id,
            student_id: studentAlex.id,
            status: 'PRESENT',
            marked_by_id: facultyTaylor.id,
          },
        });
      }
    }
  }

  // 15. CS341 Data Warehousing Resources & Attendance
  const dwSub = createdSubjects['CS341'];
  if (dwSub) {
    const dwResCount = await prisma.subjectResource.count({ where: { subject_id: dwSub.id } });
    if (dwResCount === 0) {
      await prisma.subjectResource.create({
        data: {
          subject_id: dwSub.id,
          uploaded_by_id: facultyTaylor.id,
          academic_term_id: activeTerm.id,
          academic_year: activeYear.year_name,
          title: 'Unit 1: Data Warehousing Fundamentals & OLAP Schemas',
          description: 'Dimensions, Fact tables, Star Schema vs Snowflake Schema, and ETL architecture.',
          file_url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          file_type: 'application/pdf',
          unit: 'Unit 1',
          topic: 'Data Warehouse Architecture',
          resource_type: 'NOTES',
          visibility: 'PUBLIC',
        },
      });
    }

    const dwSessCount = await prisma.subjectAttendanceSession.count({ where: { subject_id: dwSub.id } });
    if (dwSessCount === 0) {
      for (let i = 1; i <= 4; i++) {
        const d = new Date(Date.now() - (i * 3) * 24 * 60 * 60 * 1000);
        const session = await prisma.subjectAttendanceSession.create({
          data: {
            subject_id: dwSub.id,
            faculty_id: facultyTaylor.id,
            academic_term_id: activeTerm.id,
            section: 'A',
            session_date: d,
            start_time: '10:40 AM',
            end_time: '11:30 AM',
            topic: `Data Warehousing Session ${i}`,
            status: 'LOCKED',
            total_students: 1,
            present_count: 1,
          },
        });

        await prisma.studentAttendanceRecord.create({
          data: {
            session_id: session.id,
            subject_id: dwSub.id,
            student_id: studentAlex.id,
            status: 'PRESENT',
            marked_by_id: facultyTaylor.id,
          },
        });
      }
    }
  }

  console.log('✅ Academic Ecosystem Master Data Seeded Successfully!');
}

if (require.main === module) {
  seedAcademicEcosystem()
    .catch((err) => {
      console.error('❌ Seed error:', err);
      process.exit(1);
    })
    .finally(() => prisma.$disconnect());
}
