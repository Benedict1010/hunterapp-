import '../domain/job.dart';

const softwareEngineerIntern = Job(
  id: 'software-engineer-intern',
  title: 'Software Engineer Intern',
  company: 'ABC Technologies',
  location: 'Bangalore, India',
  workMode: 'Hybrid',
  compensation: '₹40k - ₹60k / month',
  postedLabel: '2 days ago',
  about:
      "Join ABC Technologies' core engineering team as a Software Engineer Intern. You'll work on building scalable microservices and enhancing our AI-driven productivity suite. This is a high-impact role with mentorship from senior architects.",
  requirements: [
    'Currently pursuing B.Tech/M.Tech in Computer Science or related field.',
    'Strong proficiency in React, TypeScript, and Node.js.',
    'Understanding of RESTful APIs and modern frontend architectures.',
    'Excellent problem-solving skills and a passion for building clean UI.',
  ],
);

const jobMatches = [
  JobMatch(
    job: Job(
      id: 'tech-corp',
      title: 'Senior Product',
      company: 'TechCorp',
      location: 'San Francisco, CA (Remote)',
      workMode: 'Remote',
      compensation: '\$140k - \$180k',
      postedLabel: 'Today',
      about: '',
      requirements: [],
    ),
    score: 98,
    rationale:
        'Your experience with high-fidelity prototyping and design systems perfectly aligns with their core requirements.',
    tags: ['Full-time', 'Senior', 'Remote'],
  ),
  JobMatch(
    job: Job(
      id: 'design-studio',
      title: 'Creative UI',
      company: 'DesignStudio',
      location: 'New York, NY',
      workMode: 'On-site',
      compensation: '\$130k - \$160k',
      postedLabel: 'Today',
      about: '',
      requirements: [],
    ),
    score: 92,
    rationale:
        'Your portfolio showcases the editorial elegance and technical precision they are looking for in their new brand lead.',
    tags: ['Full-time', 'Leadership', 'On-site'],
  ),
  JobMatch(
    job: Job(
      id: 'data-solutions',
      title: 'Data',
      company: 'DataSolutions',
      location: 'Austin, TX (Hybrid)',
      workMode: 'Hybrid',
      compensation: '\$120k - \$155k',
      postedLabel: 'Today',
      about: '',
      requirements: [],
    ),
    score: 88,
    rationale:
        'Strong overlap with your React and D3.js skills. They value the surgical precision in your dashboard work.',
    tags: ['Contract', 'Mid-senior', 'Hybrid'],
  ),
];

const internSkillMatches = [
  SkillMatch('React', 95),
  SkillMatch('TypeScript', 90),
  SkillMatch('UI/UX Design', 85),
  SkillMatch('Node.js', 80),
];
