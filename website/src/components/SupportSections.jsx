import { Link } from 'react-router-dom';
import { BookOpen, HandHeart, MessageCircle, UsersRound } from 'lucide-react';
import { PageHero, SectionIntro } from './Layout';

export function SupportHero() {
  return (
    <PageHero
      compact
      eyebrow="Support"
      title="Community support through education, dialogue, and connection."
      lead="MindRise creates respectful spaces for expression and learning while helping communities understand how to respond with care."
    />
  );
}

export function SupportPathways() {
  return (
    <section className="section support-grid">
      <article className="support-card support-card--primary">
        <MessageCircle size={30} aria-hidden="true" />
        <h3>Safe spaces for dialogue</h3>
        <p>We encourage open conversations where young people can express themselves, listen to others, and challenge stigma together.</p>
        <Link className="button button--light" to="/contact">Partner with us</Link>
      </article>
      <article className="support-card">
        <UsersRound size={30} aria-hidden="true" />
        <h3>Community and school support</h3>
        <p>Through outreach, campaigns, and education, MindRise works with students, professionals, institutions, and community leaders.</p>
      </article>
    </section>
  );
}

export function UrgentSupportSection() {
  return (
    <section className="section urgent-section">
      <SectionIntro
        eyebrow="Guidance"
        title="Practical education that helps communities respond early."
        lead="Our work focuses on awareness, prevention, and supportive conversations in settings where young people live, study, and gather."
      />
      <div className="resource-list">
        <article className="resource-item">
          <BookOpen size={22} aria-hidden="true" />
          <div>
            <strong>Mental health literacy</strong>
            <p>Clear, youth-friendly education that helps people understand emotional well-being and reduce stigma.</p>
          </div>
        </article>
        <article className="resource-item">
          <HandHeart size={22} aria-hidden="true" />
          <div>
            <strong>Community response</strong>
            <p>Programs that help schools, families, and local groups build more supportive environments.</p>
          </div>
        </article>
      </div>
    </section>
  );
}

export function CommunityCareCallout() {
  return (
    <section className="section organization-callout">
      <div>
        <p className="eyebrow">Community care</p>
        <h2>Support becomes stronger when communities learn how to talk, listen, and respond.</h2>
      </div>
      <HandHeart size={44} aria-hidden="true" />
    </section>
  );
}