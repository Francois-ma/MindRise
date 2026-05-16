import { useState } from 'react';
import { Heart, Save, Clock } from 'lucide-react';
import { Button } from '../ui/button';
import { Card } from '../ui/card';
import { Textarea } from '../ui/textarea';
import { ProfileButton } from '../ProfileButton';

interface MoodScreenProps {
  onNavigate: (screen: string) => void;
}

export function MoodScreen({ onNavigate }: MoodScreenProps) {
  const [selectedMood, setSelectedMood] = useState<string | null>(null);
  const [note, setNote] = useState('');

  const moods = [
    { id: 'happy', emoji: '😊', label: 'Happy', color: 'from-yellow-400 via-amber-400 to-orange-400' },
    { id: 'calm', emoji: '😌', label: 'Calm', color: 'from-blue-400 via-sky-400 to-cyan-400' },
    { id: 'stressed', emoji: '😰', label: 'Stressed', color: 'from-orange-400 via-amber-500 to-yellow-500' },
    { id: 'sad', emoji: '😔', label: 'Sad', color: 'from-blue-500 via-indigo-500 to-sky-500' },
    { id: 'angry', emoji: '😠', label: 'Angry', color: 'from-red-500 via-orange-500 to-amber-500' },
    { id: 'energetic', emoji: '⚡', label: 'Energetic', color: 'from-lime-400 via-green-400 to-emerald-500' },
  ];

  const recentMoods = [
    { time: '2 hours ago', mood: '😊', label: 'Happy', note: 'Great meeting with team' },
    { time: 'Yesterday', mood: '😌', label: 'Calm', note: 'Morning meditation helped' },
    { time: '2 days ago', mood: '😰', label: 'Stressed', note: 'Deadline pressure' },
  ];

  return (
    <div className="pb-24 px-4 pt-8 max-w-md mx-auto">
      {/* Header */}
      <div className="mb-8">
        <div className="bg-gradient-to-br from-emerald-500 via-teal-500 to-cyan-500 rounded-3xl p-6 text-white relative shadow-xl shadow-emerald-200/50">
          <div className="absolute top-6 right-6">
            <ProfileButton onClick={() => onNavigate('profile')} />
          </div>
          <Heart className="w-8 h-8 mb-3" />
          <h1 className="text-3xl mb-1">How are you feeling?</h1>
          <p className="opacity-90">Track your emotional state</p>
        </div>
      </div>

      {/* Mood Selector */}
      <Card className="mb-6 p-6 bg-white/60 backdrop-blur-sm">
        <h3 className="mb-4">Select your mood</h3>
        <div className="grid grid-cols-3 gap-3">
          {moods.map((mood) => (
            <button
              key={mood.id}
              onClick={() => setSelectedMood(mood.id)}
              className={`p-4 rounded-2xl transition-all ${
                selectedMood === mood.id
                  ? `bg-gradient-to-br ${mood.color} text-white scale-105`
                  : 'bg-accent/50 hover:bg-accent'
              }`}
            >
              <div className="text-4xl mb-2">{mood.emoji}</div>
              <div className="text-sm">{mood.label}</div>
            </button>
          ))}
        </div>
      </Card>

      {/* Note Input */}
      <Card className="mb-6 p-6 bg-white/60 backdrop-blur-sm">
        <h3 className="mb-3">What made you feel this way?</h3>
        <Textarea
          placeholder="Write your thoughts here..."
          value={note}
          onChange={(e) => setNote(e.target.value)}
          className="min-h-32 bg-white/80 rounded-2xl resize-none"
        />
      </Card>

      {/* Save Button */}
      <Button
        className="w-full h-14 rounded-2xl bg-gradient-to-r from-emerald-600 via-teal-600 to-cyan-600 hover:from-emerald-700 hover:via-teal-700 hover:to-cyan-700 mb-8 shadow-lg shadow-emerald-200"
        disabled={!selectedMood}
      >
        <Save className="w-5 h-5 mr-2" />
        Save Mood
      </Button>

      {/* Recent Moods */}
      <div>
        <div className="flex items-center gap-2 mb-4">
          <Clock className="w-5 h-5 text-muted-foreground" />
          <h3>Recent Entries</h3>
        </div>
        <div className="space-y-3">
          {recentMoods.map((entry, idx) => (
            <Card key={idx} className="p-4 bg-white/60 backdrop-blur-sm">
              <div className="flex items-start gap-3">
                <div className="text-3xl">{entry.mood}</div>
                <div className="flex-1">
                  <div className="flex justify-between items-start mb-1">
                    <span className="text-sm">{entry.label}</span>
                    <span className="text-xs text-muted-foreground">{entry.time}</span>
                  </div>
                  <p className="text-sm text-muted-foreground">{entry.note}</p>
                </div>
              </div>
            </Card>
          ))}
        </div>
      </div>
    </div>
  );
}
