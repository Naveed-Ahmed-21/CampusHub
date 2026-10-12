import { prisma } from '../src/infrastructure/prisma/prisma.service';
import { AuthService } from '../src/modules/auth/auth.service';
import { AuthRepository } from '../src/modules/auth/auth.repository';
import { ProfileService } from '../src/modules/profile/profile.service';
import { ProfileRepository } from '../src/modules/profile/profile.repository';
import { AdminService } from '../src/modules/admin/admin.service';
import { AdminRepository } from '../src/modules/admin/admin.repository';
import { Role, UserStatus } from '@prisma/client';
import * as argon2 from 'argon2';

async function main() {
  console.log('========================================================================');
  console.log('STARTING COMPLETE IDENTITY, PROFILE & PROFILE-CHANGE REQUEST VERIFICATION');
  console.log('========================================================================\n');

  const authRepo = new AuthRepository();
  const authService = new AuthService(authRepo);
  const profileRepo = new ProfileRepository();
  const profileService = new ProfileService(profileRepo);
  const adminRepo = new AdminRepository();
  const adminService = new AdminService(adminRepo);

  // 1. Setup College and Department
  let college = await prisma.college.findFirst();
  if (!college) {
    college = await prisma.college.create({
      data: {
        name: 'CampusHub University',
        code: 'CHU',
        domain: 'campushub.edu',
      },
    });
    console.log(`[SETUP] Created test college: ${college.name} (${college.id})`);
  } else {
    console.log(`[SETUP] Using existing college: ${college.name} (${college.id})`);
  }

  let dept = await prisma.department.findFirst({
    where: { college_id: college.id },
  });
  if (!dept) {
    dept = await prisma.department.create({
      data: {
        college_id: college.id,
        name: 'Computer Science and Engineering',
        code: 'CSE',
        is_active: true,
      },
    });
    console.log(`[SETUP] Created test department: ${dept.name} (${dept.id})`);
  } else {
    console.log(`[SETUP] Using existing department: ${dept.name} (${dept.id})`);
  }

  // Ensure Admin user exists
  const adminEmail = 'superadmin@campushub.edu';
  let adminUser = await prisma.user.findUnique({ where: { email: adminEmail } });
  if (!adminUser) {
    adminUser = await prisma.user.create({
      data: {
        college_id: college.id,
        email: adminEmail,
        first_name: 'Super',
        last_name: 'Admin',
        role: Role.COLLEGE_ADMIN,
        password_hash: await argon2.hash('AdminPassword123!'),
        status: UserStatus.ACTIVE,
        is_password_configured: true,
        is_profile_completed: true,
        first_login_completed: true,
      },
    });
    console.log(`[SETUP] Created Admin user: ${adminUser.email}`);
  } else {
    console.log(`[SETUP] Using existing Admin user: ${adminUser.email}`);
  }

  const adminActor = {
    actorUserId: adminUser.id,
    actorRole: adminUser.role,
    actorCollegeId: college.id,
    actorDeptId: adminUser.department_id || undefined,
  };

  const testStudentEmail = 'e2e_student_test@campushub.edu';

  // Clean up any previous test student with this email
  const existingStudent = await prisma.user.findUnique({ where: { email: testStudentEmail } });
  if (existingStudent) {
    await prisma.profileChangeRequest.deleteMany({ where: { student_id: existingStudent.id } });
    await prisma.studentProfile.deleteMany({ where: { user_id: existingStudent.id } });
    await prisma.studentAcademicProfile.deleteMany({ where: { student_id: existingStudent.id } });
    await prisma.notification.deleteMany({ where: { user_id: existingStudent.id } });
    await prisma.user.delete({ where: { id: existingStudent.id } });
    console.log(`[SETUP] Cleaned up previous test student`);
  }

  // -------------------------------------------------------------------------
  // TEST 1: Admin Creates Student with Minimal Invitation Form
  // -------------------------------------------------------------------------
  console.log('\n--- TEST 1: Admin Creates Student via Minimal Invite ---');
  const createdUser = await adminService.createUser(
    college.id,
    {
      email: testStudentEmail,
      role: Role.STUDENT,
      departmentId: dept.id,
      batchName: '2024-2028',
      rollNumber: 'CS2024E2E01',
    },
    adminActor,
  );

  console.log(`Created user ID: ${createdUser.id}, Status: ${createdUser.status}`);

  // Direct PostgreSQL assertion
  const studentDb = await prisma.user.findUnique({
    where: { id: createdUser.id },
    include: {
      academic_profile: true,
    },
  });

  if (!studentDb) throw new Error('Student record was not found in PostgreSQL!');
  if (studentDb.status !== UserStatus.INVITED) {
    throw new Error(`Expected status INVITED, got: ${studentDb.status}`);
  }
  if (studentDb.is_password_configured !== false) {
    throw new Error(`Expected is_password_configured=false, got: ${studentDb.is_password_configured}`);
  }
  if (studentDb.is_profile_completed !== false) {
    throw new Error(`Expected is_profile_completed=false, got: ${studentDb.is_profile_completed}`);
  }
  if (studentDb.first_login_completed !== false) {
    throw new Error(`Expected first_login_completed=false, got: ${studentDb.first_login_completed}`);
  }
  if (!studentDb.academic_profile || studentDb.academic_profile.batch_name !== '2024-2028') {
    throw new Error('StudentAcademicProfile was not created with correct batchName!');
  }

  console.log('✓ PASS: Student successfully created in PostgreSQL with INVITED status and unconfigured password');

  // -------------------------------------------------------------------------
  // TEST 2: First-time Account Status Check
  // -------------------------------------------------------------------------
  console.log('\n--- TEST 2: Account Status Check ---');
  const statusCheck = await authService.checkStatus(testStudentEmail);
  console.log('CheckStatus response:', statusCheck);

  if (statusCheck.status !== 'INVITED') throw new Error(`Unexpected status: ${statusCheck.status}`);
  if (statusCheck.isPasswordConfigured !== false) throw new Error('Expected isPasswordConfigured=false');
  const requiresPasswordSetup = !statusCheck.isPasswordConfigured && (statusCheck.status === 'INVITED' || statusCheck.status === 'PASSWORD_SETUP_REQUIRED');
  if (!requiresPasswordSetup) throw new Error('Expected requiresPasswordSetup=true');

  console.log('✓ PASS: checkStatus correctly identifies unactivated invited account');

  // -------------------------------------------------------------------------
  // TEST 3: Login Rejection on Unactivated Account
  // -------------------------------------------------------------------------
  console.log('\n--- TEST 3: Login Rejection on Unactivated Account ---');
  let loginRejected = false;
  try {
    await authService.login({ email: testStudentEmail, password: 'AnyPassword123!' });
  } catch (err: any) {
    loginRejected = true;
    console.log(`Login properly rejected with message: "${err.message}"`);
  }
  if (!loginRejected) throw new Error('Login should have failed for unactivated account!');
  console.log('✓ PASS: Login rejected for unactivated account');

  // -------------------------------------------------------------------------
  // TEST 4: Password Setup
  // -------------------------------------------------------------------------
  console.log('\n--- TEST 4: Password Setup & First-Time Activation ---');
  const setupRes = await authService.setupPassword({
    email: testStudentEmail,
    newPassword: 'SecurePassword123!',
    confirmPassword: 'SecurePassword123!',
  });
  console.log('SetupPassword response:', setupRes);

  if (!setupRes.tokens || !setupRes.user) throw new Error('setupPassword reported failure');

  // Direct PostgreSQL check
  const studentAfterPwd = await prisma.user.findUnique({ where: { id: studentDb.id } });
  if (!studentAfterPwd) throw new Error('User disappeared from DB!');
  if (studentAfterPwd.status !== UserStatus.PROFILE_SETUP_REQUIRED) {
    throw new Error(`Expected status PROFILE_SETUP_REQUIRED, got: ${studentAfterPwd.status}`);
  }
  if (studentAfterPwd.is_password_configured !== true) {
    throw new Error('Expected is_password_configured=true in PostgreSQL!');
  }
  const pwdMatches = await argon2.verify(studentAfterPwd.password_hash, 'SecurePassword123!');
  if (!pwdMatches) throw new Error('Argon2 password hash does not match newly set password!');

  console.log('✓ PASS: Password configured, argon2 verified, status transitioned to PROFILE_SETUP_REQUIRED');

  // -------------------------------------------------------------------------
  // TEST 5: Login with Configured Password
  // -------------------------------------------------------------------------
  console.log('\n--- TEST 5: Login with Configured Password ---');
  const loginResult = await authService.login({
    email: testStudentEmail,
    password: 'SecurePassword123!',
  });
  console.log(`Login successful. Access token received. User status: ${loginResult.user.status}`);

  if (loginResult.user.isPasswordConfigured !== true) throw new Error('Expected isPasswordConfigured=true');
  if (loginResult.user.isProfileCompleted !== false) throw new Error('Expected isProfileCompleted=false');
  if (loginResult.user.status !== 'PROFILE_SETUP_REQUIRED') throw new Error('Expected status PROFILE_SETUP_REQUIRED');

  console.log('✓ PASS: Login succeeds, user correctly guided to onboarding');

  // -------------------------------------------------------------------------
  // TEST 6: Fetch Onboarding Context
  // -------------------------------------------------------------------------
  console.log('\n--- TEST 6: Onboarding Context ---');
  const onboardingContext = await profileService.getOnboardingContext(studentDb.id);
  console.log('Onboarding context:', onboardingContext);

  if (onboardingContext.departmentName !== dept.name) {
    throw new Error(`Expected dept ${dept.name}, got ${onboardingContext.departmentName}`);
  }
  if (onboardingContext.batchName !== '2024-2028') {
    throw new Error(`Expected batch 2024-2028, got ${onboardingContext.batchName}`);
  }

  console.log('✓ PASS: Institutional identity context successfully retrieved for student wizard');

  // -------------------------------------------------------------------------
  // TEST 7: Complete Multi-Step Student Onboarding
  // -------------------------------------------------------------------------
  console.log('\n--- TEST 7: Submit Student Onboarding Wizard ---');
  const onboardingPayload = {
    firstName: 'Naveed',
    lastName: 'Ahmed',
    phone: '+919876543210',
    dob: '2004-03-15',
    bloodGroup: 'B+',
    fatherName: 'Mushtaq Ahmed',
    fatherPhone: '+919876543211',
    motherName: 'Farida Ahmed',
    motherPhone: '+919876543212',
    currentAddress: '123 Tech Campus Hostel Block A',
    currentCity: 'Bangalore',
    currentState: 'Karnataka',
    currentPincode: '560001',
    permanentAddress: '45 Green Park Residency',
    permanentCity: 'Hyderabad',
    permanentState: 'Telangana',
    permanentPincode: '500001',
    tenthPercentage: 92.5,
    twelfthPercentage: 89.0,
    registrationNumber: 'REG2024CS099',
  };

  const onboardResult = await profileService.submitOnboarding(studentDb.id, onboardingPayload);
  console.log('Onboarding submitted:', onboardResult);

  // Verify PostgreSQL
  const studentAfterOnboard = await prisma.user.findUnique({
    where: { id: studentDb.id },
    include: {
      student_profile: true,
      academic_profile: true,
    },
  });

  if (!studentAfterOnboard) throw new Error('Student record not found!');
  if (studentAfterOnboard.first_name !== 'Naveed' || studentAfterOnboard.last_name !== 'Ahmed') {
    throw new Error(`User names not updated in PostgreSQL: ${studentAfterOnboard.first_name} ${studentAfterOnboard.last_name}`);
  }
  if (studentAfterOnboard.status !== UserStatus.ACTIVE) {
    throw new Error(`Expected status ACTIVE, got: ${studentAfterOnboard.status}`);
  }
  if (studentAfterOnboard.is_profile_completed !== true) {
    throw new Error('Expected is_profile_completed=true in PostgreSQL!');
  }
  if (studentAfterOnboard.first_login_completed !== true) {
    throw new Error('Expected first_login_completed=true in PostgreSQL!');
  }
  if (!studentAfterOnboard.student_profile) {
    throw new Error('StudentProfile record was NOT created in PostgreSQL!');
  }
  if (studentAfterOnboard.student_profile.father_name !== 'Mushtaq Ahmed') {
    throw new Error(`Father name mismatch in StudentProfile: ${studentAfterOnboard.student_profile.father_name}`);
  }
  if (studentAfterOnboard.student_profile.registration_number !== 'REG2024CS099') {
    throw new Error(`Registration number mismatch in StudentProfile: ${studentAfterOnboard.student_profile.registration_number}`);
  }

  console.log('✓ PASS: Onboarding transaction written to PostgreSQL: User=ACTIVE, isProfileCompleted=true, StudentProfile created');

  // -------------------------------------------------------------------------
  // TEST 8: Detailed Student Profile & Edit Permission Policy
  // -------------------------------------------------------------------------
  console.log('\n--- TEST 8: Detailed Student Profile & Edit Policies ---');
  const detailedProfile = await profileService.getDetailedStudentProfile(studentDb.id);
  console.log(`Completion Percentage: ${detailedProfile.overview.completionPercentage}%`);

  if (typeof detailedProfile.overview.completionPercentage !== 'number' || detailedProfile.overview.completionPercentage <= 0) {
    throw new Error(`Expected positive completion percentage, got: ${detailedProfile.overview.completionPercentage}`);
  }
  if (detailedProfile.fieldPolicies.rollNumber !== 'LOCKED') {
    throw new Error(`Expected rollNumber=LOCKED, got: ${detailedProfile.fieldPolicies.rollNumber}`);
  }
  if (detailedProfile.fieldPolicies.fatherName !== 'APPROVAL_REQUIRED') {
    throw new Error(`Expected fatherName=APPROVAL_REQUIRED, got: ${detailedProfile.fieldPolicies.fatherName}`);
  }
  if (detailedProfile.fieldPolicies.bio !== 'EDITABLE') {
    throw new Error(`Expected bio=EDITABLE, got: ${detailedProfile.fieldPolicies.bio}`);
  }

  console.log('✓ PASS: Profile completion and strict field permission policy validated');

  // -------------------------------------------------------------------------
  // TEST 9: Student Submits Profile Change Request
  // -------------------------------------------------------------------------
  console.log('\n--- TEST 9: Student Submits Change Request ---');
  const changeReq = await profileService.createProfileChangeRequest(studentDb.id, college.id, {
    category: 'PERSONAL_CHANGE',
    field: 'father_name',
    requestedValue: 'Mushtaq M. Ahmed',
    reason: 'Middle initial update as per passport',
  });
  console.log('Change request created:', changeReq);

  // PostgreSQL assertion
  const reqDb = await prisma.profileChangeRequest.findUnique({
    where: { id: changeReq.id },
  });
  if (!reqDb) throw new Error('Change request was not created in PostgreSQL!');
  if (reqDb.status !== 'PENDING') throw new Error(`Expected PENDING, got: ${reqDb.status}`);
  if (reqDb.current_value !== 'Mushtaq Ahmed') throw new Error(`Expected current Mushtaq Ahmed, got: ${reqDb.current_value}`);
  if (reqDb.requested_value !== 'Mushtaq M. Ahmed') throw new Error(`Expected requested Mushtaq M. Ahmed, got: ${reqDb.requested_value}`);

  console.log('✓ PASS: ProfileChangeRequest recorded in PostgreSQL with status PENDING');

  // -------------------------------------------------------------------------
  // TEST 10: Duplicate Pending Prevention
  // -------------------------------------------------------------------------
  console.log('\n--- TEST 10: Duplicate Pending Prevention ---');
  let duplicateRejected = false;
  try {
    await profileService.createProfileChangeRequest(studentDb.id, college.id, {
      category: 'PERSONAL_CHANGE',
      field: 'father_name',
      requestedValue: 'Mushtaq Different',
      reason: 'Second change',
    });
  } catch (err: any) {
    duplicateRejected = true;
    console.log(`Duplicate properly rejected with message: "${err.message}"`);
  }
  if (!duplicateRejected) throw new Error('Duplicate change request on the same pending field must be rejected!');
  console.log('✓ PASS: Duplicate pending change request rejected');

  // -------------------------------------------------------------------------
  // TEST 11: Admin Approves Profile Change Request
  // -------------------------------------------------------------------------
  console.log('\n--- TEST 11: Admin Approves Profile Change Request ---');
  const adminReqList = await adminService.getChangeRequests(college.id, { status: 'PENDING' }, adminActor);
  console.log(`Admin pending requests count: ${adminReqList.total}`);

  const foundReq = adminReqList.items.find((r) => r.id === changeReq.id);
  if (!foundReq) throw new Error('Student change request not found in Admin list!');

  const approveResult = await adminService.approveChangeRequest(
    college.id,
    changeReq.id,
    'Verified with government identification document',
    adminActor,
  );
  console.log('Admin approved change request:', approveResult.id);

  // Verify in PostgreSQL:
  // 1. Request status = APPROVED
  const approvedReqDb = await prisma.profileChangeRequest.findUnique({ where: { id: changeReq.id } });
  if (approvedReqDb?.status !== 'APPROVED') {
    throw new Error(`Expected request status APPROVED, got: ${approvedReqDb?.status}`);
  }

  // 2. Canonical StudentProfile.father_name immediately updated in DB!
  const updatedProfile = await prisma.studentProfile.findUnique({ where: { user_id: studentDb.id } });
  if (updatedProfile?.father_name !== 'Mushtaq M. Ahmed') {
    throw new Error(`Canonical father_name was NOT updated in DB! Got: ${updatedProfile?.father_name}`);
  }

  // 3. AuditLog written
  const auditLog = await prisma.auditLog.findFirst({
    where: {
      entity_type: 'ProfileChangeRequest',
      entity_id: changeReq.id,
      action: 'PROFILE_CHANGE_APPROVED',
    },
  });
  if (!auditLog) throw new Error('AuditLog for PROFILE_CHANGE_APPROVED was not written in PostgreSQL!');

  // 4. Notification delivered to student
  const studentNotification = await prisma.notification.findFirst({
    where: {
      user_id: studentDb.id,
      title: 'Profile Change Approved',
    },
  });
  if (!studentNotification) throw new Error('Notification for student was not written to PostgreSQL!');

  console.log('✓ PASS: Profile change approved! Canonical PostgreSQL record updated, AuditLog and Notification created.');

  // -------------------------------------------------------------------------
  // TEST 12: Student Submits Phone Change Request and Admin Rejects
  // -------------------------------------------------------------------------
  console.log('\n--- TEST 12: Phone Change Request & Admin Rejection ---');
  const phoneReq = await profileService.createProfileChangeRequest(studentDb.id, college.id, {
    category: 'PERSONAL_CHANGE',
    field: 'phone',
    requestedValue: '+919999999999',
    reason: 'Lost old SIM card',
  });

  const rejectResult = await adminService.rejectChangeRequest(
    college.id,
    phoneReq.id,
    'Proof of new SIM card was blurry and unreadable',
    adminActor,
  );
  console.log('Admin rejected change request:', rejectResult.id);

  // PostgreSQL assertions:
  // 1. Request status = REJECTED
  const rejectedReqDb = await prisma.profileChangeRequest.findUnique({ where: { id: phoneReq.id } });
  if (rejectedReqDb?.status !== 'REJECTED') {
    throw new Error(`Expected request status REJECTED, got: ${rejectedReqDb?.status}`);
  }

  // 2. Canonical User.phone remains unchanged (+919876543210)
  const unchangedUser = await prisma.user.findUnique({ where: { id: studentDb.id } });
  if (unchangedUser?.phone !== '+919876543210') {
    throw new Error(`Canonical phone was unexpectedly altered! Got: ${unchangedUser?.phone}`);
  }

  // 3. AuditLog written for rejection
  const rejectAuditLog = await prisma.auditLog.findFirst({
    where: {
      entity_type: 'ProfileChangeRequest',
      entity_id: phoneReq.id,
      action: 'PROFILE_CHANGE_REJECTED',
    },
  });
  if (!rejectAuditLog) throw new Error('AuditLog for PROFILE_CHANGE_REJECTED was not found!');

  // 4. Notification delivered with rejection reason
  const rejectionNotification = await prisma.notification.findFirst({
    where: {
      user_id: studentDb.id,
      title: 'Profile Change Rejected',
    },
  });
  if (!rejectionNotification || !rejectionNotification.body.includes('Proof of new SIM card was blurry')) {
    throw new Error('Rejection notification was not properly recorded for student!');
  }

  console.log('✓ PASS: Profile change rejected! Canonical DB phone unchanged, Rejection AuditLog and Student Notification created.');

  // -------------------------------------------------------------------------
  // CLEANUP
  // -------------------------------------------------------------------------
  console.log('\n--- CLEANUP ---');
  await prisma.profileChangeRequest.deleteMany({ where: { student_id: studentDb.id } });
  await prisma.studentProfile.deleteMany({ where: { user_id: studentDb.id } });
  await prisma.studentAcademicProfile.deleteMany({ where: { student_id: studentDb.id } });
  await prisma.notification.deleteMany({ where: { user_id: studentDb.id } });
  await prisma.auditLog.deleteMany({
    where: {
      OR: [
        { entity_id: changeReq.id },
        { entity_id: phoneReq.id },
        { entity_id: studentDb.id },
      ],
    },
  });
  await prisma.user.delete({ where: { id: studentDb.id } });
  console.log('✓ Cleaned up test student, profiles, requests, and notifications.');

  console.log('\n========================================================================');
  console.log('ALL 12 REAL DATABASE WORKFLOWS VERIFIED 100% IN POSTGRESQL SUCCESSFULLY!');
  console.log('========================================================================');
}

main()
  .catch((e) => {
    console.error('\n❌ VERIFICATION FAILED:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
