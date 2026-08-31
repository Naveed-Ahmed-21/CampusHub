import crypto from 'crypto';
import { PostsRepository } from './posts.repository';
import { CreatePostDTO, FeedType, PostResponseDTO } from './posts.types';
import { PostType } from '@prisma/client';
import { logger } from '../../infrastructure/logger/logger';

export class PostsService {
  constructor(private readonly postsRepo: PostsRepository) {}

  async getFeed({
    userId,
    collegeId,
    departmentId,
    feedType,
    authorId,
    clubId,
    departmentIdFilter,
    search,
    page,
    limit,
  }: {
    userId: string;
    collegeId: string;
    departmentId?: string | null;
    feedType: FeedType;
    authorId?: string;
    clubId?: string;
    departmentIdFilter?: string;
    search?: string;
    page: number;
    limit: number;
  }): Promise<PostResponseDTO[]> {
    try {
      const skip = (page - 1) * limit;
      const posts = await this.postsRepo.getPosts({
        userId,
        collegeId,
        departmentId,
        feedType,
        authorId,
        clubId,
        departmentIdFilter,
        search,
        skip,
        take: limit,
      });

      return posts.map((p) => ({
        id: p.id,
        title: p.title,
        content: p.content,
        type: p.type,
        isPinned: p.is_pinned,
        createdAt: p.created_at,
        author: {
          id: p.author.id,
          name: `${p.author.first_name} ${p.author.last_name}`,
          avatarUrl: p.author.avatar_url,
          role: p.author.role,
        },
        clubId: (p as any).club_id || (p as any).club?.id || null,
        clubName: (p as any).club?.name || null,
        clubLogoUrl: (p as any).club?.logo_url || null,
        clubCategory: (p as any).club?.category || null,
        club: (p as any).club || null,
        attachments: p.attachments.map((a) => ({
          id: a.id,
          fileName: a.file_name,
          fileUrl: a.file_url,
          fileType: a.file_type,
        })),
        likesCount: p._count.likes,
        commentsCount: p._count.comments,
        isLiked: p.likes.length > 0,
        isSaved: p.saves.length > 0,
      }));
    } catch (err) {
      logger.error({ err }, 'Error in getFeed repository query');
      return [];
    }
  }

  async createPost(
    userId: string,
    collegeId: string,
    departmentId: string | undefined | null,
    dto: CreatePostDTO
  ): Promise<PostResponseDTO> {
    const isCross = dto.isCrossDepartment === true || dto.scope === 'CROSS_DEPARTMENT';
    const effectiveDepartmentId = isCross ? null : (dto.departmentId !== undefined ? dto.departmentId : departmentId);
    const effectiveClubId = dto.clubId || (dto as any).club_id || null;

    const post = await this.postsRepo.createPost({
      collegeId,
      departmentId: effectiveDepartmentId,
      clubId: effectiveClubId,
      authorId: userId,
      title: dto.title,
      content: dto.content,
      type: dto.type as PostType,
      attachments: dto.attachments,
    });

    const p = post as never as {
      id: string;
      title: string;
      content: string;
      type: string;
      is_pinned: boolean;
      created_at: Date;
      club_id?: string | null;
      club?: { id: string; name: string; logo_url?: string | null; category?: string | null } | null;
      author: { id: string; first_name: string; last_name: string; avatar_url?: string | null; role: string };
      attachments: Array<{ id: string; file_name: string; file_url: string; file_type: string }>;
    };

    return {
      id: p.id,
      title: p.title,
      content: p.content,
      type: p.type,
      isPinned: p.is_pinned,
      createdAt: p.created_at,
      author: {
        id: p.author.id,
        name: `${p.author.first_name} ${p.author.last_name}`,
        avatarUrl: p.author.avatar_url,
        role: p.author.role,
      },
      clubId: p.club_id || p.club?.id || effectiveClubId || null,
      clubName: p.club?.name || null,
      clubLogoUrl: p.club?.logo_url || null,
      clubCategory: p.club?.category || null,
      club: p.club || null,
      attachments: (p.attachments || []).map((a) => ({
        id: a.id,
        fileName: a.file_name,
        fileUrl: a.file_url,
        fileType: a.file_type,
      })),
      likesCount: 0,
      commentsCount: 0,
      isLiked: false,
      isSaved: false,
    };
  }

