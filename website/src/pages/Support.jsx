import React from 'react';
import { createRoot } from 'react-dom/client';
import { Layout } from '../components/Layout';
import { CommunityCareCallout, SupportHero, SupportPathways, UrgentSupportSection } from '../components/SupportSections';
import '../styles.css';

function Support() {
  return (
    <Layout active="support">
      <SupportHero />
      <SupportPathways />
      <UrgentSupportSection />
      <CommunityCareCallout />
    </Layout>
  );
}

createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <Support />
  </React.StrictMode>,
);