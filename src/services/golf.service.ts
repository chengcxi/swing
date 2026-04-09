import { Injectable, signal, computed, Signal, inject, effect } from '@angular/core';
import { UserStats, GolfRound, CourseRanking, GolfCourse, CourseReview } from '../models/golf.model';
import { AuthService } from './auth.service';
import { supabase } from './supabase';

const MOCK_STATS: UserStats = { bestRound: 72, averageScore: 82, roundsPlayed: 128, handicap: 10.2 };

const MOCK_ROUNDS: GolfRound[] = [
  { courseName: 'Riviera Country Club', location: 'Pacific Palisades, CA', holes: 18, date: '2025-11-17', score: 103 },
  { courseName: 'Sandpiper Golf Club', location: 'Goleta, CA', holes: 18, date: '2025-11-02', score: 85 },
  { courseName: 'Sandpiper Golf Club', location: 'Goleta, CA', holes: 18, date: '2025-10-28', score: 87 },
  { courseName: 'Pebble Beach', location: 'Pebble Beach, CA', holes: 18, date: '2025-10-15', score: 92 },
  { courseName: 'Pebble Beach', location: 'Pebble Beach, CA', holes: 18, date: '2025-09-20', score: 95 },
  { courseName: 'Sandpiper Golf Club', location: 'Goleta, CA', holes: 18, date: '2025-09-05', score: 88 },
  { courseName: 'Riviera Country Club', location: 'Pacific Palisades, CA', holes: 18, date: '2025-08-15', score: 98 },
  { courseName: 'Pebble Beach', location: 'Pebble Beach, CA', holes: 18, date: '2025-08-01', score: 90 },
  { courseName: 'Sandpiper Golf Club', location: 'Goleta, CA', holes: 18, date: '2025-07-22', score: 82 },
  { courseName: 'Riviera Country Club', location: 'Pacific Palisades, CA', holes: 18, date: '2025-07-10', score: 96 },
  { courseName: 'Rustic Canyon Golf Course', location: 'Moorpark, CA', holes: 18, date: '2025-05-30', score: 78 },
  { courseName: 'Rustic Canyon Golf Course', location: 'Moorpark, CA', holes: 18, date: '2025-05-15', score: 79 },
  { courseName: 'Alisal River Course', location: 'Solvang, CA', holes: 18, date: '2025-04-28', score: 81 },
  { courseName: 'Alisal River Course', location: 'Solvang, CA', holes: 18, date: '2025-04-10', score: 83 },
  { courseName: 'Rustic Canyon Golf Course', location: 'Moorpark, CA', holes: 18, date: '2025-02-01', score: 72 },
].sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

const MOCK_RANKINGS: CourseRanking[] = [
  { rank: 1, courseName: 'Sandpiper Golf Club', location: 'Goleta, CA' },
  { rank: 2, courseName: 'Riviera Country Club', location: 'Pacific Palisades, CA' },
  { rank: 3, courseName: 'Alisal River Course', location: 'Solvang, CA' },
  { rank: 4, courseName: 'Rustic Canyon Golf Course', location: 'Moorpark, CA' },
  { rank: 5, courseName: 'Pebble Beach', location: 'Pebble Beach, CA' },
];

