import { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  AlertCircle,
  ArrowRight,
  CheckCircle2,
  Camera,
  Loader2,
  Mail,
  MapPin,
  MessageCircle,
  Send,
  ShieldCheck,
  Smartphone,
  X as XIcon,
} from 'lucide-react';
import { sendContactMessage } from '../api';
import { logoFullUrl } from './siteConfig';

const socialLinks = [
  {
    label: 'Instagram',
    href: 'https://www.instagram.com/mindrise_rwanda',
    icon: Camera,
  },
  {
    label: 'X',
    href: 'https://x.com/MindRise_RW',
    icon: XIcon,
  },
  {
    label: 'WhatsApp Channel',
    href: 'https://whatsapp.com/channel/0029VbAwpnf7j6fxTq8D6t3r',
    icon: MessageCircle,
  },
];

export function Footer() {
  const year = new Date().getFullYear();

  return (
    <footer className="site-footer">
      <div className="footer-main footer-main--enhanced">
        <div className="footer-brand-block">
          <Link className="footer-brand footer-brand--lockup" to="/" aria-label="MindRise Wellness Initiative home">
            <img className="footer-logo-full" src={logoFullUrl} alt="MindRise Wellness Initiative" />
          </Link>
          <p>MindRise Wellness Initiative is a youth-driven mental health organization promoting emotional well-being, psychological resilience, and mental health literacy in Rwanda.</p>
          <strong>Rise Above, Speak Out.</strong>
          <Link className="footer-action-link" to="/start">
            Create a MindRise account
            <ArrowRight size={16} aria-hidden="true" />
          </Link>
          <div className="footer-assurance">
            <ShieldCheck size={17} aria-hidden="true" />
            <span>Private digital access for verified MindRise accounts.</span>
          </div>
        </div>

        <FooterNewsletter />

        <div className="footer-directory" aria-label="MindRise footer navigation">
          <div className="footer-link-grid">
            <nav className="footer-column" aria-label="Organization links">
              <span>Organization</span>
              <Link to="/about">About MindRise</Link>
              <Link to="/programs">Programs</Link>
              <Link to="/resources">Resources</Link>
              <Link to="/support">Support</Link>
            </nav>

            <nav className="footer-column" aria-label="Program links">
              <span>Focus Areas</span>
              <Link to="/programs">School outreach</Link>
              <Link to="/programs">Awareness campaigns</Link>
              <Link to="/programs">Community engagement</Link>
              <Link to="/programs">Media education</Link>
            </nav>

            <nav className="footer-column" aria-label="Digital access links">
              <span>Digital Access</span>
              <Link to="/start"><Smartphone size={16} aria-hidden="true" /> Create account</Link>
              <Link to="/start">Verify email</Link>
              <Link to="/app">Web dashboard</Link>
              <p>Use the same MindRise account on web and mobile.</p>
            </nav>

            <div className="footer-column footer-contact">
              <span>Contact</span>
              <a href="mailto:mindriserwanda@gmail.com"><Mail size={16} aria-hidden="true" /> mindriserwanda@gmail.com</a>
              <a href="tel:+250787804069"><Smartphone size={16} aria-hidden="true" /> +250 787804069</a>
              <p><MapPin size={16} aria-hidden="true" /> Kigali, Rwanda</p>
            </div>
          </div>

          <div className="footer-social-panel">
            <div>
              <span>Official channels</span>
              <p>Follow MindRise updates, outreach moments, and youth mental health conversations.</p>
            </div>
            <div className="footer-social-row" aria-label="MindRise social media">
              {socialLinks.map((item) => {
                const Icon = item.icon;
                return (
                  <a className="footer-social-chip" key={item.href} href={item.href} target="_blank" rel="noopener noreferrer" aria-label={`MindRise on ${item.label}`}>
                    <Icon size={17} aria-hidden="true" />
                    <span>{item.label}</span>
                  </a>
                );
              })}
            </div>
          </div>
        </div>
      </div>

      <div className="footer-bottom">
        <span>&copy; {year} MindRise Wellness Initiative. All rights reserved.</span>
        <div className="footer-bottom-links">
          <a href="mailto:mindriserwanda@gmail.com">mindriserwanda@gmail.com</a>
          <span>Kigali, Rwanda</span>
        </div>
      </div>
    </footer>
  );
}

function FooterNewsletter() {
  const [email, setEmail] = useState('');
  const [website, setWebsite] = useState('');
  const [status, setStatus] = useState({ type: '', message: '' });
  const [loading, setLoading] = useState(false);
  const canSubmit = useMemo(() => /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim()), [email]);

  async function submitNewsletter(event) {
    event.preventDefault();
    if (!canSubmit || loading) return;

    const cleanEmail = email.trim();
    setLoading(true);
    setStatus({ type: '', message: '' });
    try {
      await sendContactMessage({
        name: 'Newsletter subscriber',
        email: cleanEmail,
        organization: 'MindRise website footer',
        topic: 'general',
        message: `Newsletter signup request from ${cleanEmail}. Please add this contact to MindRise Wellness Initiative updates.`,
        website,
      });
      setEmail('');
      setWebsite('');
      setStatus({ type: 'success', message: 'Thank you. MindRise will keep you updated.' });
    } catch (error) {
      setStatus({ type: 'error', message: error.message || 'We could not add this email right now. Please try again.' });
    } finally {
      setLoading(false);
    }
  }

  return (
    <section className="footer-newsletter-card" aria-labelledby="footer-newsletter-title">
      <span>Newsletter</span>
      <h2 id="footer-newsletter-title">Receive MindRise updates.</h2>
      <p>Get thoughtful updates about youth mental health literacy, outreach programs, and community conversations in Rwanda.</p>
      <form className="footer-newsletter-form" onSubmit={submitNewsletter}>
        <label htmlFor="footer-newsletter-email">Email address</label>
        <div className="footer-newsletter-control">
          <Mail size={17} aria-hidden="true" />
          <input
            id="footer-newsletter-email"
            type="email"
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            placeholder="you@example.com"
            autoComplete="email"
            required
          />
          <button type="submit" aria-label="Join MindRise newsletter" disabled={!canSubmit || loading}>
            {loading ? <Loader2 className="spin" size={17} aria-hidden="true" /> : <Send size={17} aria-hidden="true" />}
          </button>
        </div>
        <input
          className="footer-honeypot"
          type="text"
          name="website"
          tabIndex={-1}
          autoComplete="off"
          value={website}
          onChange={(event) => setWebsite(event.target.value)}
          aria-hidden="true"
        />
        <FooterStatus status={status} />
      </form>
    </section>
  );
}

function FooterStatus({ status }) {
  if (!status.message) return null;
  const Icon = status.type === 'success' ? CheckCircle2 : AlertCircle;
  return (
    <p className={`footer-newsletter-status footer-newsletter-status--${status.type}`} role={status.type === 'error' ? 'alert' : 'status'}>
      <Icon size={16} aria-hidden="true" />
      <span>{status.message}</span>
    </p>
  );
}