  async toggleLike(postId: string, userId: string): Promise<{ isLiked: boolean }> {
    const isLiked = await this.postsRepo.toggleLike(postId, userId);
    return { isLiked };
  }

  async toggleSave(postId: string, userId: string): Promise<{ isSaved: boolean }> {
    const isSaved = await this.postsRepo.toggleSave(postId, userId);
    return { isSaved };
  }

  async addComment(postId: string, userId: string, content: string, parentCommentId?: string | null) {
    const comment = await this.postsRepo.addComment(postId, userId, content, parentCommentId);
    return {
      id: comment.id,
      postId: comment.post_id,
      authorId: comment.author_id,
      parentCommentId: comment.parent_id,
      content: comment.content,
      createdAt: comment.created_at,
      updatedAt: comment.updated_at,
      author: {
        id: comment.author.id,
        name: `${comment.author.first_name} ${comment.author.last_name}`,
        avatarUrl: comment.author.avatar_url,
      },
      likesCount: comment._count.likes,
      isLiked: comment.likes.length > 0,
      repliesCount: comment._count.replies,
      replies: [],
    };
  }

  async toggleCommentLike(commentId: string, userId: string): Promise<{ isLiked: boolean; likesCount: number }> {
    return this.postsRepo.toggleCommentLike(commentId, userId);
  }

  async getComments(postId: string, currentUserId?: string) {
    const comments = await this.postsRepo.getComments(postId, currentUserId);
    return comments.map((c: any) => ({
      id: c.id,
      postId: c.post_id,
      authorId: c.author_id,
      parentCommentId: c.parent_id,
      content: c.content,
      createdAt: c.created_at,
      updatedAt: c.updated_at,
      author: {
        id: c.author.id,
        name: `${c.author.first_name} ${c.author.last_name}`,
        avatarUrl: c.author.avatar_url,
      },
      likesCount: c._count?.likes ?? 0,
      isLiked: Array.isArray(c.likes) && c.likes.length > 0,
      repliesCount: c._count?.replies ?? 0,
      replies: (c.replies || []).map((r: any) => ({
        id: r.id,
        postId: r.post_id,
        authorId: r.author_id,
        parentCommentId: r.parent_id,
        content: r.content,
        createdAt: r.created_at,
        updatedAt: r.updated_at,
        author: {
          id: r.author.id,
          name: `${r.author.first_name} ${r.author.last_name}`,
          avatarUrl: r.author.avatar_url,
        },
        likesCount: r._count?.likes ?? 0,
        isLiked: Array.isArray(r.likes) && r.likes.length > 0,
        repliesCount: r._count?.replies ?? 0,
      })),
    }));
  }

  async checkOwnershipOrAdmin(postId: string, userId: string, userRole: string): Promise<boolean> {
    try {
      if (['ADMIN', 'COLLEGE_ADMIN', 'SUPER_ADMIN'].includes(userRole)) return true;
      const post = await this.postsRepo.findPostById(postId);
      if (!post) return false;
      if (post.club_id && (post as any).club) {
        const club = (post as any).club;
        if (club.created_by_id === userId) return true;
        const member = club.members?.find((m: any) => m.user_id === userId);
        if (member && ['LEAD', 'ASSISTANT_ADMIN', 'FACULTY_ADVISOR'].includes(member.role)) {
          return true;
        }
        return false;
      }
      return post.author_id === userId;
    } catch (_) {
      return ['ADMIN', 'COLLEGE_ADMIN', 'SUPER_ADMIN'].includes(userRole);
    }
  }

  async deletePost(postId: string): Promise<void> {
    try {
      await this.postsRepo.deletePost(postId);
    } catch (_) {
      // Fallback
    }
  }

  async updatePost(postId: string, data: { title?: string; content?: string; type?: PostType }) {
    return this.postsRepo.updatePost(postId, data);
  }
}
