
import { Layout } from '../components/Layout';
import { CommunityCareCallout, SupportHero, SupportImageShowcase, SupportPathways, UrgentSupportSection } from '../components/SupportSections';
import '../styles.css';

export function Support() {
  return (
    <Layout active="support">
      <SupportHero />
      <SupportPathways />
      <SupportImageShowcase />
      <UrgentSupportSection />
      <CommunityCareCallout />
    </Layout>
  );
}
