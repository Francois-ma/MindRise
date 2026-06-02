import { Footer } from './Footer';
import { Header } from './Header';
import { logoUrl } from './siteConfig';

export function Layout({ active, children }) {
  const shellClassName = ['site-shell', active ? `site-shell--${active}` : ''].filter(Boolean).join(' ');
  const mainClassName = ['site-main', active ? `site-main--${active}` : ''].filter(Boolean).join(' ');

  return (
    <div className={shellClassName}>
      <Header active={active} />
      <main className={mainClassName}>{children}</main>
      <Footer />
    </div>
  );
}

export function PageHero({ eyebrow, title, lead, children, compact = false, className = '', image = '', imageAlt = '', focal = 'center' }) {
  const heroClassName = ['page-hero', image ? 'page-hero--with-image' : '', compact ? 'page-hero--compact' : '', className].filter(Boolean).join(' ');
  const heroStyle = image ? { '--hero-focal': focal } : undefined;

  return (
    <section className={heroClassName} style={heroStyle}>
      <div className="page-hero__content">
        <p className="eyebrow">{eyebrow}</p>
        <h1>{title}</h1>
        <p>{lead}</p>
        {children}
      </div>
      {image && (
        <figure className="page-hero__media">
          <img src={image} alt={imageAlt || `${title} visual`} loading={compact ? 'lazy' : 'eager'} decoding="async" fetchPriority={compact ? 'auto' : 'high'} />
        </figure>
      )}
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