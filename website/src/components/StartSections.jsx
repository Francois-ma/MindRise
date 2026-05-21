import { PageHero, SectionIntro } from './Layout';
import { SignupPanel } from './SignupPanel';

export function StartHero() {
  return (
    <PageHero
      compact
      eyebrow="Digital platform"
      title="Access MindRise digital wellness tools."
      lead="The MindRise platform supports private check-ins, learning, and youth-friendly mental wellness guidance as part of our broader community initiative."
    />
  );
}

export function StartAccountSection() {
  return (
    <section className="section section--start-page">
      <SectionIntro
        eyebrow="Secure onboarding"
        title="Create a verified account for the MindRise mobile experience."
        lead="Registration connects to the existing Django backend and sends a verification code before sign-in. Browser-based signup also requires the website origin to be allowed in Render CORS settings."
      />
      <SignupPanel />
    </section>
  );
}