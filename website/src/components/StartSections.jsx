import { Link } from 'react-router-dom';
import { ArrowRight, Building2, Mail, ShieldCheck } from 'lucide-react';
import { PageHero, SectionIntro } from './Layout';
import { ValueCard } from './Cards';
import { LoginPanel, SignupPanel } from './SignupPanel';

export function StartHero() {
  return (
    <PageHero
      compact
      image="/6.png"
      imageAlt="MindRise digital account access visual"
      focal="center"
      eyebrow="Account access"
      title="Open the MindRise digital experience."
      lead="Create a verified account or sign in to use the MindRise dashboard on the web, with the same account ready for mobile access."
    />
  );
}

export function StartAccountSection() {
  return (
    <>
      <section className="section account-section">
        <SectionIntro
          eyebrow="Web app access"
          title="Create an account or sign in to continue."
          lead="After email verification, MindRise opens a private dashboard with mood tracking, insights, reset tools, learning resources, support pathways, and profile access."
        />
        <div className="auth-access-grid">
          <SignupPanel />
          <LoginPanel />
        </div>
      </section>

      <section className="section section--start-page">
        <SectionIntro
          eyebrow="Partnership pathway"
          title="Bring mental health awareness into your school, organization, or community."
          lead="Share your collaboration interest and our team will follow up with a thoughtful next step."
        />
        <div className="partnership-panel">
          <div className="partnership-panel__intro">
            <ShieldCheck size={30} aria-hidden="true" />
            <h3>Responsible outreach</h3>
            <p>We keep public conversations educational, respectful, and appropriate for young people and community settings.</p>
          </div>
          <div className="card-grid">
            <ValueCard title="Schools" text="Student-centered mental health literacy and dialogue sessions." />
            <ValueCard title="Communities" text="Awareness activities shaped around local needs and cultural context." />
            <ValueCard title="Institutions" text="Partnerships for prevention, education, and public engagement." />
          </div>
          <div className="partnership-actions">
            <Link className="button button--primary" to="/contact"><Mail size={18} aria-hidden="true" /><span>Contact MindRise</span></Link>
            <Link className="button button--secondary" to="/programs"><Building2 size={18} aria-hidden="true" /><span>View programs</span><ArrowRight size={16} aria-hidden="true" /></Link>
          </div>
        </div>
      </section>
    </>
  );
}