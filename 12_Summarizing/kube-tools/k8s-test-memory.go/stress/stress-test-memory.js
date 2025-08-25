// This script performs a stress test on a given endpoint to simulate memory usage.

import http from 'k6/http';
import { check, sleep } from 'k6';

// Define the test options. This configuration sets up a basic stress test.
export let options = {
  // Define stages for the test. This example ramps up to 10 virtual users (VUs) over 10 seconds,
  // stays at 10 VUs for 20 seconds, and then ramps down to 0 VUs over 10 seconds.
  stages: [
    { duration: '10s', target: 10 }, // Ramp up to 10 VUs
    { duration: '20s', target: 10 }, // Stay at 10 VUs
    { duration: '10s', target: 0 },  // Ramp down to 0 VUs
  ],
  thresholds: {
    // We want the request duration to be fast, so we set a threshold.
    // 95% of requests must complete within 250ms.
    'http_req_duration': ['p(95)<250'],
    // We want all requests to be successful, so we check for a 200 status code.
    'http_req_failed': ['rate<0.01'], // less than 1% of requests should fail
  },
};

// The default function is the entry point for each virtual user (VU).
export default function () {
  const url = 'http://localhost:8080/test-memory';

  // Make an HTTP GET request to the target URL.
  const res = http.get(url);

  // Check if the response status is 200. If it's not, the check will fail and will be logged.
  check(res, {
    'is status 200': (r) => r.status === 200,
  });

  // Pause for 1 second between requests to simulate user think time.
  sleep(1);
}

