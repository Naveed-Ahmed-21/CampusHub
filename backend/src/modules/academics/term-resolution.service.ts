import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export interface ResolvedTerm {
  academicYearId: string;
  academicYear: string;
  termId: string;
  termName: string;
  termType: 'ODD' | 'EVEN';
  semesterNumber: number; // 1 or 2
  startDate: string;
  endDate: string;
  status: string;
}

export interface StudentAcademicProgression {
  studentId: string;
  admissionYear: number;
  batchName: string;
  programId: string;
  programName: string;
  programCode: string;
  departmentId: string;
  departmentName: string;
  departmentCode: string;
  section: string;
  yearOfStudy: number; // 1, 2, 3, 4
  yearRoman: string;   // I, II, III, IV
  yearLabel: string;   // "IV Year"
  semester: number;    // 1..8
  semesterRoman: string; // VII
  semesterLabel: string; // "VII Semester"
  academicYear: string;  // "2026–27"
  academicTerm: string;  // "Semester 1"
  academicHeader: string; // "IV Year • VII Semester | 2026–27 | CSE • Section A"
  status: string;      // "ACTIVE", "SEMESTER_REPEAT", etc.
  hasOverride: boolean;
  overrideReason?: string;
}

const ROMAN_NUMERALS: Record<number, string> = {
  1: 'I',
  2: 'II',
  3: 'III',
  4: 'IV',
  5: 'V',
  6: 'VI',
  7: 'VII',
  8: 'VIII',
  9: 'IX',
  10: 'X',
};

export class TermResolutionService {
  /**
   * Initializes standard academic years and terms if none exist for this college.
   */
  async ensureAcademicStructure(collegeId: string): Promise<void> {
    const existingYears = await prisma.academicYear.findMany({
      where: { college_id: collegeId },
      include: { terms: true },
    });

    if (existingYears.length === 0) {
      // Create 2026-27 and 2027-28
      const year2026 = await prisma.academicYear.create({
        data: {
          college_id: collegeId,
          year_name: '2026-27',
          start_date: new Date('2026-06-01'),
          end_date: new Date('2027-05-31'),
          is_active: true,
          terms: {
            create: [
              {
                name: 'Semester 1',
                term_type: 'ODD',
                semester_number: 1,
                start_date: new Date('2026-06-01'),
                end_date: new Date('2026-12-31'),
                status: 'ACTIVE',
              },
              {
                name: 'Semester 2',
                term_type: 'EVEN',
                semester_number: 2,
                start_date: new Date('2027-01-01'),
                end_date: new Date('2027-05-31'),
                status: 'UPCOMING',
              },
            ],
          },
        },
      });

      await prisma.academicYear.create({
        data: {
          college_id: collegeId,
          year_name: '2027-28',
          start_date: new Date('2027-06-01'),
          end_date: new Date('2028-05-31'),
          is_active: false,
          terms: {
            create: [
              {
                name: 'Semester 1',
                term_type: 'ODD',
                semester_number: 1,
                start_date: new Date('2027-06-01'),
                end_date: new Date('2027-12-31'),
                status: 'UPCOMING',
              },
              {
                name: 'Semester 2',
                term_type: 'EVEN',
                semester_number: 2,
                start_date: new Date('2028-01-01'),
                end_date: new Date('2028-05-31'),
                status: 'UPCOMING',
              },
            ],
          },
        },
      });
    } else {
      // Ensure existing academic years have terms
      for (const year of existingYears) {
        if (!year.terms || year.terms.length === 0) {
          const startYear = year.start_date.getFullYear();
          const endYear = year.end_date.getFullYear();
          await prisma.academicTerm.createMany({
            data: [
              {
                academic_year_id: year.id,
                name: 'Semester 1',
                term_type: 'ODD',
                semester_number: 1,
                start_date: year.start_date,
                end_date: new Date(`${startYear}-12-31`),
                status: 'ACTIVE',
              },
              {
                academic_year_id: year.id,
                name: 'Semester 2',
                term_type: 'EVEN',
                semester_number: 2,
                start_date: new Date(`${endYear}-01-01`),
                end_date: year.end_date,
                status: 'UPCOMING',
              },
            ],
          });
        }
      }
    }

    // Ensure at least one AcademicProgram exists per department
    const depts = await prisma.department.findMany({
      where: { college_id: collegeId },
    });

    for (const dept of depts) {
      const existingProg = await prisma.academicProgram.findFirst({
        where: { college_id: collegeId, department_id: dept.id },
      });
      if (!existingProg) {
        await prisma.academicProgram.create({
          data: {
            college_id: collegeId,
            department_id: dept.id,
            name: `B.Tech in ${dept.name}`,
            code: `BTECH_${dept.code.toUpperCase()}`,
            degree_type: 'UNDERGRADUATE',
            total_semesters: 8,
            is_active: true,
          },
        });
      }
    }

    // Ensure common engineering batches exist for the college
    const commonBatches = [
      { name: '2026-2030', admissionYear: 2026, graduationYear: 2030 },
      { name: '2025-2029', admissionYear: 2025, graduationYear: 2029 },
      { name: '2024-2028', admissionYear: 2024, graduationYear: 2028 },
      { name: '2023-2027', admissionYear: 2023, graduationYear: 2027 },
      { name: '2022-2026', admissionYear: 2022, graduationYear: 2026 },
      { name: '2021-2025', admissionYear: 2021, graduationYear: 2025 },
      { name: '2020-2024', admissionYear: 2020, graduationYear: 2024 },
    ];

    for (const b of commonBatches) {
      const exists = await prisma.batch.findFirst({
        where: {
          college_id: collegeId,
          name: b.name,
        },
      });
      if (!exists) {
        await prisma.batch.create({
          data: {
            college_id: collegeId,
            name: b.name,
            admission_year: b.admissionYear,
            graduation_year: b.graduationYear,
            status: 'ACTIVE',
            department_id: null,
          },
        });
      }
    }
  }

