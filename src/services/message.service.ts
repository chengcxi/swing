import { Injectable, signal } from '@angular/core';
import { Conversation } from '../models/message.model';

@Injectable({ providedIn: 'root' })
export class MessageService {
  private conversations = signal<Conversation[]>([
    {
      id: '1',
      participantName: 'Weekend Golf Warriors',
      participantAvatar: 'https://cdn-icons-png.freepik.com/512/166/166258.png',
      lastMessage: 'Jack: Sounds good, see you Saturday!',
      timestamp: '15m ago',
      unreadCount: 2,
      isGroup: true,
    },
    {
      id: '2',
      participantName: 'Jane Doe',
      participantAvatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG',
      lastMessage: 'Yeah, the new driver is amazing.',
      timestamp: '1h ago',
      unreadCount: 0,
      isGroup: false,
    },
    {
      id: '3',
      participantName: 'Jason Doe',
      participantAvatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG',
      lastMessage: 'Are we still on for this weekend?',
      timestamp: 'yesterday',
      unreadCount: 0,
      isGroup: false,
    },
    {
      id: '4',
      participantName: 'Moorpark Country Club Crew',
      participantAvatar: 'https://cdn-icons-png.freepik.com/512/166/166258.png',
      lastMessage: 'John: I just booked a tee time for 8am.',
      timestamp: '2d ago',
      unreadCount: 0,
      isGroup: true,
    },
    {
        id: '5',
        participantName: 'Jayden Doe',
        participantAvatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG',
        lastMessage: 'Thanks for the swing tips!',
        timestamp: '4d ago',
        unreadCount: 1,
        isGroup: false,
    }
  ]);

  getConversations() {
    return this.conversations.asReadonly();
  }
}
