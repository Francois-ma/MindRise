import { TrendingUp, TrendingDown, Minus } from 'lucide-react';
import { Card } from '../ui/card';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar } from 'recharts';
import { ProfileButton } from '../ProfileButton';

interface InsightsScreenProps {
  onNavigate: (screen: string) => void;
}

export function InsightsScreen({ onNavigate }: InsightsScreenProps) {
  const weeklyData = [
    { day: 'Mon', mood: 4 },
    { day: 'Tue', mood: 5 },
    { day: 'Wed', mood: 3 },
    { day: 'Thu', mood: 4 },
    { day: 'Fri', mood: 6 },
    { day: 'Sat', mood: 7 },
    { day: 'Sun', mood: 6 },
  ];

  const moodDistribution = [
    { mood: 'Happy', count: 12 },
    { mood: 'Calm', count: 8 },
    { mood: 'Neutral', count: 5 },
    { mood: 'Stressed', count: 4 },
    { mood: 'Sad', count: 2 },
  ];

  const insights = [
    {
      text: "You feel more stressed on Mondays",
      icon: TrendingDown,
      color: 'text-amber-600',
      bg: 'from-yellow-50 via-amber-50 to-orange-50',
    },
    {
      text: "Your mood improves after journaling",
      icon: TrendingUp,
      color: 'text-emerald-600',
      bg: 'from-emerald-50 via-teal-50 to-cyan-50',
    },
    {
      text: "Weekend moods are consistently positive",
      icon: TrendingUp,
      color: 'text-blue-600',
      bg: 'from-blue-50 via-sky-50 to-cyan-50',
    },
  ];

  return (
    <div className="pb-24 px-4 pt-8 max-w-md mx-auto">
      {/* Header */}
      <div className="mb-8">
        <div className="bg-gradient-to-br from-blue-500 via-sky-500 to-cyan-500 rounded-3xl p-6 text-white relative shadow-xl shadow-blue-200/50">
          <div className="absolute top-6 right-6">
            <ProfileButton onClick={() => onNavigate('profile')} />
          </div>
          <TrendingUp className="w-8 h-8 mb-3" />
          <h1 className="text-3xl mb-1">Your Insights</h1>
          <p className="opacity-90">Understanding your emotional patterns</p>
        </div>
      </div>

      {/* Progress Summary */}
      <div className="grid grid-cols-3 gap-3 mb-6">
        <Card className="p-4 bg-gradient-to-br from-emerald-50 via-teal-50 to-cyan-50 border-emerald-200 shadow-lg shadow-emerald-100/50">
          <div className="text-3xl mb-1">7.2</div>
          <div className="text-xs text-muted-foreground">Stability Score</div>
          <TrendingUp className="w-4 h-4 text-emerald-600 mt-1" />
        </Card>
        <Card className="p-4 bg-gradient-to-br from-yellow-50 via-amber-50 to-orange-50 border-yellow-200 shadow-lg shadow-yellow-100/50">
          <div className="text-3xl mb-1">😊</div>
          <div className="text-xs text-muted-foreground">Most Frequent</div>
          <Minus className="w-4 h-4 text-amber-600 mt-1" />
        </Card>
        <Card className="p-4 bg-gradient-to-br from-blue-50 via-sky-50 to-cyan-50 border-blue-200 shadow-lg shadow-blue-100/50">
          <div className="text-3xl mb-1">+15%</div>
          <div className="text-xs text-muted-foreground">Improvement</div>
          <TrendingUp className="w-4 h-4 text-blue-600 mt-1" />
        </Card>
      </div>

      {/* Weekly Trend */}
      <Card className="mb-6 p-6 bg-white/60 backdrop-blur-sm">
        <h3 className="mb-4">Weekly Mood Trend</h3>
        <ResponsiveContainer width="100%" height={200}>
          <LineChart data={weeklyData}>
            <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
            <XAxis dataKey="day" stroke="#9ca3af" fontSize={12} />
            <YAxis stroke="#9ca3af" fontSize={12} domain={[0, 10]} />
            <Tooltip
              contentStyle={{
                backgroundColor: 'rgba(255, 255, 255, 0.9)',
                border: '1px solid #e5e7eb',
                borderRadius: '12px',
              }}
            />
            <Line
              type="monotone"
              dataKey="mood"
              stroke="url(#colorGradient)"
              strokeWidth={3}
              dot={{ fill: '#8b5cf6', r: 5 }}
            />
            <defs>
              <linearGradient id="colorGradient" x1="0" y1="0" x2="1" y2="0">
                <stop offset="0%" stopColor="#10b981" />
                <stop offset="50%" stopColor="#14b8a6" />
                <stop offset="100%" stopColor="#06b6d4" />
              </linearGradient>
            </defs>
          </LineChart>
        </ResponsiveContainer>
      </Card>

      {/* Mood Distribution */}
      <Card className="mb-6 p-6 bg-white/60 backdrop-blur-sm">
        <h3 className="mb-4">Mood Distribution (This Month)</h3>
        <ResponsiveContainer width="100%" height={200}>
          <BarChart data={moodDistribution}>
            <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
            <XAxis dataKey="mood" stroke="#9ca3af" fontSize={12} />
            <YAxis stroke="#9ca3af" fontSize={12} />
            <Tooltip
              contentStyle={{
                backgroundColor: 'rgba(255, 255, 255, 0.9)',
                border: '1px solid #e5e7eb',
                borderRadius: '12px',
              }}
            />
            <Bar dataKey="count" fill="url(#barGradient)" radius={[8, 8, 0, 0]} />
            <defs>
              <linearGradient id="barGradient" x1="0" y1="0" x2="0" y2="1">
                <stop offset="0%" stopColor="#10b981" />
                <stop offset="50%" stopColor="#14b8a6" />
                <stop offset="100%" stopColor="#06b6d4" />
              </linearGradient>
            </defs>
          </BarChart>
        </ResponsiveContainer>
      </Card>

      {/* AI Insights */}
      <div>
        <h3 className="mb-4">AI-Generated Insights</h3>
        <div className="space-y-3">
          {insights.map((insight, idx) => {
            const Icon = insight.icon;
            return (
              <Card key={idx} className={`p-4 bg-gradient-to-br ${insight.bg}`}>
                <div className="flex items-start gap-3">
                  <Icon className={`w-5 h-5 ${insight.color} flex-shrink-0 mt-0.5`} />
                  <p className="text-sm">{insight.text}</p>
                </div>
              </Card>
            );
          })}
        </div>
      </div>
    </div>
  );
}
