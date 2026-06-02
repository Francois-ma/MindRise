import { useMemo, useRef, useState } from 'react';
import { AlertCircle, Bot, Loader2, MessageCircle, Send, ShieldCheck, X } from 'lucide-react';
import { sendChatbotMessage } from '../api';

function createMessageId() {
  return typeof crypto !== 'undefined' && crypto.randomUUID
    ? crypto.randomUUID()
    : `${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

const initialMessages = [
  {
    id: 'welcome',
    role: 'assistant',
    content: 'Hello, I am the MindRise assistant. I can share mental health education, coping ideas, and guidance on MindRise support.',
  },
];

export function ChatbotWidget() {
  const [open, setOpen] = useState(false);
  const [messages, setMessages] = useState(initialMessages);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const inputRef = useRef(null);

  const history = useMemo(
    () => messages
      .filter((message) => message.role === 'user' || message.role === 'assistant')
      .slice(-8)
      .map(({ role, content }) => ({ role, content })),
    [messages],
  );

  function toggleOpen() {
    setOpen((current) => {
      const next = !current;
      if (next) window.setTimeout(() => inputRef.current?.focus(), 120);
      return next;
    });
  }

  async function submitMessage(event) {
    event.preventDefault();
    const message = input.trim();
    if (!message || loading) return;

    const userMessage = { id: createMessageId(), role: 'user', content: message };
    setMessages((current) => [...current, userMessage]);
    setInput('');
    setError('');
    setLoading(true);

    try {
      const result = await sendChatbotMessage({ message, history });
      setMessages((current) => [
        ...current,
        {
          id: createMessageId(),
          role: 'assistant',
          content: result?.reply || 'I am here with you. Try one slow breath and tell me what feels heaviest right now.',
        },
      ]);
    } catch (requestError) {
      setError(requestError.message || 'The MindRise assistant is unavailable right now.');
    } finally {
      setLoading(false);
    }
  }

  return (
    <aside className={`chatbot ${open ? 'chatbot--open' : ''}`} aria-label="MindRise AI assistant">
      {open && (
        <div className="chatbot-panel" role="dialog" aria-modal="false" aria-labelledby="chatbot-title">
          <div className="chatbot-panel__header">
            <div className="chatbot-panel__identity">
              <span className="chatbot-panel__icon"><Bot size={20} aria-hidden="true" /></span>
              <div>
                <h2 id="chatbot-title">MindRise Assistant</h2>
                <p>Supportive education, not emergency care.</p>
              </div>
            </div>
            <button className="icon-button chatbot-panel__close" type="button" onClick={toggleOpen} aria-label="Close assistant">
              <X size={19} aria-hidden="true" />
            </button>
          </div>

          <div className="chatbot-panel__notice">
            <ShieldCheck size={16} aria-hidden="true" />
            <span>If you may be in immediate danger, contact local emergency services or a trusted person now.</span>
          </div>

          <div className="chatbot-messages" aria-live="polite">
            {messages.map((message) => (
              <div className={`chatbot-message chatbot-message--${message.role}`} key={message.id}>
                <p>{message.content}</p>
              </div>
            ))}
            {loading && (
              <div className="chatbot-message chatbot-message--assistant chatbot-message--loading">
                <Loader2 className="spin" size={17} aria-hidden="true" />
                <p>Thinking...</p>
              </div>
            )}
          </div>

          {error && <p className="chatbot-error"><AlertCircle size={16} aria-hidden="true" />{error}</p>}

          <form className="chatbot-form" onSubmit={submitMessage}>
            <label className="sr-only" htmlFor="mindrise-chat-message">Message</label>
            <textarea
              id="mindrise-chat-message"
              ref={inputRef}
              value={input}
              onChange={(event) => setInput(event.target.value)}
              rows={2}
              maxLength={1200}
              placeholder="Ask about stress, anxiety, self-esteem, or MindRise support."
            />
            <button className="button button--primary chatbot-form__send" type="submit" disabled={!input.trim() || loading} aria-label="Send message">
              {loading ? <Loader2 className="spin" size={18} aria-hidden="true" /> : <Send size={18} aria-hidden="true" />}
            </button>
          </form>
        </div>
      )}

      <button className="chatbot-toggle" type="button" onClick={toggleOpen} aria-expanded={open} aria-label={open ? 'Close MindRise assistant' : 'Open MindRise assistant'}>
        {open ? <X size={23} aria-hidden="true" /> : <MessageCircle size={24} aria-hidden="true" />}
        <span>{open ? 'Close' : 'Ask MindRise'}</span>
      </button>
    </aside>
  );
}
