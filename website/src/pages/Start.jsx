import React from 'react';
import { createRoot } from 'react-dom/client';
import { Layout, PageHero, SectionIntro } from '../components/Layout';
import { SignupPanel } from '../components/SignupPanel';
import '../styles.css';

function Start() {
  return (
    <Layout active="start">
      <PageHero
        compact
        eyebrow="Digital platform"
        title="Access MindRise digital wellness tools."
        lead="The MindRise platform supports private check-ins, learning, and youth-friendly mental wellness guidance as part of our broader community initiative."
      />
      <section className="section section--start-page">
        <SectionIntro
          eyebrow="Secure onboarding"
          title="Create a verified account for the MindRise mobile experience."
          lead="Registration connects to the existing Django backend and sends a verification code before sign-in. Browser-based signup also requires the website origin to be allowed in Render CORS settings."
        />
        <SignupPanel />
      </section>
    </Layout>
  );
}

createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <Start />
  </React.StrictMode>,
);