  /**
   * Calculates the student's study year (1..5) from their admission year / batch
   * following Anna University's academic calendar (June to May cycle).
   */
  calculateYearFromBatch(admissionYear: number, targetDate: Date = new Date()): {
    currentYear: number;
    yearLabel: string;
    isGraduated: boolean;
  } {
    const month = targetDate.getMonth() + 1; // 1-12
    const acadStartYear = month >= 6 ? targetDate.getFullYear() : targetDate.getFullYear() - 1;
    const diff = acadStartYear - admissionYear + 1;

    if (diff <= 1) {
      return { currentYear: 1, yearLabel: '1st Year', isGraduated: false };
    } else if (diff === 2) {
      return { currentYear: 2, yearLabel: '2nd Year', isGraduated: false };
    } else if (diff === 3) {
      return { currentYear: 3, yearLabel: '3rd Year', isGraduated: false };
    } else if (diff === 4) {
      return { currentYear: 4, yearLabel: '4th Year', isGraduated: false };
    } else {
      return { currentYear: 5, yearLabel: 'Graduated', isGraduated: true };
    }
  }

  /**
   * Resolves the current academic term dynamically based on current date.
   * Backend is the single source of truth.
   */
  async getCurrentTerm(collegeId: string, targetDate: Date = new Date()): Promise<ResolvedTerm> {
    await this.ensureAcademicStructure(collegeId);

    // 1. Find term where targetDate falls within [start_date, end_date]
    const termByDate = await prisma.academicTerm.findFirst({
      where: {
        academic_year: { college_id: collegeId },
        start_date: { lte: targetDate },
        end_date: { gte: targetDate },
      },
      include: {
        academic_year: true,
      },
    });

    if (termByDate) {
      return {
        academicYearId: termByDate.academic_year_id,
        academicYear: termByDate.academic_year.year_name,
        termId: termByDate.id,
        termName: termByDate.name,
        termType: termByDate.term_type as 'ODD' | 'EVEN',
        semesterNumber: termByDate.semester_number,
        startDate: termByDate.start_date.toISOString(),
        endDate: termByDate.end_date.toISOString(),
        status: termByDate.status,
      };
    }

    // 2. Fallback to active term
    const activeTerm = await prisma.academicTerm.findFirst({
      where: {
        academic_year: { college_id: collegeId, is_active: true },
        status: 'ACTIVE',
      },
      include: {
        academic_year: true,
      },
    });

    if (activeTerm) {
      return {
        academicYearId: activeTerm.academic_year_id,
        academicYear: activeTerm.academic_year.year_name,
        termId: activeTerm.id,
        termName: activeTerm.name,
        termType: activeTerm.term_type as 'ODD' | 'EVEN',
        semesterNumber: activeTerm.semester_number,
        startDate: activeTerm.start_date.toISOString(),
        endDate: activeTerm.end_date.toISOString(),
        status: activeTerm.status,
      };
    }

    // 3. Fallback to latest created term
    let latestTerm: any = await prisma.academicTerm.findFirst({
      where: {
        academic_year: { college_id: collegeId },
      },
      orderBy: { start_date: 'desc' },
      include: {
        academic_year: true,
      },
    });

    if (!latestTerm) {
      let activeYear = await prisma.academicYear.findFirst({
        where: { college_id: collegeId },
      });
      if (!activeYear) {
        activeYear = await prisma.academicYear.create({
          data: {
            college_id: collegeId,
            year_name: '2026-27',
            start_date: new Date('2026-06-01'),
            end_date: new Date('2027-05-31'),
            is_active: true,
          },
        });
      }

      latestTerm = await prisma.academicTerm.create({
        data: {
          academic_year_id: activeYear.id,
          name: 'Semester 1',
          term_type: 'ODD',
          semester_number: 1,
          start_date: new Date('2026-06-01'),
          end_date: new Date('2026-12-31'),
          status: 'ACTIVE',
        },
        include: {
          academic_year: true,
        },
      });
    }

    return {
      academicYearId: latestTerm.academic_year_id,
      academicYear: latestTerm.academic_year.year_name,
      termId: latestTerm.id,
      termName: latestTerm.name,
      termType: latestTerm.term_type as 'ODD' | 'EVEN',
      semesterNumber: latestTerm.semester_number,
      startDate: latestTerm.start_date.toISOString(),
      endDate: latestTerm.end_date.toISOString(),
      status: latestTerm.status,
    };
  }

