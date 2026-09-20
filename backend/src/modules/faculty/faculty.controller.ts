import { Request, Response } from 'express';
import { FacultyService } from './faculty.service';
import { ResponseUtil } from '../../shared/utils/api-response.util';
import { asyncHandler } from '../../shared/utils/async-handler.util';

export class FacultyController {
  constructor(private readonly service: FacultyService = new FacultyService()) {}

  getDashboard = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const collegeId = req.user!.collegeId;
    const data = await this.service.getDashboard(facultyId, collegeId);
    ResponseUtil.success(res, data, 'Faculty dashboard retrieved successfully');
  });

  getSubjects = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const collegeId = req.user!.collegeId;
    const data = await this.service.getSubjects(facultyId, collegeId);
    ResponseUtil.success(res, data, 'Faculty subjects retrieved successfully');
  });

  createSubject = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const collegeId = req.user!.collegeId;
    const data = await this.service.createSubject(facultyId, collegeId, req.body);
    ResponseUtil.success(res, data, 'Subject created and assigned successfully', 201);
  });

  updateSubject = asyncHandler(async (req: Request, res: Response) => {
    const subjectId = req.params.id as string;
    const facultyId = req.user!.userId;
    const userRole = req.user!.role;
    const data = await this.service.updateSubject(facultyId, subjectId, req.body, userRole);
    ResponseUtil.success(res, data, 'Subject updated successfully');
  });

  deleteSubject = asyncHandler(async (req: Request, res: Response) => {
    const subjectId = req.params.id as string;
    const facultyId = req.user!.userId;
    const userRole = req.user!.role;
    const data = await this.service.deleteSubject(facultyId, subjectId, userRole);
    ResponseUtil.success(res, data, 'Subject deleted successfully');
  });

  getSubjectDetails = asyncHandler(async (req: Request, res: Response) => {
    const subjectId = req.params.id as string;
    const userId = req.user!.userId;
    const userRole = req.user!.role;
    const data = await this.service.getSubjectDetails(subjectId, userId, userRole);
    ResponseUtil.success(res, data, 'Subject details retrieved successfully');
  });

  addSubjectResource = asyncHandler(async (req: Request, res: Response) => {
    const subjectId = req.params.id as string;
    const facultyId = req.user!.userId;
    const userRole = req.user!.role;
    const data = await this.service.addSubjectResource(facultyId, subjectId, req.body, userRole);
    ResponseUtil.success(res, data, 'Academic resource uploaded and linked successfully', 201);
  });

  updateSubjectResource = asyncHandler(async (req: Request, res: Response) => {
    const subjectId = req.params.id as string;
    const resourceId = req.params.resourceId as string;
    const facultyId = req.user!.userId;
    const userRole = req.user!.role;
    const data = await this.service.updateSubjectResource(facultyId, subjectId, resourceId, req.body, userRole);
    ResponseUtil.success(res, data, 'Academic resource updated successfully');
  });

  deleteSubjectResource = asyncHandler(async (req: Request, res: Response) => {
    const subjectId = req.params.id as string;
    const resourceId = req.params.resourceId as string;
    const facultyId = req.user!.userId;
    const userRole = req.user!.role;
    const data = await this.service.deleteSubjectResource(facultyId, subjectId, resourceId, userRole);
    ResponseUtil.success(res, data, 'Academic resource deleted successfully');
  });

  addSubjectAnnouncement = asyncHandler(async (req: Request, res: Response) => {
    const subjectId = req.params.id as string;
    const facultyId = req.user!.userId;
    const userRole = req.user!.role;
    const data = await this.service.addSubjectAnnouncement(facultyId, subjectId, req.body, userRole);
    ResponseUtil.success(res, data, 'Subject announcement published successfully', 201);
  });

  getTodaySchedule = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const data = await this.service.getTodaySchedule(facultyId);
    ResponseUtil.success(res, data, "Today's class schedule retrieved successfully");
  });

  getMentees = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const collegeId = req.user!.collegeId;
    const data = await this.service.getMentees(facultyId, collegeId);
    ResponseUtil.success(res, data, 'Faculty student mentees retrieved successfully');
  });

  getProfile = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const data = await this.service.getFacultyProfile(facultyId);
    ResponseUtil.success(res, data, 'Faculty profile retrieved successfully');
  });

  updateProfile = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const data = await this.service.updateFacultyProfile(facultyId, req.body);
    ResponseUtil.success(res, data, 'Faculty profile updated successfully');
  });

  createScheduleSlot = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const data = await this.service.createScheduleSlot(facultyId, req.body);
    ResponseUtil.success(res, data, 'Schedule slot created successfully', 201);
  });

  updateScheduleSlot = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const slotId = req.params.id as string;
    const data = await this.service.updateScheduleSlot(facultyId, slotId, req.body);
    ResponseUtil.success(res, data, 'Schedule slot updated successfully');
  });

  deleteScheduleSlot = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const slotId = req.params.id as string;
    await this.service.deleteScheduleSlot(facultyId, slotId);
    ResponseUtil.success(res, null, 'Schedule slot deleted successfully');
  });

  createAssignment = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const userRole = req.user!.role;
    const subjectId = req.params.id as string;
    const data = await this.service.createAssignment(facultyId, subjectId, req.body, userRole);
    ResponseUtil.success(res, data, 'Assignment created successfully', 201);
  });

  getSubjectAssignments = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const userRole = req.user!.role;
    const subjectId = req.params.id as string;
    const data = await this.service.getSubjectAssignments(facultyId, subjectId, userRole);
    ResponseUtil.success(res, data, 'Subject assignments retrieved successfully');
  });

  getAssignmentSubmissions = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const userRole = req.user!.role;
    const assignmentId = req.params.id as string;
    const data = await this.service.getAssignmentSubmissions(facultyId, assignmentId, userRole);
    ResponseUtil.success(res, data, 'Assignment submissions retrieved successfully');
  });

  gradeSubmission = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const userRole = req.user!.role;
    const assignmentId = req.params.id as string;
    const submissionId = req.params.submissionId as string;
    const data = await this.service.gradeAssignmentSubmission(
      facultyId,
      assignmentId,
      submissionId,
      req.body,
      userRole
    );
    ResponseUtil.success(res, data, 'Submission graded successfully');
  });

  recordAttendance = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const userRole = req.user!.role;
    const subjectId = req.params.id as string;
    const data = await this.service.recordAttendance(facultyId, subjectId, req.body, userRole);
    ResponseUtil.success(res, data, 'Attendance recorded successfully', 201);
  });

  getAttendanceSessions = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const userRole = req.user!.role;
    const subjectId = req.params.id as string;
    const data = await this.service.getAttendanceSessions(facultyId, subjectId, userRole);
    ResponseUtil.success(res, data, 'Attendance sessions retrieved successfully');
  });

  createAssessment = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const userRole = req.user!.role;
    const subjectId = req.params.id as string;
    const data = await this.service.createAssessment(facultyId, subjectId, req.body, userRole);
    ResponseUtil.success(res, data, 'Assessment created successfully', 201);
  });

  getSubjectAssessments = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const userRole = req.user!.role;
    const subjectId = req.params.id as string;
    const data = await this.service.getSubjectAssessments(facultyId, subjectId, userRole);
    ResponseUtil.success(res, data, 'Assessments retrieved successfully');
  });

  getAssessmentResults = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const userRole = req.user!.role;
    const assessmentId = req.params.id as string;
    const data = await this.service.getAssessmentResults(facultyId, assessmentId, userRole);
    ResponseUtil.success(res, data, 'Assessment results retrieved successfully');
  });

  recordAssessmentMarks = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const userRole = req.user!.role;
    const assessmentId = req.params.id as string;
    const data = await this.service.recordAssessmentMarks(facultyId, assessmentId, req.body, userRole);
    ResponseUtil.success(res, data, 'Assessment marks recorded successfully');
  });

  getAcademicContext = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const collegeId = req.user!.collegeId;
    const dateParam = req.query.date as string;
    const targetDate = dateParam ? new Date(dateParam) : new Date();
    const data = await this.service.getAcademicContext(facultyId, collegeId, targetDate);
    ResponseUtil.success(res, data, 'Faculty academic context retrieved successfully');
  });

  getSessionAttendance = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const userRole = req.user!.role;
    const sessionId = req.params.sessionId as string;
    const data = await this.service.getSessionAttendance(facultyId, sessionId, userRole);
    ResponseUtil.success(res, data, 'Session attendance retrieved successfully');
  });

  bulkRecordAttendance = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const userRole = req.user!.role;
    const data = await this.service.bulkRecordAttendance(facultyId, req.body, userRole);
    ResponseUtil.success(res, data, 'Attendance updated successfully');
  });

  updateAttendanceRecord = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const recordId = req.params.recordId as string;
    const { status, remarks } = req.body;
    const data = await this.service.updateAttendanceRecord(facultyId, recordId, status, remarks);
    ResponseUtil.success(res, data, 'Attendance record updated successfully');
  });

  toggleSessionLock = asyncHandler(async (req: Request, res: Response) => {
    const facultyId = req.user!.userId;
    const sessionId = req.params.sessionId as string;
    const lock = req.body.locked !== undefined ? Boolean(req.body.locked) : true;
    const data = await this.service.toggleSessionLock(facultyId, sessionId, lock);
    ResponseUtil.success(res, data, `Session attendance ${lock ? 'locked' : 'reopened'} successfully`);
  });
}

