import { useMemo, useState } from 'react';
import { CheckCircle2, HeartPulse, Loader2, LockKeyhole, Mail, ShieldCheck, UserRound } from 'lucide-react';
import { registerAccount, verifyEmail } from '../api';
import { logoFullUrl } from './siteConfig';

export function SignupPanel() {
  const [form, setForm] = useState({ name: '', email: '', password: '', accepts: false });
  const [code, setCode] = useState('');
  const [pendingEmail, setPendingEmail] = useState('');
  const [status, setStatus] = useState({ type: '', message: '' });
  const [loading, setLoading] = useState(false);
  const [verified, setVerified] = useState(false);

  const canSubmit = useMemo(
    () => form.name.trim().length > 1 && form.email.includes('@') && form.password.length >= 10 && form.accepts,
    [form],
  );

  async function submitRegistration(event) {
    event.preventDefault();
    if (!canSubmit || loading) return;
    setLoading(true);
    setStatus({ type: '', message: '' });
    try {
      const result = await registerAccount({ name: form.name.trim(), email: form.email.trim(), password: form.password });
      setPendingEmail(result?.email || form.email.trim());
      setStatus({ type: 'success', message: 'Account created. Check your email for the verification code.' });
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
      await verifyEmail({ email: pendingEmail, code: code.trim() });
      setVerified(true);
      setStatus({ type: 'success', message: 'Email verified. Your account is ready for MindRise.' });
    } catch (error) {
      setStatus({ type: 'error', message: error.message });
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="signup-panel">
      <div className="signup-panel__aside">
        <img className="signup-panel__logo" src={logoFullUrl} alt="MindRise Wellness Initiative logo" />
        <h3>Create a MindRise account</h3>
        <p>Use the form to create your account and confirm your email before signing in.</p>
        <div className="account-note">
          <ShieldCheck size={18} aria-hidden="true" />
          <span>Email verification helps keep accounts trusted and ready for the MindRise experience.</span>
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
              <p>{verified ? 'Your account is ready.' : `Enter the six digit code sent to ${pendingEmail}.`}</p>
            </div>
          </div>
          {!verified && (
            <>
              <Field icon={ShieldCheck} label="Verification code" value={code} onChange={setCode} inputMode="numeric" maxLength={6} />
              <button className="button button--primary button--full" type="submit" disabled={code.trim().length !== 6 || loading}>
                {loading ? <Loader2 className="spin" size={18} aria-hidden="true" /> : <CheckCircle2 size={18} aria-hidden="true" />}
                <span>Verify email</span>
              </button>
            </>
          )}
          <FormStatus status={status} />
        </form>
      )}
    </div>
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