  /**
   * Derives student's current academic progression: Year of study, semester, section, etc.
   * Progression formula:
   *   Academic Year start year Y_ay (e.g. 2026 from "2026-27")
   *   Admission Year Y_adm (e.g. 2023)
   *   Year of Study = Y_ay - Y_adm + 1 (e.g. 2026 - 2023 + 1 = 4 -> IV Year)
   *   Expected Semester = (YearOfStudy - 1) * 2 + (termType === 'ODD' ? 1 : 2)
   *   Check for Administrative Override (StudentAcademicOverride)
   */
  async deriveStudentProgression(
    studentId: string,
    targetDate: Date = new Date()
  ): Promise<StudentAcademicProgression> {
    const student = await prisma.user.findUnique({
      where: { id: studentId },
      include: {
        department: true,
        academic_profile: {
          include: { program: true },
        },
      },
    });

    if (!student) {
      throw new Error(`Student ${studentId} not found`);
    }

    const collegeId = student.college_id;
    const currentTerm = await this.getCurrentTerm(collegeId, targetDate);

    // Resolve or auto-create StudentAcademicProfile
    let profile = student.academic_profile;
    if (!profile) {
      // Find matching program for department
      let program = await prisma.academicProgram.findFirst({
        where: {
          college_id: collegeId,
          department_id: student.department_id || undefined,
        },
      });

      if (!program) {
        program = await prisma.academicProgram.findFirst({
          where: { college_id: collegeId },
        });
      }

      // Infer admission year:
      // Alex Vance roll_number = "21CS101" -> Batch 2023 for 4th year in 2026, or 2023 default
      const admissionYear = 2023;

      profile = await prisma.studentAcademicProfile.create({
        data: {
          student_id: studentId,
          program_id: program?.id,
          admission_year: admissionYear,
          batch_name: `${admissionYear}-${admissionYear + 4}`,
          current_status: 'ACTIVE',
          section: 'A',
        },
        include: { program: true },
      });
    }

    const admissionYear = profile.admission_year;
    const totalSemesters = profile.program?.total_semesters || 8;

    // Parse start year of the current academic year (e.g. "2026-27" -> 2026)
    const ayMatch = currentTerm.academicYear.match(/^(\d{4})/);
    const ayStartYear = ayMatch ? parseInt(ayMatch[1], 10) : new Date(currentTerm.startDate).getFullYear();

    const rawYear = ayStartYear - admissionYear + 1;
    const isGraduated = profile.current_status === 'GRADUATED' || rawYear > Math.ceil(totalSemesters / 2);
    const effectiveYear = profile.current_year || (isGraduated ? 5 : Math.max(1, Math.min(rawYear, Math.ceil(totalSemesters / 2))));
    const yearOfStudy = Math.min(effectiveYear, Math.ceil(totalSemesters / 2));

    // Term 1 (June–Dec) is ODD; Term 2 (Jan–May) is EVEN
    const isOdd = currentTerm.termType === 'ODD' || currentTerm.semesterNumber === 1;
    const expectedSemester = (yearOfStudy - 1) * 2 + (isOdd ? 1 : 2);

    // Check for explicit override
    const override = await prisma.studentAcademicOverride.findUnique({
      where: {
        student_id_academic_term_id: {
          student_id: studentId,
          academic_term_id: currentTerm.termId,
        },
      },
    });

    const finalSemester = override ? override.override_semester : Math.min(expectedSemester, totalSemesters);
    const derivedYearOfStudy = Math.ceil(finalSemester / 2);

    const yearRoman = ROMAN_NUMERALS[derivedYearOfStudy] || `${derivedYearOfStudy}`;
    const semesterRoman = ROMAN_NUMERALS[finalSemester] || `${finalSemester}`;

    const deptCode = student.department?.code || 'GEN';
    const section = profile.section || 'A';

    const yearLabel = (isGraduated || effectiveYear >= 5)
      ? 'Graduated'
      : (effectiveYear === 1 ? '1st Year' : effectiveYear === 2 ? '2nd Year' : effectiveYear === 3 ? '3rd Year' : '4th Year');

    return {
      studentId: student.id,
      admissionYear,
      batchName: profile.batch_name || `${admissionYear}-${admissionYear + 4}`,
      programId: profile.program_id || '',
      programName: profile.program?.name || `B.Tech in ${deptCode}`,
      programCode: profile.program?.code || `BTECH_${deptCode}`,
      departmentId: student.department_id || '',
      departmentName: student.department?.name || 'Academic Department',
      departmentCode: deptCode,
      section,
      yearOfStudy: isGraduated ? 5 : derivedYearOfStudy,
      yearRoman: isGraduated ? 'Graduated' : yearRoman,
      yearLabel,
      semester: finalSemester,
      semesterRoman,
      semesterLabel: isGraduated ? 'Graduated' : `${semesterRoman} Semester`,
      academicYear: currentTerm.academicYear,
      academicTerm: currentTerm.termName,
      academicHeader: isGraduated
        ? `Graduated | Batch ${profile.batch_name || `${admissionYear}-${admissionYear + 4}`} | ${deptCode}`
        : `${yearLabel} • ${semesterRoman} Semester | ${currentTerm.academicYear} | ${deptCode}`,
      status: isGraduated ? 'GRADUATED' : profile.current_status,
      hasOverride: !!override,
      overrideReason: override?.reason || undefined,
    };
  }

