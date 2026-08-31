import { prisma } from '../../config/database';
import { Post, PostType } from '@prisma/client';
import { FeedType } from './posts.types';

export class PostsRepository {
  async getPosts({
    userId,
    collegeId,
    departmentId,
    feedType,
    authorId,
    clubId,
    departmentIdFilter,
    search,
    skip,
    take,
  }: {
    userId: string;
    collegeId: string;
    departmentId?: string | null;
    feedType: FeedType;
    authorId?: string;
    clubId?: string;
    departmentIdFilter?: string;
    search?: string;
    skip: number;
    take: number;
  }) {
    let effectiveDeptId = departmentId;
    if (!effectiveDeptId && userId) {
      try {
        const user = await prisma.user.findUnique({
          where: { id: userId },
          select: { department_id: true },
        });
        effectiveDeptId = user?.department_id;
      } catch (_) {}
    }

    let whereCondition: Record<string, unknown> = { college_id: collegeId };

    if (authorId) {
      whereCondition = { author_id: authorId };
    } else if (clubId) {
      whereCondition = { club_id: clubId };
    } else if (departmentIdFilter) {
      whereCondition = { department_id: departmentIdFilter };
    } else {
      switch (feedType) {
        case FeedType.MY_FEED:
          whereCondition = { college_id: collegeId };
          break;
        case FeedType.DEPARTMENT:
          if (effectiveDeptId) {
            whereCondition.OR = [
              { department_id: effectiveDeptId },
              { department_id: null },
            ];
          }
          break;
        case FeedType.CROSS_DEPARTMENT:
          if (effectiveDeptId) {
            whereCondition.OR = [
              { department_id: { not: effectiveDeptId } },
              { department_id: null },
              { type: PostType.EVENT_PROMO },
              { type: PostType.PLACEMENT },
              { type: PostType.ANNOUNCEMENT },
            ];
          } else {
            whereCondition = { college_id: collegeId };
          }
          break;
        case FeedType.CLUB:
          whereCondition.OR = [
            { type: PostType.ANNOUNCEMENT },
            { type: PostType.EVENT_PROMO },
            { club_id: { not: null } },
          ];
          break;
        case FeedType.FOLLOWING:
          whereCondition = {
            college_id: collegeId,
            author: {
              followers: {
                some: { follower_id: userId },
              },
            },
          };
          break;
        case FeedType.MY_POSTS:
          whereCondition = { author_id: userId, club_id: null };
          break;
        case FeedType.AUTHOR:
          whereCondition = { author_id: authorId || userId, club_id: null };
          break;
        case FeedType.SAVED:
          whereCondition = {
            saves: {
              some: { user_id: userId },
            },
          };
          break;
      }
    }

    if (search && search.trim().length > 0) {
      whereCondition.AND = [
        {
          OR: [
            { title: { contains: search.trim(), mode: 'insensitive' } },
            { content: { contains: search.trim(), mode: 'insensitive' } },
          ],
        },
      ];
    }

    return prisma.post.findMany({
      where: whereCondition as never,
      skip,
      take,
      orderBy: { created_at: 'desc' },
      include: {
        author: {
          select: { id: true, username: true, first_name: true, last_name: true, avatar_url: true, role: true },
        },
        club: {
          select: { id: true, name: true, logo_url: true, category: true },
        },
        attachments: true,
        _count: {
          select: { likes: true, comments: true },
        },
        likes: {
          where: { user_id: userId },
          select: { id: true },
        },
        saves: {
          where: { user_id: userId },
          select: { id: true },
        },
      },
    });
  }

  async getFeed(params: {
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
  }) {
    const skip = (params.page - 1) * params.limit;
    return this.getPosts({
      userId: params.userId,
      collegeId: params.collegeId,
      departmentId: params.departmentId,
      feedType: params.feedType,
      authorId: params.authorId,
      clubId: params.clubId,
      departmentIdFilter: params.departmentIdFilter,
      search: params.search,
      skip,
      take: params.limit,
    });
  }

