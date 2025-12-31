import React from 'react';
import { useMsal, useIsAuthenticated } from '@azure/msal-react';
import { loginRequest } from '../authConfig';

export const AuthButton: React.FC = () => {
  const { instance, accounts } = useMsal();
  const isAuthenticated = useIsAuthenticated();

  const handleLogin = () => {
    instance.loginPopup(loginRequest).catch((error) => {
      console.error('Login failed:', error);
    });
  };

  const handleLogout = () => {
    instance.logoutPopup().catch((error) => {
      console.error('Logout failed:', error);
    });
  };

  if (isAuthenticated) {
    const account = accounts[0];
    return (
      <div className="auth-container">
        <span className="user-name">
          {account?.name || account?.username || 'User'}
        </span>
        <button onClick={handleLogout} className="auth-button logout">
          Sign Out
        </button>
      </div>
    );
  }

  return (
    <button onClick={handleLogin} className="auth-button login">
      Sign In
    </button>
  );
};

export const UserInfo: React.FC = () => {
  const { accounts } = useMsal();
  const isAuthenticated = useIsAuthenticated();

  if (!isAuthenticated) {
    return (
      <div className="user-info">
        <p>You are not signed in.</p>
        <p>Sign in to access personalized features.</p>
      </div>
    );
  }

  const account = accounts[0];
  return (
    <div className="user-info">
      <h3>Welcome, {account?.name || 'User'}!</h3>
      <p>Email: {account?.username}</p>
    </div>
  );
};
