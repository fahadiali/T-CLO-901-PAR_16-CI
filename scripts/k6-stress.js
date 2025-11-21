// Enhanced k6 stress test script for IaaS vs PaaS comparison
import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';
import { htmlReport } from 'https://raw.githubusercontent.com/benc-uk/k6-reporter/main/dist/bundle.js';
import { textSummary } from 'https://jslib.k6.io/k6-summary/0.0.1/index.js';

// Custom metrics
const errorRate = new Rate('errors');
const httpReqDuration = new Trend('http_req_duration');
const httpReqCounter = new Counter('http_reqs_total');

// Test configuration from environment variables
const APP_URL = __ENV.APP_URL || 'http://localhost';
const TEST_SCENARIO = __ENV.SCENARIO || 'smoke'; // smoke, load, stress, spike, endurance
const TEST_DURATION = __ENV.DURATION || '30s';
const VUS = parseInt(__ENV.VUS || '5');

// Scenario configurations
const scenarios = {
  smoke: {
    executor: 'shared-iterations',
    vus: 5,
    iterations: 10,
    maxDuration: '30s',
  },
  load: {
    executor: 'ramping-vus',
    startVUs: 0,
    stages: [
      { duration: '1m', target: 20 },   // Ramp up to 20 users
      { duration: '3m', target: 20 },   // Stay at 20 users
      { duration: '1m', target: 0 },    // Ramp down to 0 users
    ],
    gracefulRampDown: '30s',
  },
  stress: {
    executor: 'ramping-vus',
    startVUs: 0,
    stages: [
      { duration: '2m', target: 50 },   // Ramp up to 50 users
      { duration: '3m', target: 50 },   // Stay at 50 users
      { duration: '2m', target: 100 },  // Increase to 100 users
      { duration: '3m', target: 100 },  // Stay at 100 users
      { duration: '2m', target: 0 },    // Ramp down to 0 users
    ],
    gracefulRampDown: '30s',
  },
  spike: {
    executor: 'ramping-vus',
    startVUs: 0,
    stages: [
      { duration: '30s', target: 10 },  // Normal load
      { duration: '30s', target: 100 }, // Spike to 100 users
      { duration: '1m', target: 100 },  // Stay at spike
      { duration: '30s', target: 10 },  // Back to normal
      { duration: '1m', target: 10 },   // Stay at normal
      { duration: '30s', target: 0 },   // Ramp down
    ],
    gracefulRampDown: '30s',
  },
  endurance: {
    executor: 'constant-vus',
    vus: 20,
    duration: '10m', // 10 minutes of constant load
  },
};

// Select scenario based on TEST_SCENARIO
export const options = {
  scenarios: {
    main: scenarios[TEST_SCENARIO] || scenarios.smoke,
  },
  thresholds: {
    http_req_duration: ['p(50)<500', 'p(95)<1000', 'p(99)<2000'], // 50% < 500ms, 95% < 1s, 99% < 2s
    http_req_failed: ['rate<0.05'], // Error rate < 5%
    errors: ['rate<0.05'], // Custom error rate < 5%
  },
  summaryTrendStats: ['avg', 'min', 'med', 'max', 'p(50)', 'p(90)', 'p(95)', 'p(99)', 'p(99.9)', 'p(99.99)', 'count'],
};

// Setup function (runs once before all VUs)
export function setup() {
  console.log(`Starting ${TEST_SCENARIO} test against ${APP_URL}`);
  console.log(`Scenario: ${JSON.stringify(scenarios[TEST_SCENARIO])}`);
  
  // Check if application is reachable
  const healthCheck = http.get(`${APP_URL}`, { timeout: '10s' });
  if (healthCheck.status !== 200 && healthCheck.status !== 302) {
    throw new Error(`Application not reachable at ${APP_URL}. Status: ${healthCheck.status}`);
  }
  
  return { baseUrl: APP_URL };
}

// Main test function (runs for each VU iteration)
export default function (data) {
  const baseUrl = data.baseUrl;
  let success = true;

  group('Homepage', () => {
    const response = http.get(baseUrl, {
      tags: { name: 'Homepage' },
      timeout: '10s',
    });

    const checks = check(response, {
      'status is 200 or 302': (r) => r.status === 200 || r.status === 302,
      'response time < 2s': (r) => r.timings.duration < 2000,
      'response has content': (r) => r.body && r.body.length > 0,
    });

    if (!checks['status is 200 or 302']) {
      errorRate.add(1);
      success = false;
    } else {
      errorRate.add(0);
    }

    httpReqDuration.add(response.timings.duration);
    httpReqCounter.add(1);
  });

  // Test API endpoints if available
  group('API Endpoints', () => {
    // Test API root
    const apiResponse = http.get(`${baseUrl}/api`, {
      tags: { name: 'API' },
      timeout: '10s',
    });

    const apiChecks = check(apiResponse, {
      'API responds': (r) => r.status >= 200 && r.status < 500,
    });

    if (!apiChecks['API responds'] || apiResponse.status >= 400) {
      errorRate.add(1);
      success = false;
    }
  });

  // Add think time between requests (simulate user behavior)
  sleep(Math.random() * 2 + 1); // Random sleep between 1-3 seconds

  return success;
}

// Teardown function (runs once after all VUs)
export function teardown(data) {
  console.log('Test completed');
}

// Handle summary data
export function handleSummary(data) {
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
    'summary.json': JSON.stringify(data, null, 2),
    'summary.html': htmlReport(data),
  };
}

