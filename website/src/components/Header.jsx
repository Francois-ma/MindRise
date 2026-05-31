import { useEffect, useState } from 'react';
import { createPortal } from 'react-dom';
import { Link, NavLink, useLocation } from 'react-router-dom';
import { ArrowRight, LayoutDashboard, Menu, X } from 'lucide-react';
import { useAuth } from '../auth';
import { logoMarkUrl, navItems } from './siteConfig';

export function Header() {
  const [menuOpen, setMenuOpen] = useState(false);
  const location = useLocation();
  const auth = useAuth();

  useEffect(() => {
    setMenuOpen(false);
  }, [location.pathname]);

  useEffect(() => {
    const desktopQuery = window.matchMedia('(min-width: 1121px)');

    function closeOnDesktop() {
      if (desktopQuery.matches) {
        setMenuOpen(false);
      }
    }

    closeOnDesktop();
    desktopQuery.addEventListener('change', closeOnDesktop);

    return () => {
      desktopQuery.removeEventListener('change', closeOnDesktop);
    };
  }, []);

  useEffect(() => {
    if (!menuOpen) return undefined;

    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';

    function handleKeyDown(event) {
      if (event.key === 'Escape') {
        setMenuOpen(false);
      }
    }

    window.addEventListener('keydown', handleKeyDown);

    return () => {
      document.body.style.overflow = previousOverflow;
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [menuOpen]);

  function closeMenu() {
    setMenuOpen(false);
  }

  const actionTarget = auth.isAuthenticated ? '/app' : '/start';
  const actionLabel = auth.isAuthenticated ? 'Open app' : 'Get involved';
  const ActionIcon = auth.isAuthenticated ? LayoutDashboard : ArrowRight;

  return (
    <header className="site-header">
      <Link className="brand" to="/" aria-label="MindRise Wellness Initiative home" onClick={closeMenu}>
        <img src={logoMarkUrl} alt="MindRise Wellness Initiative logo" />
        <span className="brand-text"><strong>MindRise</strong><small>Wellness Initiative</small></span>
      </Link>
      <nav className="desktop-nav" aria-label="Primary navigation">
        {navItems.map((item) => (
          <NavLink className={({ isActive }) => (isActive ? 'is-active' : undefined)} key={item.key} to={item.href}>{item.label}</NavLink>
        ))}
        {auth.isAuthenticated && <NavLink className={({ isActive }) => (isActive ? 'is-active' : undefined)} to="/app">App</NavLink>}
      </nav>
      <Link className="header-action" to={actionTarget}>
        <span>{actionLabel}</span>
        <ActionIcon size={18} aria-hidden="true" />
      </Link>
      <button
        className="icon-button mobile-menu-button"
        type="button"
        aria-label={menuOpen ? 'Close menu' : 'Open menu'}
        aria-controls="mobile-navigation"
        aria-expanded={menuOpen}
        onClick={() => setMenuOpen((open) => !open)}
      >
        {menuOpen ? <X size={22} aria-hidden="true" /> : <Menu size={22} aria-hidden="true" />}
      </button>
      {menuOpen && <MobileMenu onClose={closeMenu} isAuthenticated={auth.isAuthenticated} />}
    </header>
  );
}

function MobileMenu({ onClose, isAuthenticated }) {
  if (typeof document === 'undefined') return null;

  return createPortal(
    <div className="mobile-drawer" role="presentation">
      <button className="mobile-panel__backdrop" type="button" aria-label="Close menu" onClick={onClose} />
      <nav id="mobile-navigation" className="mobile-panel" aria-label="Mobile navigation">
        <div className="mobile-panel__top">
          <span>MindRise Wellness Initiative</span>
          <button className="icon-button" type="button" aria-label="Close menu" onClick={onClose}>
            <X size={22} aria-hidden="true" />
          </button>
        </div>
        <div className="mobile-panel__links">
          {navItems.map((item) => (
            <NavLink className={({ isActive }) => (isActive ? 'is-active' : undefined)} key={item.key} to={item.href} onClick={onClose}>{item.label}</NavLink>
          ))}
          {isAuthenticated && <NavLink className={({ isActive }) => (isActive ? 'is-active' : undefined)} to="/app" onClick={onClose}>App</NavLink>}
          <NavLink className={({ isActive }) => `mobile-panel__cta${isActive ? ' is-active' : ''}`} to={isAuthenticated ? '/app' : '/start'} onClick={onClose}>{isAuthenticated ? 'Open app' : 'Get involved'}</NavLink>
        </div>
      </nav>
    </div>,
    document.body,
  );
}