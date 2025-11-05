// Simple k6 smoke test for the Web App
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  vus: 5,
  duration: '30s',
};

export default function () {
  const url = __ENV.APP_URL || 'https://example.azurewebsites.net/';
  let res = http.get(url);

  check(res, {
    'status is 200': (r) => r.status === 200,
    'ttfb < 800ms': (r) => r.timings.waiting < 800,
  });

  sleep(1);
}
