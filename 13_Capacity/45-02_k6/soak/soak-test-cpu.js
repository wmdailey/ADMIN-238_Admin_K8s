import http from 'k6/http';
import { check, sleep } from 'k6';

// Using the MetalLB Load Balancer hostname
const BASE_URL = 'http://perf-test:8080';

export const options = {
  // Scenario for a 2-hour soak test
  scenarios: {
    soak_test: {
      executor: 'ramping-vus',
      // ADJUSTED VUs: Reduced from 10 to 6 for stability over the long duration
      stages: [
        { duration: '5m', target: 6 },    // Ramp up to 6 VUs in 5 minutes
        { duration: '2h', target: 6 },    // Stay at 6 VUs for 2 hours (Soak Period)
        { duration: '5m', target: 0 },    // Ramp down to 0 VUs in 5 minutes
      ],
      gracefulStop: '30s',
    },
  },
  // Thresholds: Tightened for performance check, but still realistic
  thresholds: {
    // 95% of requests must be under 500ms
    'http_req_duration': ['p(95)<500'], 
    // Max 1% failure rate for stability check
    'http_req_failed': ['rate<0.01'],    
  },
};

export default function () {
  const res = http.get(`${BASE_URL}/test-cpu`);
  check(res, { 
    'status is 200': (r) => r.status === 200,
    'body confirms task started': (r) => r.body && r.body.includes('Started a CPU performance test task')
  });
  // ADJUSTED SLEEP: Increased to 2 seconds for stability
  sleep(2); 
}
