import '../domain/job.dart';

const softwareEngineerIntern = Job(
  id: 'software-engineer-intern',
  title: 'Software Engineer Intern',
  company: 'ABC Technologies',
  location: 'Bangalore, India',
  jobType: 'Hybrid',
  salaryRange: '₹40k - ₹60k / month',
  description:
      "Join ABC Technologies' core engineering team as a Software Engineer Intern. You'll work on building scalable microservices and enhancing our AI-driven productivity suite. This is a high-impact role with mentorship from senior architects.",
  externalUrl: 'https://abctechnologies.com/careers/intern',
  source: 'LinkedIn',
  skills: [
    JobSkill(
      name:
          'Currently pursuing B.Tech/M.Tech in Computer Science or related field.',
    ),
    JobSkill(name: 'Strong proficiency in React, TypeScript, and Node.js.'),
    JobSkill(
      name: 'Understanding of RESTful APIs and modern frontend architectures.',
    ),
    JobSkill(
      name:
          'Excellent problem-solving skills and a passion for building clean UI.',
    ),
  ],
);

const defaultMockJobs = [
  softwareEngineerIntern,
  Job(
    id: 'tech-corp',
    title: 'Senior Product',
    company: 'TechCorp',
    location: 'San Francisco, CA (Remote)',
    jobType: 'Remote',
    salaryRange: '\$140k - \$180k',
    description: 'Senior Product position at TechCorp.',
    externalUrl: 'https://techcorp.com/jobs/senior-product',
    source: 'LinkedIn',
    skills: [
      JobSkill(name: 'Design Systems'),
      JobSkill(name: 'Figma'),
      JobSkill(name: 'Prototyping'),
    ],
  ),
  Job(
    id: 'design-studio',
    title: 'Creative UI Lead',
    company: 'DesignStudio',
    location: 'New York, NY',
    jobType: 'On-site',
    salaryRange: '\$130k - \$160k',
    description: 'Creative UI Lead position at DesignStudio.',
    externalUrl: 'https://designstudio.com/jobs/ui-lead',
    source: 'Unstop',
    skills: [
      JobSkill(name: 'UI Design'),
      JobSkill(name: 'Branding'),
    ],
  ),
];
