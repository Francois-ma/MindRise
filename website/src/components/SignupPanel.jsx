import { useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  CheckCircle2,
  HeartPulse,
  Loader2,
  LockKeyhole,
  LogIn,
  Mail,
  RefreshCw,
  ShieldCheck,
  UserRound,
} from 'lucide-react';
import { registerAccount, resendVerificationEmail, verifyEmail } from '../api';
import { useAuth } from '../auth';
import { logoFullUrl } from './siteConfig';

const webAppReadyMessage = 'After verification, MindRise will open your private web dashboard. You can use the same account on the mobile app.';

export function SignupPanel() {
  const navigate = useNavigate();
  const { applyAuthResponse } = useAuth();
  const [form, setForm] = useState({ name: '', email: '', password: '', accepts: false });
  const [code, setCode] = useState('');
  const [pendingEmail, setPendingEmail] = useState('');
  const [status, setStatus] = useState({ type: '', message: '' });
  const [loading, setLoading] = useState(false);
  const [verified, setVerified] = useState(false);
  const [resent, setResent] = useState(false);

  const canSubmit = useMemo(
    () => form.name.trim().length > 1 && form.email.includes('@') && form.password.length >= 10 && form.accepts,
    [form],
  );

  async function submitRegistration(event) {
    event.preventDefault();
    if (!canSubmit || loading) return;
    setLoading(true);
    setStatus({ type: '', message: '' });
    setResent(false);
    try {
      const result = await registerAccount({ name: form.name.trim(), email: form.email.trim(), password: form.password });
      setPendingEmail(result?.email || form.email.trim());
      setStatus({ type: 'success', message: `Account created. Check your email for the verification code. ${webAppReadyMessage}` });
    } catch (error) {
      setStatus({ type: 'error', message: error.message });
    } finally {
      setLoading(false);
    }
  }

  async function submitVerification(event) {
    event.preventDefault();
    if (!pendingEmail || code.trim().length !== 6 || loading) return;
    setLoading(true);
    setStatus({ type: '', message: '' });
    try {
      const authPayload = await verifyEmail({ email: pendingEmail, code: code.trim() });
      applyAuthResponse(authPayload);
      setVerified(true);
      setStatus({ type: 'success', message: 'Email verified. Opening your MindRise dashboard.' });
      navigate('/app', { replace: true });
    } catch (error) {
      setStatus({ type: 'error', message: error.message });
    } finally {
      setLoading(false);
    }
  }

  async function resendCode() {
    if (!pendingEmail || loading) return;
    setLoading(true);
    setStatus({ type: '', message: '' });
    try {
      await resendVerificationEmail(pendingEmail);
      setResent(true);
      setStatus({ type: 'success', message: 'A new verification code was sent. Use the newest code in your inbox.' });
    } catch (error) {
      setStatus({ type: 'error', message: error.message });
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="signup-panel signup-panel--single">
      <div className="signup-panel__aside">
        <img className="signup-panel__logo" src={logoFullUrl} alt="MindRise Wellness Initiative logo" />
        <h3>Create a MindRise account</h3>
        <p>Create your account, verify your email, then continue into the private MindRise web dashboard or mobile app.</p>
        <div className="account-note">
          <ShieldCheck size={18} aria-hidden="true" />
          <span>Email verification keeps account access trusted across web and mobile.</span>
        </div>
      </div>
      {!pendingEmail && !verified ? (
        <form className="form-card" onSubmit={submitRegistration}>
          <Field icon={UserRound} label="Full name" value={form.name} onChange={(value) => setForm((current) => ({ ...current, name: value }))} autoComplete="name" />
          <Field icon={Mail} label="Email address" type="email" value={form.email} onChange={(value) => setForm((current) => ({ ...current, email: value }))} autoComplete="email" />
          <Field icon={LockKeyhole} label="Password" type="password" value={form.password} onChange={(value) => setForm((current) => ({ ...current, password: value }))} autoComplete="new-password" hint="At least 10 characters" />
          <label className="checkbox-row">
            <input type="checkbox" checked={form.accepts} onChange={(event) => setForm((current) => ({ ...current, accepts: event.target.checked }))} />
            <span>I agree to create a MindRise account.</span>
          </label>
          <button className="button button--primary button--full" type="submit" disabled={!canSubmit || loading}>
            {loading ? <Loader2 className="spin" size={18} aria-hidden="true" /> : <HeartPulse size={18} aria-hidden="true" />}
            <span>Create account</span>
          </button>
          <FormStatus status={status} />
        </form>
      ) : (
        <form className="form-card" onSubmit={submitVerification}>
          <div className="verification-heading">
            {verified ? <CheckCircle2 size={28} aria-hidden="true" /> : <Mail size={28} aria-hidden="true" />}
            <div>
              <h3>{verified ? 'Email verified' : 'Verify your email'}</h3>
              <p>{verified ? 'Your account is ready.' : `Enter the six-digit code sent to ${pendingEmail}.`}</p>
            </div>
          </div>
          <div className="account-note">
            <LogIn size={18} aria-hidden="true" />
            <span>{resent ? 'Use the newest code in your inbox.' : verified ? 'Your web dashboard is opening.' : webAppReadyMessage}</span>
          </div>
          {!verified && (
            <>
              <Field icon={ShieldCheck} label="Verification code" value={code} onChange={setCode} inputMode="numeric" maxLength={6} />
              <button className="button button--primary button--full" type="submit" disabled={code.trim().length !== 6 || loading}>
                {loading ? <Loader2 className="spin" size={18} aria-hidden="true" /> : <CheckCircle2 size={18} aria-hidden="true" />}
                <span>Verify and open dashboard</span>
              </button>
              <button className="button button--secondary button--full" type="button" onClick={resendCode} disabled={loading || !pendingEmail}>
                {loading ? <Loader2 className="spin" size={18} aria-hidden="true" /> : <RefreshCw size={18} aria-hidden="true" />}
                <span>Send a new code</span>
              </button>
            </>
          )}
          <FormStatus status={status} />
        </form>
      )}
    </div>
  );
}

export function LoginPanel() {
  const navigate = useNavigate();
  const { login } = useAuth();
  const [form, setForm] = useState({ email: '', password: '' });
  const [status, setStatus] = useState({ type: '', message: '' });
  const [loading, setLoading] = useState(false);
  const canSubmit = form.email.includes('@') && form.password.length >= 6;

  async function submitLogin(event) {
    event.preventDefault();
    if (!canSubmit || loading) return;
    setLoading(true);
    setStatus({ type: '', message: '' });
    try {
      await login({ email: form.email.trim(), password: form.password });
      setStatus({ type: 'success', message: 'Signed in. Opening your MindRise dashboard.' });
      navigate('/app', { replace: true });
    } catch (error) {
      setStatus({ type: 'error', message: error.message });
    } finally {
      setLoading(false);
    }
  }

  return (
    <form className="form-card login-panel" onSubmit={submitLogin}>
      <div className="verification-heading">
        <LogIn size={28} aria-hidden="true" />
        <div>
          <h3>Sign in to MindRise</h3>
          <p>Use your verified account to open the same MindRise experience on the web.</p>
        </div>
      </div>
      <Field icon={Mail} label="Email address" type="email" value={form.email} onChange={(value) => setForm((current) => ({ ...current, email: value }))} autoComplete="email" />
      <Field icon={LockKeyhole} label="Password" type="password" value={form.password} onChange={(value) => setForm((current) => ({ ...current, password: value }))} autoComplete="current-password" />
      <button className="button button--primary button--full" type="submit" disabled={!canSubmit || loading}>
        {loading ? <Loader2 className="spin" size={18} aria-hidden="true" /> : <LogIn size={18} aria-hidden="true" />}
        <span>Sign in and open dashboard</span>
      </button>
      <FormStatus status={status} />
    </form>
  );
}

function Field({ icon: Icon, label, type = 'text', value, onChange, hint, ...props }) {
  return (
    <label className="field">
      <span>{label}</span>
      <div>
        <Icon size={18} aria-hidden="true" />
        <input type={type} value={value} onChange={(event) => onChange(event.target.value)} placeholder={label} {...props} />
      </div>
      {hint && <small>{hint}</small>}
    </label>
  );
}

function FormStatus({ status }) {
  if (!status.message) return null;
  return <p className={`form-status form-status--${status.type}`}>{status.message}</p>;
}
