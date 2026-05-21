
import { Layout } from '../components/Layout';
import { CommunityCareCallout, SupportHero, SupportPathways, UrgentSupportSection } from '../components/SupportSections';
import '../styles.css';

export function Support() {
  return (
    <Layout active="support">
      <SupportHero />
      <SupportPathways />
      <UrgentSupportSection />
      <CommunityCareCallout />
    </Layout>
  );
}
