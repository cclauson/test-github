import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css';
import App from './App';
import reportWebVitals from './reportWebVitals';
import { ApplicationInsights } from '@microsoft/applicationinsights-web'

const root = ReactDOM.createRoot(
  document.getElementById('root') as HTMLElement
);
root.render(
  <React.StrictMode>
    <App />
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
    metricRating: metric.rating,
  });
});
