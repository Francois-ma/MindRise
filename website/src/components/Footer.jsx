import { ExternalLink, Mail, MapPin } from 'lucide-react';
import { API_BASE_URL } from '../api';
import { logoUrl } from './siteConfig';

export function Footer() {
  const year = new Date().getFullYear();

  return (
    <footer className="site-footer">
      <div className="footer-main">
        <div className="footer-brand-block">
          <div className="footer-brand">
            <img src={logoUrl} alt="" />
            <span>MindRise Wellness Initiative</span>
          </div>
          <p>MindRise is a youth-driven mental health organization promoting emotional well-being, psychological resilience, and mental health literacy in Rwanda.</p>
          <strong>Rise Above, Speak Out.</strong>
        </div>

        <nav className="footer-column" aria-label="Organization links">
          <span>Organization</span>
          <a href="/about.html">About MindRise</a>
          <a href="/programs.html">Programs</a>
          <a href="/resources.html">Resources</a>
          <a href="/support.html">Support</a>
        </nav>

        <nav className="footer-column" aria-label="Program links">
          <span>Focus Areas</span>
          <a href="/programs.html">School outreach</a>
          <a href="/programs.html">Awareness campaigns</a>
          <a href="/programs.html">Community engagement</a>
          <a href="/programs.html">Media education</a>
        </nav>

        <div className="footer-column footer-contact">
          <span>Connect</span>
          <a href="mailto:hello@mindrise.health"><Mail size={16} aria-hidden="true" /> hello@mindrise.health</a>
          <p><MapPin size={16} aria-hidden="true" /> Rwanda, youth and underserved communities</p>
          <a href="https://mind-rise-coral.vercel.app" target="_blank" rel="noreferrer"><ExternalLink size={16} aria-hidden="true" /> mind-rise-coral.vercel.app</a>
        </div>
      </div>

      <div className="footer-bottom">
        <span>© {year} MindRise Wellness Initiative. All rights reserved.</span>
        <span>Backend connected to {API_BASE_URL}</span>
      </div>
    </footer>
  );
}