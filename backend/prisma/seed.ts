/// <reference types="node" />
import { PrismaClient, Role, UserStatus } from '@prisma/client';
import argon2 from 'argon2';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting Clean CampusHub Database Seeding...');

  // 1. Clean existing transactional content (posts, events, clubs, drives, portfolio, career)
  console.log('🧹 Cleaning existing content...');
  await prisma.postComment.deleteMany();
  await prisma.postLike.deleteMany();
  await prisma.savedPost.deleteMany();
  await prisma.postAttachment.deleteMany();
  await prisma.post.deleteMany();

  await prisma.eventRegistration.deleteMany();
  await prisma.event.deleteMany();

  await prisma.clubResource.deleteMany();
  await prisma.clubMember.deleteMany();
  await prisma.club.deleteMany();

  await prisma.placementInterview.deleteMany();
  await prisma.placementApplication.deleteMany();
  await prisma.placementDrive.deleteMany();

  await prisma.portfolioProject.deleteMany();
  await prisma.portfolioSkill.deleteMany();
  await prisma.portfolioCertificate.deleteMany();
  await prisma.portfolioAchievement.deleteMany();
  await prisma.portfolio.deleteMany();

  await prisma.weeklyGoal.deleteMany();
  await prisma.userNodeProgress.deleteMany();
  await prisma.userRoadmapProgress.deleteMany();
  await prisma.userMiniProjectSubmission.deleteMany();

  console.log('✅ All existing feed posts, events, clubs, drives, and portfolio items cleared!');

  // 2. Create Sample College
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

  console.log(`✅ College Configured: ${college.name} (${college.id})`);

  // 3. Create Departments
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

  console.log(`✅ Departments Configured: ${deptCse.name}, ${deptIt.name}`);

  // 4. Create Role Accounts (Clean slate for testing each role)
  const hashedPassword = await argon2.hash('Password@123');

  const student = await prisma.user.upsert({
    where: { email: 'student@campushub.edu' },
    update: {
      password_hash: hashedPassword,
      status: UserStatus.ACTIVE,
    },
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
    update: {
      password_hash: hashedPassword,
      status: UserStatus.ACTIVE,
    },
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
    update: {
      password_hash: hashedPassword,
      status: UserStatus.ACTIVE,
    },
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
    update: {
      password_hash: hashedPassword,
      status: UserStatus.ACTIVE,
    },
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

  console.log(`✅ Accounts Ready for User Content Creation:`);
  console.log(`   - Student: ${student.email}`);
  console.log(`   - Faculty: ${faculty.email}`);
  console.log(`   - Placement Officer: ${placementOfficer.email}`);
  console.log(`   - Admin: ${admin.email}`);

  console.log('🎉 Database is clean & ready for users to create new Feed posts, Events, Clubs, Placement Drives, and Portfolios!');
}

main()
  .catch((e) => {
    console.error('❌ Error during seeding:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