  /**
   * Idempotent Academic Year Transition Process.
   * Advances active students:
   *   1st Year -> 2nd Year
   *   2nd Year -> 3rd Year
   *   3rd Year -> 4th Year
   *   4th Year -> Graduated
   * If already processed for this academic year, skips execution.
   */
  async processYearTransition(collegeId: string, academicYearId: string, actorUserId?: string): Promise<{
    success: boolean;
    alreadyProcessed: boolean;
    academicYear: string;
    studentsAffected: number;
    graduatedCount: number;
    message: string;
  }> {
    const academicYear = await prisma.academicYear.findUnique({
      where: { id: academicYearId },
    });
    if (!academicYear || academicYear.college_id !== collegeId) {
      throw new Error('Academic year not found');
    }

    // 1. Check if transition already processed (idempotency guard)
    const existing = await prisma.academicTransitionRecord.findUnique({
      where: {
        college_id_academic_year_id: {
          college_id: collegeId,
          academic_year_id: academicYearId,
        },
      },
    });

    if (existing) {
      return {
        success: true,
        alreadyProcessed: true,
        academicYear: academicYear.year_name,
        studentsAffected: existing.students_affected,
        graduatedCount: existing.graduated_count,
        message: `Academic year transition for ${academicYear.year_name} was already processed on ${existing.processed_at.toISOString().split('T')[0]}.`,
      };
    }

    // 2. Parse academic year start (e.g. "2026-27" -> 2026)
    const ayMatch = academicYear.year_name.match(/^(\d{4})/);
    const ayStartYear = ayMatch ? parseInt(ayMatch[1], 10) : new Date(academicYear.start_date).getFullYear();

    // 3. Find all students in college
    const students = await prisma.user.findMany({
      where: {
        college_id: collegeId,
        role: 'STUDENT',
        status: { not: 'DEACTIVATED' },
      },
      include: {
        academic_profile: {
          include: { program: true },
        },
      },
    });

    let studentsAffected = 0;
    let graduatedCount = 0;

    for (const student of students) {
      const profile = student.academic_profile;
      if (!profile) continue;

      if (profile.current_status === 'GRADUATED') {
        continue;
      }

      const admissionYear = profile.admission_year;
      const totalSemesters = profile.program?.total_semesters || 8;
      const maxYear = Math.ceil(totalSemesters / 2);

      const newYearOfStudy = ayStartYear - admissionYear + 1;

      if (newYearOfStudy > maxYear) {
        // Mark as Graduated
        await prisma.studentAcademicProfile.update({
          where: { id: profile.id },
          data: {
            current_status: 'GRADUATED',
            current_year: maxYear + 1,
          },
        });
        graduatedCount++;
        studentsAffected++;
      } else {
        await prisma.studentAcademicProfile.update({
          where: { id: profile.id },
          data: {
            current_year: newYearOfStudy,
          },
        });
        studentsAffected++;
      }
    }

    // 4. Record transition
    await prisma.academicTransitionRecord.create({
      data: {
        college_id: collegeId,
        academic_year_id: academicYearId,
        academic_year: academicYear.year_name,
        processed_by: actorUserId,
        students_affected: studentsAffected,
        graduated_count: graduatedCount,
        notes: `Automated progression transition for academic calendar year ${academicYear.year_name}.`,
      },
    });

    return {
      success: true,
      alreadyProcessed: false,
      academicYear: academicYear.year_name,
      studentsAffected,
      graduatedCount,
      message: `Academic year transition completed successfully for ${academicYear.year_name}. ${studentsAffected} students progressed (${graduatedCount} graduated).`,
    };
  }

