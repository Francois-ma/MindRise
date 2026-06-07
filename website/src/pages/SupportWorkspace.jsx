import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Link, Navigate, useNavigate, useParams } from 'react-router-dom';
import {
  Bell,
  Check,
  Clock3,
  Headphones,
  Loader2,
  MessageCircle,
  Phone,
  RefreshCw,
  Send,
  ShieldAlert,
  UserRound,
  Video,
  Wifi,
  WifiOff,
  X,
} from 'lucide-react';
import {
  acceptSupportSession,
  createSupportThread,
  fetchOnlinePractitioners,
  fetchPractitioners,
  fetchSupportCalls,
  fetchSupportMessages,
  fetchSupportNotifications,
  fetchSupportSession,
  fetchSupportThreads,
  readListPayload,
  rejectSupportSession,
  sendSupportMessage,
  startSupportCall,
  updatePractitionerAvailability,
  updatePractitionerContact,
  updateSupportCall,
} from '../api';
import { useAuth } from '../auth';
import { Layout } from '../components/Layout';
import '../styles.css';

export const supportDisclaimer = 'MindRise support is not an emergency service. If you are in immediate danger, thinking about harming yourself, or someone else may be harmed, please contact emergency services or go to the nearest hospital immediately.';

export function SupportRequestPage() {
  const auth = useAuth();
  const navigate = useNavigate();
  const [state, setState] = useState({ loading: true, error: '', items: [] });
  const [busyId, setBusyId] = useState(null);

  const load = useCallback(async () => {
    if (!auth.accessToken) return;
    setState((current) => ({ ...current, loading: true, error: '' }));
    try {
      const data = await fetchOnlinePractitioners(auth.accessToken);
      setState({ loading: false, error: '', items: readListPayload(data) });
    } catch (error) {
      setState({ loading: false, error: error.message, items: [] });
    }
  }, [auth.accessToken]);

  useEffect(() => { void load(); }, [load]);

  async function requestSupport(practitioner) {
    setBusyId(practitioner.id);
    try {
      const session = await createSupportThread(auth.accessToken, {
        practitionerId: practitioner.id,
        contactMethod: 'text',
        subject: `Support with ${practitioner.display_name}`,
      });
      navigate(`/support/chat/${session.id}`);
    } catch (error) {
      setState((current) => ({ ...current, error: error.message }));
    } finally {
      setBusyId(null);
    }
  }

  const guard = roleGuard(auth, 'patient');
  if (guard) return guard;

  return (
    <Layout active="support">
      <SupportWorkspaceShell eyebrow="Request support" title="Choose an approved practitioner who is online." subtitle="Your request stays private between you and the practitioner assigned to the session.">
        <EmergencyDisclaimer />
        <WorkspaceToolbar label={`${state.items.length} online practitioner${state.items.length === 1 ? '' : 's'}`} loading={state.loading} onRefresh={load} />
        {state.error && <StatusMessage type="error">{state.error}</StatusMessage>}
        <div className="support-request-grid">
          {state.loading ? <WorkspaceLoading /> : state.items.length ? state.items.map((person) => (
            <article className="support-request-practitioner" key={person.id}>
              <div className="support-request-practitioner__identity">
                <span className="support-request-avatar">{person.profile_picture_url ? <img src={person.profile_picture_url} alt="" /> : <UserRound size={22} />}</span>
                <div><h2>{person.display_name}</h2><p>{person.specialization || 'MindRise practitioner'}</p></div>
                <span className="support-presence support-presence--online"><Wifi size={14} />Online</span>
              </div>
              {person.bio && <p>{person.bio}</p>}
              <div className="support-request-practitioner__actions">
                <button className="button button--primary" type="button" disabled={busyId === person.id} onClick={() => requestSupport(person)}>
                  {busyId === person.id ? <Loader2 className="spin" size={17} /> : <MessageCircle size={17} />}
                  <span>Request private support</span>
                </button>
                {person.can_call && <a className="button button--secondary" href={`tel:${person.phone_number}`}><Phone size={17} />Call</a>}
                {person.can_whatsapp && <a className="button button--secondary" href={person.whatsapp_url} target="_blank" rel="noreferrer"><MessageCircle size={17} />WhatsApp</a>}
              </div>
            </article>
          )) : <WorkspaceEmpty icon={Clock3} title="No approved practitioner is online" text="Refresh later or use emergency services if the situation cannot wait." />}
        </div>
      </SupportWorkspaceShell>
    </Layout>
  );
}

