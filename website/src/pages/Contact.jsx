
import { ContactCallout, ContactContent, ContactHero } from '../components/ContactSections';
import { Layout } from '../components/Layout';
import '../styles.css';

export function Contact() {
  return (
    <Layout active="contact">
      <ContactHero />
      <ContactContent />
      <ContactCallout />
    </Layout>
  );
}
