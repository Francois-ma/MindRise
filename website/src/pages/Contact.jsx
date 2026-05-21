import React from 'react';
import { createRoot } from 'react-dom/client';
import { Building2, Mail, MapPin, School, UsersRound } from 'lucide-react';
import { Layout, PageHero, SectionIntro } from '../components/Layout';
import { ValueCard } from '../components/Cards';
import '../styles.css';

function Contact() {
  return (
    <Layout active="contact">
      <PageHero
        compact
        eyebrow="Contact"
        title="Work with MindRise Wellness Initiative."
        lead="Connect with us for school outreach, awareness campaigns, community engagement, media conversations, partnerships, or youth mental health education in Rwanda."
      />

      <section className="section contact-layout">
        <div>
          <SectionIntro
            eyebrow="Partnerships and inquiries"
            title="We collaborate with students, professionals, institutions, and community leaders."
            lead="If your school, organization, media platform, or community group wants to strengthen mental health literacy and reduce stigma, MindRise is ready to build with you."
          />
          <div className="contact-methods">
            <div><Mail size={22} aria-hidden="true" /><span>hello@mindrise.health</span></div>
            <div><MapPin size={22} aria-hidden="true" /><span>Rwanda, with youth and underserved communities at the center</span></div>
            <div><Building2 size={22} aria-hidden="true" /><span>Awareness, education, outreach, media, and community programs</span></div>
          </div>
        </div>
        <div className="contact-panel">
          <h3>Collaboration focus</h3>
          <div className="card-grid">
            <ValueCard title="Schools" text="Mental health literacy sessions and safe conversations for students." />
            <ValueCard title="Communities" text="Awareness campaigns and culturally sensitive engagement for underserved groups." />
            <ValueCard title="Media and institutions" text="Public education, storytelling, and partnerships that normalize mental health dialogue." />
          </div>
          <a className="button button--primary" href="mailto:hello@mindrise.health"><Mail size={18} aria-hidden="true" /><span>Email MindRise</span></a>
        </div>
      </section>

      <section className="section organization-callout">
        <div>
          <p className="eyebrow">Rise Above, Speak Out</p>
          <h2>Let us build mental health awareness before silence becomes suffering.</h2>
        </div>
        <School size={44} aria-hidden="true" />
      </section>
    </Layout>
  );
}

createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <Contact />
  </React.StrictMode>,
);