export function PractitionerDashboardPage({ pendingOnly = false }) {
  const auth = useAuth();
  const [state, setState] = useState({ loading: true, error: '', sessions: [], profile: null, notifications: [] });
  const [savingStatus, setSavingStatus] = useState('');
  const [savingContact, setSavingContact] = useState(false);
  const [busySession, setBusySession] = useState(null);

  const load = useCallback(async () => {
    if (!auth.accessToken) return;
    setState((current) => ({ ...current, loading: true, error: '' }));
    try {
      const [sessionData, practitionerData, notificationData] = await Promise.all([
        fetchSupportThreads(auth.accessToken, pendingOnly ? 'status=pending' : ''),
        fetchPractitioners(auth.accessToken),
        fetchSupportNotifications(auth.accessToken),
      ]);
      const sessions = readListPayload(sessionData).filter((item) => item.thread_type === 'practitioner');
      setState({
        loading: false,
        error: '',
        sessions,
        profile: readListPayload(practitionerData).find((item) => item.is_my_profile) || null,
        notifications: readListPayload(notificationData),
      });
    } catch (error) {
      setState((current) => ({ ...current, loading: false, error: error.message }));
    }
  }, [auth.accessToken, pendingOnly]);

  useEffect(() => { void load(); }, [load]);
  usePolling(load, 20000, Boolean(auth.accessToken));

  async function setStatus(status) {
    setSavingStatus(status);
    try {
      const profile = await updatePractitionerAvailability(auth.accessToken, { status });
      setState((current) => ({ ...current, profile }));
    } catch (error) {
      setState((current) => ({ ...current, error: error.message }));
    } finally {
      setSavingStatus('');
    }
  }

  async function saveContact(phoneNumber) {
    setSavingContact(true);
    try {
      const profile = await updatePractitionerContact(auth.accessToken, { phoneNumber });
      setState((current) => ({ ...current, profile, error: '' }));
    } catch (error) {
      setState((current) => ({ ...current, error: error.message }));
    } finally {
      setSavingContact(false);
    }
  }

  async function decide(sessionId, action) {
    setBusySession(sessionId);
    try {
      if (action === 'accept') await acceptSupportSession(auth.accessToken, sessionId);
      else await rejectSupportSession(auth.accessToken, sessionId);
      await load();
    } catch (error) {
      setState((current) => ({ ...current, error: error.message }));
    } finally {
      setBusySession(null);
    }
  }

  const guard = roleGuard(auth, 'practitioner');
  if (guard) return guard;
  const pendingCount = state.sessions.filter((item) => item.status === 'pending').length;

  return (
    <Layout active="app">
      <SupportWorkspaceShell eyebrow="Practitioner workspace" title={pendingOnly ? 'Pending support requests' : `Welcome, ${auth.user?.name || 'Practitioner'}.`} subtitle="Manage your presence, accept assigned requests, and continue private patient sessions.">
        <EmergencyDisclaimer />
        {!pendingOnly && <><PractitionerPresence profile={state.profile} saving={savingStatus} onChange={setStatus} /><PractitionerContactSettings profile={state.profile} saving={savingContact} onSave={saveContact} /></>}
        <nav className="support-workspace-tabs" aria-label="Practitioner support views">
          <Link className={!pendingOnly ? 'is-active' : ''} to="/practitioner/dashboard">Dashboard</Link>
          <Link className={pendingOnly ? 'is-active' : ''} to="/practitioner/pending-requests">Pending requests <span>{pendingCount}</span></Link>
        </nav>
        <WorkspaceToolbar label={`${state.sessions.length} ${pendingOnly ? 'pending request' : 'support session'}${state.sessions.length === 1 ? '' : 's'}`} loading={state.loading} onRefresh={load} />
        {state.error && <StatusMessage type="error">{state.error}</StatusMessage>}
        {!pendingOnly && state.notifications.length > 0 && <NotificationStrip notifications={state.notifications} />}
        <SessionList sessions={state.sessions} role="practitioner" loading={state.loading} busySession={busySession} onDecide={decide} />
      </SupportWorkspaceShell>
    </Layout>
  );
}

