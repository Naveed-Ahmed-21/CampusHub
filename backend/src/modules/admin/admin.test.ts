import { AdminService } from './admin.service';
import { AdminRepository } from './admin.repository';
import { Role, UserStatus } from '@prisma/client';
import { BadRequestError, ForbiddenError, NotFoundError, ConflictError } from '../../shared/errors/AppError';

describe('AdminService', () => {
  let adminService: AdminService;
  let adminRepository: jest.Mocked<AdminRepository>;

  beforeEach(() => {
    adminRepository = {
      getDashboardMetrics: jest.fn(),
      findUsers: jest.fn(),
      findUserById: jest.fn(),
      createUser: jest.fn(),
      updateUser: jest.fn(),
      updateUserRole: jest.fn(),
      updateUserStatus: jest.fn(),
      findDepartments: jest.fn(),
      findDepartmentById: jest.fn(),
      findDepartmentByCode: jest.fn(),
      createDepartment: jest.fn(),
      updateDepartment: jest.fn(),
      getAuditLogs: jest.fn(),
      createAuditLog: jest.fn(),
      findAcademicYears: jest.fn(),
      findAcademicYearById: jest.fn(),
      findAcademicYearByName: jest.fn(),
      createAcademicYear: jest.fn(),
      updateAcademicYear: jest.fn(),
      setActiveAcademicYear: jest.fn(),
      findAcademicTerms: jest.fn(),
      findAcademicTermById: jest.fn(),
      createAcademicTerm: jest.fn(),
      updateAcademicTerm: jest.fn(),
      findAcademicPrograms: jest.fn(),
      findAcademicProgramById: jest.fn(),
      findAcademicProgramByCode: jest.fn(),
      createAcademicProgram: jest.fn(),
      updateAcademicProgram: jest.fn(),
      findBatches: jest.fn(),
      findBatchById: jest.fn(),
      findBatchByName: jest.fn(),
      createBatch: jest.fn(),
      updateBatch: jest.fn(),
      findSubjects: jest.fn(),
      findSubjectById: jest.fn(),
      findSubjectByCodeAndSection: jest.fn(),
      createSubject: jest.fn(),
      updateSubject: jest.fn(),
      findCurriculumSubjects: jest.fn(),
      createCurriculumSubject: jest.fn(),
      deleteCurriculumSubject: jest.fn(),
      findAcademicClasses: jest.fn(),
      findAcademicClassById: jest.fn(),
      createAcademicClass: jest.fn(),
      updateAcademicClass: jest.fn(),
      findRooms: jest.fn(),
      findRoomById: jest.fn(),
      findRoomByCode: jest.fn(),
      createRoom: jest.fn(),
      updateRoom: jest.fn(),
      findFacultyAssignments: jest.fn(),
      findFacultyAssignmentById: jest.fn(),
      findFacultyAssignmentUnique: jest.fn(),
      createFacultyAssignment: jest.fn(),
      deleteFacultyAssignment: jest.fn(),
      findSchedules: jest.fn(),
      findScheduleById: jest.fn(),
      findPotentialConflicts: jest.fn(),
      createSchedule: jest.fn(),
      updateSchedule: jest.fn(),
      deleteSchedule: jest.fn(),
      getMonitoringMetrics: jest.fn(),
      findAttendanceSessions: jest.fn(),
      findAttendanceSessionById: jest.fn(),
      findSubjectAssignments: jest.fn(),
      findSubjectAssignmentById: jest.fn(),
      findSubjectAssessments: jest.fn(),
      findSubjectAssessmentById: jest.fn(),
      findTargetUserIds: jest.fn(),
      createBroadcastNotifications: jest.fn(),
      findModerationEvents: jest.fn(),
      findModerationEventById: jest.fn(),
      deleteModerationEvent: jest.fn(),
      findModerationPosts: jest.fn(),
      findModerationPostById: jest.fn(),
      deleteModerationPost: jest.fn(),
      findCollegeById: jest.fn(),
      updateCollege: jest.fn(),
    } as unknown as jest.Mocked<AdminRepository>;

    adminService = new AdminService(adminRepository);
  });

  describe('getDashboardMetrics', () => {
    it('should return metrics from repository', async () => {
      const mockMetrics = {
        totalUsers: 100,
        totalDepartments: 5,
        approvedClubs: 10,
        pendingClubs: 2,
        totalEvents: 15,
        totalDrives: 8,
        placedCount: 40,
      };

      adminRepository.getDashboardMetrics.mockResolvedValue(mockMetrics);

      const result = await adminService.getDashboardMetrics('clg_1');
      expect(result.totalUsers).toBe(100);
      expect(result.approvedClubs).toBe(10);
    });

    it('should throw an error if repository throws', async () => {
      adminRepository.getDashboardMetrics.mockRejectedValue(new Error('DB offline'));

      await expect(adminService.getDashboardMetrics('clg_1')).rejects.toThrow('DB offline');
    });
  });

  describe('getUserById', () => {
    it('should return user if found', async () => {
      adminRepository.findUserById.mockResolvedValue({
        id: 'usr_1',
        first_name: 'Jane',
        department_id: 'dept_1',
      } as any);

      const result = await adminService.getUserById('usr_1');
      expect(result.id).toBe('usr_1');
    });

    it('should throw NotFoundError if user does not exist', async () => {
      adminRepository.findUserById.mockResolvedValue(null);

      await expect(adminService.getUserById('usr_unknown')).rejects.toThrow(NotFoundError);
    });

    it('should throw NotFoundError if user does not exist', async () => {
      adminRepository.findUserById.mockResolvedValue(null);

      await expect(
        adminService.getUserById('usr_missing')
      ).rejects.toThrow(NotFoundError);
    });
  });

  describe('setTemporaryPassword', () => {
    it('should allow setting temporary password for FACULTY', async () => {
      adminRepository.findUserById.mockResolvedValue({
        id: 'usr_fac',
        email: 'faculty@gcee.ac.in',
        first_name: 'Dr. John',
        last_name: 'Doe',
        role: Role.FACULTY,
        college_id: 'clg_1',
      } as any);

      adminRepository.updateUser.mockResolvedValue({ id: 'usr_fac' } as any);

      const res = await adminService.setTemporaryPassword(
        { actorUserId: 'usr_admin', actorRole: Role.ADMIN },
        'clg_1',
        'usr_fac',
        'TempPass123!',
      );

      expect(res.message).toContain('Temporary password set');
      expect(adminRepository.updateUser).toHaveBeenCalledWith('usr_fac', expect.objectContaining({
        is_password_configured: false,
        status: UserStatus.PASSWORD_SETUP_REQUIRED,
      }));
    });

    it('should allow setting temporary password for PLACEMENT', async () => {
      adminRepository.findUserById.mockResolvedValue({
        id: 'usr_plc',
        email: 'placement@gcee.ac.in',
        first_name: 'Sarah',
        last_name: 'Officer',
        role: Role.PLACEMENT,
        college_id: 'clg_1',
      } as any);

      adminRepository.updateUser.mockResolvedValue({ id: 'usr_plc' } as any);

      const res = await adminService.setTemporaryPassword(
        { actorUserId: 'usr_admin', actorRole: Role.ADMIN },
        'clg_1',
        'usr_plc',
      );

      expect(res.message).toContain('Temporary password set');
      expect(adminRepository.updateUser).toHaveBeenCalledWith('usr_plc', expect.objectContaining({
        is_password_configured: false,
        status: UserStatus.PASSWORD_SETUP_REQUIRED,
      }));
    });

    it('should forbid setting temporary password for STUDENT', async () => {
      adminRepository.findUserById.mockResolvedValue({
        id: 'usr_stud',
        email: 'student@gcee.ac.in',
        first_name: 'Student',
        last_name: 'User',
        role: Role.STUDENT,
        college_id: 'clg_1',
      } as any);

      await expect(
        adminService.setTemporaryPassword(
          { actorUserId: 'usr_admin', actorRole: Role.ADMIN },
          'clg_1',
          'usr_stud',
        ),
      ).rejects.toThrow('Temporary passwords cannot be set for students. Students must verify via OTP.');
    });
  });


  describe('updateUserRole', () => {
    it('should update user role successfully', async () => {
      adminRepository.findUserById.mockResolvedValue({
        id: 'usr_1',
        email: 'user@test.com',
        first_name: 'Test',
        last_name: 'User',
        role: Role.STUDENT,
        college_id: 'clg_1',
      } as any);

      adminRepository.updateUserRole.mockResolvedValue({
        id: 'usr_1',
        role: Role.ADMIN,
      } as any);

      const result = await adminService.updateUserRole(
        { userId: 'usr_1', newRole: Role.ADMIN },
        { actorUserId: 'admin_actor', actorRole: Role.ADMIN }
      );
      expect(result.role).toBe(Role.ADMIN);
      expect(adminRepository.createAuditLog).toHaveBeenCalled();
    });

    it('should prevent user from changing their own role', async () => {
      await expect(
        adminService.updateUserRole(
          { userId: 'usr_same', newRole: Role.ADMIN },
          { actorUserId: 'usr_same', actorRole: Role.ADMIN }
        )
      ).rejects.toThrow(ForbiddenError);
    });
  });

  describe('updateUserStatus', () => {
    it('should prevent admin from deactivating their own account', async () => {
      await expect(
        adminService.updateUserStatus(
          { userId: 'admin_1', isActive: false },
          { actorUserId: 'admin_1', actorRole: Role.ADMIN }
        )
      ).rejects.toThrow(ForbiddenError);
    });

    it('should allow active status update and record audit log', async () => {
      adminRepository.findUserById.mockResolvedValue({
        id: 'usr_2',
        email: 'usr2@test.com',
        first_name: 'User',
        last_name: 'Two',
        status: UserStatus.DEACTIVATED,
        college_id: 'clg_1',
      } as any);

      adminRepository.updateUserStatus.mockResolvedValue({
        id: 'usr_2',
        status: UserStatus.ACTIVE,
      } as any);

      const result = await adminService.updateUserStatus(
        { userId: 'usr_2', isActive: true },
        { actorUserId: 'admin_actor', actorRole: Role.ADMIN }
      );

      expect(result.status).toBe(UserStatus.ACTIVE);
      expect(adminRepository.createAuditLog).toHaveBeenCalled();
    });
  });

  describe('createDepartment and updateDepartment', () => {
    it('should throw BadRequestError if department code already exists', async () => {
      adminRepository.findDepartmentByCode.mockResolvedValue({ id: 'dept_1', code: 'MECH' } as any);
      await expect(
        adminService.createDepartment(
          'clg_1',
          { name: 'Mechanical', code: 'MECH' },
          { actorUserId: 'admin_1', actorRole: Role.ADMIN }
        )
      ).rejects.toThrow(BadRequestError);
    });

    it('should throw NotFoundError if updating non-existent department', async () => {
      adminRepository.findDepartmentById.mockResolvedValue(null);
      await expect(
        adminService.updateDepartment(
          'clg_1',
          'dept_missing',
          { name: 'EEE Updated' },
          { actorUserId: 'admin_1', actorRole: Role.ADMIN }
        )
      ).rejects.toThrow(NotFoundError);
    });
  });

  describe('Academic Management (Phase 3)', () => {
    it('should throw BadRequestError if start date is after end date when creating academic year', async () => {
      await expect(
        adminService.createAcademicYear(
          'clg_1',
          { yearName: '2026-2027', startDate: '2027-08-01', endDate: '2026-05-31' },
          { actorUserId: 'admin_1', actorRole: Role.ADMIN }
        )
      ).rejects.toThrow(BadRequestError);
    });

    it('should create academic year and record audit log', async () => {
      adminRepository.findAcademicYearByName.mockResolvedValue(null);
      adminRepository.createAcademicYear.mockResolvedValue({
        id: 'ay_1',
        year_name: '2026-2027',
        start_date: new Date('2026-08-01'),
        end_date: new Date('2027-05-31'),
        is_active: false,
      } as any);

      const result = await adminService.createAcademicYear(
        'clg_1',
        { yearName: '2026-2027', startDate: '2026-08-01', endDate: '2027-05-31' },
        { actorUserId: 'admin_1', actorRole: Role.ADMIN }
      );

      expect(result.year_name).toBe('2026-2027');
      expect(adminRepository.createAuditLog).toHaveBeenCalled();
    });

    it('should reject batch creation if admission year is after graduation year', async () => {
      await expect(
        adminService.createBatch(
          'clg_1',
          { name: 'Invalid Batch', admissionYear: 2026, graduationYear: 2024 },
          { actorUserId: 'admin_1', actorRole: Role.ADMIN }
        )
      ).rejects.toThrow(BadRequestError);
    });

    it('should prevent duplicate program code in same college', async () => {
      adminRepository.findAcademicProgramByCode.mockResolvedValue({
        id: 'prog_1',
        code: 'CSE',
      } as any);

      await expect(
        adminService.createAcademicProgram(
          'clg_1',
          { departmentId: 'dept_1', name: 'Computer Science', code: 'CSE' },
          { actorUserId: 'admin_1', actorRole: Role.ADMIN }
        )
      ).rejects.toThrow(BadRequestError);
    });
  });

  describe('Courses, Curriculum & Classes (Phase 4)', () => {
    it('should create a subject with assigned faculty instructor', async () => {
      adminRepository.findUserById.mockResolvedValue({
        id: 'fac_1',
        college_id: 'clg_1',
        role: Role.FACULTY,
      } as any);

      adminRepository.findSubjectByCodeAndSection.mockResolvedValue(null);
      adminRepository.createSubject.mockResolvedValue({
        id: 'sub_1',
        code: 'CS301',
        name: 'Database Management Systems',
      } as any);

      const result = await adminService.createSubject(
        'clg_1',
        {
          code: 'CS301',
          name: 'Database Management Systems',
          facultyId: 'fac_1',
          semester: '5',
          section: 'A',
          credits: 4,
        },
        { actorUserId: 'admin_1', actorRole: Role.ADMIN }
      );

      expect(result.code).toBe('CS301');
      expect(adminRepository.createAuditLog).toHaveBeenCalled();
    });

    it('should prevent creating a subject with duplicate code, semester and section', async () => {
      adminRepository.findUserById.mockResolvedValue({
        id: 'fac_1',
        college_id: 'clg_1',
      } as any);

      adminRepository.findSubjectByCodeAndSection.mockResolvedValue({
        id: 'sub_existing',
      } as any);

      await expect(
        adminService.createSubject(
          'clg_1',
          {
            code: 'CS301',
            name: 'Database Management Systems',
            facultyId: 'fac_1',
            semester: '5',
            section: 'A',
          },
          { actorUserId: 'admin_1', actorRole: Role.ADMIN }
        )
      ).rejects.toThrow(BadRequestError);
    });

    it('should create an academic class section and record audit log', async () => {
      adminRepository.createAcademicClass.mockResolvedValue({
        id: 'cls_1',
        name: 'CSE 4th Year - Sec A',
        year_of_study: 4,
        semester: 7,
        section: 'A',
      } as any);

      const result = await adminService.createAcademicClass(
        'clg_1',
        {
          departmentId: 'dept_1',
          name: 'CSE 4th Year - Sec A',
          yearOfStudy: 4,
          semester: 7,
          section: 'A',
        },
        { actorUserId: 'admin_1', actorRole: Role.ADMIN }
      );

      expect(result.name).toBe('CSE 4th Year - Sec A');
      expect(adminRepository.createAuditLog).toHaveBeenCalled();
    });
  });

  describe('Rooms, Assignments & Timetable Scheduling (Phase 5)', () => {
    it('should throw BadRequestError if room code already exists', async () => {
      adminRepository.findRoomByCode.mockResolvedValue({ id: 'room_existing', code: 'LH-101' } as any);
      await expect(
        adminService.createRoom(
          'clg_1',
          { code: 'LH-101', name: 'Lecture Hall 101' },
          { actorUserId: 'admin_1', actorRole: Role.ADMIN }
        )
      ).rejects.toThrow(ConflictError);
    });

    it('should create room and write audit log for ADMIN', async () => {
      adminRepository.findRoomByCode.mockResolvedValue(null);
      adminRepository.createRoom.mockResolvedValue({
        id: 'room_1',
        code: 'LH-101',
        name: 'Lecture Hall 101',
        capacity: 120,
      } as any);

      const result = await adminService.createRoom(
        'clg_1',
        { code: 'LH-101', name: 'Lecture Hall 101', capacity: 120 },
        { actorUserId: 'admin_1', actorRole: Role.ADMIN }
      );

      expect(result.code).toBe('LH-101');
      expect(adminRepository.createAuditLog).toHaveBeenCalled();
    });

    it('should detect room conflict and reject schedule creation when room is already booked', async () => {
      adminRepository.findUserById.mockResolvedValue({
        id: 'fac_1',
        college_id: 'clg_1',
      } as any);

      adminRepository.findRoomById.mockResolvedValue({
        id: 'room_1',
        college_id: 'clg_1',
        code: 'LH-101',
      } as any);

      adminRepository.findPotentialConflicts.mockResolvedValue([
        {
          id: 'sched_existing',
          day_of_week: 'MONDAY',
          start_time: '09:00',
          end_time: '10:30',
          room_id: 'room_1',
          faculty_id: 'fac_other',
          room: { code: 'LH-101' },
        } as any,
      ]);

      await expect(
        adminService.createSchedule(
          'clg_1',
          {
            facultyId: 'fac_1',
            roomId: 'room_1',
            dayOfWeek: 'MONDAY',
            startTime: '10:00',
            endTime: '11:00',
          },
          { actorUserId: 'admin_1', actorRole: Role.ADMIN }
        )
      ).rejects.toThrow(ConflictError);
    });

    it('should detect faculty conflict and reject schedule creation when faculty is already booked', async () => {
      adminRepository.findUserById.mockResolvedValue({
        id: 'fac_1',
        college_id: 'clg_1',
      } as any);

      adminRepository.findPotentialConflicts.mockResolvedValue([
        {
          id: 'sched_existing',
          day_of_week: 'MONDAY',
          start_time: '14:00',
          end_time: '15:00',
          room_id: 'room_other',
          faculty_id: 'fac_1',
          faculty: { first_name: 'Alan', last_name: 'Turing' },
        } as any,
      ]);

      await expect(
        adminService.createSchedule(
          'clg_1',
          {
            facultyId: 'fac_1',
            dayOfWeek: 'MONDAY',
            startTime: '14:30',
            endTime: '15:30',
          },
          { actorUserId: 'admin_1', actorRole: Role.ADMIN }
        )
      ).rejects.toThrow(ConflictError);
    });

    it('should create timetable schedule slot when no conflict exists and record audit log', async () => {
      adminRepository.findUserById.mockResolvedValue({
        id: 'fac_1',
        college_id: 'clg_1',
        first_name: 'Grace',
        last_name: 'Hopper',
      } as any);

      adminRepository.findPotentialConflicts.mockResolvedValue([]);
      adminRepository.createSchedule.mockResolvedValue({
        id: 'sched_new',
        day_of_week: 'TUESDAY',
        start_time: '09:00',
        end_time: '10:00',
        faculty_id: 'fac_1',
      } as any);

      const result = await adminService.createSchedule(
        'clg_1',
        {
          facultyId: 'fac_1',
          dayOfWeek: 'TUESDAY',
          startTime: '09:00',
          endTime: '10:00',
        },
        { actorUserId: 'admin_1', actorRole: Role.ADMIN }
      );

      expect(result.id).toBe('sched_new');
      expect(adminRepository.createAuditLog).toHaveBeenCalled();
    });
  });

  describe('Academic Monitoring (Phase 6)', () => {
    it('should return academic monitoring metrics for ADMIN without department restriction', async () => {
      adminRepository.getMonitoringMetrics.mockResolvedValue({
        totalAttendanceSessions: 42,
        averageAttendanceRate: 88.5,
        totalAssignments: 15,
        totalSubmissions: 450,
        totalAssessments: 8,
        averageAssessmentScore: 78.4,
      });

      const result = await adminService.getMonitoringMetrics('clg_1', undefined, {
        actorUserId: 'admin_1',
        actorRole: Role.ADMIN,
      });

      expect(result.totalAttendanceSessions).toBe(42);
      expect(result.averageAttendanceRate).toBe(88.5);
      expect(adminRepository.getMonitoringMetrics).toHaveBeenCalledWith('clg_1', undefined);
    });

    it('should scope academic monitoring metrics when departmentId is provided', async () => {
      adminRepository.getMonitoringMetrics.mockResolvedValue({
        totalAttendanceSessions: 10,
        averageAttendanceRate: 92.0,
        totalAssignments: 4,
        totalSubmissions: 120,
        totalAssessments: 2,
        averageAssessmentScore: 82.1,
      });

      const result = await adminService.getMonitoringMetrics('clg_1', 'dept_cs', {
        actorUserId: 'admin_1',
        actorRole: Role.ADMIN,
      });

      expect(result.totalAttendanceSessions).toBe(10);
      expect(adminRepository.getMonitoringMetrics).toHaveBeenCalledWith('clg_1', 'dept_cs');
    });

    it('should throw NotFoundError if attendance session does not exist', async () => {
      adminRepository.findAttendanceSessionById.mockResolvedValue(null);

      await expect(
        adminService.getAttendanceSessionById('clg_1', 'session_missing', {
          actorUserId: 'admin_1',
          actorRole: Role.ADMIN,
        })
      ).rejects.toThrow(NotFoundError);
    });
  });

  describe('Phase 7: Campus Moderation & Broadcast Notifications', () => {
    it('should broadcast notification to targeted audience and record audit log', async () => {
      adminRepository.findTargetUserIds.mockResolvedValue([
        { id: 'user_1' },
        { id: 'user_2' },
      ] as any);
      adminRepository.createBroadcastNotifications.mockResolvedValue({ count: 2 } as any);
      adminRepository.createAuditLog.mockResolvedValue({} as any);

      const result = await adminService.sendBroadcastNotification(
        'clg_1',
        {
          title: 'Campus Townhall',
          body: 'All students and faculty attend at 10 AM.',
          targetAudience: 'ALL',
        },
        { actorUserId: 'admin_1', actorRole: Role.ADMIN }
      );

      expect(result.success).toBe(true);
      expect(result.count).toBe(2);
      expect(adminRepository.createBroadcastNotifications).toHaveBeenCalledWith(
        expect.arrayContaining([
          expect.objectContaining({ user_id: 'user_1', title: 'Campus Townhall' }),
          expect.objectContaining({ user_id: 'user_2', title: 'Campus Townhall' }),
        ])
      );
      expect(adminRepository.createAuditLog).toHaveBeenCalledWith(
        expect.objectContaining({ action: 'BROADCAST_NOTIFICATION_SENT' })
      );
    });

    it('should throw BadRequestError if broadcast title or body is missing', async () => {
      await expect(
        adminService.sendBroadcastNotification(
          'clg_1',
          {
            title: '',
            body: 'Hello',
            targetAudience: 'ALL',
          },
          { actorUserId: 'admin_1', actorRole: Role.ADMIN }
        )
      ).rejects.toThrow(BadRequestError);
    });

    it('should delete event and record audit log for moderation', async () => {
      adminRepository.findModerationEventById.mockResolvedValue({
        id: 'event_1',
        college_id: 'clg_1',
        department_id: 'dept_cs',
        title: 'Spam Event',
        organizer_id: 'user_bad',
      } as any);
      adminRepository.deleteModerationEvent.mockResolvedValue({} as any);
      adminRepository.createAuditLog.mockResolvedValue({} as any);

      const result = await adminService.deleteModerationEvent('clg_1', 'event_1', {
        actorUserId: 'admin_1',
        actorRole: Role.ADMIN,
      });

      expect(result.success).toBe(true);
      expect(adminRepository.deleteModerationEvent).toHaveBeenCalledWith('event_1');
      expect(adminRepository.createAuditLog).toHaveBeenCalledWith(
        expect.objectContaining({ action: 'EVENT_DELETED_BY_ADMIN' })
      );
    });

    it('should throw NotFoundError if event does not exist during moderation deletion', async () => {
      adminRepository.findModerationEventById.mockResolvedValue(null);

      await expect(
        adminService.deleteModerationEvent('clg_1', 'event_missing', {
          actorUserId: 'admin_1',
          actorRole: Role.ADMIN,
        })
      ).rejects.toThrow(NotFoundError);
    });

    it('should delete post and record audit log for moderation', async () => {
      adminRepository.findModerationPostById.mockResolvedValue({
        id: 'post_1',
        college_id: 'clg_1',
        department_id: 'dept_cs',
        title: 'Inappropriate Post',
        author_id: 'user_bad',
      } as any);
      adminRepository.deleteModerationPost.mockResolvedValue({} as any);
      adminRepository.createAuditLog.mockResolvedValue({} as any);

      const result = await adminService.deleteModerationPost('clg_1', 'post_1', {
        actorUserId: 'admin_1',
        actorRole: Role.ADMIN,
      });

      expect(result.success).toBe(true);
      expect(adminRepository.deleteModerationPost).toHaveBeenCalledWith('post_1');
      expect(adminRepository.createAuditLog).toHaveBeenCalledWith(
        expect.objectContaining({ action: 'POST_DELETED_BY_ADMIN' })
      );
    });
  });

  describe('Phase 9: Institutional Settings & Audit Log CSV Export', () => {
    it('should generate properly formatted CSV string for audit reports', async () => {
      adminRepository.getAuditLogs.mockResolvedValue([
        {
          id: 'log_1',
          timestamp: new Date('2026-09-20T10:00:00.000Z'),
          actorName: 'Naveed Ahmed',
          actorEmail: 'admin@campushub.edu',
          actorRole: 'ADMIN',
          action: 'USER_CREATED',
          category: 'USER_MANAGEMENT',
          entityType: 'User',
          entityId: 'u_1',
          details: 'Created student John Doe',
        },
      ] as any);

      const csv = await adminService.getAuditReportsCsv('clg_1');
      expect(csv).toContain('ID,Timestamp,Actor Name,Actor Email,Actor Role,Action,Category,Entity Type,Entity ID,Details');
      expect(csv).toContain('"log_1"');
      expect(csv).toContain('"Naveed Ahmed"');
      expect(csv).toContain('"USER_CREATED"');
      expect(csv).toContain('"Created student John Doe"');
    });

    it('should update college profile and log audit action', async () => {
      adminRepository.findCollegeById.mockResolvedValue({
        id: 'clg_1',
        name: 'National Institute of Engineering',
        code: 'NIE',
      } as any);
      adminRepository.updateCollege.mockResolvedValue({
        id: 'clg_1',
        name: 'National University of Technology',
        code: 'NIE',
      } as any);
      adminRepository.createAuditLog.mockResolvedValue({} as any);

      const updated = await adminService.updateCollegeSettings(
        'clg_1',
        { name: 'National University of Technology' },
        { actorUserId: 'admin_1', actorRole: Role.ADMIN }
      );

      expect(updated.name).toBe('National University of Technology');
      expect(adminRepository.updateCollege).toHaveBeenCalledWith('clg_1', {
        name: 'National University of Technology',
      });
      expect(adminRepository.createAuditLog).toHaveBeenCalledWith(
        expect.objectContaining({ action: 'COLLEGE_SETTINGS_UPDATED' })
      );
    });

    it('should throw NotFoundError if updating non-existent college settings', async () => {
      adminRepository.findCollegeById.mockResolvedValue(null);
      await expect(
        adminService.updateCollegeSettings(
          'clg_missing',
          { name: 'Updated Name' },
          { actorUserId: 'admin_1', actorRole: Role.ADMIN }
        )
      ).rejects.toThrow(NotFoundError);
    });
  });

  describe('Profile Change Request Approval Workflow', () => {
    it('should list change requests with filters', async () => {
      (adminRepository as any).getChangeRequests = jest.fn().mockResolvedValue({
        items: [],
        total: 0,
        page: 1,
        limit: 20,
        totalPages: 0,
      });

      await adminService.getChangeRequests(
        'clg_1',
        { status: 'PENDING', departmentId: 'dept_cs' },
        { actorUserId: 'admin_1', actorRole: Role.ADMIN }
      );

      expect((adminRepository as any).getChangeRequests).toHaveBeenCalledWith(
        'clg_1',
        expect.objectContaining({ departmentId: 'dept_cs', status: 'PENDING' })
      );
    });

    it('should approve change request and write audit log', async () => {
      (adminRepository as any).getChangeRequestById = jest.fn().mockResolvedValue({
        id: 'req_1',
        college_id: 'clg_1',
        student_id: 'std_1',
        field: 'first_name',
        current_value: 'Alex',
        requested_value: 'Alexander',
        status: 'PENDING',
        student: { id: 'std_1', first_name: 'Alex', last_name: 'Vance' },
      });
      (adminRepository as any).approveChangeRequest = jest.fn().mockResolvedValue({
        request: { id: 'req_1', status: 'APPROVED' },
        student: { id: 'std_1', first_name: 'Alexander', last_name: 'Vance' },
      });
      adminRepository.createAuditLog = jest.fn().mockResolvedValue({} as any);

      const res = await adminService.approveChangeRequest(
        'clg_1',
        'req_1',
        'Verified birth certificate',
        { actorUserId: 'admin_1', actorRole: Role.ADMIN }
      );

      expect(res.status).toBe('APPROVED');
      expect(adminRepository.createAuditLog).toHaveBeenCalledWith(
        expect.objectContaining({
          action: 'PROFILE_CHANGE_APPROVED',
          entity_type: 'ProfileChangeRequest',
        })
      );
    });

    it('should reject change request with required reason and write audit log', async () => {
      (adminRepository as any).getChangeRequestById = jest.fn().mockResolvedValue({
        id: 'req_2',
        college_id: 'clg_1',
        student_id: 'std_1',
        field: 'phone',
        current_value: '9876543210',
        requested_value: '9999999999',
        status: 'PENDING',
        student: { id: 'std_1', first_name: 'Alex', last_name: 'Vance' },
      });
      (adminRepository as any).rejectChangeRequest = jest.fn().mockResolvedValue({
        request: { id: 'req_2', status: 'REJECTED' },
        student: { id: 'std_1', first_name: 'Alex', last_name: 'Vance' },
      });
      adminRepository.createAuditLog = jest.fn().mockResolvedValue({} as any);

      const res = await adminService.rejectChangeRequest(
        'clg_1',
        'req_2',
        'Document unreadable',
        { actorUserId: 'admin_1', actorRole: Role.ADMIN }
      );

      expect(res.status).toBe('REJECTED');
      expect(adminRepository.createAuditLog).toHaveBeenCalledWith(
        expect.objectContaining({
          action: 'PROFILE_CHANGE_REJECTED',
          entity_type: 'ProfileChangeRequest',
        })
      );
    });

    it('should throw BadRequestError when rejecting without a reason', async () => {
      await expect(
        adminService.rejectChangeRequest(
          'clg_1',
          'req_2',
          '',
          { actorUserId: 'admin_1', actorRole: Role.ADMIN }
        )
      ).rejects.toThrow(BadRequestError);
    });
  });
});




