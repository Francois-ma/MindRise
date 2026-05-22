import { useEffect, useState } from 'react';
import { BookOpen, ExternalLink, Loader2, ShieldCheck } from 'lucide-react';
import { fetchLearningContent } from '../api';
import { PageHero, SectionIntro } from './Layout';
import { InlineState } from './Cards';

const fallbackCategories = [
  { id: 'stress', name: 'Stress' },
  { id: 'anxiety', name: 'Anxiety' },
  { id: 'depression', name: 'Depression' },
  { id: 'self-esteem', name: 'Self-esteem' },
  { id: 'life-transitions', name: 'Life transitions' },
  { id: 'resilience', name: 'Psychological resilience' },
];

const fallbackArticles = [
  {
    id: 'stress-young-people',
    title: 'Understanding stress before it becomes overwhelming',
    summary: 'A youth-friendly guide to noticing stress, naming triggers, and choosing a healthy next step.',
    read_time_minutes: 5,
    category: { name: 'Stress' },
  },
  {
    id: 'speaking-about-mental-health',
    title: 'How open conversations break mental health stigma',
    summary: 'Why speaking out matters, how to listen safely, and how communities can respond with dignity.',
    read_time_minutes: 6,
    category: { name: 'Stigma' },
  },
  {
    id: 'self-esteem-transitions',
    title: 'Self-esteem during school, work, and life transitions',
    summary: 'Practical guidance for young people navigating identity, pressure, change, and uncertainty.',
    read_time_minutes: 7,
    category: { name: 'Self-esteem' },
  },
];

export function ResourcesHero() {
  return (
    <PageHero
      compact
      eyebrow="Resources"
      title="Mental health literacy that young people can actually use."
      lead="MindRise provides evidence-based, culturally sensitive resources on emotional well-being, resilience, stress, anxiety, depression, self-esteem, and life transitions."
    />
  );
}

export function ResourceLibrary() {
  const [learning, setLearning] = useState({ categories: [], articles: [], materials: [], error: '', loading: true });

  useEffect(() => {
    fetchLearningContent()
      .then((data) => setLearning({ ...data, loading: false }))
      .catch((error) => setLearning({ categories: [], articles: [], materials: [], error: error.message, loading: false }));
  }, []);

  const categories = learning.categories.length ? learning.categories : fallbackCategories;
  const articles = learning.articles.length ? learning.articles : fallbackArticles;

  return (
    <section className="section resource-page-grid">
      <TopicPanel categories={categories} loading={learning.loading} error={learning.error} />
      <div>
        <SectionIntro
          eyebrow="Psychoeducation"
          title="Resources for awareness, prevention, and early support."
          lead="MindRise keeps practical education available for visitors while supporting published learning content from our digital platform."
        />
        <ArticleList articles={articles} />
        {learning.materials.length > 0 && <MaterialsRow materials={learning.materials} />}
      </div>
    </section>
  );
}

function TopicPanel({ categories, loading, error }) {
  return (
    <aside className="topic-panel">
      <div className="panel-heading">
        <BookOpen size={22} aria-hidden="true" />
        <span>Learning topics</span>
      </div>
      <div className="topic-list">
        {categories.map((category) => (
          <span key={category.id || category.slug || category.name}>{category.name}</span>
        ))}
      </div>
      {loading && <InlineState icon={Loader2} text="Loading MindRise resources" spin />}
      {error && <InlineState icon={ShieldCheck} text={error} />}
    </aside>
  );
}

function ArticleList({ articles }) {
  return (
    <div className="article-list">
      {articles.map((article) => (
        <article className="article-card" key={article.id || article.slug || article.title}>
          <div>
            <span>{categoryName(article.category)}</span>
            <h3>{article.title}</h3>
            <p>{article.summary || 'A MindRise learning item is ready to read.'}</p>
          </div>
          <small>{article.read_time_minutes || article.readTimeMinutes || 5} min read</small>
        </article>
      ))}
    </div>
  );
}

function MaterialsRow({ materials }) {
  return (
    <div className="materials-row">
      {materials.map((material) => (
        <a key={material.id || material.slug || material.title} href={material.material_url || material.external_url || '#'} target="_blank" rel="noreferrer">
          <ExternalLink size={16} aria-hidden="true" />
          <span>{material.title}</span>
        </a>
      ))}
    </div>
  );
}

function categoryName(category) {
  if (typeof category === 'string') return category;
  return category?.name || 'MindRise';
}
