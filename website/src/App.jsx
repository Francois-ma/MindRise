import { lazy, Suspense, useEffect } from 'react';
import { Navigate, Route, Routes, useLocation } from 'react-router-dom';

const About = lazyNamed(() => import('./pages/About'), 'About');
const AppDashboard = lazyNamed(() => import('./pages/AppDashboard'), 'AppDashboard');
const ChatbotWidget = lazyNamed(() => import('./components/ChatbotWidget'), 'ChatbotWidget');
const Contact = lazyNamed(() => import('./pages/Contact'), 'Contact');
const Home = lazyNamed(() => import('./pages/Home'), 'Home');
const PractitionerDashboardPage = lazyNamed(() => import('./pages/SupportWorkspace'), 'PractitionerDashboardPage');
const Programs = lazyNamed(() => import('./pages/Programs'), 'Programs');
const Resources = lazyNamed(() => import('./pages/Resources'), 'Resources');
const Start = lazyNamed(() => import('./pages/Start'), 'Start');
const Support = lazyNamed(() => import('./pages/Support'), 'Support');
const SupportChatPage = lazyNamed(() => import('./pages/SupportWorkspace'), 'SupportChatPage');
const SupportRequestPage = lazyNamed(() => import('./pages/SupportWorkspace'), 'SupportRequestPage');

function lazyNamed(loader, name) {
  return lazy(() => loader().then((module) => ({ default: module[name] })));
}

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
      <Suspense fallback={<RouteLoading />}>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/about" element={<About />} />
          <Route path="/programs" element={<Programs />} />
          <Route path="/resources" element={<Resources />} />
          <Route path="/support" element={<Support />} />
          <Route path="/support/request" element={<SupportRequestPage />} />
          <Route path="/support/chat/:sessionId" element={<SupportChatPage />} />
          <Route path="/practitioner/dashboard" element={<PractitionerDashboardPage />} />
          <Route path="/practitioner/pending-requests" element={<PractitionerDashboardPage pendingOnly />} />
          <Route path="/practitioner/chat/:sessionId" element={<SupportChatPage practitionerRoute />} />
          <Route path="/start" element={<Start />} />
          <Route path="/app" element={<AppDashboard />} />
          <Route path="/contact" element={<Contact />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </Suspense>
      <Suspense fallback={null}>
        <ChatbotWidget />
      </Suspense>
    </>
  );
}

function RouteLoading() {
  return <div className="route-loading" role="status" aria-live="polite">Loading MindRise...</div>;
}
