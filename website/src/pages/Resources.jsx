import React from 'react';
import { createRoot } from 'react-dom/client';
import { Layout } from '../components/Layout';
import { ResourceLibrary, ResourcesHero } from '../components/ResourceLibrary';
import '../styles.css';

function Resources() {
  return (
    <Layout active="resources">
      <ResourcesHero />
      <ResourceLibrary />
    </Layout>
  );
}

createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <Resources />
  </React.StrictMode>,
);