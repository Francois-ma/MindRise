
import { Layout } from '../components/Layout';
import { ResourceLibrary, ResourcesHero } from '../components/ResourceLibrary';
import '../styles.css';

export function Resources() {
  return (
    <Layout active="resources">
      <ResourcesHero />
      <ResourceLibrary />
    </Layout>
  );
}
