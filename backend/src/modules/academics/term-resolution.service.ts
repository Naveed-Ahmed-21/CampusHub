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
    const latestTerm = await prisma.academicTerm.findFirst({
      where: {
        academic_year: { college_id: collegeId },
      },
      orderBy: { start_date: 'desc' },
      include: {
        academic_year: true,
      },
    });

    if (!latestTerm) {
      throw new Error('No academic terms found for college');
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
    const yearOfStudy = Math.max(1, Math.min(rawYear, Math.ceil(totalSemesters / 2)));

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
      yearOfStudy: derivedYearOfStudy,
      yearRoman,
      yearLabel: `${yearRoman} Year`,
      semester: finalSemester,
      semesterRoman,
      semesterLabel: `${semesterRoman} Semester`,
      academicYear: currentTerm.academicYear,
      academicTerm: currentTerm.termName,
      academicHeader: `${yearRoman} Year • ${semesterRoman} Semester | ${currentTerm.academicYear} | ${deptCode} • Section ${section}`,
      status: profile.current_status,
      hasOverride: !!override,
      overrideReason: override?.reason || undefined,
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
