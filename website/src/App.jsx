import { useEffect } from 'react';
import { Navigate, Route, Routes, useLocation } from 'react-router-dom';
import { About } from './pages/About';
import { AppDashboard } from './pages/AppDashboard';
import { Contact } from './pages/Contact';
import { Home } from './pages/Home';
import { Programs } from './pages/Programs';
import { Resources } from './pages/Resources';
import { Start } from './pages/Start';
import { Support } from './pages/Support';

function ScrollToTop() {
  const { hash, pathname, search } = useLocation();

  useEffect(() => {
    if (hash) {
      const target = document.querySelector(hash);
      if (target) {
        target.scrollIntoView({ block: 'start' });
        return;
      }
    }

    window.scrollTo({ top: 0, left: 0, behavior: 'auto' });
  }, [hash, pathname, search]);

  return null;
}

export default function App() {
  return (
    <>
      <ScrollToTop />
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/about" element={<About />} />
        <Route path="/programs" element={<Programs />} />
        <Route path="/resources" element={<Resources />} />
        <Route path="/support" element={<Support />} />
        <Route path="/start" element={<Start />} />
        <Route path="/app" element={<AppDashboard />} />
        <Route path="/contact" element={<Contact />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </>
  );
}