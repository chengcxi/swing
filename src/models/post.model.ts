export interface Post {
  id: number | string;
  author: string;
  authorUsername: string;
  authorAvatar: string;
  timestamp: string;
  content: string;
  image?: string;
  likes: number;
  comments: number;
  taggedUsers?: string[];
  taggedCourses?: string[];
}
