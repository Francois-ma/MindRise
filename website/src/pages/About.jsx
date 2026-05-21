import React from 'react';
import { createRoot } from 'react-dom/client';
import { AboutHero, ApproachSection, DevelopmentCallout, HealingTimeline, MissionSection } from '../components/AboutSections';
import { Layout } from '../components/Layout';
import '../styles.css';

function About() {
  return (
    <Layout active="about">
      <AboutHero />
      <MissionSection />
      <ApproachSection />
      <HealingTimeline />
      <DevelopmentCallout />
    </Layout>
  );
}

createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <About />
  </React.StrictMode>,
);