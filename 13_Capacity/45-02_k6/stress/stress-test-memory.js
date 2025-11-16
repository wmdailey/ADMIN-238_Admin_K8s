import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = 'http://perf-test:8080';
const MEMORY_SIZE = 10; // Allocate a safe 10MB per iteration

export const options = {
  // Scenario for incrementally increasing stress
  scenarios: {
    stress_test: {
      executor: 'ramping-vus',
      // Significantly reduced and gentler ramp-up to find the breaking point
      stages: [
        { duration: '5m', target: 2 },    // Low load (5 minutes)
        { duration: '5m', target: 4 },    // Medium load (5 minutes)
        { duration: '5m', target: 7 },    // High load (5 minutes)
        { duration: '5m', target: 10 },   // Stress load (Find the break point)
        { duration: '1m', target: 0 },    // Ramp down
      ],
      gracefulStop: '30s',
    },
  },
  // Thresholds: Still relaxed, as the goal is to observe where the system breaks.
  thresholds: {
    // Allowing up to 5 seconds latency before system break
    'http_req_duration': ['p(99)<5000'],
    // Max 15% failure rate
    'http_req_failed': ['rate<0.15'],
  },
};

export default function () {
  // Hit the memory test endpoint
  const res = http.get(`${BASE_URL}/test-memory?mb=${MEMORY_SIZE}`);

  // Robust checks
  check(res, {
    'status is 200': (r) => r.status === 200,
    'body confirms allocation': (r) => r.body && r.body.includes(`Allocated ${MEMORY_SIZE} MB of memory`)
  });

  // Increased sleep to 2 seconds for stability
  sleep(2);
}
