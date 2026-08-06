class EventModel {
  final String id;
  final String collegeId;
  final String? departmentId;
  final String? clubId;
  final String organizerId;
  final String scope; // COLLEGE, DEPARTMENT, CLUB
  final String category;
  final String title;
  final String? description;
  final String? venue;
  final DateTime startTime;
  final DateTime endTime;
  final String? bannerUrl;
  final int? maxCapacity;
  final int registeredCount;
  final String? organizerName;
  final String? departmentName;
  final String? clubName;

  EventModel({
    required this.id,
    required this.collegeId,
    this.departmentId,
    this.clubId,
    required this.organizerId,
    required this.scope,
    required this.category,
    required this.title,
    this.description,
    this.venue,
    required this.startTime,
    required this.endTime,
    this.bannerUrl,
    this.maxCapacity,
    this.registeredCount = 0,
    this.organizerName,
    this.departmentName,
    this.clubName,
  });

  bool get isFull => maxCapacity != null && registeredCount >= maxCapacity!;

  factory EventModel.fromJson(Map<String, dynamic> json) {
    final organizer = json['organizer'] as Map<String, dynamic>? ?? {};
    final dept = json['department'] as Map<String, dynamic>? ?? {};
    final club = json['club'] as Map<String, dynamic>? ?? {};
    final countMap = json['_count'] as Map<String, dynamic>? ?? {};

    return EventModel(
      id: json['id'] ?? '',
      collegeId: json['college_id'] ?? '',
      departmentId: json['department_id'],
      clubId: json['club_id'],
      organizerId: json['organizer_id'] ?? '',
      scope: json['scope'] ?? 'COLLEGE',
      category: json['category'] ?? 'General',
      title: json['title'] ?? '',
      description: json['description'],
      venue: json['venue'],
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time']) : DateTime.now(),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : DateTime.now().add(const Duration(hours: 2)),
      bannerUrl: json['banner_url'],
      maxCapacity: json['max_capacity'],
      registeredCount: countMap['registrations'] ?? 0,
      organizerName: '${organizer['first_name'] ?? ''} ${organizer['last_name'] ?? ''}'.trim(),
      departmentName: dept['name'],
      clubName: club['name'],
    );
  }
}

class EventRegistrationModel {
  final String id;
  final String eventId;
  final String userId;
  final String status;
  final String ticketCode;
  final String? qrCodeToken;
  final String attendanceStatus; // REGISTERED, ATTENDED, CANCELLED
  final DateTime? attendedAt;
  final DateTime registeredAt;
  final EventModel? event;

  EventRegistrationModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.status,
    required this.ticketCode,
    this.qrCodeToken,
    required this.attendanceStatus,
    this.attendedAt,
    required this.registeredAt,
    this.event,
  });

  factory EventRegistrationModel.fromJson(Map<String, dynamic> json) {
    return EventRegistrationModel(
      id: json['id'] ?? '',
      eventId: json['event_id'] ?? '',
      userId: json['user_id'] ?? '',
      status: json['status'] ?? 'REGISTERED',
      ticketCode: json['ticket_code'] ?? '',
      qrCodeToken: json['qr_code_token'],
      attendanceStatus: json['attendance_status'] ?? 'REGISTERED',
      attendedAt: json['attended_at'] != null ? DateTime.parse(json['attended_at']) : null,
      registeredAt: json['registered_at'] != null ? DateTime.parse(json['registered_at']) : DateTime.now(),
      event: json['event'] != null ? EventModel.fromJson(json['event']) : null,
    );
  }
}
