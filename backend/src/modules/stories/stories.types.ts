export interface CreateStoryDTO {
  mediaUrl: string;
  mediaType?: 'IMAGE' | 'VIDEO';
  caption?: string;
  duration?: number;
}

export interface StoryItemDTO {
  id: string;
  mediaUrl: string;
  mediaType: string;
  caption?: string | null;
  duration: number;
  createdAt: Date;
  expiresAt: Date;
  isViewed: boolean;
  viewsCount: number;
}

export interface UserStoriesGroupDTO {
  userId: string;
  userName: string;
  userAvatar?: string | null;
  userRole: string;
  hasUnseenStories: boolean;
  latestStoryCreatedAt: Date;
  stories: StoryItemDTO[];
}
