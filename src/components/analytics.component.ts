import { Component, ChangeDetectionStrategy, inject, signal, computed, ElementRef, viewChild, effect } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GolfService } from '../services/golf.service';
import { GolfRound } from '../models/golf.model';
import * as d3 from 'd3';

@Component({
  selector: 'app-analytics-dashboard',
  templateUrl: './analytics.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule],
})
export class AnalyticsDashboardComponent {
  private golfService = inject(GolfService);
  
  chartContainer = viewChild<ElementRef<HTMLDivElement>>('chartContainer');

  allRounds = this.golfService.getAllRounds();
  courseNames = this.golfService.getCourseNames();
  
  selectedCourse = signal<string>('All Courses');

  filteredRounds = computed(() => {
    const course = this.selectedCourse();
    if (course === 'All Courses') {
      return this.allRounds();
    }
    return this.allRounds().filter(round => round.courseName === course);
  });
  
  analyticsStats = computed(() => {
    const rounds = this.filteredRounds();
    const globalStats = this.golfService.getUserStats()();
    if (rounds.length === 0) {
      return { totalRounds: 0, averageScore: 0, bestScore: 0, handicap: globalStats.handicap };
    }
    const scores = rounds.map(r => r.score);
    const totalRounds = rounds.length;
    const averageScore = Math.round(scores.reduce((a, b) => a + b, 0) / totalRounds);
    const bestScore = Math.min(...scores);
    
    return { totalRounds, averageScore, bestScore, handicap: globalStats.handicap };
  });

  constructor() {
    effect(() => {
      if (this.chartContainer()) {
        this.createChart();
      }
    });
  }

  onCourseChange(event: Event) {
    const target = event.target as HTMLSelectElement;
    this.selectedCourse.set(target.value);
  }

  private createChart() {
    const element = this.chartContainer()?.nativeElement;
    if (!element) return;

    d3.select(element).select('svg').remove();

    const rounds = this.filteredRounds().slice().reverse(); 
    if (rounds.length < 2) {
      element.innerHTML = `<div class="flex items-center justify-center h-full text-center text-gray-500 py-8">Not enough data to display a chart for this course.</div>`;
      return;
    };
    element.innerHTML = '';

    const margin = { top: 20, right: 20, bottom: 60, left: 40 };
    const width = element.clientWidth - margin.left - margin.right;
    const height = 300 - margin.top - margin.bottom;

    const svg = d3.select(element).append('svg')
      .attr('width', '100%')
      .attr('height', '100%')
      .attr('viewBox', `0 0 ${width + margin.left + margin.right} ${height + margin.top + margin.bottom}`)
      .append('g')
      .attr('transform', `translate(${margin.left},${margin.top})`);

    const x = d3.scaleTime()
      .domain(d3.extent(rounds, d => new Date(d.date)) as [Date, Date])
      .range([0, width]);

    const y = d3.scaleLinear()
      .domain([d3.min(rounds, d => d.score)! - 5, d3.max(rounds, d => d.score)! + 5])
      .range([height, 0]);

    svg.append('g')
      .attr('transform', `translate(0,${height})`)
      .call(d3.axisBottom(x).ticks(5).tickFormat(d3.timeFormat("%b '%y")))
      .selectAll('text')
      .style('text-anchor', 'end')
      .attr('dx', '-.8em')
      .attr('dy', '.15em')
      .attr('transform', 'rotate(-45)');

    svg.append('g')
      .call(d3.axisLeft(y));

    const line = d3.line<GolfRound>()
      .x(d => x(new Date(d.date)))
      .y(d => y(d.score))
      .curve(d3.curveMonotoneX);
      
    svg.append('path')
      .datum(rounds)
      .attr('fill', 'none')
      .attr('stroke', '#1A4D2E')
      .attr('stroke-width', 2)
      .attr('d', line);

    svg.selectAll('dots')
      .data(rounds)
      .enter().append('circle')
      .attr('cx', d => x(new Date(d.date)))
      .attr('cy', d => y(d.score))
      .attr('r', 4)
      .attr('fill', '#4F6F52');
  }
}
