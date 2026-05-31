import { useEffect, useMemo, useState } from 'react';
import { Navigate } from 'react-router-dom';
import {
  Activity,
  BarChart3,
  BookOpen,
  CheckCircle2,
  HeartPulse,
  Home,
  Loader2,
  LogOut,
  MessageCircle,
  RefreshCw,
  ShieldCheck,
  Sparkles,
  UserRound,
  Wind,
} from 'lucide-react';
import {
  createGratitudeEntry,
  createMoodEntry,
  createThoughtReframe,
  fetchCrisisResources,
  fetchLearningContent,
  fetchMoodEntries,
  fetchMoodSummary,
  fetchPersonalizedInsights,
  fetchPractitioners,
  readListPayload,
} from '../api';
import { useAuth } from '../auth';
import { Layout } from '../components/Layout';
import '../styles.css';

const tabs = [
  { key: 'home', label: 'Home', icon: Home },
  { key: 'mood', label: 'Mood', icon: HeartPulse },
  { key: 'insights', label: 'Insights', icon: BarChart3 },
  { key: 'reset', label: 'Reset', icon: Wind },
  { key: 'learn', label: 'Learn', icon: BookOpen },
  { key: 'support', label: 'Support', icon: MessageCircle },
  { key: 'profile', label: 'Profile', icon: UserRound },
];

const moodOptions = ['happy', 'calm', 'neutral', 'sad', 'stressed', 'angry', 'energetic'];

export function AppDashboard() {
  const auth = useAuth();
  const [activeTab, setActiveTab] = useState('home');
  const [dashboard, setDashboard] = useState({ loading: true, error: '', data: null });

  const loadDashboard = useMemo(
    () => async () => {
      if (!auth.accessToken) return;
      setDashboard((current) => ({ ...current, loading: true, error: '' }));
      try {
        const [summary, entries, insights, learning, practitioners, crisis] = await Promise.allSettled([
          fetchMoodSummary(auth.accessToken),
          fetchMoodEntries(auth.accessToken),
          fetchPersonalizedInsights(auth.accessToken),
          fetchLearningContent(auth.accessToken),
          fetchPractitioners(auth.accessToken),
          fetchCrisisResources(),
        ]);

        setDashboard({
          loading: false,
          error: firstRejectedMessage([summary, entries, insights, learning, practitioners, crisis]),
          data: {
            summary: valueOr(summary, emptySummary),
            entries: readListPayload(valueOr(entries, [])),
            insights: valueOr(insights, { cards: [] }),
            learning: valueOr(learning, { categories: [], articles: [], materials: [] }),
            practitioners: readListPayload(valueOr(practitioners, [])),
            crisis: readListPayload(valueOr(crisis, [])),
          },
        });
      } catch (error) {
        setDashboard({ loading: false, error: error.message, data: null });
      }
    },
    [auth.accessToken],
  );

  useEffect(() => {
    loadDashboard();
  }, [loadDashboard]);

  if (auth.loading) {
    return <AppLoadingScreen />;
  }

  if (!auth.isAuthenticated) {
    return <Navigate to="/start" replace />;
  }

  const data = dashboard.data || defaultDashboardData;

  return (
    <Layout active="app">
      <section className="web-app-shell">
        <div className="web-app-topbar">
          <div>
            <p className="eyebrow">MindRise web app</p>
            <h1>Welcome back, {firstName(auth.user?.name)}</h1>
            <p>Use the same private MindRise experience across web and mobile.</p>
          </div>
          <div className="web-app-topbar__actions">
            <button className="button button--secondary" type="button" onClick={loadDashboard} disabled={dashboard.loading}>
              {dashboard.loading ? <Loader2 className="spin" size={17} aria-hidden="true" /> : <RefreshCw size={17} aria-hidden="true" />}
              <span>Refresh</span>
            </button>
            <button className="button button--primary" type="button" onClick={auth.logout}>
              <LogOut size={17} aria-hidden="true" />
              <span>Log out</span>
            </button>
          </div>
        </div>

        {dashboard.error && <div className="web-app-alert"><ShieldCheck size={18} aria-hidden="true" /><span>{dashboard.error}</span></div>}

        <div className="web-app-layout">
          <aside className="web-app-nav" aria-label="MindRise app sections">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              return (
                <button className={activeTab === tab.key ? 'is-active' : ''} type="button" key={tab.key} onClick={() => setActiveTab(tab.key)}>
                  <Icon size={18} aria-hidden="true" />
                  <span>{tab.label}</span>
                </button>
              );
            })}
          </aside>

          <section className="web-app-panel">
            {dashboard.loading ? (
              <DashboardLoading />
            ) : (
              <ActivePanel
                tab={activeTab}
                user={auth.user}
                token={auth.accessToken}
                data={data}
                setTab={setActiveTab}
                onRefresh={loadDashboard}
              />
            )}
          </section>
        </div>
      </section>
    </Layout>
  );
}

