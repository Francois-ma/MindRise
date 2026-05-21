import React from 'react';
import { createRoot } from 'react-dom/client';
import { BookOpen, Brain, Building2, HeartPulse, Megaphone, MessageCircle, Radio, School } from 'lucide-react';
import { Layout, PageHero, SectionIntro } from '../components/Layout';
import { ProgramCard } from '../components/Cards';
import '../styles.css';

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
    text: 'Youth-friendly sessions for students on stress, anxiety, depression, self-esteem, and life transitions.',
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
    text: 'Preventive and psychoeducational tools that support emotional awareness before crisis develops.',
    tone: 'cyan',
  },
  {
    icon: Radio,
    title: 'Media engagement',
    text: 'Storytelling, public education, and youth-led media conversations that bring mental health into the open.',
    tone: 'lavender',
  },
];

function Programs() {
  return (
    <Layout active="programs">
      <PageHero
        compact
        eyebrow="Programs"
        title="Community programs for mental health literacy and resilience."
        lead="MindRise works through digital platforms, community programs, school outreach, and media engagement to make mental health support practical and accessible."
      />

      <section className="section">
        <SectionIntro eyebrow="What we do" title="Programs designed for young people and underserved communities." />
        <div className="card-grid card-grid--three">
          {programs.map((program) => (
            <ProgramCard key={program.title} {...program} />
          ))}
        </div>
      </section>

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

      <section className="section organization-callout">
        <div>
          <p className="eyebrow">Collaboration</p>
          <h2>We collaborate with students, professionals, institutions, and community leaders.</h2>
          <p>Partnership helps ensure no one feels alone in their mental health journey.</p>
        </div>
        <Building2 size={44} aria-hidden="true" />
      </section>
    </Layout>
  );
}

createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <Programs />
  </React.StrictMode>,
);