export function SupportChatPage({ practitionerRoute = false }) {
  const auth = useAuth();
  const { sessionId } = useParams();
  const numericSessionId = Number(sessionId);
  const [state, setState] = useState({ loading: true, error: '', session: null, messages: [], calls: [] });
  const [draft, setDraft] = useState('');
  const [busy, setBusy] = useState('');
  const messageListRef = useRef(null);

  const load = useCallback(async () => {
    if (!auth.accessToken || !numericSessionId) return;
    try {
      const [session, messages, calls] = await Promise.all([
        fetchSupportSession(auth.accessToken, numericSessionId),
        fetchSupportMessages(auth.accessToken, numericSessionId),
        fetchSupportCalls(auth.accessToken, numericSessionId),
      ]);
      const serverMessages = Array.isArray(messages) ? messages : readListPayload(messages);
      setState((current) => ({
        loading: false,
        error: '',
        session,
        messages: [...serverMessages, ...current.messages.filter((message) => message.delivery_state === 'sending' || message.delivery_state === 'failed')],
        calls: readListPayload(calls),
      }));
    } catch (error) {
      setState((current) => ({ ...current, loading: false, error: error.message }));
    }
  }, [auth.accessToken, numericSessionId]);

  useEffect(() => { void load(); }, [load]);
  usePolling(load, 10000, Boolean(auth.accessToken && numericSessionId));

  async function send(event) {
    event.preventDefault();
    const body = draft.trim();
    if (!body) return;
    const temporaryId = `pending-${Date.now()}`;
    const optimisticMessage = {
      id: temporaryId,
      sender: auth.user?.id,
      sender_name: auth.user?.name || 'You',
      body,
      created_at: new Date().toISOString(),
      read_at: null,
      delivery_state: 'sending',
    };
    setDraft('');
    setBusy('message');
    setState((current) => ({ ...current, error: '', messages: [...current.messages, optimisticMessage] }));
    try {
      const savedMessage = await sendSupportMessage(auth.accessToken, numericSessionId, body);
      setState((current) => ({
        ...current,
        messages: current.messages.filter((message) => message.id !== savedMessage.id).map((message) => message.id === temporaryId ? { ...savedMessage, delivery_state: 'sent' } : message),
      }));
    } catch (error) {
      setState((current) => ({
        ...current,
        error: error.message,
        messages: current.messages.map((message) => message.id === temporaryId ? { ...message, delivery_state: 'failed' } : message),
      }));
    } finally {
      setBusy('');
    }
  }

  async function sessionAction(action) {
    setBusy(action);
    try {
      if (action === 'accept') await acceptSupportSession(auth.accessToken, numericSessionId);
      else await rejectSupportSession(auth.accessToken, numericSessionId);
      await load();
    } catch (error) {
      setState((current) => ({ ...current, error: error.message }));
    } finally {
      setBusy('');
    }
  }

  async function callAction(action, callId = null) {
    setBusy(`${action}:${callId || ''}`);
    try {
      if (action === 'audio' || action === 'video') await startSupportCall(auth.accessToken, numericSessionId, action);
      else await updateSupportCall(auth.accessToken, callId, action);
      await load();
    } catch (error) {
      setState((current) => ({ ...current, error: error.message }));
    } finally {
      setBusy('');
    }
  }

  const guard = roleGuard(auth, practitionerRoute ? 'practitioner' : 'patient');
  if (guard) return guard;
  const session = state.session;
  const otherName = practitionerRoute ? session?.patient_name : session?.practitioner?.display_name;
  const ringingCall = state.calls.find((call) => call.status === 'ringing');
  const activeCall = state.calls.find((call) => call.status === 'accepted');

  return (
    <Layout active={practitionerRoute ? 'app' : 'support'}>
      <SupportWorkspaceShell eyebrow="Private support session" title="MindRise" subtitle={session ? `Private chat with ${otherName || 'your assigned practitioner'} - ${formatStatus(session.status)}` : 'Loading assigned session.'}>
        <EmergencyDisclaimer />
        {state.error && <StatusMessage type="error">{state.error}</StatusMessage>}
        {state.loading ? <WorkspaceLoading /> : session ? (
          <div className="support-chat-workspace">
            <div className="support-chat-workspace__toolbar">
              <Link className="button button--secondary" to={practitionerRoute ? '/practitioner/dashboard' : '/support/request'}>Back</Link>
              {practitionerRoute && session.status === 'pending' && <>
                <button className="button button--primary" type="button" disabled={Boolean(busy)} onClick={() => sessionAction('accept')}><Check size={17} />Accept</button>
                <button className="button button--secondary" type="button" disabled={Boolean(busy)} onClick={() => sessionAction('reject')}><X size={17} />Reject</button>
              </>}
              {!practitionerRoute && session.status === 'accepted' && session.practitioner?.can_call && <a className="button button--secondary" href={`tel:${session.practitioner.phone_number}`}><Phone size={17} />Call practitioner</a>}
              {!practitionerRoute && session.status === 'accepted' && session.practitioner?.can_whatsapp && <a className="button button--secondary" href={session.practitioner.whatsapp_url} target="_blank" rel="noreferrer"><MessageCircle size={17} />Open WhatsApp</a>}
              {session.can_call && <>
                <button className="button button--secondary" type="button" disabled={Boolean(busy || ringingCall || activeCall)} onClick={() => callAction('audio')}><Phone size={17} />MindRise audio request</button>
                <button className="button button--secondary" type="button" disabled={Boolean(busy || ringingCall || activeCall)} onClick={() => callAction('video')}><Video size={17} />MindRise video request</button>
              </>}
            </div>
            {(ringingCall || activeCall) && <CallBanner call={activeCall || ringingCall} currentUserId={auth.user?.id} busy={busy} onAction={callAction} />}
            <div className="support-chat-message-list" aria-live="polite" ref={messageListRef}>
              {state.messages.length ? state.messages.map((message) => {
                const isOwn = Number(message.sender) === Number(auth.user?.id);
                return <article className={`${isOwn ? 'is-own' : ''}${message.delivery_state === 'failed' ? ' is-failed' : ''}`} key={message.id}><strong>{isOwn ? 'You' : message.sender_name}</strong><p>{message.body}</p><footer><time>{formatTime(message.created_at)}</time>{isOwn && <span className={`support-message-receipt support-message-receipt--${message.delivery_state || (message.read_at ? 'read' : 'sent')}`}>{messageDeliveryLabel(message)}</span>}</footer></article>;
              }) : <WorkspaceEmpty icon={MessageCircle} title="No messages yet" text="Send a private message to begin the conversation." />}
            </div>
            <form className="support-chat-composer" onSubmit={send}>
              <textarea rows={3} value={draft} onChange={(event) => setDraft(event.target.value)} placeholder="Write a private message" disabled={!session.can_message} />
              <button className="button button--primary" type="submit" disabled={!draft.trim() || busy === 'message' || !session.can_message}>{busy === 'message' ? <Loader2 className="spin" size={17} /> : <Send size={17} />}Send</button>
            </form>
          </div>
        ) : null}
      </SupportWorkspaceShell>
    </Layout>
  );
}

