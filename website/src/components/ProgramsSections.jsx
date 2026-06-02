import { BookOpen, Building2, HeartPulse, Megaphone, MessageCircle, Radio, School } from 'lucide-react';
import { PageHero, SectionIntro } from './Layout';
import { ProgramCard } from './Cards';
import { ImageShowcase } from './ImageShowcase';

const programs = [
  {
    icon: Megaphone,
    title: 'Awareness campaigns',
    text: 'Public campaigns that challenge stigma, normalize help-seeking, and make mental health language easier to use.',
    tone: 'emerald',
  },
  {
    icon: School,
    title: 'School outreach',
    text: 'Youth-friendly sessions for students on emotional awareness, confidence, communication, and life transitions.',
    tone: 'blue',
  },
  {
    icon: BookOpen,
    title: 'Educational resources',
    text: 'Evidence-based information translated into practical guidance for young people and communities.',
    tone: 'lime',
  },
  {
    icon: MessageCircle,
    title: 'Safe dialogue spaces',
    text: 'Community conversations and peer spaces where people can speak openly and feel heard.',
    tone: 'amber',
  },
  {
    icon: HeartPulse,
    title: 'Early-intervention tools',
    text: 'Preventive education tools that support emotional awareness before challenges grow.',
    tone: 'cyan',
  },
  {
    icon: Radio,
    title: 'Media engagement',
    text: 'Storytelling, public education, and youth-led media conversations that bring mental health into the open.',
    tone: 'lavender',
  },
];

export function ProgramsHero() {
  return (
    <PageHero
      compact
      image="/3.png"
      imageAlt="MindRise outreach and program visual"
      focal="center"
      eyebrow="Programs"
      title="Community programs for mental health literacy and resilience."
      lead="MindRise works through community programs, school outreach, educational resources, and media engagement to make mental health support practical and accessible."
    />
  );
}

export function ProgramGrid() {
  return (
    <section className="section">
      <SectionIntro eyebrow="What we do" title="Programs designed for young people and underserved communities." />
      <div className="card-grid card-grid--three">
        {programs.map((program) => (
          <ProgramCard key={program.title} {...program} />
        ))}
      </div>
    </section>
  );
}

const programShowcaseItems = [
  {
    src: '/3.png',
    alt: 'MindRise program and school outreach visual',
    label: 'Programs',
    text: 'Program visuals are grouped around outreach, education, and community readiness.',
  },
  {
    src: '/4.png',
    alt: 'MindRise learning resources visual',
    label: 'Resources',
    text: 'Learning materials are treated as practical tools for young people and schools.',
  },
  {
    src: '/7%20%282%29.png',
    alt: 'MindRise community engagement visual',
    label: 'Engagement',
    text: 'Community moments are shown with restraint so the message remains clear.',
  },
];

export function ProgramsImageShowcase() {
  return (
    <ImageShowcase
      className="image-showcase--programs"
      eyebrow="Program moments"
      title="Images grouped around outreach, learning, and engagement."
      lead="A focused image show gives the Programs page visual depth without making the layout feel crowded."
      items={programShowcaseItems}
    />
  );
}

export function ProgramModel() {
  return (
    <section className="section section--split program-model">
      <SectionIntro
        eyebrow="Our model"
        title="Awareness, dialogue, tools, and community support."
        lead="Our work is grounded in psychological science and cultural sensitivity, while staying practical enough for schools, youth groups, families, and local communities."
      />
      <div className="model-steps">
        <span>1. Build mental health awareness</span>
        <span>2. Create safe spaces for expression</span>
        <span>3. Share preventive tools and education</span>
        <span>4. Connect young people to support</span>
      </div>
    </section>
  );
}

export function CollaborationCallout() {
  return (
    <section className="section organization-callout">
      <div>
        <p className="eyebrow">Collaboration</p>
        <h2>We collaborate with students, professionals, institutions, and community leaders.</h2>
        <p>Partnership helps ensure no one feels alone in their mental health journey.</p>
      </div>
      <Building2 size={44} aria-hidden="true" />
    </section>
  );
}