const MOCK_COURSES: GolfCourse[] = [
  { id: '1', name: 'Los Robles Greens', location: 'Thousand Oaks, CA', holes: 18, difficulty: 7.1, facilities: { drivingRange: true, puttingGreen: true }, imageUrl: 'https://picsum.photos/seed/losrobles/400/200', rating: 4.2 },
  { id: '2', name: 'Westlake Golf Course', location: 'Westlake Village, CA', holes: 18, difficulty: 6.2, facilities: { drivingRange: true, puttingGreen: true }, imageUrl: 'https://picsum.photos/seed/westlake/400/200', rating: 3.8 },
  { id: '3', name: 'Rustic Canyon Golf Course', location: 'Moorpark, CA', holes: 18, difficulty: 8.5, facilities: { drivingRange: true, puttingGreen: true }, imageUrl: 'https://picsum.photos/seed/rustic/400/200', rating: 4.8 },
  { id: '4', name: 'Moorpark Country Club', location: 'Moorpark, CA', holes: 27, difficulty: 9.1, facilities: { drivingRange: true, puttingGreen: true }, imageUrl: 'https://picsum.photos/seed/moorpark/400/200', rating: 4.5 },
  { id: '5', name: 'Sandpiper Golf Club', location: 'Goleta, CA', holes: 18, difficulty: 9.4, facilities: { drivingRange: true, puttingGreen: true }, imageUrl: 'https://picsum.photos/seed/sandpiper/400/200', rating: 4.9 },
  { id: '6', name: 'Pebble Beach', location: 'Pebble Beach, CA', holes: 18, difficulty: 9.8, facilities: { drivingRange: true, puttingGreen: true }, imageUrl: 'https://picsum.photos/seed/pebble/400/200', rating: 5.0 },
  { id: '7', name: 'The Links at Spanish Bay', location: 'Pebble Beach, CA', holes: 18, difficulty: 9.2, facilities: { drivingRange: true, puttingGreen: false }, imageUrl: 'https://picsum.photos/seed/spanishbay/400/200', rating: 4.7 },
  { id: '8', name: 'Simi Hills Golf Course', location: 'Simi Valley, CA', holes: 18, difficulty: 6.8, facilities: { drivingRange: true, puttingGreen: true }, imageUrl: 'https://picsum.photos/seed/simi/400/200', rating: 4.0 },
  { id: '9', name: 'Olivas Links', location: 'Ventura, CA', holes: 18, difficulty: 7.5, facilities: { drivingRange: true, puttingGreen: true }, imageUrl: 'https://picsum.photos/seed/olivas/400/200', rating: 4.3 },
];

