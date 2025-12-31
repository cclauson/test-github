import React from 'react';
import ReactDOM from 'react-dom/client';
import { PublicClientApplication, InteractionRequiredAuthError } from '@azure/msal-browser';
import { MsalProvider } from '@azure/msal-react';
import './index.css';
import App from './App';
import reportWebVitals from './reportWebVitals';
import { ApplicationInsights } from '@microsoft/applicationinsights-web';
import { msalConfig, loginRequest, isAuthConfigured } from './authConfig';

// Initialize MSAL instance
const msalInstance = new PublicClientApplication(msalConfig);

const root = ReactDOM.createRoot(
  document.getElementById('root') as HTMLElement
);

// Initialize auth and render app
async function initializeApp() {
  if (isAuthConfigured()) {
    try {
      // Initialize MSAL before any other calls
      await msalInstance.initialize();

      // Handle redirect response (if returning from login)
      const response = await msalInstance.handleRedirectPromise();

      if (response) {
        // User just logged in via redirect
        console.log('Login successful:', response.account?.username);
      } else {
        // Check if user is already signed in
        const accounts = msalInstance.getAllAccounts();

        if (accounts.length === 0) {
          // No user signed in - try silent SSO first, then redirect
          try {
            await msalInstance.ssoSilent(loginRequest);
          } catch (error) {
            if (error instanceof InteractionRequiredAuthError) {
              // Silent SSO failed - redirect to login
              console.log('No active session, redirecting to login...');
              await msalInstance.loginRedirect(loginRequest);
              return; // Don't render yet, will redirect
            }
            throw error;
          }
        }
      }
    } catch (error) {
      console.error('Auth initialization error:', error);
    }
  }

  // Render the app
  root.render(
    <React.StrictMode>
      {isAuthConfigured() ? (
        <MsalProvider instance={msalInstance}>
          <App />
        </MsalProvider>
      ) : (
        <App />
      )}
    </React.StrictMode>
  );
}

initializeApp();

// App insights: TODO: Reorg this
declare const APP_INSIGHTS_CONNECTION_STRING: string;
const appInsights = new ApplicationInsights({ config: {
  connectionString: APP_INSIGHTS_CONNECTION_STRING,
  /* ...Other Configuration Options... */
} });
appInsights.loadAppInsights();
appInsights.trackPageView();


// Send Web Vitals metrics to Application Insights
reportWebVitals((metric) => {
  appInsights.trackMetric({
    name: metric.name,
    average: metric.value,
  }, {
    metricId: metric.id,
    delta: metric.delta.toString(),
  });
});
