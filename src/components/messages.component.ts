import { Component, ChangeDetectionStrategy, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MessageService } from '../services/message.service';
import { Conversation } from '../models/message.model';

@Component({
  selector: 'app-messages',
  templateUrl: './messages.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule],
})
export class MessagesComponent {
  private messageService = inject(MessageService);
  conversations = this.messageService.getConversations();

  searchTerm = signal('');
  selectedConversation = signal<Conversation | null>(null);
  showNewMessage = signal(false);
  chatInput = signal('');
  sentMessage = signal(false);

  filteredConversations = () => {
    const term = this.searchTerm().toLowerCase();
    if (!term) return this.conversations();
    return this.conversations().filter(c =>
      c.participantName.toLowerCase().includes(term) ||
      c.lastMessage.toLowerCase().includes(term)
    );
  };

  onSearch(event: Event) {
    this.searchTerm.set((event.target as HTMLInputElement).value);
  }

  openConversation(convo: Conversation) {
    this.selectedConversation.set(convo);
  }

  closeConversation() {
    this.selectedConversation.set(null);
  }

  toggleNewMessage() {
    this.showNewMessage.update(v => !v);
  }

  onChatInput(event: Event) {
    this.chatInput.set((event.target as HTMLInputElement).value);
  }

  sendMessage() {
    if (!this.chatInput().trim()) return;
    this.sentMessage.set(true);
    this.chatInput.set('');
    setTimeout(() => this.sentMessage.set(false), 2000);
  }
}
