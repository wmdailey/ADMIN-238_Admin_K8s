import http from 'k6/http';
import { check, sleep } from 'k6';

// Define the base URL using a host
const BASE_URL = 'http://perf-test:8080';
const MEMORY_SIZE = 10; // Allocate a safe 10MB per iteration

export const options = {
  // Scenario for a 1-hour soak test to check for stability and resource leaks
  scenarios: {
    memory_soak_test: {
      executor: 'ramping-vus',
      // ADJUSTED VUs: 6 VUs for stability over the long duration
      stages: [
        { duration: '5m', target: 6 },    // Ramp up to 6 VUs in 5 minutes
        { duration: '1h', target: 6 },    // Stay at 6 VUs for 1 hour (Soak period)
        { duration: '5m', target: 0 },    // Ramp down to 0 VUs in 5 minutes
      ],
      gracefulStop: '30s',
    },
  },
  // Thresholds: Very strict latency threshold reflecting the observed speed
  thresholds: {
    // 95% of requests must be under 100ms
    'http_req_duration': ['p(95)<100'], 
    // Max 1% failure rate
    'http_req_failed': ['rate<0.01'],    
  },
};

export default function () {
  // Hit the memory test endpoint
  const res = http.get(`${BASE_URL}/test-memory?mb=${MEMORY_SIZE}`);
  
  check(res, { 
    'status is 200': (r) => r.status === 200,
    // Check for expected confirmation text
    'body confirms allocation': (r) => r.body && r.body.includes(`Allocated ${MEMORY_SIZE} MB of memory`)
  });
  
  // ADJUSTED SLEEP: Increased to 2 seconds for stability
  sleep(2); 
}
