import { Injectable, signal } from '@angular/core';
import { Conversation } from '../models/message.model';

@Injectable({ providedIn: 'root' })
export class MessageService {
  private conversations = signal<Conversation[]>([
    {
      id: '1',
      participantName: 'Weekend Golf Warriors',
      participantAvatar: 'https://i.pravatar.cc/60?u=group1',
      lastMessage: 'Jack: Sounds good, see you Saturday!',
      timestamp: '15m ago',
      unreadCount: 2,
      isGroup: true,
    },
    {
      id: '2',
      participantName: 'Jaxon Smith',
      participantAvatar: 'https://i.pravatar.cc/60?u=jaxonsmith',
      lastMessage: 'Yeah, the new driver is amazing.',
      timestamp: '1h ago',
      unreadCount: 0,
      isGroup: false,
    },
    {
      id: '3',
      participantName: 'Jack Burke',
      participantAvatar: 'https://i.pravatar.cc/60?u=jackburke',
      lastMessage: 'Are we still on for this weekend?',
      timestamp: 'yesterday',
      unreadCount: 0,
      isGroup: false,
    },
    {
      id: '4',
      participantName: 'Moorpark Country Club Crew',
      participantAvatar: 'https://i.pravatar.cc/60?u=group2',
      lastMessage: 'John: I just booked a tee time for 8am.',
      timestamp: '2d ago',
      unreadCount: 0,
      isGroup: true,
    },
    {
        id: '5',
        participantName: 'Jane Doe',
        participantAvatar: 'https://i.pravatar.cc/60?u=janedoe',
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
