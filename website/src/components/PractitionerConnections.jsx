import { useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { Clock3, Loader2, MessageCircle, Phone, RefreshCw, Send, ShieldCheck, UserRound, Video, Wifi } from 'lucide-react';
import { createSupportThread, fetchOnlinePractitioners, fetchPractitioners, fetchSupportMessages, fetchSupportThreads, readListPayload, sendSupportMessage, updatePractitionerAvailability } from '../api';
import { useAuth } from '../auth';
import { SectionIntro } from './Layout';

const contactMethods = {
  text: { label: 'Text', icon: MessageCircle },
  phone: { label: 'Call', icon: Phone },
  video: { label: 'Video', icon: Video },
};

export function PractitionerConnectionSection() {
  const auth = useAuth();
  const isPractitioner = auth.user?.role === 'practitioner';

  return (
    <section className="section practitioner-connect-section">
      <div className="practitioner-connect-shell">
        <div className="practitioner-connect-heading">
          <SectionIntro
            eyebrow="Live support"
            title={isPractitioner ? 'Manage your live support availability.' : 'Choose an online practitioner.'}
            lead={isPractitioner ? 'Go online when you are ready, then answer patient conversations from your private inbox.' : 'Patients can connect with available practitioners through a private text thread, a phone call, or a configured video room.'}
          />
          <div className="practitioner-connect-heading__signal" aria-hidden="true">
            <Wifi size={18} />
            <span>Online now</span>
          </div>
        </div>

        {auth.loading ? (
          <div className="practitioner-connect-state"><Loader2 className="spin" size={22} aria-hidden="true" /><p>Checking your MindRise session...</p></div>
        ) : auth.isAuthenticated && auth.user?.role === 'practitioner' ? (
          <div className="practitioner-connect-stack">
            <PractitionerAvailabilityControl token={auth.accessToken} autoLoad />
            <SupportConversationInbox token={auth.accessToken} role={auth.user.role} userId={auth.user.id} />
          </div>
        ) : auth.isAuthenticated && auth.user?.role === 'patient' ? (
          <div className="practitioner-connect-stack">
            <PractitionerConnectionBoard token={auth.accessToken} autoLoad />
            <SupportConversationInbox token={auth.accessToken} role={auth.user.role} userId={auth.user.id} />
          </div>
        ) : (
          <div className="practitioner-connect-lock">
            <ShieldCheck size={24} aria-hidden="true" />
            <div>
              <h3>Patient sign-in required</h3>
              <p>Practitioner contact details are protected inside verified MindRise accounts.</p>
            </div>
            <Link className="button button--primary" to="/start">Sign in</Link>
          </div>
        )}
      </div>
    </section>
  );
}


export function PractitionerAvailabilityControl({ token, initialProfile = null, autoLoad = false, onUpdated }) {
  const [profile, setProfile] = useState(initialProfile);
  const [loading, setLoading] = useState(Boolean(autoLoad && !initialProfile));
  const [saving, setSaving] = useState(false);
  const [status, setStatus] = useState({ type: '', message: '' });

  const loadProfile = useMemo(
    () => async () => {
      if (!autoLoad || !token) return;
      setLoading(true);
      setStatus({ type: '', message: '' });
      try {
        const data = await fetchPractitioners(token);
        const ownProfile = readListPayload(data).find((person) => person.is_my_profile) || null;
        setProfile(ownProfile);
      } catch (error) {
        setStatus({ type: 'error', message: error.message });
      } finally {
        setLoading(false);
      }
    },
    [autoLoad, token],
  );

  useEffect(() => {
    if (initialProfile) setProfile(initialProfile);
  }, [initialProfile]);

  useEffect(() => {
    if (autoLoad && !initialProfile) void loadProfile();
  }, [autoLoad, initialProfile, loadProfile]);

  async function setAvailability(isAvailable) {
    setSaving(true);
    setStatus({ type: '', message: '' });
    try {
      const updated = await updatePractitionerAvailability(token, { isAvailable });
      setProfile(updated);
      setStatus({ type: 'success', message: isAvailable ? 'You are online for patient support.' : 'You are offline now.' });
      onUpdated?.(updated);
    } catch (error) {
      setStatus({ type: 'error', message: error.message });
    } finally {
      setSaving(false);
    }
  }

  const isOnline = Boolean(profile?.is_available);

  return (
    <div className="practitioner-availability-card">
      <div className="practitioner-availability-card__main">
        <span className={isOnline ? 'practitioner-status-dot is-online' : 'practitioner-status-dot'} aria-hidden="true" />
        <div>
          <p className="eyebrow">Practitioner status</p>
          <h3>{loading ? 'Checking your availability...' : isOnline ? 'You are online' : 'You are offline'}</h3>
          <p>{isOnline ? 'Patients can choose you for support while you remain online.' : 'Go online when you are ready to receive patient support requests.'}</p>
        </div>
      </div>
      <div className="practitioner-availability-card__actions">
        <button className="button button--primary" type="button" onClick={() => setAvailability(true)} disabled={saving || loading || isOnline}>
          {saving && !isOnline ? <Loader2 className="spin" size={17} aria-hidden="true" /> : <Wifi size={17} aria-hidden="true" />}
          <span>Go online</span>
        </button>
        <button className="button button--secondary" type="button" onClick={() => setAvailability(false)} disabled={saving || loading || !isOnline}>
          {saving && isOnline ? <Loader2 className="spin" size={17} aria-hidden="true" /> : <Clock3 size={17} aria-hidden="true" />}
          <span>Go offline</span>
        </button>
      </div>
      {status.message && <p className={`form-status form-status--${status.type}`}>{status.message}</p>}
    </div>
  );
}

export function SupportConversationInbox({ token, role, userId }) {
  const [threads, setThreads] = useState({ loading: true, error: '', items: [] });
  const [selectedThreadId, setSelectedThreadId] = useState(null);
  const [messages, setMessages] = useState({ loading: false, error: '', items: [] });
  const [draft, setDraft] = useState('');
  const [sending, setSending] = useState(false);

  const loadThreads = useMemo(
    () => async () => {
      if (!token) return;
      setThreads((current) => ({ ...current, loading: true, error: '' }));
      try {
        const data = await fetchSupportThreads(token);
        const items = readListPayload(data).filter((thread) => thread.thread_type === 'practitioner');
        setThreads({ loading: false, error: '', items });
        setSelectedThreadId((current) => (items.some((thread) => thread.id === current) ? current : items[0]?.id || null));
      } catch (error) {
        setThreads({ loading: false, error: error.message, items: [] });
      }
    },
    [token],
  );

  const loadMessages = useMemo(
    () => async () => {
      if (!token || !selectedThreadId) {
        setMessages({ loading: false, error: '', items: [] });
        return;
      }
      setMessages((current) => ({ ...current, loading: true, error: '' }));
      try {
        const data = await fetchSupportMessages(token, selectedThreadId);
        setMessages({ loading: false, error: '', items: readListPayload(data).length ? readListPayload(data) : (Array.isArray(data) ? data : []) });
      } catch (error) {
        setMessages({ loading: false, error: error.message, items: [] });
      }
    },
    [selectedThreadId, token],
  );

  useEffect(() => {
    void loadThreads();
  }, [loadThreads]);

  useEffect(() => {
    void loadMessages();
  }, [loadMessages]);

  async function submitMessage(event) {
    event.preventDefault();
    if (!selectedThreadId || !draft.trim()) return;
    setSending(true);
    try {
      await sendSupportMessage(token, selectedThreadId, draft.trim());
      setDraft('');
      await Promise.all([loadMessages(), loadThreads()]);
    } catch (error) {
      setMessages((current) => ({ ...current, error: error.message }));
    } finally {
      setSending(false);
    }
  }

  const selectedThread = threads.items.find((thread) => thread.id === selectedThreadId) || null;
  const isPractitioner = role === 'practitioner';

  return (
    <section className="support-inbox" aria-label="Private support conversations">
      <div className="support-inbox__heading">
        <div>
          <p className="eyebrow">Private conversations</p>
          <h3>{isPractitioner ? 'Patient support inbox' : 'Your practitioner messages'}</h3>
        </div>
        <button className="button button--secondary" type="button" onClick={loadThreads} disabled={threads.loading}>
          {threads.loading ? <Loader2 className="spin" size={16} aria-hidden="true" /> : <RefreshCw size={16} aria-hidden="true" />}
          <span>Refresh</span>
        </button>
      </div>

      {threads.error && <p className="form-status form-status--error">{threads.error}</p>}
      <div className="support-inbox__layout">
        <div className="support-thread-list" aria-label="Support threads">
          {threads.items.length ? threads.items.map((thread) => (
            <button className={selectedThreadId === thread.id ? 'is-active' : ''} type="button" key={thread.id} onClick={() => setSelectedThreadId(thread.id)}>
              <strong>{isPractitioner ? thread.patient_name : thread.practitioner?.display_name || 'Practitioner'}</strong>
              <span>{formatConversationTime(thread.updated_at)}</span>
              <p>{thread.latest_message?.body || `${formatConnectionMethod(thread.contact_method)} support started`}</p>
            </button>
          )) : <p className="support-thread-list__empty">{threads.loading ? 'Loading conversations...' : 'No private support conversations yet.'}</p>}
        </div>

        <div className="support-conversation">
          {selectedThread ? (
            <>
              <div className="support-conversation__title">
                <strong>{isPractitioner ? selectedThread.patient_name : selectedThread.practitioner?.display_name || 'Practitioner'}</strong>
                <span>{formatConnectionMethod(selectedThread.contact_method)}</span>
              </div>
              <div className="support-message-list" aria-live="polite">
                {messages.loading ? <p>Loading messages...</p> : messages.items.length ? messages.items.map((message) => (
                  <article className={Number(message.sender) === Number(userId) ? 'is-own' : ''} key={message.id}>
                    <strong>{message.sender_name}</strong>
                    <p>{message.body}</p>
                    <span>{formatConversationTime(message.created_at)}</span>
                  </article>
                )) : <p>No messages in this conversation yet.</p>}
              </div>
              {messages.error && <p className="form-status form-status--error">{messages.error}</p>}
              <form className="support-conversation__composer" onSubmit={submitMessage}>
                <textarea value={draft} rows={3} onChange={(event) => setDraft(event.target.value)} placeholder="Write a private message." disabled={selectedThread.is_closed} />
                <button className="button button--primary" type="submit" disabled={sending || selectedThread.is_closed || !draft.trim()}>
                  {sending ? <Loader2 className="spin" size={16} aria-hidden="true" /> : <Send size={16} aria-hidden="true" />}
                  <span>Send</span>
                </button>
              </form>
            </>
          ) : (
            <div className="support-conversation__empty"><MessageCircle size={22} aria-hidden="true" /><p>Select a conversation when one becomes available.</p></div>
          )}
        </div>
      </div>
    </section>
  );
}
export function PractitionerConnectionBoard({ token, practitioners = null, autoLoad = false, compact = false }) {
  const [state, setState] = useState({ loading: Boolean(autoLoad), error: '', items: practitioners || [] });
  const [busyAction, setBusyAction] = useState('');
  const [status, setStatus] = useState({ type: '', message: '' });
  const [activeThread, setActiveThread] = useState(null);
  const [message, setMessage] = useState('');
  const [sending, setSending] = useState(false);

  const loadOnline = useMemo(
    () => async () => {
      if (!autoLoad || !token) return;
      setState((current) => ({ ...current, loading: true, error: '' }));
      try {
        const data = await fetchOnlinePractitioners(token);
        setState({ loading: false, error: '', items: readListPayload(data) });
      } catch (error) {
        setState({ loading: false, error: error.message, items: [] });
      }
    },
    [autoLoad, token],
  );

  useEffect(() => {
    if (autoLoad) {
      void loadOnline();
      return;
    }
    setState({ loading: false, error: '', items: practitioners || [] });
  }, [autoLoad, loadOnline, practitioners]);

  const onlinePractitioners = useMemo(
    () => (state.items || []).filter((person) => person?.is_available),
    [state.items],
  );

  async function connect(person, contactMethod) {
    if (!token) {
      setStatus({ type: 'error', message: 'Sign in as a patient to connect with a practitioner.' });
      return;
    }
    if (contactMethod === 'phone' && !person.can_call) {
      setStatus({ type: 'error', message: 'Phone calling is not available for this practitioner yet.' });
      return;
    }
    if (contactMethod === 'video' && !person.can_video_call) {
      setStatus({ type: 'error', message: 'Video calling is not available for this practitioner yet.' });
      return;
    }

    const actionKey = `${person.id}:${contactMethod}`;
    setBusyAction(actionKey);
    setStatus({ type: '', message: '' });
    try {
      const thread = await createSupportThread(token, {
        practitionerId: person.id,
        contactMethod,
        subject: `${contactMethods[contactMethod].label} support with ${person.display_name}`,
      });
      setActiveThread({ thread, practitioner: person, contactMethod });
      setStatus({ type: 'success', message: `${person.display_name} is ready for ${contactMethods[contactMethod].label.toLowerCase()} support.` });

      if (contactMethod === 'phone' && person.phone_number && typeof window !== 'undefined') {
        window.location.href = `tel:${person.phone_number}`;
      }
      if (contactMethod === 'video' && person.video_call_url && typeof window !== 'undefined') {
        window.open(person.video_call_url, '_blank', 'noopener,noreferrer');
      }
    } catch (error) {
      setStatus({ type: 'error', message: error.message });
    } finally {
      setBusyAction('');
    }
  }

  async function submitMessage(event) {
    event.preventDefault();
    if (!activeThread?.thread?.id || !message.trim()) return;

    setSending(true);
    setStatus({ type: '', message: '' });
    try {
      await sendSupportMessage(token, activeThread.thread.id, message.trim());
      setMessage('');
      setStatus({ type: 'success', message: 'Your message was sent to the practitioner.' });
    } catch (error) {
      setStatus({ type: 'error', message: error.message });
    } finally {
      setSending(false);
    }
  }

  return (
    <div className={`practitioner-board${compact ? ' practitioner-board--compact' : ''}`}>
      {autoLoad && (
        <div className="practitioner-board__toolbar">
          <span>{state.loading ? 'Refreshing availability' : `${onlinePractitioners.length} online practitioner${onlinePractitioners.length === 1 ? '' : 's'}`}</span>
          <button className="button button--secondary" type="button" onClick={loadOnline} disabled={state.loading}>
            {state.loading ? <Loader2 className="spin" size={16} aria-hidden="true" /> : <RefreshCw size={16} aria-hidden="true" />}
            <span>Refresh</span>
          </button>
        </div>
      )}

      {status.message && <p className={`form-status form-status--${status.type}`}>{status.message}</p>}
      {state.error && <div className="web-app-alert"><ShieldCheck size={18} aria-hidden="true" /><span>{state.error}</span></div>}

      {state.loading ? (
        <div className="practitioner-connect-state"><Loader2 className="spin" size={22} aria-hidden="true" /><p>Loading online practitioners...</p></div>
      ) : onlinePractitioners.length ? (
        <div className="practitioner-grid">
          {onlinePractitioners.map((person) => (
            <PractitionerCard key={person.id} person={person} busyAction={busyAction} onConnect={connect} />
          ))}
        </div>
      ) : (
        <div className="practitioner-empty-state">
          <Clock3 size={22} aria-hidden="true" />
          <div>
            <h3>No practitioner is online right now</h3>
            <p>Check again later or use the urgent support resources if the situation cannot wait.</p>
          </div>
        </div>
      )}

      {activeThread?.contactMethod === 'text' && (
        <form className="practitioner-message-composer" onSubmit={submitMessage}>
          <div>
            <p className="eyebrow">Private text thread</p>
            <h3>{activeThread.practitioner.display_name}</h3>
          </div>
          <label>
            <span>Message</span>
            <textarea value={message} rows={4} onChange={(event) => setMessage(event.target.value)} placeholder="Write your message to the practitioner." />
          </label>
          <button className="button button--primary" type="submit" disabled={sending || !message.trim()}>
            {sending ? <Loader2 className="spin" size={17} aria-hidden="true" /> : <Send size={17} aria-hidden="true" />}
            <span>Send message</span>
          </button>
        </form>
      )}
    </div>
  );
}

function PractitionerCard({ person, busyAction, onConnect }) {
  return (
    <article className="practitioner-card">
      <div className="practitioner-card__top">
        <div className="practitioner-avatar"><UserRound size={21} aria-hidden="true" /></div>
        <span className="practitioner-online-badge"><Wifi size={14} aria-hidden="true" />Online</span>
      </div>
      <div className="practitioner-card__body">
        <h3>{person.display_name}</h3>
        <p className="practitioner-specialty">{person.specialization || 'MindRise practitioner'}</p>
        {person.bio && <p>{person.bio}</p>}
      </div>
      <div className="practitioner-action-grid" aria-label={`Connection options for ${person.display_name}`}>
        {Object.entries(contactMethods).map(([method, config]) => {
          const Icon = config.icon;
          const disabled = (method === 'phone' && !person.can_call) || (method === 'video' && !person.can_video_call);
          const busy = busyAction === `${person.id}:${method}`;
          return (
            <button
              className="button button--secondary practitioner-action"
              type="button"
              key={method}
              disabled={disabled || busy}
              onClick={() => onConnect(person, method)}
              title={disabled ? `${config.label} is not available for this practitioner yet.` : `${config.label} ${person.display_name}`}
            >
              {busy ? <Loader2 className="spin" size={16} aria-hidden="true" /> : <Icon size={16} aria-hidden="true" />}
              <span>{config.label}</span>
            </button>
          );
        })}
      </div>
    </article>
  );
}
function formatConnectionMethod(method = 'text') {
  return method === 'phone' ? 'Phone call' : method === 'video' ? 'Video call' : 'Text';
}

function formatConversationTime(value) {
  if (!value) return '';
  return new Intl.DateTimeFormat(undefined, { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' }).format(new Date(value));
}