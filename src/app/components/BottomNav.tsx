import { Home, Heart, BarChart3, Wind, BookOpen, MessageCircle } from 'lucide-react';
import appIcon from '../../imports/icon.jpeg';

interface BottomNavProps {
  active: string;
  onNavigate: (screen: string) => void;
}

export function BottomNav({ active, onNavigate }: BottomNavProps) {
  const navItems = [
    { id: 'home', label: 'Home', icon: Home },
    { id: 'mood', label: 'Mood', icon: Heart },
    { id: 'insights', label: 'Insights', icon: BarChart3 },
    { id: 'reset', label: 'Reset', icon: Wind },
    { id: 'learn', label: 'Learn', icon: BookOpen },
    { id: 'support', label: 'Support', icon: MessageCircle },
  ];

  return (
    <nav className="fixed bottom-0 left-0 right-0 bg-white/80 backdrop-blur-lg border-t border-border">
      <div className="max-w-md mx-auto px-4 py-2">
        <div className="flex items-center justify-center mb-1">
          <img src={appIcon} alt="MindRise" className="w-8 h-8 rounded-xl" />
        </div>
        <div className="flex justify-around items-center">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = active === item.id;
            return (
              <button
                key={item.id}
                onClick={() => onNavigate(item.id)}
                className="flex flex-col items-center gap-1 px-3 py-2 rounded-xl transition-all"
              >
                <Icon
                  className={`w-5 h-5 transition-colors ${
                    isActive
                      ? 'text-emerald-600'
                      : 'text-muted-foreground'
                  }`}
                />
                <span
                  className={`text-[10px] transition-colors ${
                    isActive
                      ? 'text-emerald-600'
                      : 'text-muted-foreground'
                  }`}
                >
                  {item.label}
                </span>
              </button>
            );
          })}
        </div>
      </div>
    </nav>
  );
}
