// This k6 script performs a soak test (also known as an endurance test).
// Its purpose is to test the application's stability and performance over a long period,
// helping to identify potential issues like memory leaks.

import http from 'k6/http';
import { check, sleep } from 'k6';

// Define the test options. The key for a soak test is a long duration.
export let options = {
  // Use a 'ramping-vus' executor to simulate a gradual increase in users
  // followed by a long period of sustained load.
  scenarios: {
    soak_scenario: {
      executor: 'ramping-vus',
      // Start with 0 users.
      startVUs: 0,
      // Stages define the load profile over time.
      stages: [
        // Ramp up to 20 concurrent VUs over 5 minutes.
        { duration: '5m', target: 20 },
        // Stay at 20 VUs for 4 hours. This is the "soak" period.
        { duration: '4h', target: 20 },
        // Ramp down to 0 VUs over 5 minutes to end the test gracefully.
        { duration: '5m', target: 0 },
      ],
      gracefulRampDown: '30s',
    },
  },
  thresholds: {
    // We expect a very low failure rate over a long period. A rising failure rate
    // could indicate a resource exhaustion issue.
    'http_req_failed': ['rate<0.01'], // Less than 1% of requests should fail.
    // Response times should remain stable. A gradual increase in duration
    // is a classic sign of a memory leak.
    'http_req_duration': ['p(95)<1000'], // 95% of requests must complete within 1 second.
  },
};

// The default function is the entry point for each virtual user.
export default function () {
  const url = 'http://localhost:8080/test-memory';

  // Perform a GET request to the memory-incrementing endpoint.
  const res = http.get(url, {
    tags: { name: 'MemorySoakRequest' },
  });

  // Check if the response status is 200. This helps monitor the service's health.
  check(res, {
    'is status 200': (r) => r.status === 200,
  });

  // Pause for a short duration between requests to simulate user think time.
  sleep(1); // Sleep for 1 second.
}

