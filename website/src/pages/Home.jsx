import { useEffect, useState } from 'react';
import { fetchHealth } from '../api';
import { Layout } from '../components/Layout';
import { BeliefCallout, CommitmentStrip, HealingPathSection, HomeHero, PathwaysSection, WhatWeProvideSection, WhoWeAreSection } from '../components/HomeSections';
import '../styles.css';

export function Home() {
  const [health, setHealth] = useState({ status: 'checking', message: 'Checking availability' });

  useEffect(() => {
    fetchHealth()
      .then(() => setHealth({ status: 'online', message: 'Organization updates available' }))
      .catch(() => setHealth({ status: 'offline', message: 'Updates are temporarily unavailable' }));
  }, []);

  return (
    <Layout active="home">
      <HomeHero health={health} />
      <CommitmentStrip />
      <WhoWeAreSection />
      <PathwaysSection />
      <WhatWeProvideSection />
      <HealingPathSection />
      <BeliefCallout />
    </Layout>
  );
}