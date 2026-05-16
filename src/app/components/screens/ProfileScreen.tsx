import { User, Settings, Bell, Lock, HelpCircle, LogOut, ChevronRight, Award, Calendar, Heart, Edit } from 'lucide-react';
import { Card } from '../ui/card';
import { Button } from '../ui/button';
import { Avatar, AvatarFallback } from '../ui/avatar';
import { Switch } from '../ui/switch';
import { Separator } from '../ui/separator';

interface ProfileScreenProps {
  onNavigate: (screen: string) => void;
  onLogout: () => void;
}

export function ProfileScreen({ onNavigate, onLogout }: ProfileScreenProps) {
  const stats = [
    { label: 'Current Streak', value: '7 days', icon: Award, color: 'text-orange-600' },
    { label: 'Total Entries', value: '42', icon: Calendar, color: 'text-blue-600' },
    { label: 'Mood Average', value: '7.2/10', icon: Heart, color: 'text-pink-600' },
  ];

  const settingsSections = [
    {
      title: 'Preferences',
      items: [
        { icon: Bell, label: 'Notifications', toggle: true, value: true },
        { icon: Calendar, label: 'Daily Reminders', toggle: true, value: true },
        { icon: Settings, label: 'App Settings', toggle: false },
      ],
    },
    {
      title: 'Account',
      items: [
        { icon: Lock, label: 'Privacy & Security', toggle: false },
        { icon: User, label: 'Personal Information', toggle: false },
      ],
    },
    {
      title: 'Support',
      items: [
        { icon: HelpCircle, label: 'Help Center', toggle: false },
      ],
    },
  ];

  return (
    <div className="pb-24 px-4 pt-8 max-w-md mx-auto">
      {/* Header */}
      <div className="mb-8">
        <div className="bg-gradient-to-br from-emerald-500 via-teal-500 to-cyan-500 rounded-3xl p-6 text-white relative shadow-xl shadow-emerald-200/50">
          <button
            onClick={() => onNavigate('home')}
            className="absolute top-6 left-6 text-white/80 hover:text-white"
          >
            ← Back
          </button>
          <div className="flex flex-col items-center pt-6">
            <div className="relative mb-4">
              <Avatar className="w-24 h-24 bg-white/90">
                <AvatarFallback className="bg-gradient-to-br from-emerald-600 via-teal-600 to-cyan-600 text-white text-3xl">
                  F
                </AvatarFallback>
              </Avatar>
              <button className="absolute bottom-0 right-0 w-8 h-8 bg-white rounded-full flex items-center justify-center shadow-lg hover:scale-110 transition-transform">
                <Edit className="w-4 h-4 text-emerald-600" />
              </button>
            </div>
            <h1 className="text-2xl mb-1">Francois</h1>
            <p className="opacity-90">francois@mindrise.com</p>
          </div>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-3 gap-3 mb-6">
        {stats.map((stat, idx) => {
          const Icon = stat.icon;
          return (
            <Card key={idx} className="p-4 bg-white/60 backdrop-blur-sm text-center">
              <Icon className={`w-5 h-5 mx-auto mb-2 ${stat.color}`} />
              <div className="text-xl mb-1">{stat.value}</div>
              <div className="text-xs text-muted-foreground">{stat.label}</div>
            </Card>
          );
        })}
      </div>

      {/* Settings Sections */}
      <div className="space-y-6">
        {settingsSections.map((section, idx) => (
          <div key={idx}>
            <h3 className="mb-3 text-muted-foreground">{section.title}</h3>
            <Card className="p-2 bg-white/60 backdrop-blur-sm">
              {section.items.map((item, itemIdx) => {
                const Icon = item.icon;
                return (
                  <div key={itemIdx}>
                    <button className="w-full flex items-center justify-between p-4 hover:bg-accent/50 rounded-xl transition-colors">
                      <div className="flex items-center gap-3">
                        <Icon className="w-5 h-5 text-muted-foreground" />
                        <span>{item.label}</span>
                      </div>
                      {item.toggle ? (
                        <Switch defaultChecked={item.value} />
                      ) : (
                        <ChevronRight className="w-5 h-5 text-muted-foreground" />
                      )}
                    </button>
                    {itemIdx < section.items.length - 1 && (
                      <Separator className="mx-4" />
                    )}
                  </div>
                );
              })}
            </Card>
          </div>
        ))}
      </div>

      {/* Logout Button */}
      <Button
        variant="outline"
        onClick={onLogout}
        className="w-full h-14 rounded-2xl mt-6 text-destructive border-destructive/30 hover:bg-destructive/10"
      >
        <LogOut className="w-5 h-5 mr-2" />
        Log Out
      </Button>

      {/* App Version */}
      <p className="text-center text-xs text-muted-foreground mt-6">
        MindRise v1.0.0
      </p>
    </div>
  );
}
