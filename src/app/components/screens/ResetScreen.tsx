import { useState, useEffect } from 'react';
import { Wind, Play, Pause, Check, Heart, Sparkles, RefreshCw, Brain, ChevronRight, Save } from 'lucide-react';
import { Button } from '../ui/button';
import { Card } from '../ui/card';
import { Textarea } from '../ui/textarea';
import { motion } from 'motion/react';
import { ProfileButton } from '../ProfileButton';

type Activity = 'breathing' | 'gratitude' | 'reframing' | 'meditation' | null;

interface ResetScreenProps {
  onNavigate: (screen: string) => void;
}

export function ResetScreen({ onNavigate }: ResetScreenProps) {
  const [activeActivity, setActiveActivity] = useState<Activity>(null);
  const [isBreathing, setIsBreathing] = useState(false);
  const [selectedDuration, setSelectedDuration] = useState<number | null>(null);
  const [timeRemaining, setTimeRemaining] = useState(0);
  const [gratitudeEntries, setGratitudeEntries] = useState(['', '', '']);
  const [negativeThought, setNegativeThought] = useState('');
  const [reframedThought, setReframedThought] = useState('');

  useEffect(() => {
    if (isBreathing && timeRemaining > 0) {
      const timer = setInterval(() => {
        setTimeRemaining((prev) => {
          if (prev <= 1) {
            setIsBreathing(false);
            return 0;
          }
          return prev - 1;
        });
      }, 1000);
      return () => clearInterval(timer);
    }
  }, [isBreathing, timeRemaining]);

  const startBreathing = (duration: number) => {
    setSelectedDuration(duration);
    setTimeRemaining(duration);
    setIsBreathing(true);
  };

  const formatTime = (seconds: number) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const activities = [
    {
      id: 'breathing' as Activity,
      title: 'Breathing Exercises',
      description: 'Calm your mind with guided breathing',
      icon: Wind,
      gradient: 'from-blue-400 via-sky-400 to-cyan-500',
      bgGradient: 'from-blue-50 via-sky-50 to-cyan-50',
    },
    {
      id: 'gratitude' as Activity,
      title: 'Gratitude Journaling',
      description: 'Focus on what you\'re grateful for',
      icon: Heart,
      gradient: 'from-emerald-400 via-teal-400 to-cyan-500',
      bgGradient: 'from-emerald-50 via-teal-50 to-cyan-50',
    },
    {
      id: 'reframing' as Activity,
      title: 'Thought Reframing',
      description: 'Transform negative thoughts into positive ones',
      icon: RefreshCw,
      gradient: 'from-yellow-400 via-amber-400 to-orange-500',
      bgGradient: 'from-yellow-50 via-amber-50 to-orange-50',
    },
    {
      id: 'meditation' as Activity,
      title: 'Quick Meditation',
      description: 'Short guided meditation sessions',
      icon: Brain,
      gradient: 'from-lime-400 via-green-400 to-emerald-500',
      bgGradient: 'from-lime-50 via-green-50 to-emerald-50',
    },
  ];

  const affirmations = [
    'You are safe',
    'This moment will pass',
    'You are in control',
    'You are worthy of peace',
    'You are doing your best',
  ];

  const meditationThemes = [
    { title: 'Body Scan', duration: '5 min', description: 'Release tension from head to toe' },
    { title: 'Loving Kindness', duration: '7 min', description: 'Cultivate compassion for yourself' },
    { title: 'Mindful Awareness', duration: '10 min', description: 'Be present in this moment' },
  ];

  // Render activity selection
  if (!activeActivity) {
    return (
      <div className="pb-24 px-4 pt-8 max-w-md mx-auto">
        {/* Header */}
        <div className="mb-8">
          <div className="bg-gradient-to-br from-yellow-500 via-amber-500 to-orange-500 rounded-3xl p-6 text-white relative shadow-xl shadow-yellow-200/50">
            <div className="absolute top-6 right-6">
              <ProfileButton onClick={() => onNavigate('profile')} />
            </div>
            <Wind className="w-8 h-8 mb-3" />
            <h1 className="text-3xl mb-1">Reset Your Mind</h1>
            <p className="opacity-90">Choose a wellness activity to center yourself</p>
          </div>
        </div>

        {/* Activity Cards */}
        <div className="space-y-4">
          {activities.map((activity) => {
            const Icon = activity.icon;
            return (
              <Card
                key={activity.id}
                onClick={() => setActiveActivity(activity.id)}
                className={`p-5 bg-gradient-to-br ${activity.bgGradient} border-opacity-50 cursor-pointer hover:shadow-lg transition-all hover:scale-[1.02]`}
              >
                <div className="flex items-center gap-4">
                  <div className={`w-14 h-14 rounded-2xl bg-gradient-to-br ${activity.gradient} flex items-center justify-center flex-shrink-0`}>
                    <Icon className="w-7 h-7 text-white" />
                  </div>
                  <div className="flex-1">
                    <h3 className="mb-1">{activity.title}</h3>
                    <p className="text-sm text-muted-foreground">{activity.description}</p>
                  </div>
                  <ChevronRight className="w-5 h-5 text-muted-foreground flex-shrink-0" />
                </div>
              </Card>
            );
          })}
        </div>

        {/* Quick Affirmations */}
        <div className="mt-8">
          <h3 className="mb-4">Quick Affirmations</h3>
          <div className="space-y-3">
            {affirmations.map((affirmation, idx) => (
              <Card
                key={idx}
                className="p-4 bg-gradient-to-br from-blue-50 to-cyan-50 border-blue-100"
              >
                <div className="flex items-center gap-3">
                  <Sparkles className="w-4 h-4 text-blue-500" />
                  <p className="text-sm">{affirmation}</p>
                </div>
              </Card>
            ))}
          </div>
        </div>
      </div>
    );
  }

  // Breathing Exercise Activity
  if (activeActivity === 'breathing') {
    return (
      <div className="pb-24 px-4 pt-8 max-w-md mx-auto">
        <Button
          variant="ghost"
          onClick={() => setActiveActivity(null)}
          className="mb-4"
        >
          ← Back to Activities
        </Button>

        <div className="mb-8">
          <div className="bg-gradient-to-br from-blue-500 via-sky-500 to-cyan-500 rounded-3xl p-6 text-white shadow-xl shadow-blue-200/50">
            <Wind className="w-8 h-8 mb-3" />
            <h1 className="text-3xl mb-1">Breathing Exercise</h1>
            <p className="opacity-90">Follow the rhythm to calm your mind</p>
          </div>
        </div>

        <Card className="mb-6 p-8 bg-gradient-to-br from-indigo-50 via-purple-50 to-blue-50 border-indigo-100">
          <div className="flex flex-col items-center justify-center">
            <div className="relative w-64 h-64 flex items-center justify-center mb-6">
              <motion.div
                animate={
                  isBreathing
                    ? {
                        scale: [1, 1.5, 1],
                        opacity: [0.3, 0.6, 0.3],
                      }
                    : { scale: 1, opacity: 0.3 }
                }
                transition={
                  isBreathing
                    ? {
                        duration: 6,
                        repeat: Infinity,
                        ease: 'easeInOut',
                      }
                    : {}
                }
                className="absolute w-48 h-48 rounded-full bg-gradient-to-br from-blue-400 to-cyan-400"
              />
              <motion.div
                animate={
                  isBreathing
                    ? {
                        scale: [1, 1.3, 1],
                        opacity: [0.5, 0.8, 0.5],
                      }
                    : { scale: 1, opacity: 0.5 }
                }
                transition={
                  isBreathing
                    ? {
                        duration: 6,
                        repeat: Infinity,
                        ease: 'easeInOut',
                      }
                    : {}
                }
                className="absolute w-32 h-32 rounded-full bg-gradient-to-br from-indigo-400 to-blue-400"
              />
              <div className="relative z-10 text-center">
                {isBreathing ? (
                  <>
                    <div className="text-4xl mb-2">{formatTime(timeRemaining)}</div>
                    <div className="text-sm text-muted-foreground">Breathe slowly</div>
                  </>
                ) : (
                  <Wind className="w-12 h-12 text-blue-600" />
                )}
              </div>
            </div>

            {!isBreathing && (
              <div className="text-center mb-4">
                <h3 className="mb-2">Choose your session</h3>
                <p className="text-sm text-muted-foreground">Select a duration to begin</p>
              </div>
            )}
          </div>
        </Card>

        {!isBreathing && (
          <div className="grid grid-cols-3 gap-3 mb-6">
            {[
              { duration: 60, label: '1 min' },
              { duration: 180, label: '3 min' },
              { duration: 300, label: '5 min' },
            ].map(({ duration, label }) => (
              <Button
                key={duration}
                onClick={() => startBreathing(duration)}
                className="h-20 rounded-2xl bg-gradient-to-br from-blue-600 to-cyan-600 hover:from-blue-700 hover:to-cyan-700"
              >
                <div className="flex flex-col items-center gap-1">
                  <Play className="w-5 h-5" />
                  <span>{label}</span>
                </div>
              </Button>
            ))}
          </div>
        )}

        {isBreathing && (
          <Button
            onClick={() => setIsBreathing(false)}
            variant="outline"
            className="w-full h-14 rounded-2xl mb-6"
          >
            <Pause className="w-5 h-5 mr-2" />
            Pause Session
          </Button>
        )}

        {!isBreathing && timeRemaining === 0 && selectedDuration !== null && (
          <Button className="w-full h-14 rounded-2xl bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700">
            <Check className="w-5 h-5 mr-2" />
            Session Complete
          </Button>
        )}
      </div>
    );
  }

  // Gratitude Journaling Activity
  if (activeActivity === 'gratitude') {
    return (
      <div className="pb-24 px-4 pt-8 max-w-md mx-auto">
        <Button
          variant="ghost"
          onClick={() => setActiveActivity(null)}
          className="mb-4"
        >
          ← Back to Activities
        </Button>

        <div className="mb-8">
          <div className="bg-gradient-to-br from-emerald-500 via-teal-500 to-cyan-500 rounded-3xl p-6 text-white shadow-xl shadow-emerald-200/50">
            <Heart className="w-8 h-8 mb-3" />
            <h1 className="text-3xl mb-1">Gratitude Journal</h1>
            <p className="opacity-90">Write three things you're grateful for today</p>
          </div>
        </div>

        <Card className="mb-6 p-6 bg-gradient-to-br from-pink-50 to-rose-50 border-pink-100">
          <div className="space-y-4">
            {gratitudeEntries.map((entry, idx) => (
              <div key={idx}>
                <label className="text-sm text-muted-foreground mb-2 block">
                  {idx + 1}. I am grateful for...
                </label>
                <Textarea
                  value={entry}
                  onChange={(e) => {
                    const newEntries = [...gratitudeEntries];
                    newEntries[idx] = e.target.value;
                    setGratitudeEntries(newEntries);
                  }}
                  placeholder="Something you appreciate today"
                  className="bg-white/80 rounded-xl resize-none"
                  rows={2}
                />
              </div>
            ))}
          </div>
        </Card>

        <Button
          className="w-full h-14 rounded-2xl bg-gradient-to-r from-pink-600 to-rose-600 hover:from-pink-700 hover:to-rose-700 mb-6"
          disabled={gratitudeEntries.every(e => !e.trim())}
        >
          <Save className="w-5 h-5 mr-2" />
          Save Gratitude Entry
        </Button>

        <Card className="p-5 bg-gradient-to-br from-amber-50 to-yellow-50 border-amber-100">
          <div className="flex gap-3">
            <Sparkles className="w-5 h-5 text-amber-600 flex-shrink-0 mt-1" />
            <div>
              <h4 className="mb-2 text-amber-900">Why Gratitude Matters</h4>
              <p className="text-sm text-amber-800">
                Regular gratitude practice has been shown to improve mood, reduce stress, and increase overall life satisfaction.
              </p>
            </div>
          </div>
        </Card>
      </div>
    );
  }

  // Thought Reframing Activity
  if (activeActivity === 'reframing') {
    return (
      <div className="pb-24 px-4 pt-8 max-w-md mx-auto">
        <Button
          variant="ghost"
          onClick={() => setActiveActivity(null)}
          className="mb-4"
        >
          ← Back to Activities
        </Button>

        <div className="mb-8">
          <div className="bg-gradient-to-br from-yellow-500 via-amber-500 to-orange-500 rounded-3xl p-6 text-white shadow-xl shadow-yellow-200/50">
            <RefreshCw className="w-8 h-8 mb-3" />
            <h1 className="text-3xl mb-1">Thought Reframing</h1>
            <p className="opacity-90">Transform negative thoughts into balanced perspectives</p>
          </div>
        </div>

        <Card className="mb-6 p-6 bg-gradient-to-br from-purple-50 to-indigo-50 border-purple-100">
          <div className="space-y-4">
            <div>
              <label className="text-sm text-muted-foreground mb-2 block">
                What negative thought is bothering you?
              </label>
              <Textarea
                value={negativeThought}
                onChange={(e) => setNegativeThought(e.target.value)}
                placeholder="Example: I'm not good enough at my job"
                className="bg-white/80 rounded-xl resize-none"
                rows={3}
              />
            </div>

            <div className="flex items-center justify-center py-2">
              <RefreshCw className="w-6 h-6 text-purple-600" />
            </div>

            <div>
              <label className="text-sm text-muted-foreground mb-2 block">
                How can you reframe this thought more positively?
              </label>
              <Textarea
                value={reframedThought}
                onChange={(e) => setReframedThought(e.target.value)}
                placeholder="Example: I'm learning and improving every day, and my efforts matter"
                className="bg-white/80 rounded-xl resize-none"
                rows={3}
              />
            </div>
          </div>
        </Card>

        <Button
          className="w-full h-14 rounded-2xl bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-700 hover:to-indigo-700 mb-6"
          disabled={!negativeThought.trim() || !reframedThought.trim()}
        >
          <Save className="w-5 h-5 mr-2" />
          Save Reframed Thought
        </Button>

        <Card className="p-5 bg-gradient-to-br from-blue-50 to-cyan-50 border-blue-100">
          <div>
            <h4 className="mb-3">Reframing Tips</h4>
            <ul className="space-y-2 text-sm text-muted-foreground">
              <li className="flex gap-2">
                <span className="text-blue-600">•</span>
                <span>Challenge absolute thinking ("always", "never")</span>
              </li>
              <li className="flex gap-2">
                <span className="text-blue-600">•</span>
                <span>Look for evidence that contradicts the negative thought</span>
              </li>
              <li className="flex gap-2">
                <span className="text-blue-600">•</span>
                <span>Consider what you'd tell a friend in this situation</span>
              </li>
            </ul>
          </div>
        </Card>
      </div>
    );
  }

  // Quick Meditation Activity
  if (activeActivity === 'meditation') {
    return (
      <div className="pb-24 px-4 pt-8 max-w-md mx-auto">
        <Button
          variant="ghost"
          onClick={() => setActiveActivity(null)}
          className="mb-4"
        >
          ← Back to Activities
        </Button>

        <div className="mb-8">
          <div className="bg-gradient-to-br from-lime-500 via-green-500 to-emerald-500 rounded-3xl p-6 text-white shadow-xl shadow-green-200/50">
            <Brain className="w-8 h-8 mb-3" />
            <h1 className="text-3xl mb-1">Quick Meditation</h1>
            <p className="opacity-90">Find peace in guided meditation</p>
          </div>
        </div>

        <div className="space-y-4">
          {meditationThemes.map((theme, idx) => (
            <Card
              key={idx}
              className="p-5 bg-gradient-to-br from-teal-50 to-emerald-50 border-teal-100 cursor-pointer hover:shadow-lg transition-all"
            >
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-teal-600 to-emerald-600 flex items-center justify-center flex-shrink-0">
                  <Play className="w-6 h-6 text-white" />
                </div>
                <div className="flex-1">
                  <h4 className="mb-1">{theme.title}</h4>
                  <p className="text-sm text-muted-foreground mb-1">{theme.description}</p>
                  <span className="text-xs text-teal-600">{theme.duration}</span>
                </div>
              </div>
            </Card>
          ))}
        </div>

        <Card className="mt-6 p-5 bg-gradient-to-br from-indigo-50 to-purple-50 border-indigo-100">
          <div className="flex gap-3">
            <Sparkles className="w-5 h-5 text-indigo-600 flex-shrink-0 mt-1" />
            <div>
              <h4 className="mb-2 text-indigo-900">Meditation Benefits</h4>
              <p className="text-sm text-indigo-800">
                Regular meditation can reduce anxiety, improve focus, enhance emotional well-being, and promote better sleep.
              </p>
            </div>
          </div>
        </Card>
      </div>
    );
  }

  return null;
}
