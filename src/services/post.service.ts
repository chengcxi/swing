import { Injectable, signal } from '@angular/core';
import { Post } from '../models/post.model';

@Injectable({ providedIn: 'root' })
export class PostService {
  private posts = signal<Post[]>([
    {
      id: 1,
      author: 'Jake Shockley',
      authorUsername: 'jake',
      authorAvatar: 'https://i.pravatar.cc/60?u=jake',
      timestamp: '2h ago',
      content: 'Great day at #RivieraCountryClub! The course was in perfect condition. Tough greens but managed to sink a few long putts with @jack.',
      image: 'https://picsum.photos/400/300?image=1011',
      likes: 42,
      comments: 7,
      taggedUsers: ['jack'],
      taggedCourses: ['RivieraCountryClub'],
    },
    {
      id: 2,
      author: 'Jaxon Smith',
      authorUsername: 'jaxonsmith',
      authorAvatar: 'https://i.pravatar.cc/60?u=jaxonsmith',
      timestamp: '5h ago',
      content: 'Working on my swing at the driving range. Finally getting that smooth tempo!',
      likes: 31,
      comments: 4,
    },
    {
      id: 3,
      author: 'Jack Burke',
      authorUsername: 'jack',
      authorAvatar: 'https://i.pravatar.cc/60?u=jackburke',
      timestamp: '1d ago',
      content: "Who's up for a round at #RusticCanyon this weekend? The weather looks amazing. @jaxonsmith you in?",
      image: 'https://picsum.photos/400/300?image=1012',
      likes: 58,
      comments: 12,
      taggedUsers: ['jaxonsmith'],
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
      author: 'Jake Shockley',
      authorUsername: 'jake',
      authorAvatar: 'https://i.pravatar.cc/60?u=jake',
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