  async createPost(data: {
    collegeId: string;
    departmentId?: string | null;
    clubId?: string | null;
    authorId: string;
    title: string;
    content: string;
    type: PostType;
    attachments?: Array<{ fileName: string; fileUrl: string; fileType: string }> | null;
  }): Promise<Post> {
    let effectiveCollegeId = data.collegeId;
    let effectiveDeptId = data.departmentId;

    if (data.authorId) {
      try {
        const user = await prisma.user.findUnique({
          where: { id: data.authorId },
          select: { college_id: true, department_id: true },
        });
        if (user?.college_id) {
          effectiveCollegeId = user.college_id;
        }
        if (!effectiveDeptId) {
          effectiveDeptId = user?.department_id;
        }
      } catch (_) {}
    }

    if (!effectiveCollegeId) {
      const firstCollege = await prisma.college.findFirst({ select: { id: true } });
      if (firstCollege) {
        effectiveCollegeId = firstCollege.id;
      }
    }

    return prisma.post.create({
      data: {
        college_id: effectiveCollegeId,
        department_id: effectiveDeptId,
        club_id: data.clubId,
        author_id: data.authorId,
        title: data.title,
        content: data.content,
        type: data.type,
        attachments: data.attachments
          ? {
              create: data.attachments.map((a) => ({
                file_name: a.fileName,
                file_url: a.fileUrl,
                file_type: a.fileType,
              })),
            }
          : undefined,
      },
      include: {
        author: {
          select: { id: true, first_name: true, last_name: true, avatar_url: true, role: true },
        },
        attachments: true,
      },
    });
  }

  async toggleLike(postId: string, userId: string): Promise<boolean> {
    const existing = await prisma.postLike.findUnique({
      where: { post_id_user_id: { post_id: postId, user_id: userId } },
    });

    if (existing) {
      await prisma.postLike.delete({ where: { id: existing.id } });
      return false;
    } else {
      await prisma.postLike.create({
        data: { post_id: postId, user_id: userId },
      });
      return true;
    }
  }

  async toggleSave(postId: string, userId: string): Promise<boolean> {
    const existing = await prisma.savedPost.findUnique({
      where: { post_id_user_id: { post_id: postId, user_id: userId } },
    });

    if (existing) {
      await prisma.savedPost.delete({ where: { id: existing.id } });
      return false;
    } else {
      await prisma.savedPost.create({
        data: { post_id: postId, user_id: userId },
      });
      return true;
    }
  }

  async addComment(postId: string, userId: string, content: string, parentId?: string | null) {
    return prisma.postComment.create({
      data: {
        post_id: postId,
        author_id: userId,
        parent_id: parentId || null,
        content,
      },
      include: {
        author: {
          select: { id: true, first_name: true, last_name: true, avatar_url: true, role: true },
        },
        _count: {
          select: { likes: true, replies: true },
        },
        likes: {
          where: { user_id: userId },
          select: { id: true },
        },
      },
    });
  }

  async toggleCommentLike(commentId: string, userId: string): Promise<{ isLiked: boolean; likesCount: number }> {
    const existing = await prisma.postCommentLike.findUnique({
      where: { comment_id_user_id: { comment_id: commentId, user_id: userId } },
    });

    if (existing) {
      await prisma.postCommentLike.delete({ where: { id: existing.id } });
    } else {
      await prisma.postCommentLike.create({
        data: { comment_id: commentId, user_id: userId },
      });
    }

    const likesCount = await prisma.postCommentLike.count({
      where: { comment_id: commentId },
    });

    return { isLiked: !existing, likesCount };
  }

  async getComments(postId: string, currentUserId?: string) {
    const commentInclude: any = {
      author: {
        select: { id: true, username: true, first_name: true, last_name: true, avatar_url: true, role: true },
      },
      _count: {
        select: { likes: true, replies: true },
      },
      replies: {
        orderBy: { created_at: 'asc' },
        include: {
          author: {
            select: { id: true, username: true, first_name: true, last_name: true, avatar_url: true, role: true },
          },
          _count: {
            select: { likes: true, replies: true },
          },
          ...(currentUserId && {
            likes: {
              where: { user_id: currentUserId },
              select: { id: true },
            },
          }),
        },
      },
    };

    if (currentUserId) {
      commentInclude.likes = {
        where: { user_id: currentUserId },
        select: { id: true },
      };
    }

    return prisma.postComment.findMany({
      where: { post_id: postId, parent_id: null },
      orderBy: { created_at: 'asc' },
      include: commentInclude,
    });
  }

  async findPostById(postId: string) {
    return prisma.post.findUnique({
      where: { id: postId },
      include: {
        club: {
          include: {
            members: true,
          },
        },
      },
    });
  }

  async deletePost(postId: string) {
    return prisma.post.delete({
      where: { id: postId },
    });
  }

  async updatePost(postId: string, data: { title?: string; content?: string; type?: PostType }) {
    return prisma.post.update({
      where: { id: postId },
      data: {
        title: data.title,
        content: data.content,
        type: data.type,
      },
      include: {
        author: {
          select: { id: true, first_name: true, last_name: true, avatar_url: true, role: true },
        },
        attachments: true,
        _count: {
          select: { likes: true, comments: true },
        },
      },
    });
  }
}
