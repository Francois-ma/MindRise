import { useEffect, useState } from 'react';

const defaultIntervalMs = 4200;

export function ImageShowcase({ eyebrow, title, items = [], className = '', intervalMs = defaultIntervalMs }) {
  const [activeIndex, setActiveIndex] = useState(0);
  const itemCount = items.length;

  useEffect(() => {
    if (itemCount < 2) return undefined;

    const timer = window.setInterval(() => {
      setActiveIndex((current) => (current + 1) % itemCount);
    }, intervalMs);

    return () => window.clearInterval(timer);
  }, [intervalMs, itemCount]);

  if (!itemCount) return null;

  const activeItem = items[activeIndex] || items[0];
  const sectionClassName = ['section', 'image-showcase', className].filter(Boolean).join(' ');

  return (
    <section className={sectionClassName} aria-label={title || eyebrow || 'Image showcase'}>
      {eyebrow && (
        <div className="image-showcase__header">
          <p className="eyebrow">{eyebrow}</p>
        </div>
      )}

      <div className="image-showcase__stage">
        <figure className="image-showcase__frame">
          <img key={activeItem.src} src={activeItem.src} alt={activeItem.alt} />
          {itemCount > 1 && (
            <div className="image-showcase__progress" aria-hidden="true">
              <span key={activeItem.src} style={{ '--showcase-duration': `${intervalMs}ms` }} />
            </div>
          )}
        </figure>
      </div>
    </section>
  );
}