import { PrismaClient, Role, UserStatus, DriveStatus } from '@prisma/client';
import argon2 from 'argon2';

const prisma = new PrismaClient();

export async function seedDeptAdminEnvironment() {
  console.log('🏛️ Initializing Canonical GCEE Departments & IT DEPT_ADMIN environment...');

  const college = await prisma.college.findFirst();
  if (!college) {
    throw new Error('College not found');
  }
  const collegeId = college.id;

  // 1. CANONICAL 8 DEPARTMENTS
  const canonicalDepts = [
    { code: 'IT', name: 'Information Technology' },
    { code: 'CSE', name: 'Computer Science and Engineering' },
    { code: 'CSE (DS)', name: 'Computer Science and Engineering (Data Science)', legacyCode: 'CDS' },
    { code: 'MECH', name: 'Mechanical Engineering' },
    { code: 'EEE', name: 'Electrical and Electronics Engineering' },
    { code: 'ECE', name: 'Electronics and Communication Engineering' },
    { code: 'AUTOMOBILE', name: 'Automobile Engineering', legacyCode: 'AUTO' },
    { code: 'CIVIL', name: 'Civil Engineering' },
  ];

  const deptMap: Record<string, string> = {};

  for (const cd of canonicalDepts) {
    let dept = await prisma.department.findFirst({
      where: {
        college_id: collegeId,
        OR: [
          { code: cd.code },
          ...(cd.legacyCode ? [{ code: cd.legacyCode }] : []),
        ],
      },
    });

    if (dept) {
      dept = await prisma.department.update({
        where: { id: dept.id },
        data: { name: cd.name, code: cd.code, is_active: true },
      });
    } else {
      dept = await prisma.department.create({
        data: {
          college_id: collegeId,
          name: cd.name,
          code: cd.code,
          is_active: true,
        },
      });
    }
    deptMap[cd.code] = dept.id;
  }
  console.log('✅ Standardized 8 Canonical Departments.');

  // 2. DEGREE PROGRAMS (IT is B.Tech, all 7 others are B.E.)
  const programsData = [
    { deptCode: 'IT', name: 'B.Tech in Information Technology', code: 'BTECH_IT', degree: 'UNDERGRADUATE' },
    { deptCode: 'CSE', name: 'B.E. in Computer Science and Engineering', code: 'BE_CSE', degree: 'UNDERGRADUATE' },
    { deptCode: 'CSE (DS)', name: 'B.E. in Computer Science and Engineering (Data Science)', code: 'BE_CSE_DS', degree: 'UNDERGRADUATE' },
    { deptCode: 'ECE', name: 'B.E. in Electronics and Communication Engineering', code: 'BE_ECE', degree: 'UNDERGRADUATE' },
    { deptCode: 'EEE', name: 'B.E. in Electrical and Electronics Engineering', code: 'BE_EEE', degree: 'UNDERGRADUATE' },
    { deptCode: 'MECH', name: 'B.E. in Mechanical Engineering', code: 'BE_MECH', degree: 'UNDERGRADUATE' },
    { deptCode: 'CIVIL', name: 'B.E. in Civil Engineering', code: 'BE_CIVIL', degree: 'UNDERGRADUATE' },
    { deptCode: 'AUTOMOBILE', name: 'B.E. in Automobile Engineering', code: 'BE_AUTO', degree: 'UNDERGRADUATE' },
  ];

  const programMap: Record<string, string> = {};

  for (const prog of programsData) {
    const deptId = deptMap[prog.deptCode];
    if (!deptId) continue;

    let p = await prisma.academicProgram.findFirst({
      where: {
        college_id: collegeId,
        department_id: deptId,
      },
    });

    if (p) {
      p = await prisma.academicProgram.update({
        where: { id: p.id },
        data: { name: prog.name, code: prog.code, degree_type: prog.degree, is_active: true },
      });
    } else {
      p = await prisma.academicProgram.create({
        data: {
          college_id: collegeId,
          department_id: deptId,
          name: prog.name,
          code: prog.code,
          degree_type: prog.degree,
          is_active: true,
        },
      });
    }
    programMap[prog.deptCode] = p.id;
  }
  console.log('✅ Standardized Academic Programs (IT = B.Tech, others = B.E.).');

  // 3. IT DEPT_ADMIN USER
  const itDeptId = deptMap['IT'];
  const passwordHash = await argon2.hash('Password@123');

  const deptAdminEmail = 'deptadmin.it@gcee.ac.in';
  let deptAdmin = await prisma.user.findFirst({
    where: {
      OR: [
        { email: deptAdminEmail },
        { email: 'deptadmin.it@gcee.edu' },
      ],
    },
  });

  if (deptAdmin) {
    deptAdmin = await prisma.user.update({
      where: { id: deptAdmin.id },
      data: {
        email: deptAdminEmail,
        first_name: 'Dr. Naveen',
        last_name: 'Kumar',
        role: Role.DEPT_ADMIN,
        department_id: itDeptId,
        status: UserStatus.ACTIVE,
        is_profile_completed: true,
        is_password_configured: true,
      },
    });
  } else {
    deptAdmin = await prisma.user.create({
      data: {
        college_id: collegeId,
        email: deptAdminEmail,
        password_hash: passwordHash,
        first_name: 'Dr. Naveen',
        last_name: 'Kumar',
        username: 'deptadmin_it',
        role: Role.DEPT_ADMIN,
        department_id: itDeptId,
        status: UserStatus.ACTIVE,
        is_profile_completed: true,
        is_password_configured: true,
      },
    });
  }
  console.log(`✅ IT DEPT_ADMIN created/updated: ${deptAdmin.email} (Dr. Naveen Kumar).`);

  // 4. ACADEMIC YEARS & TERMS
  let activeYear = await prisma.academicYear.findFirst({
    where: { college_id: collegeId, is_active: true },
  });
  if (!activeYear) {
    activeYear = await prisma.academicYear.create({
      data: {
        college_id: collegeId,
        year_name: '2026-2027',
        start_date: new Date('2026-06-15'),
        end_date: new Date('2027-05-30'),
        is_active: true,
      },
    });
  }

  let activeTerm = await prisma.academicTerm.findFirst({
    where: { academic_year_id: activeYear.id, status: 'ACTIVE' },
  });
  if (!activeTerm) {
    activeTerm = await prisma.academicTerm.findFirst({
      where: { academic_year_id: activeYear.id },
    });
    if (activeTerm) {
      activeTerm = await prisma.academicTerm.update({
        where: { id: activeTerm.id },
        data: { status: 'ACTIVE' },
      });
    } else {
      activeTerm = await prisma.academicTerm.create({
        data: {
          academic_year_id: activeYear.id,
          name: 'Even Semester (2026-2027)',
          term_type: 'EVEN',
          semester_number: 6,
          start_date: new Date('2026-12-01'),
          end_date: new Date('2027-05-15'),
          status: 'ACTIVE',
        },
      });
    }
  }

  // 5. BATCHES FOR IT
  const itProgId = programMap['IT'];
  const batchesData = [
    { name: '2023-2027', admYear: 2023, gradYear: 2027 },
    { name: '2024-2028', admYear: 2024, gradYear: 2028 },
    { name: '2025-2029', admYear: 2025, gradYear: 2029 },
    { name: '2026-2030', admYear: 2026, gradYear: 2030 },
  ];

  const batchMap: Record<string, string> = {};
  for (const b of batchesData) {
    let batch = await prisma.batch.findFirst({
      where: {
        college_id: collegeId,
        department_id: itDeptId,
        name: b.name,
      },
    });
    if (!batch) {
      batch = await prisma.batch.create({
        data: {
          college_id: collegeId,
          department_id: itDeptId,
          program_id: itProgId,
          name: b.name,
          admission_year: b.admYear,
          graduation_year: b.gradYear,
        },
      });
    }
    batchMap[b.name] = batch.id;
  }
  console.log('✅ IT Batches initialized.');

  // 6. CLASSES / SECTIONS FOR IT
  const classesData = [
    { name: 'IT-A', section: 'A', year: 4, sem: 8 },
    { name: 'IT-B', section: 'B', year: 4, sem: 8 },
    { name: 'IT-C', section: 'C', year: 4, sem: 8 },
    { name: 'IT-3A', section: 'A', year: 3, sem: 6 },
    { name: 'IT-3B', section: 'B', year: 3, sem: 6 },
    { name: 'IT-2A', section: 'A', year: 2, sem: 4 },
  ];

  const classMap: Record<string, string> = {};
  for (const c of classesData) {
    let cl = await prisma.academicClass.findFirst({
      where: {
        college_id: collegeId,
        department_id: itDeptId,
        name: c.name,
      },
    });
    if (!cl) {
      cl = await prisma.academicClass.create({
        data: {
          college_id: collegeId,
          department_id: itDeptId,
          program_id: itProgId,
          name: c.name,
          section: c.section,
          year_of_study: c.year,
          semester: c.sem,
        },
      });
    }
    classMap[c.name] = cl.id;
  }
  console.log('✅ IT Classes / Sections initialized.');

  // 7. IT FACULTY MEMBERS
  const facultyMembers = [
    { email: 'r.kumar@gcee.ac.in', firstName: 'Dr. R.', lastName: 'Kumar', designation: 'Professor', bio: 'Specializes in Database Management and Operating Systems.' },
    { email: 's.meena@gcee.ac.in', firstName: 'Dr. S.', lastName: 'Meena', designation: 'Associate Professor', bio: 'Expert in Distributed Algorithms and Artificial Intelligence.' },
    { email: 'k.prakash@gcee.ac.in', firstName: 'Mr. K.', lastName: 'Prakash', designation: 'Assistant Professor', bio: 'Focus on Web Technologies and Computer Networks.' },
    { email: 'latha.r@gcee.ac.in', firstName: 'Ms. Latha', lastName: 'R', designation: 'Assistant Professor', bio: 'Software Engineering and Agile Project Management.' },
    { email: 'v.anand@gcee.ac.in', firstName: 'Dr. V.', lastName: 'Anand', designation: 'Professor', bio: 'Computer Networks and Network Security.' },
    { email: 'rahul.s@gcee.ac.in', firstName: 'Mr. Rahul', lastName: 'S', designation: 'Assistant Professor', bio: 'Mobile Application Development and Cloud Computing.' },
  ];

  const facultyMap: Record<string, string> = {};
  for (const f of facultyMembers) {
    let fac = await prisma.user.findUnique({ where: { email: f.email } });
    if (!fac) {
      fac = await prisma.user.create({
        data: {
          college_id: collegeId,
          department_id: itDeptId,
          email: f.email,
          password_hash: passwordHash,
          first_name: f.firstName,
          last_name: f.lastName,
          username: f.email.split('@')[0],
          role: Role.FACULTY,
          status: UserStatus.ACTIVE,
          is_profile_completed: true,
          is_password_configured: true,
        },
      });
    }
    await prisma.facultyProfile.upsert({
      where: { user_id: fac.id },
      update: { designation: f.designation, bio: f.bio },
      create: { user_id: fac.id, designation: f.designation, bio: f.bio },
    });
    facultyMap[f.email] = fac.id;
  }
  console.log('✅ IT Faculty members initialized.');

  // 8. IT SUBJECTS
  const subjectsData = [
    { code: 'CCS341', name: 'Database Management Systems', credits: 4, facultyEmail: 'r.kumar@gcee.ac.in' },
    { code: 'CCS342', name: 'Operating Systems', credits: 4, facultyEmail: 's.meena@gcee.ac.in' },
    { code: 'CCS343', name: 'Computer Networks', credits: 4, facultyEmail: 'k.prakash@gcee.ac.in' },
    { code: 'CCS356', name: 'Software Engineering', credits: 4, facultyEmail: 'latha.r@gcee.ac.in' },
    { code: 'CCS357', name: 'Web Technologies', credits: 3, facultyEmail: 'rahul.s@gcee.ac.in' },
  ];

  const subjectMap: Record<string, string> = {};
  for (const s of subjectsData) {
    let sub = await prisma.subject.findFirst({
      where: {
        college_id: collegeId,
        department_id: itDeptId,
        code: s.code,
      },
    });
    if (!sub) {
      sub = await prisma.subject.create({
        data: {
          college_id: collegeId,
          department_id: itDeptId,
          faculty_id: facultyMap[s.facultyEmail],
          code: s.code,
          name: s.name,
          credits: s.credits,
          semester: '8',
          section: 'A',
          academic_term_id: activeTerm?.id,
        },
      });
    }
    subjectMap[s.code] = sub.id;

    // Term-Faculty Assignment
    const existingAssign = await prisma.facultySubjectAssignment.findFirst({
      where: {
        subject_id: sub.id,
        faculty_id: facultyMap[s.facultyEmail],
      },
    });
    if (!existingAssign && activeTerm) {
      await prisma.facultySubjectAssignment.create({
        data: {
          subject_id: sub.id,
          faculty_id: facultyMap[s.facultyEmail],
          academic_term_id: activeTerm.id,
          section: 'A',
          role: 'PRIMARY_INSTRUCTOR',
          is_primary: true,
        },
      });
    }
  }
  console.log('✅ IT Subjects and Faculty assignments initialized.');

  // 9. ROOMS FOR TIMETABLE
  const roomsData = ['Room 301', 'Room 302', 'Room 303', 'Room 304'];
  const roomMap: Record<string, string> = {};
  for (const rName of roomsData) {
    let r = await prisma.room.findFirst({
      where: { college_id: collegeId, name: rName },
    });
    if (!r) {
      r = await prisma.room.create({
        data: {
          college_id: collegeId,
          name: rName,
          code: rName.replace(' ', ''),
          capacity: 70,
          room_type: 'LECTURE_HALL',
          building: 'IT Block',
          floor: 3,
        },
      });
    }
    roomMap[rName] = r.id;
  }

  // 10. TIMETABLE SCHEDULES (Screen 8 in mockup)
  const scheduleSlots = [
    { day: 'MONDAY', startTime: '09:00', endTime: '10:00', subCode: 'CCS341', facEmail: 'r.kumar@gcee.ac.in', room: 'Room 301' },
    { day: 'MONDAY', startTime: '10:00', endTime: '11:00', subCode: 'CCS342', facEmail: 's.meena@gcee.ac.in', room: 'Room 302' },
    { day: 'MONDAY', startTime: '11:30', endTime: '12:30', subCode: 'CCS343', facEmail: 'k.prakash@gcee.ac.in', room: 'Room 303' },
    { day: 'MONDAY', startTime: '13:30', endTime: '14:30', subCode: 'CCS356', facEmail: 'latha.r@gcee.ac.in', room: 'Room 304' },
    { day: 'TUESDAY', startTime: '09:00', endTime: '10:00', subCode: 'CCS343', facEmail: 'k.prakash@gcee.ac.in', room: 'Room 303' },
    { day: 'TUESDAY', startTime: '10:00', endTime: '11:00', subCode: 'CCS341', facEmail: 'r.kumar@gcee.ac.in', room: 'Room 301' },
  ];

  for (const slot of scheduleSlots) {
    const existing = await prisma.facultySchedule.findFirst({
      where: {
        faculty_id: facultyMap[slot.facEmail],
        day_of_week: slot.day,
        start_time: slot.startTime,
      },
    });
    if (!existing) {
      await prisma.facultySchedule.create({
        data: {
          faculty_id: facultyMap[slot.facEmail],
          subject_id: subjectMap[slot.subCode],
          class_id: classMap['IT-A'],
          room_id: roomMap[slot.room],
          academic_term_id: activeTerm?.id,
          day_of_week: slot.day,
          start_time: slot.startTime,
          end_time: slot.endTime,
          subject_code: slot.subCode,
          subject_name: subjectsData.find(s => s.code === slot.subCode)?.name,
          section: 'A',
        },
      });
    }
  }
  console.log('✅ IT Timetable schedules initialized.');

  // 11. STUDENTS FOR IT DEPARTMENT (Matching Mockup Screen 4 & 5)
  const studentsData = [
    { email: 'arun.it@gcee.ac.in', name: 'Arun Kumar', regNo: '23IT001', cgpa: 8.42, attendance: 86, placementStatus: 'SHORTLISTED', section: 'A' },
    { email: 'sneha.it@gcee.ac.in', name: 'Sneha Priya', regNo: '23IT002', cgpa: 8.18, attendance: 82, placementStatus: 'PLACED', section: 'A' },
    { email: 'vikram.it@gcee.ac.in', name: 'Vikram S', regNo: '23IT003', cgpa: 7.96, attendance: 78, placementStatus: 'APPLIED', section: 'B' },
    { email: 'divya.it@gcee.ac.in', name: 'Divya R', regNo: '23IT004', cgpa: 8.64, attendance: 90, placementStatus: 'SHORTLISTED', section: 'B' },
    { email: 'karthik.it@gcee.ac.in', name: 'Karthik M', regNo: '23IT005', cgpa: 7.58, attendance: 76, placementStatus: 'ELIGIBLE', section: 'A' },
    { email: 'dinesh.it@gcee.ac.in', name: 'Dinesh V', regNo: '23IT006', cgpa: 6.85, attendance: 68, placementStatus: 'APPLIED', section: 'A' }, // Low attendance
  ];

  for (const st of studentsData) {
    let u = await prisma.user.findUnique({ where: { email: st.email } });
    const [firstName, ...lastParts] = st.name.split(' ');
    const lastName = lastParts.join(' ');

    if (!u) {
      u = await prisma.user.create({
        data: {
          college_id: collegeId,
          department_id: itDeptId,
          email: st.email,
          password_hash: passwordHash,
          first_name: firstName,
          last_name: lastName,
          roll_number: st.regNo,
          username: st.email.split('@')[0],
          role: Role.STUDENT,
          status: UserStatus.ACTIVE,
          is_profile_completed: true,
          is_password_configured: true,
        },
      });
    }

    await prisma.studentProfile.upsert({
      where: { user_id: u.id },
      update: { registration_number: st.regNo },
      create: {
        user_id: u.id,
        registration_number: st.regNo,
        tenth_percentage: 85.0,
        permanent_address: 'Erode, Tamil Nadu',
        father_name: 'Father',
        father_phone: '9876543210',
        mother_name: 'Mother',
        mother_phone: '9876543211',
        emergency_contact_phone: '9876543212',
      },
    });

    await prisma.studentAcademicProfile.upsert({
      where: { student_id: u.id },
      update: {
        program_id: itProgId,
        batch_id: batchMap['2023-2027'],
        admission_year: 2023,
        current_year: 4,
        section: st.section,
        batch_name: '2023-2027',
      },
      create: {
        student_id: u.id,
        program_id: itProgId,
        batch_id: batchMap['2023-2027'],
        admission_year: 2023,
        current_year: 4,
        section: st.section,
        batch_name: '2023-2027',
      },
    });

    // Portfolio with CGPA & Skills
    const port = await prisma.portfolio.upsert({
      where: { user_id: u.id },
      update: {
        cgpa: st.cgpa,
        bio: 'B.Tech Information Technology student at GCE Erode.',
      },
      create: {
        user_id: u.id,
        cgpa: st.cgpa,
        bio: 'B.Tech Information Technology student at GCE Erode.',
      },
    });

    // Sample skills for Arun Kumar
    if (st.regNo === '23IT001') {
      const skills = ['Python', 'Flutter', 'MongoDB', 'SQL'];
      for (const sk of skills) {
        const existSkill = await prisma.portfolioSkill.findFirst({
          where: { portfolio_id: port.id, skill_name: sk },
        });
        if (!existSkill) {
          await prisma.portfolioSkill.create({
            data: { portfolio_id: port.id, skill_name: sk, proficiency: 'Advanced' },
          });
        }
      }
    }
  }
  console.log('✅ IT Students seeded with academic profiles & portfolios.');

  // 12. PLACEMENT DRIVES (Screen 11 in mockup: TCS, Infosys, Wipro)
  const drivesData = [
    { company: 'TCS', role: 'Software Engineer', ctc: '7.0 LPA', status: DriveStatus.ONGOING, deadline: new Date('2026-10-30') },
    { company: 'Infosys', role: 'System Engineer', ctc: '6.5 LPA', status: DriveStatus.ONGOING, deadline: new Date('2026-11-15') },
    { company: 'Wipro', role: 'Project Engineer', ctc: '6.0 LPA', status: DriveStatus.ONGOING, deadline: new Date('2026-11-20') },
  ];

  for (const d of drivesData) {
    let drive = await prisma.placementDrive.findFirst({
      where: { college_id: collegeId, company_name: d.company },
    });
    if (!drive) {
      await prisma.placementDrive.create({
        data: {
          college_id: collegeId,
          company_name: d.company,
          role_title: d.role,
          package_ctc: d.ctc,
          location: 'Chennai / Coimbatore',
          status: d.status,
          deadline: d.deadline,
          min_cgpa: 7.0,
          allowed_departments: ['IT', 'CSE'],
          target_year: 2027,
          target_batch: '2023-2027',
        },
      });
    }
  }
  console.log('✅ Relevant Placement drives initialized for IT.');

  // 13. DEPARTMENT ANNOUNCEMENT (Screen 12 in mockup)
  const existingPost = await prisma.post.findFirst({
    where: {
      college_id: collegeId,
      department_id: itDeptId,
      title: 'Internal Assessment Schedule',
    },
  });
  if (!existingPost) {
    await prisma.post.create({
      data: {
        college_id: collegeId,
        department_id: itDeptId,
        author_id: deptAdmin.id,
        title: 'Internal Assessment Schedule',
        content: 'The Internal Assessment 2 will be conducted from 22 April 2026. Please check the detailed schedule and syllabus.',
        type: 'ANNOUNCEMENT',
      },
    });
  }

  console.log('🎉 Department Admin environment successfully initialized!');
}

if (require.main === module) {
  seedDeptAdminEnvironment()
    .catch((err) => {
      console.error('❌ Error during seeding:', err);
      process.exit(1);
    })
    .finally(() => prisma.$disconnect());
}
