import React from 'react';
import logo from './logo.svg';
import './App.css';
import { AuthButton, UserInfo } from './components/AuthButton';
import { isAuthConfigured } from './authConfig';

function App() {
  const authEnabled = isAuthConfigured();

  return (
    <div className="App">
      <header className="App-header">
        {authEnabled && (
          <div className="auth-section">
            <AuthButton />
          </div>
        )}
        <img src={logo} className="App-logo" alt="logo" />
        {authEnabled ? (
          <UserInfo />
        ) : (
          <p>
            Edit <code>src/App.tsx</code> and save to reload.
          </p>
        )}
        {!authEnabled && (
          <p className="auth-notice">
            Authentication not configured. Run init.ps1 with External ID parameters.
          </p>
        )}
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
