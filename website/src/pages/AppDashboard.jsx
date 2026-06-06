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
  UserCheck,
  UserRound,
  UserX,
  Wind,
} from 'lucide-react';
import {
  approvePractitioner,
  createGratitudeEntry,
  createMoodEntry,
  deactivatePractitioner,
  createThoughtReframe,
  fetchCrisisResources,
  fetchLearningContent,
  fetchMoodEntries,
  fetchMoodSummary,
  fetchPendingPractitioners,
  fetchPersonalizedInsights,
  fetchPractitioners,
  readListPayload,
} from '../api';
import { useAuth } from '../auth';
import { Layout } from '../components/Layout';
import { PractitionerAvailabilityControl, PractitionerConnectionBoard, SupportConversationInbox } from '../components/PractitionerConnections';
import '../styles.css';

const baseTabs = [
  { key: 'home', label: 'Home', icon: Home },
  { key: 'mood', label: 'Mood', icon: HeartPulse },
  { key: 'insights', label: 'Insights', icon: BarChart3 },
  { key: 'reset', label: 'Reset', icon: Wind },
  { key: 'learn', label: 'Learn', icon: BookOpen },
  { key: 'support', label: 'Support', icon: MessageCircle },
  { key: 'profile', label: 'Profile', icon: UserRound },
];

const practitionerTabs = [
  { key: 'practitioner-home', label: 'Workspace', icon: Home },
  { key: 'practitioner-inbox', label: 'Patients', icon: MessageCircle },
  { key: 'learn', label: 'Resources', icon: BookOpen },
  { key: 'profile', label: 'Profile', icon: UserRound },
];

const moodOptions = ['happy', 'calm', 'neutral', 'sad', 'stressed', 'angry', 'energetic'];

export function AppDashboard() {
  const auth = useAuth();
  const isPractitioner = auth.user?.role === 'practitioner';
  const [activeTab, setActiveTab] = useState(() => (isPractitioner ? 'practitioner-home' : 'home'));
  const [dashboard, setDashboard] = useState({ loading: true, error: '', data: null });
  const isAdminUser = Boolean(auth.user?.is_staff || auth.user?.is_superuser || auth.user?.role === 'admin');
  const visibleTabs = useMemo(() => {
    if (isPractitioner) return practitionerTabs;
    return isAdminUser ? [...baseTabs, { key: 'admin-practitioners', label: 'Approvals', icon: UserCheck }] : baseTabs;
  }, [isAdminUser, isPractitioner]);

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

  useEffect(() => {
    if (isPractitioner && !practitionerTabs.some((tab) => tab.key === activeTab)) {
      setActiveTab('practitioner-home');
      return;
    }
    if (!isPractitioner && activeTab.startsWith('practitioner-')) {
      setActiveTab('home');
      return;
    }
    if (!isAdminUser && activeTab === 'admin-practitioners') {
      setActiveTab('home');
    }
  }, [activeTab, isAdminUser, isPractitioner]);

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
            <p className="eyebrow">{isPractitioner ? 'Practitioner workspace' : 'MindRise web app'}</p>
            <h1>{isPractitioner ? `Ready to support, ${firstName(auth.user?.name)}?` : `Welcome back, ${firstName(auth.user?.name)}`}</h1>
            <p>{isPractitioner ? 'Manage your availability and respond to patient conversations.' : 'Use the same private MindRise experience across web and mobile.'}</p>
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
            {visibleTabs.map((tab) => {
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
                isAdminUser={isAdminUser}
              />
            )}
          </section>
        </div>
      </section>
    </Layout>
  );
}

function ActivePanel({ tab, user, token, data, setTab, onRefresh, isAdminUser }) {
  if (tab === 'practitioner-home') return <PractitionerWorkspacePanel token={token} user={user} practitioners={data.practitioners} setTab={setTab} />;
  if (tab === 'practitioner-inbox') return <PractitionerInboxPanel token={token} user={user} />;
  if (tab === 'admin-practitioners') return isAdminUser ? <PendingPractitionersPanel token={token} /> : <HomePanel user={user} data={data} setTab={setTab} />;
  if (tab === 'mood') return <MoodPanel token={token} entries={data.entries} onRefresh={onRefresh} />;
  if (tab === 'insights') return <InsightsPanel summary={data.summary} insights={data.insights} />;
  if (tab === 'reset') return <ResetPanel token={token} />;
  if (tab === 'learn') return <LearnPanel learning={data.learning} />;
  if (tab === 'support') return <SupportPanel token={token} user={user} practitioners={data.practitioners} crisis={data.crisis} />;
  if (tab === 'profile') return <ProfilePanel user={user} summary={data.summary} />;
  return <HomePanel user={user} data={data} setTab={setTab} />;
}

