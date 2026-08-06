import { ClubRole, ClubStatus, PostType } from '@prisma/client';

export interface CreateClubDto {
  name: string;
  category: string;
  description?: string;
  logo_url?: string;
  is_cross_department?: boolean;
}

export interface VerifyClubDto {
  status: ClubStatus;
  rejection_reason?: string;
}

export interface UpdateClubMemberDto {
  role: ClubRole;
}

export interface CreateClubPostDto {
  title: string;
  content: string;
  type?: PostType;
}

export interface CreateClubEventDto {
  title: string;
  description?: string;
  venue?: string;
  start_time: string;
  end_time: string;
  banner_url?: string;
}

export interface CreateClubResourceDto {
  title: string;
  description?: string;
  file_url: string;
  file_name: string;
  file_type: string;
}

export interface SendClubChatMessageDto {
  message: string;
}

export interface QueryClubsDto {
  category?: string;
  status?: ClubStatus;
  search?: string;
  is_cross_department?: boolean;
  page?: number;
  limit?: number;
}
