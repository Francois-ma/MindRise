import { MessageCircle, Bot, Users, Phone, Send, AlertCircle } from 'lucide-react';
import { Card } from '../ui/card';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Avatar, AvatarFallback } from '../ui/avatar';
import { Badge } from '../ui/badge';
import { ProfileButton } from '../ProfileButton';

interface SupportScreenProps {
  onNavigate: (screen: string) => void;
}

export function SupportScreen({ onNavigate }: SupportScreenProps) {
  const psychologists = [
    {
      name: 'Dr. Jules Aimable',
      specialization: 'Anxiety & Stress',
      availability: 'Available Now',
      avatar: 'SM',
      color: 'bg-blue-500',
    },
    {
      name: 'Dr. James Chen',
      specialization: 'Depression & Mood',
      availability: 'Available in 2h',
      avatar: 'JC',
      color: 'bg-purple-500',
    },
    {
      name: 'Dr. Emily Rodriguez',
      specialization: 'Trauma & PTSD',
      availability: 'Available Tomorrow',
      avatar: 'ER',
      color: 'bg-teal-500',
    },
    {
      name: 'Dr. Michael Park',
      specialization: 'Relationships',
      availability: 'Available Now',
      avatar: 'MP',
      color: 'bg-indigo-500',
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
          <MessageCircle className="w-8 h-8 mb-3" />
          <h1 className="text-3xl mb-1">Support</h1>
          <p className="opacity-90">Get help when you need it most</p>
        </div>
      </div>

      {/* AI Support */}
      <Card className="mb-6 p-6 bg-gradient-to-br from-emerald-50 via-teal-50 to-cyan-50 border-emerald-200 cursor-pointer hover:shadow-lg transition-shadow shadow-md shadow-emerald-100/50">
        <div className="flex items-start gap-4">
          <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-emerald-600 via-teal-600 to-cyan-600 flex items-center justify-center flex-shrink-0">
            <Bot className="w-6 h-6 text-white" />
          </div>
          <div className="flex-1">
            <h3 className="mb-1">AI Support</h3>
            <p className="text-sm text-muted-foreground mb-3">
              Chat with MindRise AI Coach for instant emotional support and guidance
            </p>
            <Badge className="bg-green-100 text-green-700 hover:bg-green-200">
              Available 24/7
            </Badge>
          </div>
        </div>
        <Button className="w-full mt-4 h-12 rounded-xl bg-gradient-to-r from-emerald-600 via-teal-600 to-cyan-600 hover:from-emerald-700 hover:via-teal-700 hover:to-cyan-700 shadow-lg shadow-emerald-200">
          <MessageCircle className="w-4 h-4 mr-2" />
          Start AI Chat
        </Button>
      </Card>

      {/* Professional Support */}
      <div className="mb-6">
        <div className="flex items-center gap-2 mb-4">
          <Users className="w-5 h-5 text-muted-foreground" />
          <h3>Licensed Psychologists</h3>
        </div>
        <p className="text-sm text-muted-foreground mb-4">
          Connect with certified mental health professionals for personalized support
        </p>
        <div className="space-y-3">
          {psychologists.map((psychologist, idx) => (
            <Card
              key={idx}
              className="p-4 bg-white/60 backdrop-blur-sm hover:shadow-lg transition-shadow cursor-pointer"
            >
              <div className="flex items-start gap-4">
                <Avatar className={`w-12 h-12 ${psychologist.color}`}>
                  <AvatarFallback className="text-white">
                    {psychologist.avatar}
                  </AvatarFallback>
                </Avatar>
                <div className="flex-1">
                  <h4 className="mb-1">{psychologist.name}</h4>
                  <p className="text-sm text-muted-foreground mb-2">
                    {psychologist.specialization}
                  </p>
                  <Badge
                    variant="outline"
                    className={
                      psychologist.availability === 'Available Now'
                        ? 'bg-green-50 text-green-700 border-green-200'
                        : 'bg-amber-50 text-amber-700 border-amber-200'
                    }
                  >
                    {psychologist.availability}
                  </Badge>
                </div>
                <Button
                  size="sm"
                  variant="outline"
                  className="rounded-xl border-emerald-200 text-emerald-700 hover:bg-emerald-50"
                >
                  Chat
                </Button>
              </div>
            </Card>
          ))}
        </div>
      </div>

      {/* Chat Interface Preview */}
      <Card className="mb-6 p-4 bg-white/60 backdrop-blur-sm">
        <h4 className="mb-3">Recent Messages</h4>
        <div className="space-y-3 mb-3">
          <div className="flex gap-2">
            <div className="w-8 h-8 rounded-full bg-purple-600 flex items-center justify-center flex-shrink-0">
              <Bot className="w-4 h-4 text-white" />
            </div>
            <div className="bg-accent/50 rounded-2xl rounded-tl-sm px-4 py-2 max-w-[80%]">
              <p className="text-sm">
                Hello! I'm here to listen. How are you feeling today?
              </p>
            </div>
          </div>
        </div>
        <div className="flex gap-2">
          <Input
            placeholder="Type your message..."
            className="flex-1 h-10 rounded-xl bg-white/80"
          />
          <Button size="icon" className="h-10 w-10 rounded-xl bg-emerald-600 hover:bg-emerald-700">
            <Send className="w-4 h-4" />
          </Button>
        </div>
      </Card>

      {/* Emergency Support */}
      <Card className="p-5 bg-gradient-to-br from-red-50 to-rose-50 border-red-100">
        <div className="flex gap-3 mb-4">
          <AlertCircle className="w-6 h-6 text-red-600 flex-shrink-0" />
          <div>
            <h4 className="mb-1 text-red-900">Need Urgent Help?</h4>
            <p className="text-sm text-red-800 mb-3">
              If you're experiencing a mental health crisis, immediate support is available
            </p>
          </div>
        </div>
        <div className="space-y-2">
          <Button className="w-full h-12 rounded-xl bg-gradient-to-r from-red-600 to-rose-600 hover:from-red-700 hover:to-rose-700">
            <Phone className="w-4 h-4 mr-2" />
            Call Crisis Hotline
          </Button>
          <Button variant="outline" className="w-full h-12 rounded-xl border-red-200 text-red-700 hover:bg-red-50">
            Emergency Resources
          </Button>
        </div>
      </Card>
    </div>
  );
}
