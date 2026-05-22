import { useState } from 'react';
import { Link, NavLink } from 'react-router-dom';
import { ArrowRight, Menu, X } from 'lucide-react';
import { logoUrl, navItems } from './siteConfig';

export function Header() {
  const [menuOpen, setMenuOpen] = useState(false);

  return (
    <header className="site-header">
      <Link className="brand" to="/" aria-label="MindRise Wellness Initiative home">
        <img src={logoUrl} alt="MindRise Wellness Initiative logo" />
        <span className="brand-text"><strong>MindRise</strong><small>Wellness Initiative</small></span>
      </Link>
      <nav className="desktop-nav" aria-label="Primary navigation">
        {navItems.map((item) => (
          <NavLink className={({ isActive }) => (isActive ? 'is-active' : undefined)} key={item.key} to={item.href}>{item.label}</NavLink>
        ))}
      </nav>
      <Link className="header-action" to="/start">
        <span>Get involved</span>
        <ArrowRight size={18} aria-hidden="true" />
      </Link>
      <button className="icon-button mobile-menu-button" type="button" aria-label="Open menu" onClick={() => setMenuOpen(true)}>
        <Menu size={22} aria-hidden="true" />
      </button>
      {menuOpen && <MobileMenu onClose={() => setMenuOpen(false)} />}
    </header>
  );
}

function MobileMenu({ onClose }) {
  return (
    <div className="mobile-panel" role="dialog" aria-modal="true" aria-label="Mobile navigation">
      <div className="mobile-panel__top">
        <span>MindRise Wellness Initiative</span>
        <button className="icon-button" type="button" aria-label="Close menu" onClick={onClose}>
          <X size={22} aria-hidden="true" />
        </button>
      </div>
      {navItems.map((item) => (
        <NavLink className={({ isActive }) => (isActive ? 'is-active' : undefined)} key={item.key} to={item.href} onClick={onClose}>{item.label}</NavLink>
      ))}
      <Link className="mobile-panel__cta" to="/start" onClick={onClose}>Get involved</Link>
    </div>
  );
}
