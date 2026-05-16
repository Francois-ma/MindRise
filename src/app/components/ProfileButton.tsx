import { Avatar, AvatarFallback } from './ui/avatar';

interface ProfileButtonProps {
  onClick?: () => void;
}

export function ProfileButton({ onClick }: ProfileButtonProps) {
  return (
    <button
      onClick={onClick}
      className="w-10 h-10 rounded-full bg-white/20 backdrop-blur-sm hover:bg-white/30 transition-all flex items-center justify-center"
    >
      <Avatar className="w-10 h-10 bg-white/90">
        <AvatarFallback className="bg-gradient-to-br from-emerald-600 via-teal-600 to-cyan-600 text-white">
          F
        </AvatarFallback>
      </Avatar>
    </button>
  );
}
