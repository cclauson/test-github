import React from 'react';
import { useIsAuthenticated, useMsal } from '@azure/msal-react';
import logo from './logo.svg';
import './App.css';
import { isAuthConfigured } from './authConfig';

function AuthenticatedContent() {
  const { accounts, instance } = useMsal();
  const account = accounts[0];

  const handleLogout = () => {
    instance.logoutRedirect();
  };

  return (
    <>
      <div className="auth-section">
        <span className="user-name">{account?.name || account?.username}</span>
        <button onClick={handleLogout} className="auth-button logout">
          Sign Out
        </button>
      </div>
      <img src={logo} className="App-logo" alt="logo" />
      <div className="user-info">
        <h3>Welcome, {account?.name || 'User'}!</h3>
        <p>Email: {account?.username}</p>
      </div>
    </>
  );
}

function UnauthenticatedContent() {
  return (
    <>
      <img src={logo} className="App-logo" alt="logo" />
      <p>Signing you in...</p>
    </>
  );
}

function NoAuthContent() {
  return (
    <>
      <img src={logo} className="App-logo" alt="logo" />
      <p>
        Edit <code>src/App.tsx</code> and save to reload.
      </p>
      <p className="auth-notice">
        Authentication not configured. Run init.ps1 to configure.
      </p>
    </>
  );
}

function AppContent() {
  const isAuthenticated = useIsAuthenticated();

  if (!isAuthConfigured()) {
    return <NoAuthContent />;
  }

  return isAuthenticated ? <AuthenticatedContent /> : <UnauthenticatedContent />;
}

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <AppContent />
        <a
          className="App-link"
          href="https://reactjs.org"
          target="_blank"
          rel="noopener noreferrer"
        >
          Learn React
        </a>
      </header>
    </div>
  );
}

export default App;
