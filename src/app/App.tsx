import { useState } from 'react';
import { BottomNav } from './components/BottomNav';
import { HomeScreen } from './components/screens/HomeScreen';
import { MoodScreen } from './components/screens/MoodScreen';
import { InsightsScreen } from './components/screens/InsightsScreen';
import { ResetScreen } from './components/screens/ResetScreen';
import { LearnScreen } from './components/screens/LearnScreen';
import { SupportScreen } from './components/screens/SupportScreen';
import { ProfileScreen } from './components/screens/ProfileScreen';
import { LoginScreen } from './components/screens/LoginScreen';
import { SignupScreen } from './components/screens/SignupScreen';

export default function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [authScreen, setAuthScreen] = useState<'login' | 'signup'>('login');
  const [activeScreen, setActiveScreen] = useState('home');

  const handleLogin = () => {
    setIsAuthenticated(true);
  };

  const handleSignup = () => {
    setIsAuthenticated(true);
  };

  const handleLogout = () => {
    setIsAuthenticated(false);
    setAuthScreen('login');
    setActiveScreen('home');
  };

  // Show auth screens if not authenticated
  if (!isAuthenticated) {
    return (
      <div className="min-h-screen">
        <div className="max-w-md mx-auto min-h-screen">
          {authScreen === 'login' ? (
            <LoginScreen
              onLogin={handleLogin}
              onNavigateToSignup={() => setAuthScreen('signup')}
            />
          ) : (
            <SignupScreen
              onSignup={handleSignup}
              onNavigateToLogin={() => setAuthScreen('login')}
            />
          )}
        </div>
      </div>
    );
  }

  const renderScreen = () => {
    switch (activeScreen) {
      case 'home':
        return <HomeScreen onNavigate={setActiveScreen} />;
      case 'mood':
        return <MoodScreen onNavigate={setActiveScreen} />;
      case 'insights':
        return <InsightsScreen onNavigate={setActiveScreen} />;
      case 'reset':
        return <ResetScreen onNavigate={setActiveScreen} />;
      case 'learn':
        return <LearnScreen onNavigate={setActiveScreen} />;
      case 'support':
        return <SupportScreen onNavigate={setActiveScreen} />;
      case 'profile':
        return <ProfileScreen onNavigate={setActiveScreen} onLogout={handleLogout} />;
      default:
        return <HomeScreen onNavigate={setActiveScreen} />;
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-emerald-50 via-yellow-50 to-sky-50">
      <div className="max-w-md mx-auto bg-white/40 backdrop-blur-sm min-h-screen">
        {renderScreen()}
        {activeScreen !== 'profile' && (
          <BottomNav active={activeScreen} onNavigate={setActiveScreen} />
        )}
      </div>
    </div>
  );
}
