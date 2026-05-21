import { useState } from 'react';
import { ArrowRight, Menu, X } from 'lucide-react';
import { logoUrl, navItems } from './siteConfig';

export function Header({ active }) {
  const [menuOpen, setMenuOpen] = useState(false);

  return (
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
      {menuOpen && <MobileMenu active={active} onClose={() => setMenuOpen(false)} />}
    </header>
  );
}

function MobileMenu({ active, onClose }) {
  return (
    <div className="mobile-panel" role="dialog" aria-modal="true" aria-label="Mobile navigation">
      <div className="mobile-panel__top">
        <span>MindRise Wellness Initiative</span>
        <button className="icon-button" type="button" aria-label="Close menu" onClick={onClose}>
          <X size={22} aria-hidden="true" />
        </button>
      </div>
      {navItems.map((item) => (
        <a className={active === item.key ? 'is-active' : ''} key={item.key} href={item.href}>{item.label}</a>
      ))}
      <a className="mobile-panel__cta" href="/start.html">Rise Above, Speak Out</a>
    </div>
  );
}