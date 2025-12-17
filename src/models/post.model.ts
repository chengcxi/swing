export interface Post {
  id: number;
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
