import { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import {
  clearStoredAuth,
  fetchCurrentUser,
  loginAccount,
  logoutAccount,
  readStoredAuth,
  saveStoredAuth,
  subscribeToAuthSession,
} from './api';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [session, setSession] = useState(() => readStoredAuth());
  const [user, setUser] = useState(() => readStoredAuth()?.user || null);
  const [loading, setLoading] = useState(() => Boolean(readStoredAuth()?.access));

  const applyAuthResponse = useCallback((payload) => {
    const nextSession = {
      access: payload?.access || payload?.access_token,
      refresh: payload?.refresh || payload?.refresh_token,
      user: payload?.user || null,
    };

    if (!nextSession.access || !nextSession.refresh || !nextSession.user) {
      throw new Error('MindRise could not complete the authenticated web session.');
    }

    saveStoredAuth(nextSession);
    setSession(nextSession);
    setUser(nextSession.user);
    return nextSession.user;
  }, []);

  useEffect(() => subscribeToAuthSession((nextSession) => {
    setSession(nextSession);
    setUser(nextSession?.user || null);
  }), []);

  const logout = useCallback(async () => {
    const stored = readStoredAuth();
    clearStoredAuth();
    setSession(null);
    setUser(null);

    if (stored?.refresh) {
      try {
        await logoutAccount(stored.refresh, stored.access);
      } catch {
        // Local logout should still complete if the server token is already invalid.
      }
    }
  }, []);

  useEffect(() => {
    let cancelled = false;
    const stored = readStoredAuth();
    if (!stored?.access) {
      setLoading(false);
      return undefined;
    }

    setLoading(true);
    fetchCurrentUser(stored.access)
      .then((profile) => {
        if (cancelled) return;
        const latestStored = readStoredAuth();
        const nextSession = { ...(latestStored || stored), user: profile };
        saveStoredAuth(nextSession);
        setSession(nextSession);
        setUser(profile);
      })
      .catch(() => {
        if (!cancelled) void logout();
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [logout]);

  const updateUser = useCallback((profile) => {
    const stored = readStoredAuth();
    if (stored) saveStoredAuth({ ...stored, user: profile });
    setUser(profile);
    return profile;
  }, []);

  const login = useCallback(
    async ({ email, password }) => {
      const payload = await loginAccount({ email, password });
      return applyAuthResponse(payload);
    },
    [applyAuthResponse],
  );

  const value = useMemo(
    () => ({
      accessToken: session?.access || '',
      refreshToken: session?.refresh || '',
      user,
      loading,
      isAuthenticated: Boolean(session?.access && user?.is_email_verified),
      applyAuthResponse,
      updateUser,
      login,
      logout,
    }),
    [applyAuthResponse, loading, login, logout, session?.access, session?.refresh, updateUser, user],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used inside AuthProvider.');
  }
  return context;
}
