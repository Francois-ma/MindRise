import { Layout } from '../components/Layout';
import { PractitionerConnectionSection } from '../components/PractitionerConnections';
import { CommunityCareCallout, SupportHero, SupportImageShowcase, SupportPathways, UrgentSupportSection } from '../components/SupportSections';
import '../styles.css';

export function Support() {
  return (
    <Layout active="support">
      <SupportHero />
      <SupportPathways />
      <PractitionerConnectionSection />
      <SupportImageShowcase />
      <UrgentSupportSection />
      <CommunityCareCallout />
    </Layout>
  );
}