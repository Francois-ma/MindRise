import { Link } from 'react-router-dom';
import { ExternalLink, Mail, MapPin } from 'lucide-react';
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

        <div className="footer-column footer-contact">
          <span>Connect</span>
          <a href="mailto:hello@mindrise.health"><Mail size={16} aria-hidden="true" /> hello@mindrise.health</a>
          <p><MapPin size={16} aria-hidden="true" /> Rwanda, youth and underserved communities</p>
        </div>
      </div>

      <div className="footer-bottom">
        <span>&copy; {year} MindRise Wellness Initiative. All rights reserved.</span>
        <span>Rise Above, Speak Out.</span>
      </div>
    </footer>
  );
}
