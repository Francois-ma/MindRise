import { useEffect, useState } from 'react';
import { publicImageDimensions, responsivePublicImage } from './siteConfig';

const defaultIntervalMs = 6000;

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

  const sectionClassName = ['section', 'image-showcase', className].filter(Boolean).join(' ');

  return (
    <section className={sectionClassName} aria-label={title || eyebrow || 'Image showcase'}>
      <div className="image-showcase__stage">
        <figure className="image-showcase__frame">
          <div className="image-showcase__slides">
            {items.map((item, index) => {
              const [imageWidth, imageHeight] = publicImageDimensions[item.src] || [];
              const responsiveImage = responsivePublicImage(item.src);
              const isActive = index === activeIndex;

              return (
                <img
                  className={isActive ? 'is-active' : ''}
                  key={item.src}
                  src={item.src}
                  srcSet={responsiveImage ? `${responsiveImage} 720w, ${item.src} 1440w` : undefined}
                  sizes="(max-width: 760px) calc(100vw - 32px), 1200px"
                  alt={isActive ? item.alt : ''}
                  width={imageWidth}
                  height={imageHeight}
                  loading="lazy"
                  decoding="async"
                  aria-hidden={!isActive}
                />
              );
            })}
          </div>
        </figure>
      </div>
    </section>
  );
}
