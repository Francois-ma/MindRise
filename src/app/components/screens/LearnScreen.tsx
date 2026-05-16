import { BookOpen, Clock, Bookmark, Search, Lightbulb } from 'lucide-react';
import { Card } from '../ui/card';
import { Input } from '../ui/input';
import { Badge } from '../ui/badge';
import { ProfileButton } from '../ProfileButton';

interface LearnScreenProps {
  onNavigate: (screen: string) => void;
}

export function LearnScreen({ onNavigate }: LearnScreenProps) {
  const categories = [
    { id: 'stress', label: 'Stress & Anxiety', color: 'bg-orange-100 text-orange-700 hover:bg-orange-200' },
    { id: 'depression', label: 'Depression Awareness', color: 'bg-blue-100 text-blue-700 hover:bg-blue-200' },
    { id: 'sleep', label: 'Sleep & Recovery', color: 'bg-purple-100 text-purple-700 hover:bg-purple-200' },
    { id: 'focus', label: 'Focus & Productivity', color: 'bg-green-100 text-green-700 hover:bg-green-200' },
    { id: 'emotional', label: 'Emotional Intelligence', color: 'bg-pink-100 text-pink-700 hover:bg-pink-200' },
    { id: 'selfesteem', label: 'Self-esteem', color: 'bg-teal-100 text-teal-700 hover:bg-teal-200' },
  ];

  const articles = [
    {
      title: 'Understanding Anxiety: Causes and Coping Strategies',
      category: 'Stress & Anxiety',
      readTime: '8 min',
      gradient: 'from-orange-50 to-red-50',
      borderColor: 'border-orange-100',
    },
    {
      title: 'The Science of Sleep: Why Rest Matters for Mental Health',
      category: 'Sleep & Recovery',
      readTime: '6 min',
      gradient: 'from-purple-50 to-indigo-50',
      borderColor: 'border-purple-100',
    },
    {
      title: 'Building Emotional Resilience in Daily Life',
      category: 'Emotional Intelligence',
      readTime: '10 min',
      gradient: 'from-pink-50 to-rose-50',
      borderColor: 'border-pink-100',
    },
    {
      title: 'Mindfulness Techniques for Stress Reduction',
      category: 'Stress & Anxiety',
      readTime: '5 min',
      gradient: 'from-blue-50 to-cyan-50',
      borderColor: 'border-blue-100',
    },
    {
      title: 'Recognizing Signs of Depression and When to Seek Help',
      category: 'Depression Awareness',
      readTime: '7 min',
      gradient: 'from-indigo-50 to-blue-50',
      borderColor: 'border-indigo-100',
    },
  ];

  return (
    <div className="pb-24 px-4 pt-8 max-w-md mx-auto">
      {/* Header */}
      <div className="mb-8">
        <div className="bg-gradient-to-br from-lime-500 via-green-500 to-emerald-500 rounded-3xl p-6 text-white relative shadow-xl shadow-green-200/50">
          <div className="absolute top-6 right-6">
            <ProfileButton onClick={() => onNavigate('profile')} />
          </div>
          <BookOpen className="w-8 h-8 mb-3" />
          <h1 className="text-3xl mb-1">Mind Library</h1>
          <p className="opacity-90">Understand your mind and improve your wellbeing</p>
        </div>
      </div>

      {/* Search Bar */}
      <div className="relative mb-6">
        <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
        <Input
          placeholder="Search mental health topics..."
          className="pl-12 h-14 rounded-2xl bg-white/60 backdrop-blur-sm"
        />
      </div>

      {/* Daily Tip */}
      <Card className="mb-6 p-5 bg-gradient-to-br from-yellow-50 to-amber-50 border-yellow-100">
        <div className="flex gap-3">
          <Lightbulb className="w-6 h-6 text-amber-600 flex-shrink-0" />
          <div>
            <h4 className="mb-2 text-amber-900">Daily Mental Health Tip</h4>
            <p className="text-sm text-amber-800">
              Practice the 5-4-3-2-1 grounding technique: Name 5 things you see, 4 you can touch, 3 you hear, 2 you smell, and 1 you taste.
            </p>
          </div>
        </div>
      </Card>

      {/* Categories */}
      <div className="mb-6">
        <h3 className="mb-4">Explore Topics</h3>
        <div className="flex flex-wrap gap-2">
          {categories.map((category) => (
            <Badge
              key={category.id}
              className={`${category.color} px-4 py-2 rounded-full cursor-pointer transition-colors`}
            >
              {category.label}
            </Badge>
          ))}
        </div>
      </div>

      {/* Articles */}
      <div>
        <h3 className="mb-4">Featured Articles</h3>
        <div className="space-y-3">
          {articles.map((article, idx) => (
            <Card
              key={idx}
              className={`p-5 bg-gradient-to-br ${article.gradient} ${article.borderColor} cursor-pointer hover:shadow-lg transition-shadow`}
            >
              <div className="flex gap-4">
                <div className="flex-1">
                  <h4 className="mb-2 line-clamp-2">{article.title}</h4>
                  <div className="flex items-center gap-3 text-xs text-muted-foreground">
                    <span className="px-2 py-1 bg-white/60 rounded-full">
                      {article.category}
                    </span>
                    <div className="flex items-center gap-1">
                      <Clock className="w-3 h-3" />
                      <span>{article.readTime}</span>
                    </div>
                  </div>
                </div>
                <button className="flex-shrink-0 w-10 h-10 rounded-full bg-white/60 hover:bg-white/80 transition-colors flex items-center justify-center">
                  <Bookmark className="w-5 h-5 text-muted-foreground" />
                </button>
              </div>
            </Card>
          ))}
        </div>
      </div>
    </div>
  );
}
