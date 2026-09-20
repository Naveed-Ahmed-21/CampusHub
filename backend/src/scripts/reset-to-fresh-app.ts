import { PrismaClient, Role, UserStatus } from '@prisma/client';
import argon2 from 'argon2';

const prisma = new PrismaClient();

export async function resetToFreshApp() {
  console.log('🧹 [1/6] Purging Chat & Communications...');
  await prisma.chatMessageReaction.deleteMany();
  await prisma.chatMessageDeletion.deleteMany();
  await prisma.chatReadReceipt.deleteMany();
  await prisma.chatMessage.deleteMany();
  await prisma.chatParticipant.deleteMany();
  await prisma.chatRoom.deleteMany();

  console.log('🧹 [2/6] Purging Social, Feed & Clubs...');
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

  console.log('🧹 [3/6] Purging Placement & Portfolio...');
  await prisma.placementInterview.deleteMany();
  await prisma.placementApplication.deleteMany();
  await prisma.placementDrive.deleteMany();
  await prisma.company.deleteMany();

  await prisma.portfolioProject.deleteMany();
  await prisma.portfolioSkill.deleteMany();
  await prisma.portfolioCertificate.deleteMany();
  await prisma.portfolioAchievement.deleteMany();
  await prisma.portfolio.deleteMany();

  await prisma.notification.deleteMany();
  await prisma.notificationToken.deleteMany();

  console.log('🧹 [4/6] Purging Career, AI & Mentorship...');
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

  console.log('🧹 [5/6] Purging Academic & Teaching Hub...');
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
  await prisma.curriculumSubject.deleteMany();
  await prisma.subject.deleteMany();
  await prisma.academicClass.deleteMany();
  await prisma.room.deleteMany();
  await prisma.facultyProfile.deleteMany();
  await prisma.academicTerm.deleteMany();
  await prisma.academicYear.deleteMany();
  await prisma.academicProgram.deleteMany();

  console.log('🧹 [6/6] Purging Tokens, Follows & Resetting Users...');
  await prisma.userFollow.deleteMany();
  await prisma.refreshToken.deleteMany();
  await prisma.passwordResetToken.deleteMany();

  // Delete all non-institutional users
  const institutionalEmails = [
    'student@campushub.edu',
    'faculty@campushub.edu',
    'admin@campushub.edu',
    'placement@campushub.edu',
  ];

  await prisma.user.deleteMany({
    where: {
      email: { notIn: institutionalEmails },
    },
  });

  // Ensure Base College & Departments exist
  const college = await prisma.college.upsert({
    where: { code: 'CH-TECH' },
    update: {
      name: 'CampusHub Institute of Technology',
      domain: 'campushub.edu',
      logo_url: null,
      address: '127 Tech Campus Road, Innovation Park',
    },
    create: {
      name: 'CampusHub Institute of Technology',
      code: 'CH-TECH',
      domain: 'campushub.edu',
      logo_url: null,
      address: '127 Tech Campus Road, Innovation Park',
    },
  });

  const deptCse = await prisma.department.upsert({
    where: { college_id_code: { college_id: college.id, code: 'CSE' } },
    update: {
      name: 'Computer Science and Engineering',
      description: 'Department of Computer Science & Engineering',
    },
    create: {
      college_id: college.id,
      name: 'Computer Science and Engineering',
      code: 'CSE',
      description: 'Department of Computer Science & Engineering',
    },
  });

  const deptIt = await prisma.department.upsert({
    where: { college_id_code: { college_id: college.id, code: 'IT' } },
    update: {
      name: 'Information Technology',
      description: 'Department of Information Technology',
    },
    create: {
      college_id: college.id,
      name: 'Information Technology',
      code: 'IT',
      description: 'Department of Information Technology',
    },
  });

  // Reset the 4 core accounts to clean state
  const hashedPassword = await argon2.hash('Password@123');

  await prisma.user.upsert({
    where: { email: 'student@campushub.edu' },
    update: {
      college_id: college.id,
      department_id: deptCse.id,
      first_name: 'Alex',
      last_name: 'Vance',
      roll_number: '21CS101',
      password_hash: hashedPassword,
      role: Role.STUDENT,
      status: UserStatus.ACTIVE,
      avatar_url: null,
      phone: null,
      username: null,
      is_online: false,
      last_seen: null,
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
      avatar_url: null,
      phone: null,
      username: null,
      is_online: false,
      last_seen: null,
    },
  });

  await prisma.user.upsert({
    where: { email: 'faculty@campushub.edu' },
    update: {
      college_id: college.id,
      department_id: deptCse.id,
      first_name: 'Dr. Robert',
      last_name: 'Taylor',
      roll_number: null,
      password_hash: hashedPassword,
      role: Role.FACULTY,
      status: UserStatus.ACTIVE,
      avatar_url: null,
      phone: null,
      username: null,
      is_online: false,
      last_seen: null,
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
      avatar_url: null,
      phone: null,
      username: null,
      is_online: false,
      last_seen: null,
    },
  });

  await prisma.user.upsert({
    where: { email: 'placement@campushub.edu' },
    update: {
      college_id: college.id,
      department_id: deptIt.id,
      first_name: 'Sarah',
      last_name: 'Jenkins',
      roll_number: null,
      password_hash: hashedPassword,
      role: Role.PLACEMENT_OFFICER,
      status: UserStatus.ACTIVE,
      avatar_url: null,
      phone: null,
      username: null,
      is_online: false,
      last_seen: null,
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
      avatar_url: null,
      phone: null,
      username: null,
      is_online: false,
      last_seen: null,
    },
  });

  await prisma.user.upsert({
    where: { email: 'admin@campushub.edu' },
    update: {
      college_id: college.id,
      department_id: deptCse.id,
      first_name: 'Campus',
      last_name: 'Admin',
      roll_number: null,
      password_hash: hashedPassword,
      role: Role.ADMIN,
      status: UserStatus.ACTIVE,
      avatar_url: null,
      phone: null,
      username: null,
      is_online: false,
      last_seen: null,
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
      avatar_url: null,
      phone: null,
      username: null,
      is_online: false,
      last_seen: null,
    },
  });

  console.log('✨ Fresh app reset complete!');
  console.log('Institutional accounts (Password: Password@123):');
  console.log('  - Student: student@campushub.edu');
  console.log('  - Faculty: faculty@campushub.edu');
  console.log('  - Placement Officer: placement@campushub.edu');
  console.log('  - Admin: admin@campushub.edu');
}

if (require.main === module) {
  resetToFreshApp()
    .catch((err) => {
      console.error('❌ Reset failed:', err);
      process.exit(1);
    })
    .finally(async () => {
      await prisma.$disconnect();
    });
}
