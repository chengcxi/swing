export interface Conversation {
  id: string;
  participantName: string;
  participantAvatar: string;
  lastMessage: string;
  timestamp: string;
  unreadCount: number;
  isGroup: boolean;
}
