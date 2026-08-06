export interface CreateEventDto {
  title: string;
  description?: string;
  scope: 'COLLEGE' | 'DEPARTMENT' | 'CLUB';
  department_id?: string;
  club_id?: string;
  category?: string;
  venue?: string;
  start_time: string;
  end_time: string;
  banner_url?: string;
  max_capacity?: number;
  registration_deadline?: string;
}

export interface QueryEventsDto {
  scope?: 'COLLEGE' | 'DEPARTMENT' | 'CLUB';
  department_id?: string;
  club_id?: string;
  category?: string;
  search?: string;
  page?: number;
  limit?: number;
}

export interface MarkQRAttendanceDto {
  ticket_code: string;
}

export interface CalendarQueryDto {
  month?: number;
  year?: number;
}
