import { Injectable, signal } from '@angular/core';
import { Post } from '../models/post.model';

@Injectable({ providedIn: 'root' })
export class PostService {
  private posts = signal<Post[]>([
    {
      id: 1,
      author: 'John Doe',
      authorUsername: 'johndoe',
      authorAvatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG',
      timestamp: '2h ago',
      content: 'Great day at #RivieraCountryClub! The course was in perfect condition. Tough greens but managed to sink a few long putts with @janedoe.',
      image: 'https://picsum.photos/400/300?image=1011',
      likes: 42,
      comments: 7,
      taggedUsers: ['janedoe'],
      taggedCourses: ['RivieraCountryClub'],
    },
    {
      id: 2,
      author: 'Jane Doe',
      authorUsername: 'janedoe',
      authorAvatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG',
      timestamp: '5h ago',
      content: 'Working on my swing at the driving range. Finally getting that smooth tempo!',
      likes: 31,
      comments: 4,
    },
    {
      id: 3,
      author: 'Jack Doe',
      authorUsername: 'jackdoe',
      authorAvatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG',
      timestamp: '1d ago',
      content: "Who's up for a round at #RusticCanyon this weekend? The weather looks amazing. @jasondoe you in?",
      image: 'https://picsum.photos/400/300?image=1012',
      likes: 58,
      comments: 12,
      taggedUsers: ['jasondoe'],
      taggedCourses: ['RusticCanyon'],
    },
  ]);

  getPosts() {
    return this.posts.asReadonly();
  }

  addPost(content: string) {
    const taggedUsers = (content.match(/@(\w+)/g) || []).map(u => u.substring(1));
    const taggedCourses = (content.match(/#(\w+)/g) || []).map(c => c.substring(1));

    const newPost: Post = {
      id: Date.now(),
      author: 'John Doe',
      authorUsername: 'johndoe',
      authorAvatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG',
      timestamp: 'just now',
      content,
      likes: 0,
      comments: 0,
      taggedUsers,
      taggedCourses,
    };
    this.posts.update(posts => [newPost, ...posts]);
  }
}
