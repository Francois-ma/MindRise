import { Link } from 'react-router-dom';
import {
  Activity,
  ArrowRight,
  BookOpen,
  Building2,
  Eye,
  HandHeart,
  HeartPulse,
  Loader2,
  Megaphone,
  MessageCircle,
  School,
  ShieldCheck,
  Sparkles,
  UsersRound,
} from 'lucide-react';
import { PageHero, SectionIntro } from './Layout';
import { ProgramCard, Stat } from './Cards';

const pathways = [
  {
    icon: UsersRound,
    eyebrow: 'Young people',
    title: 'A safe place to learn, reflect, and speak.',
    text: 'Youth-friendly guidance helps young people understand emotional well-being and take early, healthy steps toward support.',
    to: '/resources',
    cta: 'Use resources',
  },
  {
    icon: School,
    eyebrow: 'Schools',
    title: 'Practical literacy for student communities.',
    text: 'MindRise supports school outreach with stigma-free conversations, preventive education, and relatable learning formats.',
    to: '/programs',
    cta: 'View programs',
  },
  {
    icon: Building2,
    eyebrow: 'Communities',
    title: 'Community-centered awareness and dialogue.',
    text: 'We work with institutions and community leaders to make mental health conversations respectful, inclusive, and accessible.',
    to: '/start',
    cta: 'Get involved',
  },
];

const healingSteps = [
  {
    icon: Eye,
    label: 'Awareness',
    text: 'People need simple language for what they feel before support can become easier to seek.',
  },
  {
    icon: MessageCircle,
    label: 'Conversation',
    text: 'Open dialogue reduces shame and helps young people feel heard, understood, and less isolated.',
  },
  {
    icon: HandHeart,
    label: 'Community',
    text: 'Support lasts longer when peers, schools, families, institutions, and leaders move together.',
  },
];

export function HomeHero({ health }) {
  return (
    <PageHero
      className="home-hero"
      eyebrow="MindRise Wellness Initiative"
      title="Rise Above, Speak Out."
      lead="A youth-driven mental health organization promoting emotional well-being, psychological resilience, and mental health literacy among young people and underserved communities in Rwanda."
    >
      <div className="hero-actions">
        <Link className="button button--primary" to="/programs"><span>Explore our work</span><ArrowRight size={18} aria-hidden="true" /></Link>
        <Link className="button button--secondary" to="/about">Our story</Link>
      </div>
      <div className="hero-proof-list" aria-label="MindRise practice principles">
        <span>Evidence-informed</span>
        <span>Youth-friendly</span>
        <span>Community-centered</span>
      </div>
      <div className={`api-pill api-pill--${health.status}`}>
        {health.status === 'checking' ? <Loader2 className="spin" size={16} aria-hidden="true" /> : <span aria-hidden="true" />}
        {health.message}
      </div>
    </PageHero>
  );
}

export function CommitmentStrip() {
  return (
    <section className="trust-strip" aria-label="MindRise commitments">
      <div><Megaphone size={22} aria-hidden="true" /><span>Breaking mental health stigma</span></div>
      <div><BookOpen size={22} aria-hidden="true" /><span>Evidence-based education</span></div>
      <div><UsersRound size={22} aria-hidden="true" /><span>Community-centered support</span></div>
    </section>
  );
}

export function WhoWeAreSection() {
  return (
    <section className="section section--split">
      <SectionIntro
        eyebrow="Who we are"
        title="Mental health is not a luxury. It is part of human well-being and sustainable development."
        lead="MindRise works to make mental health support more accessible through awareness campaigns, educational resources, community engagement, school outreach, media engagement, and early-stage education initiatives."
      />
      <div className="stats-grid">
        <Stat value="Youth" label="Driven by young leaders and lived community needs" />
        <Stat value="Rwanda" label="Focused on young people and underserved communities" />
        <Stat value="Early" label="Prevention, literacy, and early intervention" />
      </div>
    </section>
  );
}

export function PathwaysSection() {
  return (
    <section className="section pathway-section">
      <SectionIntro
        eyebrow="Who we serve"
        title="Clear pathways for young people, schools, and communities."
        lead="MindRise is designed to meet people where they are: in classrooms, community spaces, digital platforms, and everyday conversations."
      />
      <div className="pathway-grid">
        {pathways.map((pathway) => {
          const Icon = pathway.icon;

          return (
            <article className="pathway-card" key={pathway.title}>
              <div className="pathway-card__icon"><Icon size={24} aria-hidden="true" /></div>
              <p className="eyebrow">{pathway.eyebrow}</p>
              <h3>{pathway.title}</h3>
              <p>{pathway.text}</p>
              <Link className="pathway-link" to={pathway.to}>{pathway.cta}<ArrowRight size={16} aria-hidden="true" /></Link>
            </article>
          );
        })}
      </div>
    </section>
  );
}

export function WhatWeProvideSection() {
  return (
    <section className="section">
      <SectionIntro eyebrow="What we provide" title="Practical, relatable mental health support for real lives." />
      <div className="card-grid card-grid--four">
        <ProgramCard icon={BookOpen} title="Mental health information" text="Evidence-informed resources on emotional awareness, confidence, relationships, and life transitions." tone="lime" />
        <ProgramCard icon={MessageCircle} title="Safe dialogue spaces" text="Community conversations that encourage expression, listening, and stigma-free support." tone="blue" />
        <ProgramCard icon={HeartPulse} title="Preventive tools" text="Preventive education tools that help young people reflect, communicate, and seek support early." />
        <ProgramCard icon={Sparkles} title="Youth-friendly guidance" text="Clear, culturally sensitive guidance that remains practical, warm, and relatable." tone="amber" />
      </div>
    </section>
  );
}

export function HealingPathSection() {
  return (
    <section className="healing-path">
      <div className="healing-path__inner">
        <div className="healing-path__copy">
          <p className="eyebrow">MindRise method</p>
          <h2>Healing begins with awareness, grows through conversation, and is sustained by community.</h2>
          <p>Our approach is calm, inclusive, culturally sensitive, and grounded in psychological science while remaining practical enough for real community settings.</p>
        </div>
        <div className="healing-steps" aria-label="MindRise healing pathway">
          {healingSteps.map((step, index) => {
            const Icon = step.icon;

            return (
              <div className="healing-step" key={step.label}>
                <div className="healing-step__icon"><Icon size={22} aria-hidden="true" /></div>
                <div>
                  <span>{String(index + 1).padStart(2, '0')}</span>
                  <h3>{step.label}</h3>
                  <p>{step.text}</p>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}

export function BeliefCallout() {
  return (
    <section className="section organization-callout organization-callout--belief">
      <div>
        <p className="eyebrow">Our belief</p>
        <h2>No one should feel alone in their mental health journey.</h2>
        <p>We collaborate with students, professionals, institutions, and community leaders to build awareness, encourage conversation, and strengthen community support.</p>
        <div className="callout-actions">
          <Link className="button button--light" to="/start"><ShieldCheck size={18} aria-hidden="true" /><span>Get involved</span></Link>
          <Link className="button button--callout" to="/contact"><span>Contact MindRise</span><ArrowRight size={16} aria-hidden="true" /></Link>
        </div>
      </div>
      <Activity size={44} aria-hidden="true" />
    </section>
  );
}