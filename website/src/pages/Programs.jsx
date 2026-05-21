import React from 'react';
import { createRoot } from 'react-dom/client';
import { Layout } from '../components/Layout';
import { CollaborationCallout, ProgramGrid, ProgramModel, ProgramsHero } from '../components/ProgramsSections';
import '../styles.css';

function Programs() {
  return (
    <Layout active="programs">
      <ProgramsHero />
      <ProgramGrid />
      <ProgramModel />
      <CollaborationCallout />
    </Layout>
  );
}

createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <Programs />
  </React.StrictMode>,
);