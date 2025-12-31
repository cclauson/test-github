import { Configuration, LogLevel } from '@azure/msal-browser';

// Declare injected config variables from webpack
declare const AUTH_CLIENT_ID: string;
declare const AUTH_AUTHORITY: string;

// Check if auth is configured
export const isAuthConfigured = (): boolean => {
  return Boolean(AUTH_CLIENT_ID && AUTH_AUTHORITY);
};

// MSAL configuration
export const msalConfig: Configuration = {
  auth: {
    clientId: AUTH_CLIENT_ID || 'not-configured',
    authority: AUTH_AUTHORITY || 'https://login.microsoftonline.com/common',
    redirectUri: window.location.origin,
    postLogoutRedirectUri: window.location.origin,
  },
  cache: {
    cacheLocation: 'sessionStorage',
    storeAuthStateInCookie: false,
  },
  system: {
    loggerOptions: {
      loggerCallback: (level, message, containsPii) => {
        if (containsPii) {
          return;
        }
        switch (level) {
          case LogLevel.Error:
            console.error(message);
            return;
          case LogLevel.Info:
            console.info(message);
            return;
          case LogLevel.Verbose:
            console.debug(message);
            return;
          case LogLevel.Warning:
            console.warn(message);
            return;
          default:
            return;
        }
      },
      logLevel: LogLevel.Warning,
    },
  },
};

// Scopes for login
export const loginRequest = {
  scopes: ['openid', 'profile', 'email'],
};
