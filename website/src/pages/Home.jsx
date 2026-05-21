import React, { useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { fetchHealth } from '../api';
import { Layout } from '../components/Layout';
import { BeliefCallout, CommitmentStrip, HomeHero, WhatWeProvideSection, WhoWeAreSection } from '../components/HomeSections';
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
      <HomeHero health={health} />
      <CommitmentStrip />
      <WhoWeAreSection />
      <WhatWeProvideSection />
      <BeliefCallout />
    </Layout>
  );
}

createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <Home />
  </React.StrictMode>,
);