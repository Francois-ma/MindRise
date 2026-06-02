
import { AboutHero, AboutImageShowcase, ApproachSection, DevelopmentCallout, HealingTimeline, MissionSection } from '../components/AboutSections';
import { Layout } from '../components/Layout';
import '../styles.css';

export function About() {
  return (
    <Layout active="about">
      <AboutHero />
      <MissionSection />
      <AboutImageShowcase />
      <ApproachSection />
      <HealingTimeline />
      <DevelopmentCallout />
    </Layout>
  );
}
