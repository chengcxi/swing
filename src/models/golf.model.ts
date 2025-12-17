export interface UserStats {
  bestRound: number;
  averageScore: number;
  roundsPlayed: number;
  handicap: number;
}

export interface GolfRound {
  courseName: string;
  location: string;
  holes: number;
  date: string;
  score: number;
}

export interface CourseRanking {
  rank: number;
  courseName: string;
  location: string;
}

export interface GolfActivity {
  id: number;
  user: string;
  userAvatar: string;
  action: 'posted' | 'played' | 'commented on' | 'joined';
  details: string;
  target?: string;
  timestamp: string;
}

export interface GolfCourse {
  name: string;
  location: string;
  holes: 9 | 18 | 27 | 36;
  difficulty: number;
  facilities: {
    drivingRange: boolean;
    puttingGreen: boolean;
  };
}
