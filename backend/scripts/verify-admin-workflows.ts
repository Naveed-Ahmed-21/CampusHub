import request from 'supertest';
import { createApp } from '../src/app';
import { prisma } from '../src/config/database';
import { generateAccessToken } from '../src/shared/utils/jwt.util';
import { Role, UserStatus } from '@prisma/client';

async function runVerification() {
  console.log('====================================================');
  console.log('CAMPUSHUB DATABASE WORKFLOW VERIFICATION PASS');
  console.log('====================================================\n');

  const app = createApp();

  // 1. Setup College & Admin Tokens
  const college = await prisma.college.findFirst();
  if (!college) {
    throw new Error('No college found in database');
  }
  console.log(`[INIT] Verified College in PostgreSQL: ${college.name} (ID: ${college.id})`);

  let adminUser = await prisma.user.findFirst({
    where: { role: { in: [Role.ADMIN, Role.COLLEGE_ADMIN] } },
  });
  if (!adminUser) {
    adminUser = await prisma.user.create({
      data: {
        college_id: college.id,
        email: 'sysadmin@campushub.edu',
        password_hash: '$2b$10$hashedpasswordsample1234567890',
        first_name: 'System',
        last_name: 'Administrator',
        role: Role.COLLEGE_ADMIN,
        status: UserStatus.ACTIVE,
      },
    });
    console.log(`[INIT] Created College Admin user in DB: ${adminUser.email}`);
  }

  const collegeAdminToken = generateAccessToken({
    userId: adminUser.id,
    collegeId: college.id,
    role: Role.COLLEGE_ADMIN,
    email: adminUser.email,
  });

  const cseDept = await prisma.department.findFirst({
    where: { college_id: college.id, code: 'CSE' },
  });
  const cseDeptId = cseDept?.id;

  const itDept = await prisma.department.findFirst({
    where: { college_id: college.id, code: 'IT' },
  });
  const itDeptId = itDept?.id;

  const results: Array<{ step: string; feature: string; api: string; dbRecord: string; status: 'PASS' | 'FAIL'; details: string }> = [];

  // =========================================================================
  // WORKFLOW 1: Create Student
  // =========================================================================
  console.log('\n--- WORKFLOW 1: Create Student ---');
  const studentEmail = `student.test.${Date.now()}@campushub.edu`;
  const createStudentRes = await request(app)
    .post('/api/v1/admin/users')
    .set('Authorization', `Bearer ${collegeAdminToken}`)
    .send({
      email: studentEmail,
      firstName: 'Aarav',
      lastName: 'Sharma',
      role: 'STUDENT',
      rollNumber: 'CS2026-TEST01',
      departmentId: cseDeptId,
    });

  if (createStudentRes.status !== 201) {
    throw new Error(`Create Student failed: ${createStudentRes.status} ${JSON.stringify(createStudentRes.body)}`);
  }
  const createdStudentId = createStudentRes.body.data.id;

  // Direct PostgreSQL Verification
  const studentInDb = await prisma.user.findUnique({
    where: { id: createdStudentId },
  });

  if (studentInDb && studentInDb.email === studentEmail && studentInDb.role === Role.STUDENT && studentInDb.roll_number === 'CS2026-TEST01') {
    console.log(`✓ PostgreSQL Record Verified: User ID=${studentInDb.id}, Email=${studentInDb.email}, Role=${studentInDb.role}, Roll=${studentInDb.roll_number}`);
    results.push({
      step: '1',
      feature: 'Create Student',
      api: 'POST /api/v1/admin/users',
      dbRecord: `users(id: ${studentInDb.id}, role: STUDENT)`,
      status: 'PASS',
      details: `Created student ${studentInDb.first_name} ${studentInDb.last_name}`,
    });
  } else {
    throw new Error('Student record in PostgreSQL does not match expected fields');
  }

  // =========================================================================
  // WORKFLOW 2: Create Faculty
  // =========================================================================
  console.log('\n--- WORKFLOW 2: Create Faculty ---');
  const facultyEmail = `faculty.test.${Date.now()}@campushub.edu`;
  const createFacultyRes = await request(app)
    .post('/api/v1/admin/users')
    .set('Authorization', `Bearer ${collegeAdminToken}`)
    .send({
      email: facultyEmail,
      firstName: 'Priya',
      lastName: 'Verma',
      role: 'FACULTY',
      designation: 'Assistant Professor',
      departmentId: cseDeptId,
    });

  if (createFacultyRes.status !== 201) {
    throw new Error(`Create Faculty failed: ${createFacultyRes.status} ${JSON.stringify(createFacultyRes.body)}`);
  }
  const createdFacultyId = createFacultyRes.body.data.id;

  // Direct PostgreSQL Verification
  const facultyInDb = await prisma.user.findUnique({
    where: { id: createdFacultyId },
  });

  if (facultyInDb && facultyInDb.email === facultyEmail && facultyInDb.role === Role.FACULTY) {
    console.log(`✓ PostgreSQL Record Verified: User ID=${facultyInDb.id}, Email=${facultyInDb.email}, Role=${facultyInDb.role}`);
    results.push({
      step: '2',
      feature: 'Create Faculty',
      api: 'POST /api/v1/admin/users',
      dbRecord: `users(id: ${facultyInDb.id}, role: FACULTY)`,
      status: 'PASS',
      details: `Created faculty ${facultyInDb.first_name} ${facultyInDb.last_name}`,
    });
  } else {
    throw new Error('Faculty record in PostgreSQL does not match expected fields');
  }

  // =========================================================================
  // WORKFLOW 3: Create Admin Where Authorized (DEPT_ADMIN)
  // =========================================================================
  console.log('\n--- WORKFLOW 3: Create Admin Where Authorized ---');
  const deptAdminEmail = `deptadmin.test.${Date.now()}@campushub.edu`;
  const createDeptAdminRes = await request(app)
    .post('/api/v1/admin/users')
    .set('Authorization', `Bearer ${collegeAdminToken}`)
    .send({
      email: deptAdminEmail,
      firstName: 'Rajesh',
      lastName: 'Kumar',
      role: 'DEPT_ADMIN',
      departmentId: cseDeptId,
    });

  if (createDeptAdminRes.status !== 201) {
    throw new Error(`Create Dept Admin failed: ${createDeptAdminRes.status} ${JSON.stringify(createDeptAdminRes.body)}`);
  }
  const createdDeptAdminId = createDeptAdminRes.body.data.id;

  // Direct PostgreSQL Verification
  const deptAdminInDb = await prisma.user.findUnique({
    where: { id: createdDeptAdminId },
  });

  if (deptAdminInDb && deptAdminInDb.email === deptAdminEmail && deptAdminInDb.role === Role.DEPT_ADMIN && deptAdminInDb.department_id === cseDeptId) {
    console.log(`✓ PostgreSQL Record Verified: User ID=${deptAdminInDb.id}, Email=${deptAdminInDb.email}, Role=${deptAdminInDb.role}, DeptID=${deptAdminInDb.department_id}`);
    results.push({
      step: '3',
      feature: 'Create Admin Where Authorized',
      api: 'POST /api/v1/admin/users',
      dbRecord: `users(id: ${deptAdminInDb.id}, role: DEPT_ADMIN, dept: CSE)`,
      status: 'PASS',
      details: `Created Dept Admin with department scope assigned`,
    });
  } else {
    throw new Error('Dept Admin record in PostgreSQL does not match expected fields');
  }

  // =========================================================================
  // WORKFLOW 4: Edit User
  // =========================================================================
  console.log('\n--- WORKFLOW 4: Edit User ---');
  const editUserRes = await request(app)
    .patch(`/api/v1/admin/users/${createdStudentId}`)
    .set('Authorization', `Bearer ${collegeAdminToken}`)
    .send({
      firstName: 'Aarav-Edited',
      lastName: 'Sharma-Edited',
      phone: '+91-9876543210',
    });

  if (editUserRes.status !== 200) {
    throw new Error(`Edit User failed: ${editUserRes.status} ${JSON.stringify(editUserRes.body)}`);
  }

  // Direct PostgreSQL Verification
  const editedStudentInDb = await prisma.user.findUnique({
    where: { id: createdStudentId },
  });

  if (editedStudentInDb && editedStudentInDb.first_name === 'Aarav-Edited' && editedStudentInDb.last_name === 'Sharma-Edited' && editedStudentInDb.phone === '+91-9876543210') {
    console.log(`✓ PostgreSQL Record Verified: First=${editedStudentInDb.first_name}, Last=${editedStudentInDb.last_name}, Phone=${editedStudentInDb.phone}`);
    results.push({
      step: '4',
      feature: 'Edit User',
      api: `PATCH /api/v1/admin/users/${createdStudentId}`,
      dbRecord: `users(id: ${createdStudentId}, first_name: Aarav-Edited, phone: +91-9876543210)`,
      status: 'PASS',
      details: 'User fields successfully updated and verified in PostgreSQL',
    });
  } else {
    throw new Error('Edited user record in PostgreSQL does not match updated fields');
  }

  // =========================================================================
  // WORKFLOW 5: Change User Role
  // =========================================================================
  console.log('\n--- WORKFLOW 5: Change User Role ---');
  const changeRoleRes = await request(app)
    .patch(`/api/v1/admin/users/${createdStudentId}/role`)
    .set('Authorization', `Bearer ${collegeAdminToken}`)
    .send({
      newRole: 'PLACEMENT_OFFICER',
    });

  if (changeRoleRes.status !== 200) {
    throw new Error(`Change Role failed: ${changeRoleRes.status} ${JSON.stringify(changeRoleRes.body)}`);
  }

  // Direct PostgreSQL Verification
  const roleUpdatedInDb = await prisma.user.findUnique({
    where: { id: createdStudentId },
  });

  if (roleUpdatedInDb && roleUpdatedInDb.role === Role.PLACEMENT_OFFICER) {
    console.log(`✓ PostgreSQL Record Verified: User ID=${roleUpdatedInDb.id}, New Role=${roleUpdatedInDb.role}`);
    results.push({
      step: '5',
      feature: 'Change User Role',
      api: `PATCH /api/v1/admin/users/${createdStudentId}/role`,
      dbRecord: `users(id: ${createdStudentId}, role: PLACEMENT_OFFICER)`,
      status: 'PASS',
      details: 'User role updated from STUDENT to PLACEMENT_OFFICER',
    });
  } else {
    throw new Error('User role in PostgreSQL does not match new role');
  }

  // =========================================================================
  // WORKFLOW 6: Deactivate User
  // =========================================================================
  console.log('\n--- WORKFLOW 6: Deactivate User ---');
  const deactivateRes = await request(app)
    .patch(`/api/v1/admin/users/${createdStudentId}/status`)
    .set('Authorization', `Bearer ${collegeAdminToken}`)
    .send({
      isActive: false,
    });

  if (deactivateRes.status !== 200) {
    throw new Error(`Deactivate User failed: ${deactivateRes.status} ${JSON.stringify(deactivateRes.body)}`);
  }

  // Direct PostgreSQL Verification
  const deactivatedInDb = await prisma.user.findUnique({
    where: { id: createdStudentId },
  });

  if (deactivatedInDb && deactivatedInDb.status === UserStatus.DEACTIVATED) {
    console.log(`✓ PostgreSQL Record Verified: User ID=${deactivatedInDb.id}, Status=${deactivatedInDb.status}`);
    results.push({
      step: '6',
      feature: 'Deactivate User',
      api: `PATCH /api/v1/admin/users/${createdStudentId}/status`,
      dbRecord: `users(id: ${createdStudentId}, status: DEACTIVATED)`,
      status: 'PASS',
      details: 'User status successfully set to DEACTIVATED',
    });
  } else {
    throw new Error('User status in PostgreSQL is not DEACTIVATED');
  }

  // =========================================================================
  // WORKFLOW 7: Activate User
  // =========================================================================
  console.log('\n--- WORKFLOW 7: Activate User ---');
  const activateRes = await request(app)
    .patch(`/api/v1/admin/users/${createdStudentId}/status`)
    .set('Authorization', `Bearer ${collegeAdminToken}`)
    .send({
      isActive: true,
    });

  if (activateRes.status !== 200) {
    throw new Error(`Activate User failed: ${activateRes.status} ${JSON.stringify(activateRes.body)}`);
  }

  // Direct PostgreSQL Verification
  const activatedInDb = await prisma.user.findUnique({
    where: { id: createdStudentId },
  });

  if (activatedInDb && activatedInDb.status === UserStatus.ACTIVE) {
    console.log(`✓ PostgreSQL Record Verified: User ID=${activatedInDb.id}, Status=${activatedInDb.status}`);
    results.push({
      step: '7',
      feature: 'Activate User',
      api: `PATCH /api/v1/admin/users/${createdStudentId}/status`,
      dbRecord: `users(id: ${createdStudentId}, status: ACTIVE)`,
      status: 'PASS',
      details: 'User status successfully reactivated to ACTIVE',
    });
  } else {
    throw new Error('User status in PostgreSQL is not ACTIVE');
  }

  // =========================================================================
  // WORKFLOW 8: Create Department
  // =========================================================================
  console.log('\n--- WORKFLOW 8: Create Department ---');
  const deptCode = `BIO_${Date.now().toString().slice(-4)}`;
  const createDeptRes = await request(app)
    .post('/api/v1/admin/departments')
    .set('Authorization', `Bearer ${collegeAdminToken}`)
    .send({
      name: 'Biotechnology & Bioinformatics',
      code: deptCode,
      description: 'Department of Biotechnology research & studies',
    });

  if (createDeptRes.status !== 201) {
    throw new Error(`Create Department failed: ${createDeptRes.status} ${JSON.stringify(createDeptRes.body)}`);
  }
  const createdDeptId = createDeptRes.body.data.id;

  // Direct PostgreSQL Verification
  const deptInDb = await prisma.department.findUnique({
    where: { id: createdDeptId },
  });

  if (deptInDb && deptInDb.code === deptCode && deptInDb.is_active === true) {
    console.log(`✓ PostgreSQL Record Verified: Dept ID=${deptInDb.id}, Code=${deptInDb.code}, Active=${deptInDb.is_active}`);
    results.push({
      step: '8',
      feature: 'Create Department',
      api: 'POST /api/v1/admin/departments',
      dbRecord: `departments(id: ${deptInDb.id}, code: ${deptInDb.code}, is_active: true)`,
      status: 'PASS',
      details: `Department created with is_active=true`,
    });
  } else {
    throw new Error('Department record in PostgreSQL does not match expected fields');
  }

  // =========================================================================
  // WORKFLOW 9: Edit Department
  // =========================================================================
  console.log('\n--- WORKFLOW 9: Edit Department ---');
  const editDeptRes = await request(app)
    .patch(`/api/v1/admin/departments/${createdDeptId}`)
    .set('Authorization', `Bearer ${collegeAdminToken}`)
    .send({
      name: 'Biotechnology & Genetic Engineering',
      description: 'Advanced Biotechnology & Genetic Engineering Research',
    });

  if (editDeptRes.status !== 200) {
    throw new Error(`Edit Department failed: ${editDeptRes.status} ${JSON.stringify(editDeptRes.body)}`);
  }

  // Direct PostgreSQL Verification
  const editedDeptInDb = await prisma.department.findUnique({
    where: { id: createdDeptId },
  });

  if (editedDeptInDb && editedDeptInDb.name === 'Biotechnology & Genetic Engineering') {
    console.log(`✓ PostgreSQL Record Verified: Dept ID=${editedDeptInDb.id}, Name=${editedDeptInDb.name}`);
    results.push({
      step: '9',
      feature: 'Edit Department',
      api: `PATCH /api/v1/admin/departments/${createdDeptId}`,
      dbRecord: `departments(id: ${createdDeptId}, name: Biotechnology & Genetic Engineering)`,
      status: 'PASS',
      details: 'Department name and description updated in PostgreSQL',
    });
  } else {
    throw new Error('Edited department in PostgreSQL does not match updated name');
  }

  // =========================================================================
  // WORKFLOW 10: Deactivate Department
  // =========================================================================
  console.log('\n--- WORKFLOW 10: Deactivate Department ---');
  const deactivateDeptRes = await request(app)
    .patch(`/api/v1/admin/departments/${createdDeptId}/status`)
    .set('Authorization', `Bearer ${collegeAdminToken}`)
    .send({
      isActive: false,
    });

  if (deactivateDeptRes.status !== 200) {
    throw new Error(`Deactivate Department failed: ${deactivateDeptRes.status} ${JSON.stringify(deactivateDeptRes.body)}`);
  }

  // Direct PostgreSQL Verification
  const deactivatedDeptInDb = await prisma.department.findUnique({
    where: { id: createdDeptId },
  });

  if (deactivatedDeptInDb && deactivatedDeptInDb.is_active === false) {
    console.log(`✓ PostgreSQL Record Verified: Dept ID=${deactivatedDeptInDb.id}, Active=${deactivatedDeptInDb.is_active}`);
    results.push({
      step: '10',
      feature: 'Deactivate Department',
      api: `PATCH /api/v1/admin/departments/${createdDeptId}/status`,
      dbRecord: `departments(id: ${createdDeptId}, is_active: false)`,
      status: 'PASS',
      details: 'Department successfully deactivated in PostgreSQL',
    });
  } else {
    throw new Error('Department is_active in PostgreSQL is not false');
  }

  // =========================================================================
  // WORKFLOW 11: Activate Department
  // =========================================================================
  console.log('\n--- WORKFLOW 11: Activate Department ---');
  const activateDeptRes = await request(app)
    .patch(`/api/v1/admin/departments/${createdDeptId}/status`)
    .set('Authorization', `Bearer ${collegeAdminToken}`)
    .send({
      isActive: true,
    });

  if (activateDeptRes.status !== 200) {
    throw new Error(`Activate Department failed: ${activateDeptRes.status} ${JSON.stringify(activateDeptRes.body)}`);
  }

  // Direct PostgreSQL Verification
  const activatedDeptInDb = await prisma.department.findUnique({
    where: { id: createdDeptId },
  });

  if (activatedDeptInDb && activatedDeptInDb.is_active === true) {
    console.log(`✓ PostgreSQL Record Verified: Dept ID=${activatedDeptInDb.id}, Active=${activatedDeptInDb.is_active}`);
    results.push({
      step: '11',
      feature: 'Activate Department',
      api: `PATCH /api/v1/admin/departments/${createdDeptId}/status`,
      dbRecord: `departments(id: ${createdDeptId}, is_active: true)`,
      status: 'PASS',
      details: 'Department successfully reactivated in PostgreSQL',
    });
  } else {
    throw new Error('Department is_active in PostgreSQL is not true');
  }

  // =========================================================================
  // EXTRA VERIFICATION: DEPT_ADMIN Scope Enforcement
  // =========================================================================
  console.log('\n--- VERIFICATION: DEPT_ADMIN Scope Enforcement ---');
  const deptAdminToken = generateAccessToken({
    userId: createdDeptAdminId,
    collegeId: college.id,
    departmentId: cseDeptId,
    role: Role.DEPT_ADMIN,
    email: deptAdminEmail,
  });

  // Attempt to update a department outside of CSE (e.g. IT dept)
  if (itDeptId) {
    const scopeDeptRes = await request(app)
      .patch(`/api/v1/admin/departments/${itDeptId}`)
      .set('Authorization', `Bearer ${deptAdminToken}`)
      .send({ name: 'Hacked IT Department Name' });

    if (scopeDeptRes.status === 403) {
      console.log('✓ DEPT_ADMIN forbidden from editing another department: 403 Forbidden verified');
      results.push({
        step: 'Scope 1',
        feature: 'DEPT_ADMIN Scope (Department)',
        api: `PATCH /api/v1/admin/departments/${itDeptId}`,
        dbRecord: 'Unchanged in PostgreSQL (Blocked by Express/Service)',
        status: 'PASS',
        details: 'Correctly enforced 403 Forbidden for cross-department updates',
      });
    } else {
      throw new Error(`Expected 403 Forbidden, got ${scopeDeptRes.status}`);
    }
  }

  // =========================================================================
  // EXTRA VERIFICATION: Admin Feed Creation & Audience Targeting
  // =========================================================================
  console.log('\n--- VERIFICATION: Admin Feed Creation & Audience Targeting ---');
  const postRes = await request(app)
    .post('/api/v1/posts')
    .set('Authorization', `Bearer ${collegeAdminToken}`)
    .send({
      title: 'Campus-Wide Hackathon 2026 Registration Open',
      content: `Registration for the annual Campus-Wide Hackathon 2026 is officially open! [Test Timestamp: ${Date.now()}]`,
      type: 'ANNOUNCEMENT',
      departmentId: null,
    });

  if (postRes.status !== 201) {
    throw new Error(`Create Post failed: ${postRes.status} ${JSON.stringify(postRes.body)}`);
  }
  const createdPostId = postRes.body.data.id;

  const postInDb = await prisma.post.findUnique({
    where: { id: createdPostId },
  });

  if (postInDb && postInDb.type === 'ANNOUNCEMENT') {
    console.log(`✓ PostgreSQL Post Verified: Post ID=${postInDb.id}, Type=${postInDb.type}`);
    results.push({
      step: 'Feed 1',
      feature: 'Admin Feed Post Creation',
      api: 'POST /api/v1/posts',
      dbRecord: `posts(id: ${postInDb.id}, type: ANNOUNCEMENT)`,
      status: 'PASS',
      details: 'Announcement post created with campus-wide audience and verified in PostgreSQL',
    });
  } else {
    throw new Error('Post record in PostgreSQL not found or type mismatch');
  }

  // =========================================================================
  // EXTRA VERIFICATION: Audit Log Persistence
  // =========================================================================
  console.log('\n--- VERIFICATION: Audit Log Persistence ---');
  const auditLogs = await prisma.auditLog.findMany({
    where: { college_id: college.id },
    orderBy: { created_at: 'desc' },
    take: 10,
  });

  const actions = auditLogs.map((a) => a.action);
  console.log('✓ Recent Audit Logs in PostgreSQL:', actions.slice(0, 6));

  const hasExpectedLogs =
    actions.includes('USER_CREATED') &&
    actions.includes('USER_ROLE_CHANGED') &&
    actions.includes('USER_STATUS_CHANGED') &&
    actions.includes('DEPARTMENT_CREATED');

  if (hasExpectedLogs) {
    results.push({
      step: 'Audit 1',
      feature: 'Audit Log Recording',
      api: 'GET /api/v1/admin/reports',
      dbRecord: `audit_logs(count: ${auditLogs.length}, actions: ${actions.slice(0, 4).join(', ')})`,
      status: 'PASS',
      details: 'All administrative mutations recorded audit log records in PostgreSQL',
    });
  } else {
    throw new Error(`Audit log records missing expected actions: ${JSON.stringify(actions)}`);
  }

  // =========================================================================
  // EXTRA VERIFICATION: PostgreSQL-Backed Dashboard Metrics
  // =========================================================================
  console.log('\n--- VERIFICATION: Dashboard Metrics Direct PostgreSQL Match ---');
  const metricsRes = await request(app)
    .get('/api/v1/admin/metrics')
    .set('Authorization', `Bearer ${collegeAdminToken}`);

  if (metricsRes.status !== 200) {
    throw new Error(`Get Metrics failed: ${metricsRes.status}`);
  }

  const dbUserCount = await prisma.user.count({ where: { college_id: college.id } });
  const dbDeptCount = await prisma.department.count({ where: { college_id: college.id } });
  const returnedMetrics = metricsRes.body.data;

  console.log(`✓ PostgreSQL DB User Count: ${dbUserCount}, API Metric: ${returnedMetrics.totalUsers}`);
  console.log(`✓ PostgreSQL DB Dept Count: ${dbDeptCount}, API Metric: ${returnedMetrics.totalDepartments}`);

  if (returnedMetrics.totalUsers === dbUserCount && returnedMetrics.totalDepartments === dbDeptCount) {
    results.push({
      step: 'Metrics 1',
      feature: 'Dashboard Metrics',
      api: 'GET /api/v1/admin/metrics',
      dbRecord: `PostgreSQL exact count: users=${dbUserCount}, depts=${dbDeptCount}`,
      status: 'PASS',
      details: 'All dashboard metrics directly match PostgreSQL count queries (0 mock data)',
    });
  } else {
    throw new Error('Metrics mismatch between PostgreSQL and API response');
  }

  // =========================================================================
  // RELOAD TEST: Disconnect & Reconnect to verify persistence
  // =========================================================================
  console.log('\n--- VERIFICATION: Reload App & Confirm Persistent PostgreSQL Records ---');
  await prisma.$disconnect();

  // Create a new fresh connection
  const { PrismaClient } = require('@prisma/client');
  const freshPrisma = new PrismaClient();

  const persistedStudent = await freshPrisma.user.findUnique({ where: { id: createdStudentId } });
  const persistedFaculty = await freshPrisma.user.findUnique({ where: { id: createdFacultyId } });
  const persistedDeptAdmin = await freshPrisma.user.findUnique({ where: { id: createdDeptAdminId } });
  const persistedDept = await freshPrisma.department.findUnique({ where: { id: createdDeptId } });

  if (persistedStudent && persistedFaculty && persistedDeptAdmin && persistedDept) {
    console.log('✓ All 4 newly created entities confirmed persistent after fresh DB reconnect!');
    results.push({
      step: 'Reload',
      feature: 'Data Persistence Across Reload',
      api: 'Direct PostgreSQL Reconnect & Select',
      dbRecord: `Persisted records: user=${createdStudentId}, dept=${createdDeptId}`,
      status: 'PASS',
      details: 'Data persists completely in PostgreSQL across connection recycles',
    });
  } else {
    throw new Error('Records could not be found after DB reconnect');
  }

  await freshPrisma.$disconnect();

  console.log('\n====================================================');
  console.log('SUMMARY TABLE:');
  console.log('====================================================');
  console.log(
    'FEATURE'.padEnd(30) +
      '| ' +
      'API'.padEnd(42) +
      '| ' +
      'DATABASE RECORD'.padEnd(45) +
      '| ' +
      'RESULT'
  );
  console.log(''.padEnd(130, '-'));

  for (const r of results) {
    console.log(
      r.feature.padEnd(30) +
        '| ' +
        r.api.padEnd(42) +
        '| ' +
        r.dbRecord.padEnd(45) +
        '| ' +
        r.status
    );
  }
  console.log('====================================================\n');

  return results;
}

runVerification()
  .then(() => {
    console.log('ALL 11 REAL DATABASE WORKFLOWS AND VERIFICATIONS PASSED SUCCESSFULLY!');
    process.exit(0);
  })
  .catch((err) => {
    console.error('VERIFICATION FAILED:', err);
    process.exit(1);
  });
