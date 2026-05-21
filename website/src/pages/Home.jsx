import React, { useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { Activity, ArrowRight, BookOpen, HeartPulse, Loader2, Megaphone, MessageCircle, ShieldCheck, Sparkles, UsersRound } from 'lucide-react';
import { fetchHealth } from '../api';
import { Layout, PageHero, SectionIntro } from '../components/Layout';
import { ProgramCard, Stat } from '../components/Cards';
import '../styles.css';

function Home() {
  const [health, setHealth] = useState({ status: 'checking', message: 'Checking API connection' });

  useEffect(() => {
    fetchHealth()
      .then(() => setHealth({ status: 'online', message: 'Connected to MindRise API' }))
      .catch((error) => setHealth({ status: 'offline', message: error.message }));
  }, []);

  return (
    <Layout active="home">
      <PageHero
        eyebrow="MindRise Wellness Initiative"
        title="Rise Above, Speak Out."
        lead="A youth-driven mental health organization promoting emotional well-being, psychological resilience, and mental health literacy among young people and underserved communities in Rwanda."
      >
        <div className="hero-actions">
          <a className="button button--primary" href="/programs.html"><span>Explore our work</span><ArrowRight size={18} aria-hidden="true" /></a>
          <a className="button button--secondary" href="/about.html">Our story</a>
        </div>
        <div className={`api-pill api-pill--${health.status}`}>
          {health.status === 'checking' ? <Loader2 className="spin" size={16} aria-hidden="true" /> : <span aria-hidden="true" />}
          {health.message}
        </div>
      </PageHero>

      <section className="trust-strip" aria-label="MindRise commitments">
        <div><Megaphone size={22} aria-hidden="true" /><span>Breaking mental health stigma</span></div>
        <div><BookOpen size={22} aria-hidden="true" /><span>Evidence-based education</span></div>
        <div><UsersRound size={22} aria-hidden="true" /><span>Community-centered support</span></div>
      </section>

      <section className="section section--split">
        <SectionIntro
          eyebrow="Who we are"
          title="Mental health is not a luxury. It is part of human well-being and sustainable development."
          lead="MindRise works to make mental health support more accessible through awareness campaigns, educational resources, community engagement, school outreach, digital platforms, media engagement, and early-intervention initiatives."
        />
        <div className="stats-grid">
          <Stat value="Youth" label="Driven by young leaders and lived community needs" />
          <Stat value="Rwanda" label="Focused on young people and underserved communities" />
          <Stat value="Early" label="Prevention, literacy, and early intervention" />
        </div>
      </section>

      <section className="section">
        <SectionIntro eyebrow="What we provide" title="Practical, relatable mental health support for real lives." />
        <div className="card-grid card-grid--four">
          <ProgramCard icon={BookOpen} title="Mental health information" text="Evidence-based resources on stress, anxiety, depression, self-esteem, and life transitions." tone="lime" />
          <ProgramCard icon={MessageCircle} title="Safe dialogue spaces" text="Community conversations that encourage expression, listening, and stigma-free support." tone="blue" />
          <ProgramCard icon={HeartPulse} title="Preventive tools" text="Psychoeducational and early-intervention tools that help young people act before crisis." />
          <ProgramCard icon={Sparkles} title="Youth-friendly guidance" text="Clear, culturally sensitive guidance that remains practical, warm, and relatable." tone="amber" />
        </div>
      </section>

      <section className="section organization-callout">
        <div>
          <p className="eyebrow">Our belief</p>
          <h2>Healing begins with awareness, grows through conversation, and is sustained by community.</h2>
          <p>We collaborate with students, professionals, institutions, and community leaders so no one feels alone in their mental health journey.</p>
        </div>
        <Activity size={44} aria-hidden="true" />
      </section>
    </Layout>
  );
}

createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <Home />
  </React.StrictMode>,
);