const MOCK_REVIEWS: CourseReview[] = [
  { id: 'r1', courseId: '3', author: 'John Doe', authorAvatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG', rating: 5, comment: 'Absolutely stunning course. A true test of golf!', timestamp: '2 days ago' },
  { id: 'r2', courseId: '3', author: 'Jane Doe', authorAvatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG', rating: 4, comment: 'Challenging but fair. The views are incredible.', timestamp: '1 week ago' },
  { id: 'r3', courseId: '5', author: 'Jack Doe', authorAvatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG', rating: 5, comment: 'The ocean views on every hole are breathtaking. A must-play course.', timestamp: '3 days ago' },
  { id: 'r4', courseId: '6', author: 'Jason Doe', authorAvatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG', rating: 5, comment: 'Bucket list course for a reason. Every shot is memorable.', timestamp: '1 month ago' },
  { id: 'r5', courseId: '6', author: 'Jayden Doe', authorAvatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG', rating: 5, comment: 'An unforgettable experience. Worth every penny.', timestamp: '1 month ago' },
];

@Injectable({ providedIn: 'root' })
export class GolfService {
  private authService = inject(AuthService);

  private userStats = signal<UserStats>(MOCK_STATS);
  private allRounds = signal<GolfRound[]>(MOCK_ROUNDS);
  private courseRankings = signal<CourseRanking[]>(MOCK_RANKINGS);
  private allCourses = signal<GolfCourse[]>(MOCK_COURSES);
  private allReviews = signal<CourseReview[]>(MOCK_REVIEWS);

  recentRounds = computed(() => this.allRounds().slice(0, 4));

  constructor() {
    // Load data when authenticated
    effect(() => {
      const userId = this.authService.currentUserId();
      if (userId) {
        this.loadRounds(userId);
        this.loadCourses();
        this.loadUserStats(userId);
      }
    });
  }

  private async loadRounds(userId: string) {
    try {
      const { data, error } = await supabase
        .from('rounds')
        .select('*, course:golf_courses(*)')
        .eq('user_id', userId)
        .order('date_played', { ascending: false });

      if (!error && data) {
        const rounds: GolfRound[] = data.map((r: any) => ({
          courseName: r.course?.name || 'Unknown Course',
          location: r.course ? `${r.course.city}, ${r.course.state || r.course.country}` : 'Unknown',
          holes: r.course?.holes || 18,
          date: r.date_played,
          score: r.score,
        }));
        this.allRounds.set(rounds);

        // Compute course rankings from rounds played
        const courseFreq = new Map<string, { count: number; name: string; location: string }>();
        rounds.forEach(r => {
          const existing = courseFreq.get(r.courseName) || { count: 0, name: r.courseName, location: r.location };
          existing.count++;
          courseFreq.set(r.courseName, existing);
        });
        const rankings = [...courseFreq.entries()]
          .sort((a, b) => b[1].count - a[1].count)
          .slice(0, 5)
          .map((entry, i) => ({
            rank: i + 1,
            courseName: entry[1].name,
            location: entry[1].location,
          }));
        this.courseRankings.set(rankings);
      }
    } catch (e) {
      console.error('Failed to load rounds', e);
    }
  }

  private async loadCourses() {
    try {
      const { data, error } = await supabase
        .from('golf_courses')
        .select('*');

      if (!error && data) {
        this.allCourses.set(data.map((c: any) => ({
          id: c.id,
          name: c.name,
          location: `${c.city}, ${c.state || c.country}`,
          holes: c.holes || 18,
          difficulty: c.course_rating ? c.course_rating / 10 : 5,
          facilities: {
            drivingRange: true,
            puttingGreen: true,
          },
          imageUrl: c.image_url || `https://picsum.photos/seed/${c.id}/400/200`,
          rating: c.course_rating ? Math.min(5, c.course_rating / 14) : 4.0,
        })));

        // Load reviews for all courses
        this.loadReviews();
      }
    } catch (e) {
      console.error('Failed to load courses', e);
    }
  }

  private async loadReviews() {
    try {
      const { data, error } = await supabase
        .from('comments')
        .select('*, profile:profiles(username, full_name, avatar_url)')
        .order('created_at', { ascending: false })
        .limit(50);

      if (!error && data) {
        this.allReviews.set(data.map((c: any) => ({
          id: c.id,
          courseId: c.round_id, // comments are on rounds, not courses directly
          author: c.profile?.full_name || c.profile?.username || 'Anonymous',
          authorAvatar: c.profile?.avatar_url || 'https://ui-avatars.com/api/?name=A&background=1A4D2E&color=fff',
          rating: 5,
          comment: c.content,
          timestamp: this.formatTimestamp(c.created_at),
        })));
      }
    } catch (e) {
      console.error('Failed to load reviews', e);
    }
  }

  private async loadUserStats(userId: string) {
    try {
      const { data: profile } = await supabase
        .from('profiles')
        .select('handicap')
        .eq('id', userId)
        .single();

      const { data: rounds } = await supabase
        .from('rounds')
        .select('score')
        .eq('user_id', userId);

      if (rounds && rounds.length > 0) {
        const scores = rounds.map((r: any) => r.score);
        this.userStats.set({
          bestRound: Math.min(...scores),
          averageScore: Math.round(scores.reduce((a: number, b: number) => a + b, 0) / scores.length),
          roundsPlayed: scores.length,
          handicap: profile?.handicap || 0,
        });
      }
    } catch (e) {
      console.error('Failed to load stats', e);
    }
  }

  private formatTimestamp(isoDate: string): string {
    if (!isoDate) return 'Unknown';
    const date = new Date(isoDate);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    if (diffMins < 1) return 'just now';
    if (diffMins < 60) return `${diffMins}m ago`;
    const diffHours = Math.floor(diffMins / 60);
    if (diffHours < 24) return `${diffHours}h ago`;
    const diffDays = Math.floor(diffHours / 24);
    if (diffDays < 30) return `${diffDays}d ago`;
    return date.toLocaleDateString();
  }

  getUserStats() {
    return this.userStats.asReadonly();
  }

  getRecentRounds() {
    return this.recentRounds;
  }

  getAllRounds() {
    return this.allRounds.asReadonly();
  }

  getCourseNames() {
    return computed(() => [...new Set(this.allRounds().map(r => r.courseName))]);
  }

  getCourseRankings() {
    return this.courseRankings.asReadonly();
  }

  getCourses() {
    return this.allCourses.asReadonly();
  }

  getCourseById(id: string) {
    return computed(() => this.allCourses().find(c => c.id === id));
  }

  getReviewsForCourse(courseId: Signal<string>) {
    return computed(() => this.allReviews().filter(r => r.courseId === courseId()));
  }
}