  /**
   * Ensures authentic subjects and enrollments for student's derived semester.
   */
  async ensureCurriculumAndEnrollments(studentId: string, targetDate: Date = new Date()) {
    const progression = await this.deriveStudentProgression(studentId, targetDate);
    const currentTerm = await this.getCurrentTerm(progression.departmentId ? (await prisma.user.findUnique({ where: { id: studentId } }))?.college_id! : '', targetDate);

    // Find or link authentic subjects matching this semester
    const semesterStr = `Semester ${progression.semester}`;
    const subjects = await prisma.subject.findMany({
      where: {
        semester: semesterStr,
      },
    });

    for (const sub of subjects) {
      // Connect academic_term_id if not set
      if (!sub.academic_term_id) {
        await prisma.subject.update({
          where: { id: sub.id },
          data: {
            academic_term_id: currentTerm.termId,
            academic_year: currentTerm.academicYear,
          },
        });
      }

      // Upsert SubjectEnrollment
      const existingEnrollment = await prisma.subjectEnrollment.findUnique({
        where: {
          subject_id_student_id: {
            subject_id: sub.id,
            student_id: studentId,
          },
        },
      });

      if (!existingEnrollment) {
        await prisma.subjectEnrollment.create({
          data: {
            subject_id: sub.id,
            student_id: studentId,
            academic_term_id: currentTerm.termId,
            section: progression.section,
            status: 'ACTIVE',
          },
        });
      } else if (!existingEnrollment.academic_term_id) {
        await prisma.subjectEnrollment.update({
          where: { id: existingEnrollment.id },
          data: {
            academic_term_id: currentTerm.termId,
            section: progression.section,
            status: 'ACTIVE',
          },
        });
      }
    }
  }
}

export const termResolutionService = new TermResolutionService();
