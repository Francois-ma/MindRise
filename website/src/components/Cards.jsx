export function ProgramCard({ icon: Icon, title, text, tone = 'emerald' }) {
  return (
    <article className={`program-card program-card--${tone}`}>
      <Icon size={28} aria-hidden="true" />
      <h3>{title}</h3>
      <p>{text}</p>
    </article>
  );
}

export function ValueCard({ title, text }) {
  return (
    <article className="value-card">
      <h3>{title}</h3>
      <p>{text}</p>
    </article>
  );
}

export function Stat({ value, label }) {
  return (
    <div className="stat">
      <strong>{value}</strong>
      <span>{label}</span>
    </div>
  );
}

export function InlineState({ icon: Icon, text, spin }) {
  return (
    <p className="inline-state">
      <Icon className={spin ? 'spin' : ''} size={16} aria-hidden="true" />
      <span>{text}</span>
    </p>
  );
}