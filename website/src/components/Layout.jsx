import { useState } from 'react';
import { ArrowRight, Menu, X } from 'lucide-react';

const logoUrl = '/mindrise_icon.jpeg';

const navItems = [
  { href: '/index.html', label: 'Home', key: 'home' },
  { href: '/about.html', label: 'About', key: 'about' },
  { href: '/programs.html', label: 'Programs', key: 'programs' },
  { href: '/resources.html', label: 'Resources', key: 'resources' },
  { href: '/support.html', label: 'Support', key: 'support' },
  { href: '/contact.html', label: 'Contact', key: 'contact' },
];

export function Layout({ active, children }) {
  const [menuOpen, setMenuOpen] = useState(false);

  return (
    <div className="site-shell">
      <header className="site-header">
        <a className="brand" href="/index.html" aria-label="MindRise Wellness Initiative home">
          <img src={logoUrl} alt="MindRise Wellness Initiative logo" />
          <span>MindRise</span>
        </a>
        <nav className="desktop-nav" aria-label="Primary navigation">
          {navItems.map((item) => (
            <a className={active === item.key ? 'is-active' : ''} key={item.key} href={item.href}>{item.label}</a>
          ))}
        </nav>
        <a className="header-action" href="/start.html">
          <span>Rise Above</span>
          <ArrowRight size={18} aria-hidden="true" />
        </a>
        <button className="icon-button mobile-menu-button" type="button" aria-label="Open menu" onClick={() => setMenuOpen(true)}>
          <Menu size={22} aria-hidden="true" />
        </button>
        {menuOpen && (
          <div className="mobile-panel" role="dialog" aria-modal="true" aria-label="Mobile navigation">
            <div className="mobile-panel__top">
              <span>MindRise Wellness Initiative</span>
              <button className="icon-button" type="button" aria-label="Close menu" onClick={() => setMenuOpen(false)}>
                <X size={22} aria-hidden="true" />
              </button>
            </div>
            {navItems.map((item) => (
              <a className={active === item.key ? 'is-active' : ''} key={item.key} href={item.href}>{item.label}</a>
            ))}
            <a className="mobile-panel__cta" href="/start.html">Rise Above, Speak Out</a>
          </div>
        )}
      </header>
      <main>{children}</main>
      <Footer />
    </div>
  );
}

export function PageHero({ eyebrow, title, lead, children, compact = false }) {
  return (
    <section className={compact ? 'page-hero page-hero--compact' : 'page-hero'}>
      <div className="page-hero__content">
        <p className="eyebrow">{eyebrow}</p>
        <h1>{title}</h1>
        <p>{lead}</p>
        {children}
      </div>
    </section>
  );
}

export function SectionIntro({ eyebrow, title, lead }) {
  return (
    <div className="section-intro">
      <p className="eyebrow">{eyebrow}</p>
      <h2>{title}</h2>
      {lead && <p>{lead}</p>}
    </div>
  );
}

export function Footer() {
  return (
    <footer className="site-footer">
      <div className="footer-brand">
        <img src={logoUrl} alt="" />
        <span>MindRise Wellness Initiative</span>
      </div>
      <p>Rise Above, Speak Out. Youth-driven mental health awareness, education, and community support in Rwanda.</p>
      <nav aria-label="Footer navigation">
        <a href="/about.html">About</a>
        <a href="/programs.html">Programs</a>
        <a href="/contact.html">Contact</a>
      </nav>
    </footer>
  );
}

export { logoUrl };