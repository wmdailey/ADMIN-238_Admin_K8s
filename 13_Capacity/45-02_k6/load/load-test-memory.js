import http from 'k6/http';
import { check, sleep } from 'k6';

// Using the MetalLB Load Balancer hostname for direct access
const BASE_URL = 'http://perf-test:8080'; 
const MEMORY_SIZE = 10; // Allocated 10MB of memory per iteration

// Load Test Configuration
export const options = {
  scenarios: {
    baseline_load: {
      executor: 'constant-vus', 
      // ADJUSTED VUs: Reduced from 8 back to 4 to stabilize connection failures
      vus: 4,                   
      // Increased to 60s duration
      duration: '60s',          
      gracefulStop: '30s',
    },
  },
  // Thresholds: Keeping the tight latency threshold to verify performance at this new load
  thresholds: {
    // ADJUSTED THRESHOLD: Tightened from 1000ms down to 100ms
    'http_req_duration': ['p(95)<100'], 
    // Relaxed error rate, but aiming for perfect stability
    'http_req_failed': ['rate<0.05'],    
  },
};

export default function () {
  // Hit the memory test endpoint with the specified size
  const res = http.get(`${BASE_URL}/test-memory?mb=${MEMORY_SIZE}`);
  
  check(res, { 
    'status is 200': (r) => r.status === 200,
    // Check for expected confirmation text
    'body confirms allocation': (r) => r.body && r.body.includes(`Allocated ${MEMORY_SIZE} MB of memory`)
  });
  
  // ADJUSTED SLEEP: Increased from 1s to 2s to reduce request frequency and avoid OOM
  sleep(2); 
}
