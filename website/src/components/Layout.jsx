import { Footer } from './Footer';
import { Header } from './Header';
import { logoUrl } from './siteConfig';

export function Layout({ active, children }) {
  return (
    <div className="site-shell">
      <Header active={active} />
      <main>{children}</main>
      <Footer />
    </div>
  );
}

export function PageHero({ eyebrow, title, lead, children, compact = false, className = '' }) {
  const heroClassName = ['page-hero', compact ? 'page-hero--compact' : '', className].filter(Boolean).join(' ');

  return (
    <section className={heroClassName}>
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

export { logoUrl };