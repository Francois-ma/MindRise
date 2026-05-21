import React from 'react';
import { createRoot } from 'react-dom/client';
import { ContactCallout, ContactContent, ContactHero } from '../components/ContactSections';
import { Layout } from '../components/Layout';
import '../styles.css';

function Contact() {
  return (
    <Layout active="contact">
      <ContactHero />
      <ContactContent />
      <ContactCallout />
    </Layout>
  );
}

createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <Contact />
  </React.StrictMode>,
);