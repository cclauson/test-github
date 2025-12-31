import React from 'react';
import ReactDOM from 'react-dom/client';
import { PublicClientApplication } from '@azure/msal-browser';
import { MsalProvider } from '@azure/msal-react';
import './index.css';
import App from './App';
import reportWebVitals from './reportWebVitals';
import { ApplicationInsights } from '@microsoft/applicationinsights-web';
import { msalConfig, isAuthConfigured } from './authConfig';

// Initialize MSAL instance (only if auth is configured)
const msalInstance = new PublicClientApplication(msalConfig);

const root = ReactDOM.createRoot(
  document.getElementById('root') as HTMLElement
);

// Wrap app with MsalProvider if auth is configured
const AppWithAuth = () => {
  if (isAuthConfigured()) {
    return (
      <MsalProvider instance={msalInstance}>
        <App />
      </MsalProvider>
    );
  }
  return <App />;
};

root.render(
  <React.StrictMode>
    <AppWithAuth />
  </React.StrictMode>
);

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
