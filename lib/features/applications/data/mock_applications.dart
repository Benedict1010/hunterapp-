import '../domain/job_application.dart';

const mockApplications = [
  JobApplication(
    id: 'abc-senior-engineer',
    title: 'Senior Software Engineer',
    company: 'ABC Technologies',
    location: 'San Francisco, CA',
    date: 'Oct 24, 2023',
    matchScore: 94,
    status: ApplicationStatus.applied,
  ),
  JobApplication(
    id: 'tech-interview',
    title: 'Frontend Engineer',
    company: 'TechFlow Systems',
    location: 'Remote',
    date: 'Oct 18, 2023',
    matchScore: 89,
    status: ApplicationStatus.interviewing,
  ),
  JobApplication(
    id: 'offer-design',
    title: 'Product Designer',
    company: 'DesignStudio',
    location: 'New York, NY',
    date: 'Oct 12, 2023',
    matchScore: 91,
    status: ApplicationStatus.offered,
  ),
];

const applicationDetail = ApplicationDetail(
  application: JobApplication(
    id: 'techflow-senior-frontend',
    title: 'Senior Frontend Engineer',
    company: 'TechFlow Systems',
    location: 'Remote',
    date: 'Oct 12, 2023',
    matchScore: 89,
    status: ApplicationStatus.interviewing,
  ),
  employmentType: 'Full-time',
  updatedAt: 'Last updated today at 10:32 AM',
  timeline: [
    ApplicationTimelineStage(
      title: 'Application Received',
      date: 'Oct 12, 2023',
      status: ApplicationStageStatus.completed,
    ),
    ApplicationTimelineStage(
      title: 'Resume Screened',
      date: 'Oct 14, 2023',
      status: ApplicationStageStatus.completed,
    ),
    ApplicationTimelineStage(
      title: 'Technical Assessment',
      date: 'Oct 18, 2023',
      status: ApplicationStageStatus.completed,
    ),
    ApplicationTimelineStage(
      title: 'Technical Interview',
      date: 'Scheduled for Oct 26, 2023',
      status: ApplicationStageStatus.current,
    ),
    ApplicationTimelineStage(
      title: 'Final Round Panel',
      date: 'To be determined',
      status: ApplicationStageStatus.upcoming,
    ),
  ],
);
