abstract class MockData {
  static const mockUser = {
    'id': 'std_10092',
    'email': 'student@campushub.edu',
    'first_name': 'Alex',
    'last_name': 'Vance',
    'role': 'STUDENT',
    'roll_number': 'CS2026-10092',
    'department': {'name': 'Computer Science & Engineering'},
  };

  static const mockPosts = [
    {
      'id': 'post_1',
      'title': 'CampusHack 2026 Announcement',
      'content': 'Join us for 48 hours of building cutting-edge apps!',
      'type': 'ANNOUNCEMENT',
      'isPinned': true,
      'createdAt': '2026-08-06T10:00:00.000Z',
      'author': {'id': 'usr_1', 'name': 'Dr. Sarah Connor', 'role': 'FACULTY'},
      'attachments': [],
      'likesCount': 24,
      'commentsCount': 5,
      'isLiked': true,
      'isSaved': false,
    },
  ];

  static const mockEvents = [
    {
      'id': 'evt_1',
      'title': 'Annual AI & Robotics Workshop',
      'description': 'Hands-on building with ROS2 and Neural Networks.',
      'location': 'Auditorium 2, Tech Block',
      'start_time': '2026-09-10T09:00:00.000Z',
      'end_time': '2026-09-10T17:00:00.000Z',
      'scope': 'COLLEGE',
      'registered_count': 142,
      'is_registered': false,
    },
  ];

  static const mockAdminMetrics = {
    'totalUsers': 1420,
    'totalDepartments': 6,
    'approvedClubs': 14,
    'pendingClubs': 2,
    'totalEvents': 28,
    'totalDrives': 12,
    'placedCount': 84,
  };
}