function ActivePanel({ tab, user, token, data, setTab, onRefresh }) {
  if (tab === 'mood') return <MoodPanel token={token} entries={data.entries} onRefresh={onRefresh} />;
  if (tab === 'insights') return <InsightsPanel summary={data.summary} insights={data.insights} />;
  if (tab === 'reset') return <ResetPanel token={token} />;
  if (tab === 'learn') return <LearnPanel learning={data.learning} />;
  if (tab === 'support') return <SupportPanel practitioners={data.practitioners} crisis={data.crisis} />;
  if (tab === 'profile') return <ProfilePanel user={user} summary={data.summary} />;
  return <HomePanel user={user} data={data} setTab={setTab} />;
}

function HomePanel({ user, data, setTab }) {
  return (
    <div className="web-app-stack">
      <PanelHeading eyebrow="Today" title={`Good to see you, ${firstName(user?.name)}.`} text="Start with one honest check-in, then use support and learning tools when you need them." />
      <MetricGrid summary={data.summary} />
      <div className="web-care-path">
        <h3>Today's care path</h3>
        <div className="web-care-steps">
          <button type="button" onClick={() => setTab('mood')}><HeartPulse size={18} aria-hidden="true" />Check in honestly</button>
          <button type="button" onClick={() => setTab('insights')}><BarChart3 size={18} aria-hidden="true" />Notice one pattern</button>
          <button type="button" onClick={() => setTab('reset')}><Wind size={18} aria-hidden="true" />Choose one reset</button>
        </div>
      </div>
      <div className="web-app-card web-app-card--accent">
        <Sparkles size={22} aria-hidden="true" />
        <p>Small check-ins create useful patterns. Log the moment while it is fresh.</p>
      </div>
    </div>
  );
}

