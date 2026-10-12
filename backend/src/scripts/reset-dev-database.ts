import { PrismaClient, Role, UserStatus, DriveStatus } from '@prisma/client';
import argon2 from 'argon2';
import dotenv from 'dotenv';
import path from 'path';

// Load environment configuration
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const prisma = new PrismaClient();

export async function resetDatabase() {
  const dbUrl = process.env.DATABASE_URL || '';
  const isDev =
    process.env.NODE_ENV === 'development' ||
    dbUrl.includes('localhost') ||
    dbUrl.includes('127.0.0.1') ||
    dbUrl.includes('campushub_db');

  if (!isDev) {
    throw new Error('FATAL: Database reset can only run in development environment. Aborting for safety.');
  }

  const mainAdminEmail = (process.env.INITIAL_ADMIN_EMAIL || process.env.MAIN_ADMIN_EMAIL || 'admin@gcee.ac.in').trim().toLowerCase();
  const initialPassword = process.env.INITIAL_ADMIN_PASSWORD || process.env.MAIN_ADMIN_PASSWORD || '123456';

  console.log('===========================================================');
  console.log('🏛️  CAMPUSHUB — GCEE CANONICAL DATABASE RESET & BOOTSTRAP');
  console.log('===========================================================');
  console.log(`Target Main Admin Email: ${mainAdminEmail}`);

  // 1. Purge Audit & Change Requests
  console.log('🧹 Purging Audit Logs & Profile Change Requests...');
  await prisma.profileChangeRequest.deleteMany();
  await prisma.auditLog.deleteMany();

  // 2. Chat & Communications
  console.log('🧹 Purging Chat & Communications...');
  await prisma.chatBlock.deleteMany();
  await prisma.chatRequest.deleteMany();
  await prisma.studentChatSettings.deleteMany();
  await prisma.chatMessageReaction.deleteMany();
  await prisma.chatMessageDeletion.deleteMany();
  await prisma.chatReadReceipt.deleteMany();
  await prisma.chatMessage.deleteMany();
  await prisma.chatParticipant.deleteMany();
  await prisma.chatRoom.deleteMany();

  // 3. Social, Feed & Clubs
  console.log('🧹 Purging Social Feed, Stories & Clubs...');
  await prisma.postCommentLike.deleteMany();
  await prisma.postComment.deleteMany();
  await prisma.postLike.deleteMany();
  await prisma.savedPost.deleteMany();
  await prisma.postAttachment.deleteMany();
  await prisma.post.deleteMany();
  await prisma.storyView.deleteMany();
  await prisma.story.deleteMany();

  await prisma.clubResource.deleteMany();
  await prisma.clubMember.deleteMany();
  await prisma.club.deleteMany();
  await prisma.eventRegistration.deleteMany();
  await prisma.event.deleteMany();

  // 4. Placement & Portfolio
  console.log('🧹 Purging Placement Drives & Student Portfolios...');
  await prisma.placementInterview.deleteMany();
  await prisma.placementApplication.deleteMany();
  await prisma.placementResource.deleteMany();
  await prisma.placementDrive.deleteMany();
  await prisma.company.deleteMany();

  await prisma.portfolioProject.deleteMany();
  await prisma.portfolioSkill.deleteMany();
  await prisma.portfolioCertificate.deleteMany();
  await prisma.portfolioAchievement.deleteMany();
  await prisma.portfolio.deleteMany();

  await prisma.notification.deleteMany();
  await prisma.notificationToken.deleteMany();

  // 5. Career, AI & Mentorship
  console.log('🧹 Purging Career Hub & AI Data...');
  await prisma.weeklyGoal.deleteMany();
  await prisma.userNodeProgress.deleteMany();
  await prisma.userRoadmapProgress.deleteMany();
  await prisma.userMiniProjectSubmission.deleteMany();
  await prisma.careerAIInteraction.deleteMany();
  await prisma.careerMentorShare.deleteMany();
  await prisma.roadmapChange.deleteMany();
  await prisma.learningSession.deleteMany();
  await prisma.skillEvidence.deleteMany();
  await prisma.projectEvidence.deleteMany();
  await prisma.studentSkill.deleteMany();
  await prisma.skillDependency.deleteMany();
  await prisma.quizAttempt.deleteMany();
  await prisma.interviewTurn.deleteMany();
  await prisma.interviewSession.deleteMany();
  await prisma.aIMessage.deleteMany();
  await prisma.aIConversation.deleteMany();
  await prisma.careerPathfinderSession.deleteMany();
  await prisma.learningResource.deleteMany();
  await prisma.roadmapNode.deleteMany();
  await prisma.careerRoadmap.deleteMany();
  await prisma.careerJourney.deleteMany();
  await prisma.resumeTip.deleteMany();
  await prisma.placementPrepModule.deleteMany();
  await prisma.miniProjectIdea.deleteMany();
  await prisma.mediaAsset.deleteMany();

  // 6. Academic Hub & Classroom
  console.log('🧹 Purging Academic Classes, Schedules & Enrollment...');
  await prisma.studentAttendanceRecord.deleteMany();
  await prisma.subjectAttendanceSession.deleteMany();
  await prisma.studentAssessmentResult.deleteMany();
  await prisma.subjectAssessment.deleteMany();
  await prisma.assignmentSubmission.deleteMany();
  await prisma.subjectAssignment.deleteMany();
  await prisma.facultySchedule.deleteMany();
  await prisma.subjectResource.deleteMany();
  await prisma.subjectAnnouncement.deleteMany();
  await prisma.subjectEnrollment.deleteMany();
  await prisma.facultySubjectAssignment.deleteMany();
  await prisma.facultySubject.deleteMany();
  await prisma.studentMentorship.deleteMany();
  await prisma.studentAcademicOverride.deleteMany();
  await prisma.studentAcademicProfile.deleteMany();
  await prisma.studentProfile.deleteMany();
  await prisma.curriculumSubject.deleteMany();
  await prisma.subject.deleteMany();
  await prisma.academicClass.deleteMany();
  await prisma.room.deleteMany();
  await prisma.facultyProfile.deleteMany();
  await prisma.batch.deleteMany();
  await prisma.academicTerm.deleteMany();
  await prisma.academicYear.deleteMany();
  await prisma.academicTransitionRecord.deleteMany();
  await prisma.academicProgram.deleteMany();

  // 7. Security Tokens & Follow Relationships
  console.log('🧹 Purging Security Tokens & Follows...');
  await prisma.userFollow.deleteMany();
  await prisma.refreshToken.deleteMany();
  await prisma.passwordResetToken.deleteMany();

  // 8. Delete all users completely so no legacy records remain
  console.log('🧹 Purging all users from database...');
  await prisma.user.deleteMany();

  // 9. Purge old departments to enforce canonical 8
  console.log('🧹 Purging previous departments to rebuild canonical 8...');
  await prisma.department.deleteMany();

  // 10. Institutional College & Official Departments Setup
  console.log('🏛️  Configuring Institutional GCEE College & Official Departments...');
  const college = await prisma.college.upsert({
    where: { code: 'GCEE' },
    update: {
      name: 'Government College of Engineering, Erode',
      domain: 'gcee.ac.in',
      logo_url: null,
      address: 'Chithode, Erode, Tamil Nadu 638053',
      is_active: true,
    },
    create: {
      name: 'Government College of Engineering, Erode',
      code: 'GCEE',
      domain: 'gcee.ac.in',
      logo_url: null,
      address: 'Chithode, Erode, Tamil Nadu 638053',
      is_active: true,
    },
  });

  const canonicalDepartments = [
    { code: 'IT', name: 'Information Technology', degree: 'B.Tech', desc: 'Department of Information Technology' },
    { code: 'CSE', name: 'Computer Science and Engineering', degree: 'B.E.', desc: 'Department of Computer Science & Engineering' },
    { code: 'CSE (DS)', name: 'Computer Science and Engineering (Data Science)', degree: 'B.E.', desc: 'Department of Computer Science & Engineering (Data Science)' },
    { code: 'MECH', name: 'Mechanical Engineering', degree: 'B.E.', desc: 'Department of Mechanical Engineering' },
    { code: 'EEE', name: 'Electrical and Electronics Engineering', degree: 'B.E.', desc: 'Department of Electrical and Electronics Engineering' },
    { code: 'ECE', name: 'Electronics and Communication Engineering', degree: 'B.E.', desc: 'Department of Electronics and Communication Engineering' },
    { code: 'AUTOMOBILE', name: 'Automobile Engineering', degree: 'B.E.', desc: 'Department of Automobile Engineering' },
    { code: 'CIVIL', name: 'Civil Engineering', degree: 'B.E.', desc: 'Department of Civil Engineering' },
  ];

  for (const dept of canonicalDepartments) {
    const d = await prisma.department.create({
      data: {
        college_id: college.id,
        code: dept.code,
        name: dept.name,
        description: dept.desc,
        is_active: true,
      },
    });

    await prisma.academicProgram.create({
      data: {
        college_id: college.id,
        department_id: d.id,
        name: dept.name,
        code: dept.code,
        degree_type: dept.degree,
        total_semesters: 8,
        is_active: true,
      },
    });
  }

  // 11. Bootstrap ONE Canonical Institutional ADMIN Account
  console.log(`🔐 Bootstrapping Canonical ADMIN Account (${mainAdminEmail})...`);
  const hashedPassword = await argon2.hash(initialPassword);

  const admin = await prisma.user.create({
    data: {
      college_id: college.id,
      department_id: null,
      email: mainAdminEmail,
      first_name: 'Campus',
      last_name: 'Admin',
      role: Role.ADMIN,
      status: UserStatus.ACTIVE,
      password_hash: hashedPassword,
      is_password_configured: true,
      is_profile_completed: true,
      first_login_completed: true,
      username: 'admin',
    },
  });

  // Verification Audit
  const deptCount = await prisma.department.count();
  const programCount = await prisma.academicProgram.count();
  const userCount = await prisma.user.count();
  const studentCount = await prisma.user.count({ where: { role: Role.STUDENT } });
  const facultyCount = await prisma.user.count({ where: { role: Role.FACULTY } });
  const deptAdminCount = await prisma.user.count({ where: { role: Role.DEPT_ADMIN } });
  const placementCount = await prisma.user.count({ where: { role: Role.PLACEMENT } });
  const adminCount = await prisma.user.count({ where: { role: Role.ADMIN } });
  const companyCount = await prisma.company.count();
  const driveCount = await prisma.placementDrive.count();
  const appCount = await prisma.placementApplication.count();
  const interviewCount = await prisma.placementInterview.count();
  const postCount = await prisma.post.count();
  const messageCount = await prisma.chatMessage.count();
  const notifCount = await prisma.notification.count();
  const clubCount = await prisma.club.count();
  const eventCount = await prisma.event.count();
  const assignmentCount = await prisma.subjectAssignment.count();
  const assessmentCount = await prisma.subjectAssessment.count();
  const attCount = await prisma.studentAttendanceRecord.count();
  const resourceCount = await prisma.subjectResource.count();

  console.log('\n===========================================================');
  console.log('📊 DATABASE VERIFICATION AUDIT');
  console.log('===========================================================');
  console.log(`• Departments:            ${deptCount} (Expected: 8)`);
  console.log(`• Academic Programs:      ${programCount} (Expected: 8)`);
  console.log(`• Total Users:            ${userCount} (Expected: 1)`);
  console.log(`• Admins:                 ${adminCount} (Expected: 1)`);
  console.log(`• Dept Admins:            ${deptAdminCount} (Expected: 0)`);
  console.log(`• Faculty:                ${facultyCount} (Expected: 0)`);
  console.log(`• Placement Officers:     ${placementCount} (Expected: 0)`);
  console.log(`• Students:               ${studentCount} (Expected: 0)`);
  console.log(`• Companies:              ${companyCount} (Expected: 0)`);
  console.log(`• Placement Drives:       ${driveCount} (Expected: 0)`);
  console.log(`• Applications:           ${appCount} (Expected: 0)`);
  console.log(`• Interviews:             ${interviewCount} (Expected: 0)`);
  console.log(`• Clubs:                  ${clubCount} (Expected: 0)`);
  console.log(`• Feed Posts:             ${postCount} (Expected: 0)`);
  console.log(`• Events:                 ${eventCount} (Expected: 0)`);
  console.log(`• Chat Messages:          ${messageCount} (Expected: 0)`);
  console.log(`• Notifications:          ${notifCount} (Expected: 0)`);
  console.log(`• Assignments:            ${assignmentCount} (Expected: 0)`);
  console.log(`• Assessments:            ${assessmentCount} (Expected: 0)`);
  console.log(`• Attendance Records:     ${attCount} (Expected: 0)`);
  console.log(`• Resources:              ${resourceCount} (Expected: 0)`);
  console.log('-----------------------------------------------------------');
  console.log(`✅ Institutional ADMIN Account:`);
  console.log(`   Email:    ${admin.email}`);
  console.log(`   Role:     ${admin.role}`);
  console.log(`   Status:   ${admin.status}`);
  console.log('===========================================================');

  if (
    deptCount !== 8 ||
    userCount !== 1 ||
    adminCount !== 1 ||
    studentCount !== 0 ||
    facultyCount !== 0 ||
    deptAdminCount !== 0 ||
    placementCount !== 0 ||
    companyCount !== 0 ||
    driveCount !== 0 ||
    appCount !== 0 ||
    clubCount !== 0 ||
    postCount !== 0 ||
    eventCount !== 0 ||
    messageCount !== 0 ||
    notifCount !== 0 ||
    assignmentCount !== 0 ||
    assessmentCount !== 0 ||
    attCount !== 0 ||
    resourceCount !== 0
  ) {
    throw new Error('Verification failed: Database state does not match clean reset criteria!');
  }
}

if (require.main === module) {
  resetDatabase()
    .catch((err) => {
      console.error('❌ Reset failed:', err);
      process.exit(1);
    })
    .finally(async () => {
      await prisma.$disconnect();
    });
}
