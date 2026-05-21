
import { Layout } from '../components/Layout';
import { StartAccountSection, StartHero } from '../components/StartSections';
import '../styles.css';

export function Start() {
  return (
    <Layout active="start">
      <StartHero />
      <StartAccountSection />
    </Layout>
  );
}
