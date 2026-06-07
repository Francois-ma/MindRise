import { Link } from 'react-router-dom';
import {
  Activity,
  ArrowRight,
  BookOpen,
  Building2,
  CheckCircle2,
  Eye,
  HandHeart,
  HeartPulse,
  Landmark,
  Loader2,
  Megaphone,
  MessageCircle,
  School,
  ShieldCheck,
  Smartphone,
  Sparkles,
  UsersRound,
} from 'lucide-react';
import { PageHero, SectionIntro } from './Layout';
import { ProgramCard, Stat } from './Cards';
import { ImageShowcase } from './ImageShowcase';
import { logoFullUrl } from './siteConfig';

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

const trustSignals = [
  {
    icon: ShieldCheck,
    title: 'Privacy-first digital access',
    text: 'Account creation, email verification, and protected app access help keep private wellness features reserved for verified users.',
  },
  {
    icon: BookOpen,
    title: 'Evidence-informed education',
    text: 'Resources are structured around psychological literacy, prevention, resilience, and practical mental health education.',
  },
  {
    icon: Landmark,
    title: 'Institution-ready collaboration',
    text: 'MindRise is shaped for schools, youth groups, community leaders, and partners who need clear, respectful mental health engagement.',
  },
];

const impactMetrics = [
  {
    value: 'Youth',
    label: 'Primary audience for literacy, resilience, and emotional well-being programs',
  },
  {
    value: 'Schools',
    label: 'Outreach-ready program structure for student communities and educators',
  },
  {
    value: 'Rwanda',
    label: 'Community-centered focus for young people and underserved communities',
  },
  {
    value: 'Digital',
    label: 'Website and mobile pathways connected to the MindRise backend',
  },
];

const mobileSteps = [
  'Create your MindRise account on the website.',
  'Verify your email with the code sent to your inbox.',
  'Open the MindRise web dashboard or mobile app and log in for continuous use.',
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

const homeShowcaseItems = [
  {
    src: '/2.webp',
    alt: 'MindRise community wellness visual',
    label: 'Community',
    text: 'A calmer view of the people and environments MindRise serves.',
  },
  {
    src: '/7%20%281%29.webp',
    alt: 'MindRise outreach and contact visual',
    label: 'Outreach',
    text: 'A wide image moment for partnerships, contact, and public engagement.',
  },
  {
    src: '/9.webp',
    alt: 'MindRise community gathering and open dialogue',
    label: 'Dialogue',
    text: 'Community conversations bring people together around mental health awareness.',
  },
];

export function HomeHero({ health }) {
  return (
    <PageHero
      className="home-hero"
      image="/1.webp"
      imageAlt="MindRise awareness and youth mental health visual"
      focal="center"
      eyebrow="MindRise Wellness Initiative"
      title="Rise Above, Speak Out."
      lead="A youth-driven mental health organization promoting emotional well-being, psychological resilience, and mental health literacy among young people and underserved communities in Rwanda."
    >
      <div className="hero-actions">
        <Link className="button button--primary" to="/programs"><span>Explore our work</span><ArrowRight size={18} aria-hidden="true" /></Link>
        <Link className="button button--secondary" to="/start"><Smartphone size={18} aria-hidden="true" /><span>Create account</span></Link>
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
      <div className="hero-assurance-panel" aria-label="Official MindRise pathway">
        <img src={logoFullUrl} alt="MindRise Wellness Initiative" />
        <div>
          <strong>Official digital pathway</strong>
          <p>Create and verify your account on the website, then use MindRise on the web dashboard or mobile app.</p>
        </div>
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

export function HomeImageShowcase() {
  return (
    <ImageShowcase
      className="image-showcase--home"
      eyebrow="MindRise in view"
      title="A clearer visual story for awareness, community, and outreach."
      lead="Images are presented as focused moments, not busy backgrounds, so the website feels organized and easy to read."
      items={homeShowcaseItems}
    />
  );
}

export function TrustCredibilitySection() {
  return (
    <section className="section trust-credibility-section">
      <SectionIntro
        eyebrow="Trust and credibility"
        title="Designed for sensitive work, serious partners, and real community needs."
        lead="Mental health work needs clarity, privacy, and cultural care. MindRise presents a responsible digital and community pathway for young people, schools, institutions, and partners."
      />
      <div className="trust-card-grid">
        {trustSignals.map((signal) => {
          const Icon = signal.icon;
          return (
            <article className="trust-card" key={signal.title}>
              <Icon size={24} aria-hidden="true" />
              <h3>{signal.title}</h3>
              <p>{signal.text}</p>
            </article>
          );
        })}
      </div>
    </section>
  );
}

export function MobileContinuationSection() {
  return (
    <section className="mobile-continuation-band" aria-labelledby="mobile-continuation-title">
      <div className="mobile-continuation-inner">
        <div className="mobile-continuation-copy">
          <p className="eyebrow">Website to mobile</p>
          <h2 id="mobile-continuation-title">Create your account here. Continue MindRise on web or mobile.</h2>
          <p>The website supports official account creation, email verification, and a private dashboard. Verified users can continue MindRise on the web app or mobile app with the same account.</p>
          <div className="mobile-actions">
            <Link className="button button--primary" to="/start"><Smartphone size={18} aria-hidden="true" /><span>Create account</span></Link>
            <Link className="button button--light" to="/support">Support options</Link>
          </div>
        </div>
        <div className="mobile-step-panel" aria-label="Mobile continuation steps">
          {mobileSteps.map((step, index) => (
            <div className="mobile-step" key={step}>
              <span>{index + 1}</span>
              <p>{step}</p>
              {index === mobileSteps.length - 1 && <CheckCircle2 size={20} aria-hidden="true" />}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

export function ImpactReadinessSection() {
  return (
    <section className="section impact-section">
      <SectionIntro
        eyebrow="Impact framework"
        title="A structure ready for programs, partnerships, and measurable community growth."
        lead="MindRise can present program progress clearly as outreach expands, keeping the website prepared for schools, partners, funders, and community stakeholders."
      />
      <div className="impact-grid">
        {impactMetrics.map((metric) => (
          <article className="impact-card" key={metric.value}>
            <strong>{metric.value}</strong>
            <p>{metric.label}</p>
          </article>
        ))}
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