function PractitionerWorkspacePanel({ token, user, practitioners, setTab }) {
  const loadedProfile = practitioners.find((person) => person.is_my_profile) || null;
  const [ownProfile, setOwnProfile] = useState(loadedProfile);

  useEffect(() => {
    setOwnProfile(loadedProfile);
  }, [loadedProfile]);

  const isOnline = Boolean(ownProfile?.is_available);

  return (
    <div className="web-app-stack practitioner-workspace">
      <PanelHeading eyebrow="Practitioner workspace" title={`Good to see you, ${firstName(user?.name)}.`} text="Set your live status, review your support responsibilities, and respond to patients from one focused workspace." />
      <section className="practitioner-workspace__status">
        <div className="practitioner-workspace__identity">
          <span className={isOnline ? 'practitioner-status-dot is-online' : 'practitioner-status-dot'} aria-hidden="true" />
          <div>
            <p className="eyebrow">Live status</p>
            <h3>{isOnline ? 'Available for patient support' : 'Currently offline'}</h3>
            <p>{ownProfile?.specialization || 'Complete your practitioner profile to help patients understand your area of care.'}</p>
          </div>
        </div>
        <PractitionerAvailabilityControl token={token} initialProfile={ownProfile} onUpdated={setOwnProfile} />
      </section>
      <div className="practitioner-workspace__actions">
        <button type="button" onClick={() => setTab('practitioner-inbox')}>
          <MessageCircle size={20} aria-hidden="true" />
          <span><strong>Patient conversations</strong><small>Read and answer private support messages.</small></span>
        </button>
        <button type="button" onClick={() => setTab('learn')}>
          <BookOpen size={20} aria-hidden="true" />
          <span><strong>Care resources</strong><small>Open education and guidance materials.</small></span>
        </button>
        <button type="button" onClick={() => setTab('profile')}>
          <UserRound size={20} aria-hidden="true" />
          <span><strong>Professional profile</strong><small>Review your account and approval status.</small></span>
        </button>
      </div>
      <SupportConversationInbox token={token} role="practitioner" userId={user?.id} />
    </div>
  );
}

