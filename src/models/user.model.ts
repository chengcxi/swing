export interface User {
  id: string;
  name: string;
  username: string;
  avatar: string;
  isVerified: boolean;
  isPro: boolean;
  description?: string;
  favoriteCourse?: string;
}