function SupportWorkspaceShell({ eyebrow, title, subtitle, children }) {
  return <main className="support-workspace"><header className="support-workspace__header"><p className="eyebrow">{eyebrow}</p><h1>{title}</h1><p>{subtitle}</p></header>{children}</main>;
}

function EmergencyDisclaimer() {
  return <aside className="support-emergency-disclaimer"><ShieldAlert size={22} aria-hidden="true" /><p>{supportDisclaimer}</p></aside>;
}

function WorkspaceToolbar({ label, loading, onRefresh }) {
  return <div className="support-workspace__toolbar"><strong>{label}</strong><button className="button button--secondary" type="button" disabled={loading} onClick={onRefresh}>{loading ? <Loader2 className="spin" size={16} /> : <RefreshCw size={16} />}Refresh</button></div>;
}

function PractitionerPresence({ profile, saving, onChange }) {
  const status = profile?.availability_status || 'offline';
  return <section className="practitioner-presence-panel"><div><p className="eyebrow">Current status</p><h2>{formatStatus(status)}</h2><p>Patients can request support only while you are online.</p></div><div className="practitioner-presence-actions">{[['online', Wifi], ['busy', Headphones], ['offline', WifiOff]].map(([value, Icon]) => <button className={status === value ? 'is-active' : ''} type="button" key={value} disabled={Boolean(saving)} onClick={() => onChange(value)}>{saving === value ? <Loader2 className="spin" size={17} /> : <Icon size={17} />}<span>{formatStatus(value)}</span></button>)}</div></section>;
}

function PractitionerContactSettings({ profile, saving, onSave }) {
  const [phoneNumber, setPhoneNumber] = useState(profile?.phone_number || '');
  useEffect(() => { setPhoneNumber(profile?.phone_number || ''); }, [profile?.phone_number]);
  return <form className="practitioner-contact-panel" onSubmit={(event) => { event.preventDefault(); void onSave(phoneNumber.trim()); }}>
    <div><p className="eyebrow">Call & WhatsApp</p><h2>Practitioner telephone number</h2><p>Use an international number, including country code. Patients use this same number for phone calls and WhatsApp.</p></div>
    <label><span>Telephone number</span><input type="tel" value={phoneNumber} onChange={(event) => setPhoneNumber(event.target.value)} placeholder="+250 788 123 456" autoComplete="tel" /></label>
    <button className="button button--primary" type="submit" disabled={saving}>{saving ? <Loader2 className="spin" size={17} /> : <Check size={17} />}Save number</button>
  </form>;
}