function PractitionerInboxPanel({ token, user }) {
  return (
    <div className="web-app-stack practitioner-workspace">
      <PanelHeading eyebrow="Patients" title="Private patient conversations." text="Review active support requests and respond from your practitioner account." />
      <SupportConversationInbox token={token} role="practitioner" userId={user?.id} />
    </div>
  );
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

function SupportPanel({ token, user, practitioners, crisis }) {
  const primary = crisis[0];
  const ownPractitionerProfile = practitioners.find((person) => person.is_my_profile) || null;
  const isPractitioner = user?.role === 'practitioner';
  return (
    <div className="web-app-stack">
      <PanelHeading eyebrow="Support" title={isPractitioner ? 'Manage your patient support.' : 'Connect with an online practitioner.'} text={isPractitioner ? 'Control your availability and answer private patient conversations.' : 'Choose a practitioner who is available now, then continue by text, phone call, or video call where configured.'} />
      <div className="web-support-grid web-support-grid--connect">
        <div className="web-app-card web-app-card--urgent">
          <Activity size={24} aria-hidden="true" />
          <h3>{primary?.title || 'Urgent help'}</h3>
          <p>{primary?.description || 'If you are experiencing a mental health crisis, contact local emergency services immediately.'}</p>
          {primary?.phone_number && <a className="button button--primary" href={`tel:${primary.phone_number}`}>{primary.phone_number}</a>}
        </div>
        <div className="web-app-card web-app-card--support-connect">
          <h3>{isPractitioner ? 'Your support availability' : 'Online practitioners'}</h3>
          {isPractitioner ? (
            <PractitionerAvailabilityControl token={token} initialProfile={ownPractitionerProfile} />
          ) : (
            <PractitionerConnectionBoard token={token} practitioners={practitioners} compact />
          )}
        </div>
      </div>
      <SupportConversationInbox token={token} role={user?.role} userId={user?.id} />
    </div>
  );
}

function PendingPractitionersPanel({ token }) {
  const [pending, setPending] = useState({ loading: true, error: '', items: [] });
  const [actionStatus, setActionStatus] = useState({ type: '', message: '' });
  const [busyId, setBusyId] = useState(null);

  const loadPending = useMemo(
    () => async () => {
      setPending((current) => ({ ...current, loading: true, error: '' }));
      try {
        const data = await fetchPendingPractitioners(token);
        setPending({ loading: false, error: '', items: readListPayload(data) });
      } catch (error) {
        setPending({ loading: false, error: error.message, items: [] });
      }
    },
    [token],
  );

  useEffect(() => {
    loadPending();
  }, [loadPending]);

  async function approve(id) {
    setBusyId(id);
    setActionStatus({ type: '', message: '' });
    try {
      await approvePractitioner(token, id);
      setActionStatus({ type: 'success', message: 'Practitioner approved.' });
      await loadPending();
    } catch (error) {
      setActionStatus({ type: 'error', message: error.message });
    } finally {
      setBusyId(null);
    }
  }

  async function deactivate(id) {
    setBusyId(id);
    setActionStatus({ type: '', message: '' });
    try {
      await deactivatePractitioner(token, id);
      setActionStatus({ type: 'success', message: 'Practitioner account deactivated.' });
      await loadPending();
    } catch (error) {
      setActionStatus({ type: 'error', message: error.message });
    } finally {
      setBusyId(null);
    }
  }

  return (
    <div className="web-app-stack">
      <PanelHeading eyebrow="Admin" title="Pending practitioner approvals." text="Only admin and superuser accounts can approve practitioner access." />
      {actionStatus.message && <p className={`form-status form-status--${actionStatus.type}`}>{actionStatus.message}</p>}
      <div className="web-app-card admin-approval-panel">
        <div className="admin-approval-panel__heading">
          <div>
            <h3>Practitioner accounts</h3>
            <p>{pending.loading ? 'Loading pending accounts.' : `${pending.items.length} pending account${pending.items.length === 1 ? '' : 's'}`}</p>
          </div>
          <button className="button button--secondary" type="button" onClick={loadPending} disabled={pending.loading}>
            {pending.loading ? <Loader2 className="spin" size={17} aria-hidden="true" /> : <RefreshCw size={17} aria-hidden="true" />}
            <span>Refresh</span>
          </button>
        </div>

        {pending.error && <div className="web-app-alert"><ShieldCheck size={18} aria-hidden="true" /><span>{pending.error}</span></div>}

        <div className="admin-approval-list">
          {pending.items.length ? pending.items.map((person) => (
            <article className="admin-approval-card" key={person.id}>
              <div>
                <strong>{person.name || person.email}</strong>
                <span>{person.email}</span>
              </div>
              <dl>
                <div><dt>Phone</dt><dd>{person.phone_number || 'Not provided'}</dd></div>
                <div><dt>Specialization</dt><dd>{person.specialization || 'Not provided'}</dd></div>
                <div><dt>Created</dt><dd>{formatDate(person.created_at)}</dd></div>
              </dl>
              <div className="admin-approval-actions">
                <button className="button button--primary" type="button" onClick={() => approve(person.id)} disabled={busyId === person.id}>
                  {busyId === person.id ? <Loader2 className="spin" size={17} aria-hidden="true" /> : <UserCheck size={17} aria-hidden="true" />}
                  <span>Approve</span>
                </button>
                <button className="button button--secondary" type="button" onClick={() => deactivate(person.id)} disabled={busyId === person.id}>
                  <UserX size={17} aria-hidden="true" />
                  <span>Deactivate</span>
                </button>
              </div>
            </article>
          )) : <p>{pending.loading ? 'Loading pending practitioners...' : 'No pending practitioner accounts.'}</p>}
        </div>
      </div>
    </div>
  );
}

function ProfilePanel({ user, summary }) {
  const isPractitioner = user?.role === 'practitioner';
  return (
    <div className="web-app-stack">
      <PanelHeading eyebrow="Profile" title={isPractitioner ? 'Your practitioner account.' : 'Your MindRise account.'} text={isPractitioner ? 'Review your professional access and verified MindRise account status.' : 'This account opens private wellness features on web and can be used for the mobile app too.'} />
      <div className="web-profile-grid">
        <div className="web-app-card">
          <h3>Account</h3>
          <dl className="web-profile-list">
            <div><dt>Name</dt><dd>{user?.name || user?.first_name || 'MindRise member'}</dd></div>
            <div><dt>Email</dt><dd>{user?.email}</dd></div>
            <div><dt>Role</dt><dd>{formatRole(user?.role)}</dd></div>
            <div><dt>Status</dt><dd>{user?.is_email_verified ? 'Verified' : 'Verification required'}</dd></div>
            <div><dt>Approval</dt><dd>{isPractitioner ? (user?.is_approved ? 'Approved' : 'Pending') : 'Not required'}</dd></div>
          </dl>
        </div>
        {isPractitioner ? (
          <div className="web-app-card practitioner-profile-guidance">
            <ShieldCheck size={24} aria-hidden="true" />
            <h3>Professional access</h3>
            <p>Your practitioner workspace is reserved for approved accounts. Keep patient conversations private and mark yourself online only while ready to respond.</p>
          </div>
        ) : (
          <div className="web-app-card">
            <h3>Wellness record</h3>
            <MetricGrid summary={summary} compact />
          </div>
        )}
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

function formatDate(value) {
  if (!value) return '--';
  return new Intl.DateTimeFormat(undefined, { month: 'short', day: 'numeric', year: 'numeric' }).format(new Date(value));
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
