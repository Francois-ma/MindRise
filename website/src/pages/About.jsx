
import { AboutHero, ApproachSection, DevelopmentCallout, HealingTimeline, MissionSection } from '../components/AboutSections';
import { Layout } from '../components/Layout';
import '../styles.css';

export function About() {
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
