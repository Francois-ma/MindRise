import { useEffect, useState } from 'react';
import { fetchHealth } from '../api';
import { Layout } from '../components/Layout';
import { BeliefCallout, CommitmentStrip, HomeHero, WhatWeProvideSection, WhoWeAreSection } from '../components/HomeSections';
import '../styles.css';

export function Home() {
  const [health, setHealth] = useState({ status: 'checking', message: 'Checking digital services' });

  useEffect(() => {
    fetchHealth()
      .then(() => setHealth({ status: 'online', message: 'Digital services available' }))
      .catch(() => setHealth({ status: 'offline', message: 'Digital services are temporarily unavailable' }));
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
