import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🧹 Starting Academic & Faculty Data Clean Slate Reset...');

  // 1. Delete all existing dummy/seeded academic records in proper dependency order
  const deletedResources = await prisma.subjectResource.deleteMany({});
  console.log(`✅ Deleted ${deletedResources.count} Subject Resources`);

  const deletedAnnouncements = await prisma.subjectAnnouncement.deleteMany({});
  console.log(`✅ Deleted ${deletedAnnouncements.count} Subject Announcements`);

  const deletedEnrollments = await prisma.subjectEnrollment.deleteMany({});
  console.log(`✅ Deleted ${deletedEnrollments.count} Subject Enrollments`);

  const deletedFacultyAssignments = await prisma.facultySubject.deleteMany({});
  console.log(`✅ Deleted ${deletedFacultyAssignments.count} Faculty Subject Assignments`);

  const deletedSubjects = await prisma.subject.deleteMany({});
  console.log(`✅ Deleted ${deletedSubjects.count} Subjects`);

  // 2. Find or verify active Faculty user
  const faculty = await prisma.user.findUnique({
    where: { email: 'faculty@campushub.edu' },
    include: { department: true },
  });

  if (!faculty) {
    console.log('⚠️ Faculty user faculty@campushub.edu not found. Nothing to upsert for faculty profile.');
  } else {
    // 3. Upsert clean Faculty Profile for Dr. Robert Taylor
    const profile = await prisma.facultyProfile.upsert({
      where: { user_id: faculty.id },
      update: {
        designation: 'Associate Professor & Academic Coordinator',
        qualification: 'Ph.D. in Computer Science, M.Tech',
        department_name: faculty.department?.name || 'Computer Science and Engineering',
        specialization: 'Distributed Systems & Cloud Computing',
        bio: 'Dr. Robert Taylor is an Associate Professor specializing in Distributed Systems, Cloud Architecture, and Operating Systems. Advises undergraduate students and coordinates academic curriculum resources.',
        office_room: 'Tech Block B, Room 304',
        office_hours: 'Mon - Thu: 2:00 PM - 4:00 PM',
        expertise: ['Distributed Systems', 'Cloud Computing', 'Computer Networks', 'Operating Systems'],
        publications: [
          {
            title: 'Fault-Tolerant Microservices in Distributed Cloud Environments',
            venue: 'IEEE Transactions on Cloud Computing, 2024',
            link: 'https://ieee.org',
          },
        ],
        linkedin_url: 'https://linkedin.com',
        google_scholar: 'https://scholar.google.com',
      },
      create: {
        user_id: faculty.id,
        designation: 'Associate Professor & Academic Coordinator',
        qualification: 'Ph.D. in Computer Science, M.Tech',
        department_name: faculty.department?.name || 'Computer Science and Engineering',
        specialization: 'Distributed Systems & Cloud Computing',
        bio: 'Dr. Robert Taylor is an Associate Professor specializing in Distributed Systems, Cloud Architecture, and Operating Systems. Advises undergraduate students and coordinates academic curriculum resources.',
        office_room: 'Tech Block B, Room 304',
        office_hours: 'Mon - Thu: 2:00 PM - 4:00 PM',
        expertise: ['Distributed Systems', 'Cloud Computing', 'Computer Networks', 'Operating Systems'],
        publications: [
          {
            title: 'Fault-Tolerant Microservices in Distributed Cloud Environments',
            venue: 'IEEE Transactions on Cloud Computing, 2024',
            link: 'https://ieee.org',
          },
        ],
        linkedin_url: 'https://linkedin.com',
        google_scholar: 'https://scholar.google.com',
      },
    });

    console.log(`✅ Faculty Profile for Dr. Robert Taylor initialized cleanly (Profile ID: ${profile.id})`);
  }

  // 4. Final verification counts
  const finalSubjectCount = await prisma.subject.count();
  const finalResourceCount = await prisma.subjectResource.count();
  const finalAnnouncementCount = await prisma.subjectAnnouncement.count();

  console.log('\n📊 Clean Slate Verification:');
  console.log(`- Remaining Subjects: ${finalSubjectCount}`);
  console.log(`- Remaining Subject Resources: ${finalResourceCount}`);
  console.log(`- Remaining Subject Announcements: ${finalAnnouncementCount}`);
  console.log('✨ Clean slate ready for manual creation of subjects & resources through the UI!');
}

main()
  .catch((e) => {
    console.error('❌ Reset failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