function MoodPanel({ token, entries, onRefresh }) {
  const [form, setForm] = useState({ mood: 'neutral', score: 5, note: '' });
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');

  async function submitMood(event) {
    event.preventDefault();
    setSaving(true);
    setMessage('');
    try {
      await createMoodEntry(token, form);
      setForm({ mood: 'neutral', score: 5, note: '' });
      setMessage('Mood check-in saved.');
      await onRefresh();
    } catch (error) {
      setMessage(error.message);
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="web-app-stack">
      <PanelHeading eyebrow="Mood" title="Track how you feel." text="This mirrors the mobile mood check-in and stores entries in your MindRise account." />
      <form className="web-app-card web-form" onSubmit={submitMood}>
        <label>
          <span>Mood</span>
          <select value={form.mood} onChange={(event) => setForm((current) => ({ ...current, mood: event.target.value }))}>
            {moodOptions.map((mood) => <option key={mood} value={mood}>{formatLabel(mood)}</option>)}
          </select>
        </label>
        <label>
          <span>Score: {form.score}/10</span>
          <input type="range" min="1" max="10" value={form.score} onChange={(event) => setForm((current) => ({ ...current, score: Number(event.target.value) }))} />
        </label>
        <label>
          <span>Note</span>
          <textarea value={form.note} onChange={(event) => setForm((current) => ({ ...current, note: event.target.value }))} placeholder="What is affecting your mood today?" rows={4} />
        </label>
        <button className="button button--primary" type="submit" disabled={saving}>{saving ? <Loader2 className="spin" size={17} aria-hidden="true" /> : <HeartPulse size={17} aria-hidden="true" />}<span>Save mood</span></button>
        {message && <p className="form-status form-status--success">{message}</p>}
      </form>
      <div className="web-app-card">
        <h3>Recent check-ins</h3>
        <div className="web-list">
          {entries.length ? entries.map((entry) => (
            <div className="web-list-row" key={entry.id}>
              <strong>{formatLabel(entry.mood)}</strong>
              <span>{entry.score}/10</span>
              <p>{entry.note || 'No note added.'}</p>
            </div>
          )) : <p>No mood entries yet.</p>}
        </div>
      </div>
    </div>
  );
}

function InsightsPanel({ summary, insights }) {
  const cards = Array.isArray(insights?.cards) ? insights.cards : [];
  return (
    <div className="web-app-stack">
      <PanelHeading eyebrow="Insights" title="Private patterns from your wellness record." text="The dashboard shows your account-level mood summary and personalized guidance from the backend." />
      <MetricGrid summary={summary} />
      <div className="web-app-card">
        <h3>Personalized insights</h3>
        <div className="web-insight-grid">
          {cards.length ? cards.map((card) => (
            <article className="web-insight-card" key={`${card.title}-${card.action}`}>
              <span>{card.priority || 'medium'}</span>
              <h4>{card.title}</h4>
              <p>{card.message}</p>
              <strong>{card.action}</strong>
            </article>
          )) : <p>Log a few moods to unlock personalized insights.</p>}
        </div>
      </div>
    </div>
  );
}

function ResetPanel({ token }) {
  const [gratitude, setGratitude] = useState('');
  const [negativeThought, setNegativeThought] = useState('');
  const [reframedThought, setReframedThought] = useState('');
  const [message, setMessage] = useState('');

  async function saveGratitude(event) {
    event.preventDefault();
    if (!gratitude.trim()) return;
    try {
      await createGratitudeEntry(token, [gratitude.trim()]);
      setGratitude('');
      setMessage('Gratitude saved.');
    } catch (error) {
      setMessage(error.message);
    }
  }

  async function saveReframe(event) {
    event.preventDefault();
    if (!negativeThought.trim() || !reframedThought.trim()) return;
    try {
      await createThoughtReframe(token, { negativeThought, reframedThought });
      setNegativeThought('');
      setReframedThought('');
      setMessage('Reframe saved.');
    } catch (error) {
      setMessage(error.message);
    }
  }

  return (
    <div className="web-app-stack">
      <PanelHeading eyebrow="Reset" title="Small reset tools for difficult moments." text="Use quick reflection tools that match the mobile reset experience and save to your account where supported." />
      <div className="web-reset-grid">
        <form className="web-app-card web-form" onSubmit={saveGratitude}>
          <h3>Gratitude note</h3>
          <textarea value={gratitude} onChange={(event) => setGratitude(event.target.value)} rows={4} placeholder="Name one thing you are grateful for today." />
          <button className="button button--primary" type="submit">Save gratitude</button>
        </form>
        <form className="web-app-card web-form" onSubmit={saveReframe}>
          <h3>Thought reframe</h3>
          <textarea value={negativeThought} onChange={(event) => setNegativeThought(event.target.value)} rows={3} placeholder="Write the difficult thought." />
          <textarea value={reframedThought} onChange={(event) => setReframedThought(event.target.value)} rows={3} placeholder="Write a balanced reframe." />
          <button className="button button--primary" type="submit">Save reframe</button>
        </form>
      </div>
      <div className="web-app-card web-breathing-card">
        <Wind size={24} aria-hidden="true" />
        <div><h3>One-minute breathing</h3><p>Inhale for four, hold for four, exhale for six. Repeat gently three times.</p></div>
      </div>
      {message && <p className="form-status form-status--success">{message}</p>}
    </div>
  );
}

function LearnPanel({ learning }) {
  return (
    <div className="web-app-stack">
      <PanelHeading eyebrow="Learn" title="Mind Library resources." text="Read articles and materials from the same learning backend used by the public website and mobile app." />
      <div className="web-resource-grid">
        {(learning.articles || []).slice(0, 4).map((article) => (
          <article className="web-app-card" key={article.id || article.title}>
            <p className="eyebrow">{article.category?.name || 'Article'}</p>
            <h3>{article.title}</h3>
            <p>{article.summary || article.body || 'MindRise learning article.'}</p>
          </article>
        ))}
      </div>
      <div className="web-app-card">
        <h3>Uploaded materials</h3>
        <div className="web-list">
          {(learning.materials || []).length ? learning.materials.slice(0, 5).map((material) => (
            <div className="web-list-row" key={material.id || material.title}>
              <strong>{material.title}</strong>
              <span>{formatLabel(material.material_type || 'material')}</span>
              <p>{material.summary || 'Learning material from MindRise.'}</p>
            </div>
          )) : <p>No learning materials published yet.</p>}
        </div>
      </div>
    </div>
  );
}

function SupportPanel({ practitioners, crisis }) {
  const primary = crisis[0];
  return (
    <div className="web-app-stack">
      <PanelHeading eyebrow="Support" title="Support pathways and care resources." text="See practitioner availability and urgent resource information from the MindRise support backend." />
      <div className="web-support-grid">
        <div className="web-app-card web-app-card--urgent">
          <Activity size={24} aria-hidden="true" />
          <h3>{primary?.title || 'Urgent help'}</h3>
          <p>{primary?.description || 'If you are experiencing a mental health crisis, contact local emergency services immediately.'}</p>
          {primary?.phone_number && <a className="button button--primary" href={`tel:${primary.phone_number}`}>{primary.phone_number}</a>}
        </div>
        <div className="web-app-card">
          <h3>Care professionals</h3>
          <div className="web-list">
            {practitioners.length ? practitioners.map((person) => (
              <div className="web-list-row" key={person.id}>
                <strong>{person.display_name}</strong>
                <span>{person.is_available ? 'Available' : 'Schedule'}</span>
                <p>{person.specialization || person.bio || 'MindRise care professional.'}</p>
              </div>
            )) : <p>No practitioners are listed yet.</p>}
          </div>
        </div>
      </div>
    </div>
  );
}

function ProfilePanel({ user, summary }) {
  return (
    <div className="web-app-stack">
      <PanelHeading eyebrow="Profile" title="Your MindRise account." text="This account opens private wellness features on web and can be used for the mobile app too." />
      <div className="web-profile-grid">
        <div className="web-app-card">
          <h3>Account</h3>
          <dl className="web-profile-list">
            <div><dt>Name</dt><dd>{user?.name || user?.first_name || 'MindRise member'}</dd></div>
            <div><dt>Email</dt><dd>{user?.email}</dd></div>
            <div><dt>Role</dt><dd>{formatRole(user?.role)}</dd></div>
            <div><dt>Status</dt><dd>{user?.is_email_verified ? 'Verified' : 'Verification required'}</dd></div>
          </dl>
        </div>
        <div className="web-app-card">
          <h3>Wellness record</h3>
          <MetricGrid summary={summary} compact />
        </div>
      </div>
    </div>
  );
}

function MetricGrid({ summary, compact = false }) {
  const metrics = [
    { label: 'Mood average', value: summary.average_score ? Number(summary.average_score).toFixed(1) : '--' },
    { label: 'Entries', value: summary.total_entries ?? 0 },
    { label: 'Top mood', value: summary.most_frequent_mood ? formatLabel(summary.most_frequent_mood) : '--' },
  ];

  return (
    <div className={`web-metric-grid${compact ? ' web-metric-grid--compact' : ''}`}>
      {metrics.map((metric) => (
        <div className="web-metric" key={metric.label}>
          <strong>{metric.value}</strong>
          <span>{metric.label}</span>
        </div>
      ))}
    </div>
  );
}

function PanelHeading({ eyebrow, title, text }) {
  return (
    <div className="web-panel-heading">
      <p className="eyebrow">{eyebrow}</p>
      <h2>{title}</h2>
      <p>{text}</p>
    </div>
  );
}

function DashboardLoading() {
  return <div className="web-app-card"><Loader2 className="spin" size={22} aria-hidden="true" /><p>Loading your MindRise dashboard...</p></div>;
}

function AppLoadingScreen() {
  return (
    <Layout active="app">
      <section className="section"><DashboardLoading /></section>
    </Layout>
  );
}

function valueOr(result, fallback) {
  return result.status === 'fulfilled' ? result.value : fallback;
}

function firstRejectedMessage(results) {
  const rejected = results.find((result) => result.status === 'rejected');
  return rejected?.reason?.message || '';
}

function firstName(name = '') {
  return name.trim().split(/\s+/)[0] || 'there';
}

function formatLabel(value = '') {
  return value.toString().replaceAll('_', ' ').replace(/\b\w/g, (letter) => letter.toUpperCase());
}

function formatRole(role = '') {
  if (role === 'admin') return 'Administrator';
  if (role === 'practitioner') return 'Practitioner';
  return 'Member';
}

const emptySummary = {
  average_score: 0,
  total_entries: 0,
  most_frequent_mood: null,
  weekly_scores: [],
};

const defaultDashboardData = {
  summary: emptySummary,
  entries: [],
  insights: { cards: [] },
  learning: { categories: [], articles: [], materials: [] },
  practitioners: [],
  crisis: [],
};
