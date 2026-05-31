import { useMemo, useState } from 'react';
import { AlertCircle, Building2, CheckCircle2, Loader2, Mail, MapPin, School, Send } from 'lucide-react';
import { sendContactMessage } from '../api';
import { PageHero, SectionIntro } from './Layout';
import { ValueCard } from './Cards';

const contactTopics = [
  { value: 'school-outreach', label: 'School outreach' },
  { value: 'community-program', label: 'Community program' },
  { value: 'partnership', label: 'Partnership' },
  { value: 'media', label: 'Media inquiry' },
  { value: 'volunteer', label: 'Volunteer interest' },
  { value: 'general', label: 'General inquiry' },
];

const initialForm = {
  name: '',
  email: '',
  organization: '',
  topic: 'partnership',
  message: '',
  website: '',
};

export function ContactHero() {
  return (
    <PageHero
      compact
      eyebrow="Contact"
      title="Work with MindRise Wellness Initiative."
      lead="Connect with us for school outreach, awareness campaigns, community engagement, media conversations, partnerships, or youth mental health education in Rwanda."
    />
  );
}

export function ContactContent() {
  return (
    <section className="section contact-layout">
      <div>
        <SectionIntro
          eyebrow="Partnerships and inquiries"
          title="We collaborate with students, professionals, institutions, and community leaders."
          lead="If your school, organization, media platform, or community group wants to strengthen mental health literacy and reduce stigma, MindRise is ready to build with you."
        />
        <div className="contact-methods">
          <div><Mail size={22} aria-hidden="true" /><span>mindriserwanda@gmail.com</span></div>
          <div><MapPin size={22} aria-hidden="true" /><span>Rwanda, with youth and underserved communities at the center</span></div>
          <div><Building2 size={22} aria-hidden="true" /><span>Awareness, education, outreach, media, and community programs</span></div>
        </div>
        <div className="contact-focus-grid">
          <ValueCard title="Schools" text="Mental health literacy sessions and safe conversations for students." />
          <ValueCard title="Communities" text="Awareness campaigns and culturally sensitive engagement for underserved groups." />
          <ValueCard title="Media and institutions" text="Public education, storytelling, and partnerships that normalize mental health dialogue." />
        </div>
      </div>
      <div className="contact-panel">
        <ContactForm />
      </div>
    </section>
  );
}

function ContactForm() {
  const [form, setForm] = useState(initialForm);
  const [status, setStatus] = useState({ type: '', message: '' });
  const [loading, setLoading] = useState(false);

  const canSubmit = useMemo(
    () => form.name.trim().length >= 2 && form.email.includes('@') && form.message.trim().length >= 20,
    [form],
  );

  async function submitMessage(event) {
    event.preventDefault();
    if (!canSubmit || loading) return;
    setLoading(true);
    setStatus({ type: '', message: '' });
    try {
      await sendContactMessage({
        name: form.name.trim(),
        email: form.email.trim(),
        organization: form.organization.trim(),
        topic: form.topic,
        message: form.message.trim(),
        website: form.website,
      });
      setForm(initialForm);
      setStatus({ type: 'success', message: 'Your message has been sent to MindRise.' });
    } catch (error) {
      setStatus({ type: 'error', message: error.message });
    } finally {
      setLoading(false);
    }
  }

  return (
    <form className="form-card contact-form" onSubmit={submitMessage}>
      <div className="verification-heading">
        <Send size={28} aria-hidden="true" />
        <div>
          <h3>Send MindRise a message</h3>
          <p>Messages are delivered directly to the MindRise Rwanda inbox.</p>
        </div>
      </div>

      <div className="contact-form__split">
        <Field label="Full name" value={form.name} onChange={(value) => setForm((current) => ({ ...current, name: value }))} autoComplete="name" />
        <Field label="Email address" type="email" value={form.email} onChange={(value) => setForm((current) => ({ ...current, email: value }))} autoComplete="email" />
      </div>

      <Field label="Organization" value={form.organization} onChange={(value) => setForm((current) => ({ ...current, organization: value }))} autoComplete="organization" />

      <label className="field">
        <span>Topic</span>
        <div>
          <select value={form.topic} onChange={(event) => setForm((current) => ({ ...current, topic: event.target.value }))}>
            {contactTopics.map((topic) => <option key={topic.value} value={topic.value}>{topic.label}</option>)}
          </select>
        </div>
      </label>

      <label className="field">
        <span>Message</span>
        <div className="field__textarea">
          <textarea value={form.message} onChange={(event) => setForm((current) => ({ ...current, message: event.target.value }))} rows={6} placeholder="Tell us how MindRise can collaborate with you." />
        </div>
        <small>Minimum 20 characters</small>
      </label>

      <label className="field field--honeypot" aria-hidden="true">
        <span>Website</span>
        <input tabIndex={-1} autoComplete="off" value={form.website} onChange={(event) => setForm((current) => ({ ...current, website: event.target.value }))} />
      </label>

      <button className="button button--primary button--full" type="submit" disabled={!canSubmit || loading}>
        {loading ? <Loader2 className="spin" size={18} aria-hidden="true" /> : <Send size={18} aria-hidden="true" />}
        <span>Send message</span>
      </button>
      <FormStatus status={status} />
    </form>
  );
}

function Field({ label, type = 'text', value, onChange, ...props }) {
  return (
    <label className="field">
      <span>{label}</span>
      <div>
        <input type={type} value={value} onChange={(event) => onChange(event.target.value)} placeholder={label} {...props} />
      </div>
    </label>
  );
}

function FormStatus({ status }) {
  if (!status.message) return null;
  const Icon = status.type === 'success' ? CheckCircle2 : AlertCircle;
  return <p className={`form-status form-status--${status.type}`}><Icon size={17} aria-hidden="true" />{status.message}</p>;
}

export function ContactCallout() {
  return (
    <section className="section organization-callout">
      <div>
        <p className="eyebrow">Rise Above, Speak Out</p>
        <h2>Let us build mental health awareness before silence becomes suffering.</h2>
      </div>
      <School size={44} aria-hidden="true" />
    </section>
  );
}