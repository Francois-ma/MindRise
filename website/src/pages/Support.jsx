import React, { useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { HandHeart, Loader2, MessageCircle, Phone, ShieldCheck, UsersRound } from 'lucide-react';
import { fetchCrisisResources } from '../api';
import { Layout, PageHero, SectionIntro } from '../components/Layout';
import { InlineState } from '../components/Cards';
import '../styles.css';

const fallbackResources = [
  {
    id: 'emergency',
    title: 'Emergency support',
    phone_number: '112',
    description: 'If someone is in immediate danger, contact local emergency services right away.',
  },
];

function Support() {
  const [resources, setResources] = useState({ items: [], error: '', loading: true });

  useEffect(() => {
    fetchCrisisResources()
      .then((items) => setResources({ items, error: '', loading: false }))
      .catch((error) => setResources({ items: [], error: error.message, loading: false }));
  }, []);

  const crisisResources = resources.items.length ? resources.items : fallbackResources;

  return (
    <Layout active="support">
      <PageHero
        compact
        eyebrow="Support"
        title="No one should feel alone in their mental health journey."
        lead="MindRise creates safe spaces for expression, dialogue, education, and early support while helping young people know when and how to seek more help."
      />

      <section className="section support-grid">
        <article className="support-card support-card--primary">
          <MessageCircle size={30} aria-hidden="true" />
          <h3>Safe spaces for dialogue</h3>
          <p>We encourage open conversations where young people can express what they feel, listen to others, and challenge stigma together.</p>
          <a className="button button--light" href="/contact.html">Partner with us</a>
        </article>
        <article className="support-card">
          <UsersRound size={30} aria-hidden="true" />
          <h3>Community and school support</h3>
          <p>Through outreach, campaigns, and education, MindRise works with students, professionals, institutions, and community leaders.</p>
        </article>
      </section>

      <section className="section urgent-section">
        <SectionIntro
          eyebrow="Early support"
          title="Preventive help, crisis awareness, and accessible guidance."
          lead="MindRise is not an emergency service, but we help communities understand warning signs, reduce silence, and connect people to appropriate support."
        />
        <div className="resource-list">
          {crisisResources.map((resource) => (
            <article className="resource-item" key={resource.id || resource.title}>
              <Phone size={22} aria-hidden="true" />
              <div>
                <strong>{resource.title}</strong>
                <p>{resource.description}</p>
                <span>{resource.phone_number || resource.phoneNumber || 'Local emergency services'}</span>
              </div>
            </article>
          ))}
        </div>
        {resources.loading && <InlineState icon={Loader2} text="Loading crisis resources" spin />}
        {resources.error && <InlineState icon={ShieldCheck} text={resources.error} />}
      </section>

      <section className="section organization-callout">
        <div>
          <p className="eyebrow">Community care</p>
          <h2>Support becomes stronger when communities learn how to talk, listen, and respond.</h2>
        </div>
        <HandHeart size={44} aria-hidden="true" />
      </section>
    </Layout>
  );
}

createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <Support />
  </React.StrictMode>,
);