import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = 'http://perf-test:8080';

export const options = {
  // Scenario for incrementally increasing stress
  scenarios: {
    stress_test: {
      executor: 'ramping-vus',
      // Start low, double VUs every 2 minutes
      stages: [
        { duration: '2m', target: 5 },    // Low load
        { duration: '2m', target: 10 },   // Medium load
        { duration: '2m', target: 20 },   // High load
        { duration: '2m', target: 50 },   // Very high load (stress) - Find the break point
        { duration: '1m', target: 0 },    // Ramp down
      ],
      gracefulStop: '30s',
    },
  },
  // Thresholds: Relaxed, as the goal is for the test to eventually break/fail.
  thresholds: {
    'http_req_duration': ['p(99)<5000'], // 99% of requests must be under 5 seconds
    'http_req_failed': ['rate<0.15'],    // Max 15% failure rate
  },
};

export default function () {
  const res = http.get(`${BASE_URL}/test-cpu`);
  
  // Added robust checks to prevent misleading failures
  check(res, { 
    'status is 200': (r) => r.status === 200,
    'body confirms task started': (r) => r.body && r.body.includes('Started a CPU performance test task')
  });

  // Increased sleep to 2 seconds for better stability in lower stages
  sleep(2);
}
