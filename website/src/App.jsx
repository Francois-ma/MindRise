import { Navigate, Route, Routes } from 'react-router-dom';
import { About } from './pages/About';
import { Contact } from './pages/Contact';
import { Home } from './pages/Home';
import { Programs } from './pages/Programs';
import { Resources } from './pages/Resources';
import { Start } from './pages/Start';
import { Support } from './pages/Support';

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Home />} />
      <Route path="/about" element={<About />} />
      <Route path="/programs" element={<Programs />} />
      <Route path="/resources" element={<Resources />} />
      <Route path="/support" element={<Support />} />
      <Route path="/start" element={<Start />} />
      <Route path="/contact" element={<Contact />} />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}