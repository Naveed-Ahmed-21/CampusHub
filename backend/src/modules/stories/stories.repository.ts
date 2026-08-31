import { prisma } from '../../config/database';
import { CreateStoryDTO, UserStoriesGroupDTO } from './stories.types';

export class StoriesRepository {
  async getActiveStoriesGroupedByUser(collegeId: string, currentUserId: string): Promise<UserStoriesGroupDTO[]> {
    const now = new Date();

    const rawStories = await prisma.story.findMany({
      where: {
        college_id: collegeId,
        expires_at: {
          gt: now,
        },
      },
      orderBy: {
        created_at: 'asc',
      },
      include: {
        user: {
          select: {
            id: true,
            first_name: true,
            last_name: true,
            avatar_url: true,
            role: true,
          },
        },
        views: {
          select: {
            user_id: true,
          },
        },
        _count: {
          select: {
            views: true,
          },
        },
      },
    });

    const userMap = new Map<string, UserStoriesGroupDTO>();

    for (const story of rawStories) {
      const isViewed = story.views.some((v) => v.user_id === currentUserId);
      const storyDto = {
        id: story.id,
        mediaUrl: story.media_url,
        mediaType: story.media_type,
        caption: story.caption,
        duration: story.duration,
        createdAt: story.created_at,
        expiresAt: story.expires_at,
        isViewed,
        viewsCount: story._count.views,
      };

      if (!userMap.has(story.user_id)) {
        userMap.set(story.user_id, {
          userId: story.user.id,
          userName: `${story.user.first_name} ${story.user.last_name}`.trim(),
          userAvatar: story.user.avatar_url,
          userRole: story.user.role,
          hasUnseenStories: !isViewed,
          latestStoryCreatedAt: story.created_at,
          stories: [storyDto],
        });
      } else {
        const group = userMap.get(story.user_id)!;
        group.stories.push(storyDto);
        if (!isViewed) {
          group.hasUnseenStories = true;
        }
        if (story.created_at > group.latestStoryCreatedAt) {
          group.latestStoryCreatedAt = story.created_at;
        }
      }
    }

    const groups = Array.from(userMap.values());
    // Sort groups: current user first (if exists), then users with unseen stories, then by latest story created_at desc
    return groups.sort((a, b) => {
      if (a.userId === currentUserId) return -1;
      if (b.userId === currentUserId) return 1;
      if (a.hasUnseenStories && !b.hasUnseenStories) return -1;
      if (!a.hasUnseenStories && b.hasUnseenStories) return 1;
      return b.latestStoryCreatedAt.getTime() - a.latestStoryCreatedAt.getTime();
    });
  }

  async createStory(userId: string, collegeId: string, dto: CreateStoryDTO) {
    const now = new Date();
    const expiresAt = new Date(now.getTime() + 24 * 60 * 60 * 1000); // 24 hours

    let effectiveCollegeId = collegeId;
    if (userId) {
      try {
        const user = await prisma.user.findUnique({
          where: { id: userId },
          select: { college_id: true },
        });
        if (user?.college_id) {
          effectiveCollegeId = user.college_id;
        }
      } catch (_) {}
    }

    if (!effectiveCollegeId) {
      const firstCollege = await prisma.college.findFirst({ select: { id: true } });
      if (firstCollege) {
        effectiveCollegeId = firstCollege.id;
      }
    }

    return prisma.story.create({
      data: {
        college_id: effectiveCollegeId,
        user_id: userId,
        media_url: dto.mediaUrl,
        media_type: dto.mediaType || 'IMAGE',
        caption: dto.caption,
        duration: dto.duration || 5,
        expires_at: expiresAt,
      },
      include: {
        user: {
          select: {
            id: true,
            first_name: true,
            last_name: true,
            avatar_url: true,
            role: true,
          },
        },
      },
    });
  }

  async markAsViewed(storyId: string, userId: string) {
    return prisma.storyView.upsert({
      where: {
        story_id_user_id: {
          story_id: storyId,
          user_id: userId,
        },
      },
      create: {
        story_id: storyId,
        user_id: userId,
      },
      update: {},
    });
  }

  async deleteStory(storyId: string, userId: string, isAdmin = false) {
    const story = await prisma.story.findUnique({
      where: { id: storyId },
    });

    if (!story) return null;
    if (story.user_id !== userId && !isAdmin) return null;

    return prisma.story.delete({
      where: { id: storyId },
    });
  }
}