function NotificationStrip({ notifications }) {
  const unread = notifications.filter((item) => !item.is_read).slice(0, 3);
  if (!unread.length) return null;
  return <section className="support-notification-strip"><Bell size={19} /><div>{unread.map((item) => <p key={item.id}><strong>{item.title}</strong> {item.body}</p>)}</div></section>;
}

function SessionList({ sessions, role, loading, busySession, onDecide }) {
  if (loading) return <WorkspaceLoading />;
  if (!sessions.length) return <WorkspaceEmpty icon={MessageCircle} title="No support sessions here" text="New assigned support requests and conversations will appear here." />;
  return <div className="support-session-list">{sessions.map((session) => <article key={session.id}><div className="support-session-list__identity"><span className={`support-session-status support-session-status--${session.status}`}>{formatStatus(session.status)}</span><div><h2>{role === 'practitioner' ? session.patient_name : session.practitioner?.display_name}</h2><p>{session.latest_message?.body || 'Private support request'}</p></div><time>{formatTime(session.updated_at)}</time></div><div className="support-session-list__actions"><Link className="button button--secondary" to={role === 'practitioner' ? `/practitioner/chat/${session.id}` : `/support/chat/${session.id}`}>Open chat</Link>{role === 'practitioner' && session.status === 'pending' && <><button className="button button--primary" type="button" disabled={busySession === session.id} onClick={() => onDecide(session.id, 'accept')}><Check size={16} />Accept</button><button className="button button--secondary" type="button" disabled={busySession === session.id} onClick={() => onDecide(session.id, 'reject')}><X size={16} />Reject</button></>}</div></article>)}</div>;
}

function CallBanner({ call, currentUserId, busy, onAction }) {
  const incoming = Number(call.started_by) !== Number(currentUserId);
  return <section className="support-call-banner"><div><p className="eyebrow">{call.status === 'ringing' ? incoming ? 'Incoming call' : 'Calling' : 'Call connected'}</p><h2>{formatStatus(call.call_type)} call</h2></div><div>{call.status === 'ringing' && incoming && <><button className="button button--primary" type="button" disabled={Boolean(busy)} onClick={() => onAction('accept', call.id)}><Check size={17} />Accept</button><button className="button button--secondary" type="button" disabled={Boolean(busy)} onClick={() => onAction('reject', call.id)}><X size={17} />Reject</button></>}<button className="button button--secondary" type="button" disabled={Boolean(busy)} onClick={() => onAction('end', call.id)}>End call</button></div></section>;
}

function WorkspaceLoading() { return <div className="support-workspace-loading"><Loader2 className="spin" size={24} /><p>Loading secure support workspace...</p></div>; }
function WorkspaceEmpty({ icon: Icon, title, text }) { return <div className="support-workspace-empty"><Icon size={24} /><div><h2>{title}</h2><p>{text}</p></div></div>; }
function StatusMessage({ type, children }) { return <p className={`form-status form-status--${type}`}>{children}</p>; }
function formatStatus(value = '') { return value ? `${value.charAt(0).toUpperCase()}${value.slice(1)}` : ''; }
function formatTime(value) { return value ? new Intl.DateTimeFormat(undefined, { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' }).format(new Date(value)) : ''; }
function messageDeliveryLabel(message) { if (message.delivery_state === 'sending') return 'Sending'; if (message.delivery_state === 'failed') return 'Not sent'; return message.read_at ? 'Read' : 'Sent'; }
function usePolling(callback, interval, enabled) { useEffect(() => { if (!enabled) return undefined; const timer = window.setInterval(() => void callback(), interval); return () => window.clearInterval(timer); }, [callback, enabled, interval]); }
function roleGuard(auth, role) { if (auth.loading) return <WorkspaceLoading />; if (!auth.isAuthenticated) return <Navigate to="/start" replace />; if (auth.user?.role !== role) return <Navigate to={auth.user?.role === 'practitioner' ? '/practitioner/dashboard' : '/support/request'} replace />; return null; }
