export const logoMarkUrl = '/mindrise_icon.jpeg';
export const logoFullUrl = '/mindrise_logo_full.jpeg';
export const logoUrl = logoMarkUrl;

export const publicImageDimensions = {
  '/1.webp': [1440, 960],
  '/2.webp': [1440, 960],
  '/3.webp': [1440, 960],
  '/4.webp': [1440, 960],
  '/5.webp': [1440, 960],
  '/6.webp': [1440, 960],
  '/7%20%281%29.webp': [1440, 960],
  '/7%20%282%29.webp': [1440, 960],
  '/8.webp': [1440, 960],
  '/9.webp': [1440, 960],
  '/10.webp': [1440, 960],
};

export function responsivePublicImage(image) {
  return image?.endsWith('.webp') ? image.replace(/\.webp$/, '-sm.webp') : '';
}

export const navItems = [
  { href: '/', label: 'Home', key: 'home' },
  { href: '/about', label: 'About', key: 'about' },
  { href: '/programs', label: 'Programs', key: 'programs' },
  { href: '/resources', label: 'Resources', key: 'resources' },
  { href: '/support', label: 'Support', key: 'support' },
  { href: '/contact', label: 'Contact', key: 'contact' },
];
