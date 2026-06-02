
import { Layout } from '../components/Layout';
import { CollaborationCallout, ProgramGrid, ProgramModel, ProgramsHero, ProgramsImageShowcase } from '../components/ProgramsSections';
import '../styles.css';

export function Programs() {
  return (
    <Layout active="programs">
      <ProgramsHero />
      <ProgramGrid />
      <ProgramsImageShowcase />
      <ProgramModel />
      <CollaborationCallout />
    </Layout>
  );
}
