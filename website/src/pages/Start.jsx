import React from 'react';
import { createRoot } from 'react-dom/client';
import { Layout } from '../components/Layout';
import { StartAccountSection, StartHero } from '../components/StartSections';
import '../styles.css';

function Start() {
  return (
    <Layout active="start">
      <StartHero />
      <StartAccountSection />
    </Layout>
  );
}

createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <Start />
  </React.StrictMode>,
);