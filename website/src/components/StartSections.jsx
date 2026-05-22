import { Link } from 'react-router-dom';
import { ArrowRight, Building2, Mail, ShieldCheck } from 'lucide-react';
import { PageHero, SectionIntro } from './Layout';
import { ValueCard } from './Cards';
import { SignupPanel } from './SignupPanel';

export function StartHero() {
  return (
    <PageHero
      compact
      eyebrow="Get involved"
      title="Join MindRise Wellness Initiative."
      lead="Create an account for the MindRise experience or connect with us for school, community, media, and institutional partnerships."
    />
  );
}

export function StartAccountSection() {
  return (
    <>
      <section className="section account-section">
        <SectionIntro
          eyebrow="Account access"
          title="Create your MindRise account."
          lead="Start with a verified email account so you can use MindRise digital features when they are available to you."
        />
        <SignupPanel />
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