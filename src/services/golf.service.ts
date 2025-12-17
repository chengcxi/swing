import { Injectable, signal, computed } from '@angular/core';
import { UserStats, GolfRound, CourseRanking, GolfCourse } from '../models/golf.model';

@Injectable({ providedIn: 'root' })
export class GolfService {
  private userStats = signal<UserStats>({
    bestRound: 72,
    averageScore: 82,
    roundsPlayed: 128,
    handicap: 10.2,
  });

  private allRounds = signal<GolfRound[]>([
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
    { courseName: 'Pebble Beach', location: 'Pebble Beach, CA', holes: 18, date: '2025-06-25', score: 88 },
    { courseName: 'Sandpiper Golf Club', location: 'Goleta, CA', holes: 18, date: '2025-06-12', score: 84 },
    { courseName: 'Rustic Canyon Golf Course', location: 'Moorpark, CA', holes: 18, date: '2025-05-30', score: 78 },
    { courseName: 'Rustic Canyon Golf Course', location: 'Moorpark, CA', holes: 18, date: '2025-05-15', score: 79 },
    { courseName: 'Alisal River Course', location: 'Solvang, CA', holes: 18, date: '2025-04-28', score: 81 },
    { courseName: 'Alisal River Course', location: 'Solvang, CA', holes: 18, date: '2025-04-10', score: 83 },
    { courseName: 'Pebble Beach', location: 'Pebble Beach, CA', holes: 18, date: '2025-03-22', score: 91 },
    { courseName: 'Sandpiper Golf Club', location: 'Goleta, CA', holes: 18, date: '2025-03-05', score: 86 },
    { courseName: 'Riviera Country Club', location: 'Pacific Palisades, CA', holes: 18, date: '2025-02-18', score: 101 },
    { courseName: 'Rustic Canyon Golf Course', location: 'Moorpark, CA', holes: 18, date: '2025-02-01', score: 72 },
  ].sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime()));

  private courseRankings = signal<CourseRanking[]>([
    { rank: 1, courseName: 'Sandpiper Golf Club', location: 'Goleta, CA' },
    { rank: 2, courseName: 'Riviera Country Club', location: 'Pacific Palisades, CA' },
    { rank: 3, courseName: 'Alisal River Course', location: 'Solvang, CA' },
    { rank: 4, courseName: 'Rustic Canyon Golf Course', location: 'Moorpark, CA' },
    { rank: 5, courseName: 'Pebble Beach', location: 'Pebble Beach, CA' },
  ]);
  
  private allCourses = signal<GolfCourse[]>([
    { name: 'Los Robles Greens', location: 'Thousand Oaks, CA', holes: 18, difficulty: 7.1, facilities: { drivingRange: true, puttingGreen: true } },
    { name: 'Westlake Golf Course', location: 'Westlake Village, CA', holes: 18, difficulty: 6.2, facilities: { drivingRange: true, puttingGreen: true } },
    { name: 'Rustic Canyon Golf Course', location: 'Moorpark, CA', holes: 18, difficulty: 8.5, facilities: { drivingRange: true, puttingGreen: true } },
    { name: 'Moorpark Country Club', location: 'Moorpark, CA', holes: 27, difficulty: 9.1, facilities: { drivingRange: true, puttingGreen: true } },
    { name: 'Sandpiper Golf Club', location: 'Goleta, CA', holes: 18, difficulty: 9.4, facilities: { drivingRange: true, puttingGreen: true } },
    { name: 'Pebble Beach', location: 'Pebble Beach, CA', holes: 18, difficulty: 9.8, facilities: { drivingRange: true, puttingGreen: true } },
    { name: 'The Links at Spanish Bay', location: 'Pebble Beach, CA', holes: 18, difficulty: 9.2, facilities: { drivingRange: true, puttingGreen: false } },
    { name: 'Simi Hills Golf Course', location: 'Simi Valley, CA', holes: 18, difficulty: 6.8, facilities: { drivingRange: true, puttingGreen: true } },
    { name: 'Olivas Links', location: 'Ventura, CA', holes: 18, difficulty: 7.5, facilities: { drivingRange: true, puttingGreen: true } },
  ]);

  recentRounds = computed(() => this.allRounds().slice(0, 4));

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
}
