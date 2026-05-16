import { Smile, TrendingUp, BookOpen, Wind, Heart, MessageCircle, Sparkles } from 'lucide-react';
import { Button } from '../ui/button';
import { Card } from '../ui/card';
import { ProfileButton } from '../ProfileButton';
import { ImageWithFallback } from '../figma/ImageWithFallback';
import appIcon from '../../../imports/icon.jpeg';

interface HomeScreenProps {
  onNavigate: (screen: string) => void;
}

export function HomeScreen({ onNavigate }: HomeScreenProps) {
  const moods = [
    { emoji: '😊', label: 'Happy' },
    { emoji: '😌', label: 'Calm' },
    { emoji: '😐', label: 'Neutral' },
    { emoji: '😔', label: 'Sad' },
    { emoji: '😰', label: 'Stressed' },
  ];

  const quickActions = [
    { icon: Heart, label: 'Track Mood', screen: 'mood', gradient: 'from-emerald-400 via-teal-400 to-cyan-500' },
    { icon: TrendingUp, label: 'View Insights', screen: 'insights', gradient: 'from-blue-400 via-sky-400 to-cyan-500' },
    { icon: Wind, label: 'Reset Mind', screen: 'reset', gradient: 'from-yellow-400 via-amber-400 to-orange-500' },
    { icon: BookOpen, label: 'Learn', screen: 'learn', gradient: 'from-lime-400 via-green-400 to-emerald-500' },
  ];

  return (
    <div className="pb-24 px-4 pt-8 max-w-md mx-auto">
      {/* Greeting Header with Gradient */}
      <div className="mb-8">
        <div className="bg-gradient-to-br from-emerald-500 via-teal-500 to-cyan-500 rounded-3xl p-6 text-white shadow-xl shadow-emerald-200/50">
          {/* Top Row: App Icon and Profile */}
          <div className="flex items-center justify-between mb-6">
            <img src={appIcon} alt="MindRise" className="w-12 h-12 rounded-2xl shadow-lg" />
            <ProfileButton onClick={() => onNavigate('profile')} />
          </div>

          {/* Content */}
          <div className="flex items-center gap-2 mb-2">
            <Sparkles className="w-5 h-5" />
            <span className="opacity-90">Good morning</span>
          </div>
          <h1 className="text-3xl mb-1">Welcome back, Francois</h1>
          <p className="opacity-90">How are you feeling today?</p>
        </div>
      </div>

      {/* Daily Mood Selector */}
      <Card className="mb-6 p-6 bg-white/60 backdrop-blur-sm border-border/50">
        <h3 className="mb-4 text-center opacity-70">Quick Mood Check</h3>
        <div className="flex justify-between gap-2">
          {moods.map((mood) => (
            <button
              key={mood.label}
              className="flex flex-col items-center gap-2 p-3 rounded-2xl hover:bg-accent/50 transition-all"
            >
              <span className="text-3xl">{mood.emoji}</span>
              <span className="text-xs text-muted-foreground">{mood.label}</span>
            </button>
          ))}
        </div>
      </Card>

      {/* Daily Quote */}
      <Card className="mb-6 p-6 bg-gradient-to-br from-yellow-50 via-amber-50 to-orange-50 border-yellow-200 shadow-lg shadow-yellow-100/50">
        <div className="flex gap-3">
          <Sparkles className="w-5 h-5 text-amber-600 flex-shrink-0 mt-1" />
          <div>
            <p className="text-sm mb-2 italic text-foreground/80">
              "The greatest discovery of my generation is that human beings can alter their lives by altering their attitudes."
            </p>
            <p className="text-xs text-muted-foreground">— William James</p>
          </div>
        </div>
      </Card>

      {/* Quick Actions */}
      <div className="mb-6">
        <h3 className="mb-4">Quick Actions</h3>
        <div className="grid grid-cols-2 gap-3">
          {quickActions.map((action) => {
            const Icon = action.icon;
            return (
              <button
                key={action.label}
                onClick={() => onNavigate(action.screen)}
                className={`bg-gradient-to-br ${action.gradient} p-5 rounded-2xl text-white flex flex-col items-start gap-3 hover:scale-105 transition-transform shadow-lg`}
              >
                <Icon className="w-6 h-6" />
                <span className="text-sm">{action.label}</span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Additional Actions */}
      <div className="space-y-3">
        <Button
          variant="outline"
          className="w-full justify-start gap-3 h-14 rounded-2xl border-emerald-200 hover:bg-emerald-50"
          onClick={() => onNavigate('mood')}
        >
          <Smile className="w-5 h-5 text-emerald-600" />
          <span>Write in Journal</span>
        </Button>
        <Button
          variant="outline"
          className="w-full justify-start gap-3 h-14 rounded-2xl border-blue-200 hover:bg-blue-50"
          onClick={() => onNavigate('support')}
        >
          <MessageCircle className="w-5 h-5 text-blue-600" />
          <span>Talk to Support</span>
        </Button>
      </div>
    </div>
  );
}
