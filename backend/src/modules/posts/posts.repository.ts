import { prisma } from '../../config/database';
import { Post, PostType } from '@prisma/client';
import { FeedType } from './posts.types';

export class PostsRepository {
  async getPosts({
    userId,
    collegeId,
    departmentId,
    feedType,
    skip,
    take,
  }: {
    userId: string;
    collegeId: string;
    departmentId?: string | null;
    feedType: FeedType;
    skip: number;
    take: number;
  }) {
    let whereCondition: Record<string, unknown> = { college_id: collegeId };

    switch (feedType) {
      case FeedType.MY_FEED:
        whereCondition = { author_id: userId };
        break;
      case FeedType.DEPARTMENT:
        if (departmentId) whereCondition.department_id = departmentId;
        break;
      case FeedType.CROSS_DEPARTMENT:
        if (departmentId) whereCondition.department_id = { not: departmentId };
        break;
      case FeedType.CLUB:
        whereCondition.type = PostType.ANNOUNCEMENT;
        break;
      case FeedType.FOLLOWING:
        whereCondition.author = {
          followers: {
            some: { follower_id: userId },
          },
        };
        break;
    }

    return prisma.post.findMany({
      where: whereCondition as never,
      skip,
      take,
      orderBy: { created_at: 'desc' },
      include: {
        author: {
          select: { id: true, first_name: true, last_name: true, avatar_url: true, role: true },
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

  async createPost(data: {
    collegeId: string;
    departmentId?: string | null;
    authorId: string;
    title: string;
    content: string;
    type: PostType;
    attachments?: Array<{ fileName: string; fileUrl: string; fileType: string }>;
  }): Promise<Post> {
    return prisma.post.create({
      data: {
        college_id: data.collegeId,
        department_id: data.departmentId,
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

  async addComment(postId: string, userId: string, content: string) {
    return prisma.postComment.create({
      data: {
        post_id: postId,
        author_id: userId,
        content,
      },
      include: {
        author: {
          select: { id: true, first_name: true, last_name: true, avatar_url: true },
        },
      },
    });
  }

  async getComments(postId: string) {
    return prisma.postComment.findMany({
      where: { post_id: postId },
      orderBy: { created_at: 'asc' },
      include: {
        author: {
          select: { id: true, first_name: true, last_name: true, avatar_url: true },
        },
      },
    });
  }
}
