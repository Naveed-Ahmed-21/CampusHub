import { PrismaClient, Role, UserStatus } from '@prisma/client';
import argon2 from 'argon2';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting CampusHub Database Seeding...');

  // Create Sample College
  const college = await prisma.college.upsert({
    where: { code: 'CH-TECH' },
    update: {},
    create: {
      name: 'CampusHub Institute of Technology',
      code: 'CH-TECH',
      domain: 'campushub.edu',
      logo_url: 'https://images.unsplash.com/photo-1562774053-701939374585',
      address: '127 Tech Campus Road, Innovation Park',
    },
  });

  console.log(`✅ College Seeded: ${college.name} (${college.id})`);

  // Create Departments
  const deptCse = await prisma.department.upsert({
    where: { college_id_code: { college_id: college.id, code: 'CSE' } },
    update: {},
    create: {
      college_id: college.id,
      name: 'Computer Science and Engineering',
      code: 'CSE',
      description: 'Department of Computer Science & Engineering',
    },
  });

  const deptIt = await prisma.department.upsert({
    where: { college_id_code: { college_id: college.id, code: 'IT' } },
    update: {},
    create: {
      college_id: college.id,
      name: 'Information Technology',
      code: 'IT',
      description: 'Department of Information Technology',
    },
  });

  console.log(`✅ Departments Seeded: ${deptCse.name}, ${deptIt.name}`);

  // Create Sample Users for All 4 Roles
  const hashedPassword = await argon2.hash('Password@123');

  const student = await prisma.user.upsert({
    where: { email: 'student@campushub.edu' },
    update: {},
    create: {
      college_id: college.id,
      department_id: deptCse.id,
      email: 'student@campushub.edu',
      password_hash: hashedPassword,
      first_name: 'Alex',
      last_name: 'Vance',
      roll_number: '21CS101',
      role: Role.STUDENT,
      status: UserStatus.ACTIVE,
    },
  });

  const faculty = await prisma.user.upsert({
    where: { email: 'faculty@campushub.edu' },
    update: {},
    create: {
      college_id: college.id,
      department_id: deptCse.id,
      email: 'faculty@campushub.edu',
      password_hash: hashedPassword,
      first_name: 'Dr. Robert',
      last_name: 'Taylor',
      role: Role.FACULTY,
      status: UserStatus.ACTIVE,
    },
  });

  const placementOfficer = await prisma.user.upsert({
    where: { email: 'placement@campushub.edu' },
    update: {},
    create: {
      college_id: college.id,
      department_id: deptIt.id,
      email: 'placement@campushub.edu',
      password_hash: hashedPassword,
      first_name: 'Sarah',
      last_name: 'Jenkins',
      role: Role.PLACEMENT_OFFICER,
      status: UserStatus.ACTIVE,
    },
  });

  const admin = await prisma.user.upsert({
    where: { email: 'admin@campushub.edu' },
    update: {},
    create: {
      college_id: college.id,
      department_id: deptCse.id,
      email: 'admin@campushub.edu',
      password_hash: hashedPassword,
      first_name: 'Campus',
      last_name: 'Admin',
      role: Role.ADMIN,
      status: UserStatus.ACTIVE,
    },
  });

  console.log(`✅ Users Seeded across all roles:`);
  console.log(`   - Student: ${student.email}`);
  console.log(`   - Faculty: ${faculty.email}`);
  console.log(`   - Placement Officer: ${placementOfficer.email}`);
  console.log(`   - Admin: ${admin.email}`);

  // Create Sample Club
  const codingClub = await prisma.club.create({
    data: {
      college_id: college.id,
      name: 'DevSync Coding Club',
      category: 'Technical',
      description: 'The official competitive coding & open source club.',
      members: {
        create: [
          { user_id: student.id, role: 'LEAD' },
        ],
      },
    },
  });

  console.log(`✅ Club Seeded: ${codingClub.name}`);

  // Create Sample Placement Drive
  const drive = await prisma.placementDrive.create({
    data: {
      college_id: college.id,
      company_name: 'Google',
      role_title: 'Software Development Engineer I',
      package_ctc: '28 LPA',
      location: 'Bengaluru, India',
      eligibility: 'CGPA >= 8.0, No active backlogs',
      deadline: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
    },
  });

  console.log(`✅ Placement Drive Seeded: ${drive.company_name} - ${drive.role_title}`);

  console.log('🎉 Seeding completed successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Error during seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
