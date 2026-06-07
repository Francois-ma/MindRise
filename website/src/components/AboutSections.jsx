import { Brain, Eye, HandHeart, Megaphone, Target } from 'lucide-react';
import { PageHero, SectionIntro } from './Layout';
import { ValueCard } from './Cards';
import { ImageShowcase } from './ImageShowcase';

export function AboutHero() {
  return (
    <PageHero
      compact
      image="/2.webp"
      imageAlt="MindRise community wellness visual"
      focal="center"
      eyebrow="About MindRise"
      title="A youth-driven mental health initiative rooted in Rwanda."
      lead="MindRise Wellness Initiative promotes emotional well-being, psychological resilience, and mental health literacy, especially among young people and underserved communities."
    />
  );
}

export function MissionSection() {
  return (
    <section className="section section--split">
      <SectionIntro
        eyebrow="Our mission"
        title="Break stigma, encourage open conversations, and make mental health support accessible."
        lead="We believe mental health belongs in schools, communities, media spaces, community programs, and everyday conversations. Our work makes mental health knowledge easier to understand and support easier to seek."
      />
      <div className="mission-panel">
        <Target size={32} aria-hidden="true" />
        <h3>Rise Above, Speak Out</h3>
        <p>Our slogan is a call to move beyond silence and shame, speak honestly about mental health, and build communities where healing is possible.</p>
      </div>
    </section>
  );
}

const aboutShowcaseItems = [
  {
    src: '/5.webp',
    alt: 'MindRise support and listening visual',
    label: 'Listening',
    text: 'Open conversations make support feel closer and less intimidating.',
  },
  {
    src: '/8.webp',
    alt: 'MindRise digital dashboard visual',
    label: 'Digital access',
    text: 'A private web pathway supports learning, reflection, and continuity.',
  },
  {
    src: '/10.webp',
    alt: 'Young people participating in an outdoor wellness circle',
    label: 'Youth well-being',
    text: 'Calm group activities create space for reflection, connection, and growth.',
  },
];

export function AboutImageShowcase() {
  return (
    <ImageShowcase
      className="image-showcase--about"
      eyebrow="Visual identity"
      title="MindRise should feel calm, credible, and human."
      lead="The visuals now support the story instead of competing with the content."
      items={aboutShowcaseItems}
    />
  );
}

export function ApproachSection() {
  return (
    <section className="section">
      <SectionIntro eyebrow="Our approach" title="Inclusive, culturally sensitive, scientific, and practical." />
      <div className="card-grid card-grid--four">
        <ValueCard title="Youth-driven" text="Young people are not only beneficiaries. They are leaders, voices, organizers, and advocates in the work." />
        <ValueCard title="Community grounded" text="We engage schools, students, professionals, institutions, and community leaders to build trust." />
        <ValueCard title="Evidence-based" text="Our education is grounded in psychological science while remaining clear, useful, and relatable." />
        <ValueCard title="Stigma-free" text="We create safe spaces where people can express themselves without shame or judgment." />
      </div>
    </section>
  );
}

export function HealingTimeline() {
  return (
    <section className="section timeline-section">
      <SectionIntro eyebrow="Our belief" title="Healing moves through awareness, conversation, and community." />
      <div className="timeline">
        <div><Eye size={22} aria-hidden="true" /><strong>Awareness</strong><span>Mental health literacy helps people name what they feel and recognize when support matters.</span></div>
        <div><Megaphone size={22} aria-hidden="true" /><strong>Conversation</strong><span>Open dialogue breaks stigma and makes it easier for young people to seek help.</span></div>
        <div><HandHeart size={22} aria-hidden="true" /><strong>Community</strong><span>Sustainable care grows when families, schools, institutions, and peers support one another.</span></div>
      </div>
    </section>
  );
}

export function DevelopmentCallout() {
  return (
    <section className="section organization-callout">
      <div>
        <p className="eyebrow">Why it matters</p>
        <h2>Mental health is part of sustainable development.</h2>
        <p>When young people are emotionally supported, communities become healthier, more resilient, and better equipped to imagine their future.</p>
      </div>
      <Brain size={44} aria-hidden="true" />
    </section>
  );
}
