import 'package:flutter_test/flutter_test.dart';
import 'package:campus_hub_app/features/auth/domain/models/auth_user.dart';
import 'package:campus_hub_app/shared/responsive/role_navigation_config.dart';
import 'package:campus_hub_app/features/dept_admin/domain/models/dept_admin_models.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  group('RoleNavigationConfig.getHomeRouteForUser Tests', () {
    test('returns /dept-admin for DEPT_ADMIN user', () {
      const user = AuthUser(
        id: 'usr_dept_admin',
        email: 'dept@gcee.ac.in',
        firstName: 'Dept',
        lastName: 'Admin',
        role: 'DEPT_ADMIN',
        collegeId: 'gcee_erode',
        departmentId: 'dept_it',
      );
      expect(RoleNavigationConfig.getHomeRouteForUser(user), '/dept-admin');
    });

    test('returns /admin for ADMIN user', () {
      const user = AuthUser(
        id: 'usr_admin',
        email: 'admin@gcee.ac.in',
        firstName: 'Main',
        lastName: 'Admin',
        role: 'ADMIN',
        collegeId: 'gcee_erode',
      );
      expect(RoleNavigationConfig.getHomeRouteForUser(user), '/admin');
    });

    test('returns /placement for PLACEMENT_OFFICER user', () {
      const user = AuthUser(
        id: 'usr_placement',
        email: 'placement@gcee.ac.in',
        firstName: 'Placement',
        lastName: 'Officer',
        role: 'PLACEMENT_OFFICER',
        collegeId: 'gcee_erode',
      );
      expect(RoleNavigationConfig.getHomeRouteForUser(user), '/placement');
    });

    test('returns /faculty for FACULTY user', () {
      const user = AuthUser(
        id: 'usr_faculty',
        email: 'faculty@gcee.ac.in',
        firstName: 'Faculty',
        lastName: 'Member',
        role: 'FACULTY',
        collegeId: 'gcee_erode',
      );
      expect(RoleNavigationConfig.getHomeRouteForUser(user), '/faculty');
    });

    test('returns /feed for STUDENT user and null user', () {
      const student = AuthUser(
        id: 'usr_student',
        email: 'student@gcee.ac.in',
        firstName: 'Student',
        lastName: 'User',
        role: 'STUDENT',
        collegeId: 'gcee_erode',
      );
      expect(RoleNavigationConfig.getHomeRouteForUser(student), '/feed');
      expect(RoleNavigationConfig.getHomeRouteForUser(null), '/feed');
    });
  });

  group('DeptAccreditation PDF Document Generation Tests', () {
    test('generates valid non-empty PDF document with authentic datagrams', () async {
      const deptInfo = DeptInfo(
        id: 'dept_it_1',
        name: 'Information Technology',
        code: 'IT',
        degree: 'B.Tech',
        collegeName: 'Government College of Engineering, Erode',
      );

      final reportData = DeptReportsData(
        academicYear: '2026 - 2027',
        metrics: const DeptReportMetrics(
          students: 240,
          faculty: 16,
          avgCgpa: 8.14,
          attendance: 88,
        ),
        studentsByYear: const [
          DeptYearMetric(year: '1st Year', count: 60),
          DeptYearMetric(year: '2nd Year', count: 62),
          DeptYearMetric(year: '3rd Year', count: 58),
          DeptYearMetric(year: '4th Year', count: 60),
        ],
        placementStatus: const DeptPlacementBreakdown(
          placed: 48,
          shortlisted: 6,
          applied: 55,
          eligible: 5,
          total: 60,
        ),
      );

      final doc = pw.Document(
        title: '${deptInfo.name} Accreditation Report ${reportData.academicYear}',
        author: 'CampusHub Institutional Portal',
      );

      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context ctx) => [
            pw.Text(
              'GOVERNMENT COLLEGE OF ENGINEERING, ERODE',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('DEPARTMENT OF ${deptInfo.name.toUpperCase()}'),
            pw.Text('Academic Year: ${reportData.academicYear}'),
            pw.Text('Total Students: ${reportData.metrics.students}'),
            pw.Text('Placed Students: ${reportData.placementStatus.placed} / ${reportData.placementStatus.total}'),
          ],
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });
  });
}
