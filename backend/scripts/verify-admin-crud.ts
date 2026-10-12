import { prisma } from '../src/infrastructure/prisma/prisma.service';
import { AdminService } from '../src/modules/admin/admin.service';
import { AdminRepository } from '../src/modules/admin/admin.repository';
import { Role, UserStatus } from '@prisma/client';
import * as argon2 from 'argon2';

async function main() {
  console.log('========================================================================');
  console.log('VERIFYING REAL DATABASE CRUD FOR USERS AND DEPARTMENTS');
  console.log('========================================================================\n');

  const adminRepo = new AdminRepository();
  const adminService = new AdminService(adminRepo);

  const college = await prisma.college.findFirst();
  if (!college) throw new Error('College not found');

  const adminUser = await prisma.user.findFirst({ where: { role: { in: [Role.ADMIN, Role.COLLEGE_ADMIN] } } });
  if (!adminUser) throw new Error('Admin user not found');

  const actor = {
    actorUserId: adminUser.id,
    actorRole: adminUser.role,
    actorCollegeId: college.id,
    actorDeptId: adminUser.department_id || undefined,
  };

  // 1. TEST DEPARTMENT CREATION, EDIT, AND DELETION
  console.log('--- TEST 1: Department Create, Edit & Delete ---');
  const testDeptCode = 'TEMP_TEST_DEPT';
  const createdDept = await adminService.createDepartment(college.id, {
    name: 'Temporary Test Department',
    code: testDeptCode,
    description: 'Will be edited then deleted',
  }, actor);

  console.log(`Created Dept: ${createdDept.name} (${createdDept.id})`);

  // Verify in PostgreSQL
  const deptInDb = await prisma.department.findUnique({ where: { id: createdDept.id } });
  if (!deptInDb) throw new Error('Dept not found in DB!');

  // Edit Department
  const updatedDept = await adminService.updateDepartment(college.id, createdDept.id, {
    name: 'Updated Test Department Name',
    code: 'TEMP_EDITED',
    description: 'Updated Description',
    isActive: true,
  }, actor);
  console.log(`Updated Dept: ${updatedDept.name} (${updatedDept.code})`);

  if (updatedDept.name !== 'Updated Test Department Name' || updatedDept.code !== 'TEMP_EDITED') {
    throw new Error('Department update did not mutate fields correctly!');
  }

  // Delete Department
  await adminService.deleteDepartment(college.id, createdDept.id, actor);
  console.log(`Deleted Dept: ${createdDept.id}`);

  // Assert deleted from DB
  const deptAfterDelete = await prisma.department.findUnique({ where: { id: createdDept.id } });
  if (deptAfterDelete) throw new Error('Department was NOT deleted from DB!');
  console.log('✓ PASS: Department created, edited, and deleted successfully!');

  // 2. TEST USER CREATION, EDIT, AND DELETION
  console.log('\n--- TEST 2: User Create, Edit & Delete ---');
  const testUserEmail = 'temp_crud_test_user@campushub.edu';
  const createdUser = await adminService.createUser(college.id, {
    email: testUserEmail,
    role: Role.STUDENT,
    batchName: '2025-2029',
    rollNumber: 'TEMP999',
  }, actor);

  console.log(`Created User: ${createdUser.email} (${createdUser.id})`);

  // Edit User
  const updatedUser = await adminService.updateUser(college.id, createdUser.id, {
    firstName: 'EditedFirst',
    lastName: 'EditedLast',
    phone: '+919876500000',
  }, actor);
  console.log(`Updated User: ${updatedUser.first_name} ${updatedUser.last_name}`);

  if (updatedUser.first_name !== 'EditedFirst' || updatedUser.last_name !== 'EditedLast') {
    throw new Error('User update did not mutate fields correctly!');
  }

  // Self-delete prevention
  let selfDeleteBlocked = false;
  try {
    await adminService.deleteUser(college.id, adminUser.id, actor);
  } catch (e: any) {
    selfDeleteBlocked = true;
    console.log(`Self-delete properly blocked: "${e.message}"`);
  }
  if (!selfDeleteBlocked) throw new Error('Admin should not be able to delete their own account!');

  // Delete User
  await adminService.deleteUser(college.id, createdUser.id, actor);
  console.log(`Deleted User: ${createdUser.id}`);

  // Assert deleted from DB
  const userAfterDelete = await prisma.user.findUnique({ where: { id: createdUser.id } });
  if (userAfterDelete) throw new Error('User was NOT deleted from DB!');
  console.log('✓ PASS: User created, edited, self-deletion guarded, and permanently deleted successfully!');

  console.log('\n========================================================================');
  console.log('ALL CRUD (EDIT/DELETE) REAL DB WORKFLOWS VERIFIED 100%!');
  console.log('========================================================================');
}

main()
  .catch((e) => {
    console.error('\n❌ FAILED:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
