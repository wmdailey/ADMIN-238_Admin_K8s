import http from 'k6/http';
import { check, sleep } from 'k6';

// Using the MetalLB Load Balancer hostname
const BASE_URL = 'http://perf-test:8080';

export const options = {
  // Scenario for a rapid spike test
  scenarios: {
    spike_test: {
      executor: 'ramping-vus',
      // Start with a moderate baseline, spike aggressively, and check recovery.
      stages: [
        { duration: '30s', target: 10 },   // Baseline ramp up to 10 VUs
        { duration: '5s', target: 50 },    // RAPID SPIKE to 50 VUs in 5 seconds (Extreme Overload)
        { duration: '1m', target: 50 },    // Maintain spike for 1 minute
        { duration: '10s', target: 10 },   // Rapid return to baseline
        { duration: '30s', target: 0 },    // Final ramp down
      ],
      gracefulStop: '5s',
    },
  },
  // Thresholds: Relaxed to account for performance degradation and transient errors during the spike
  thresholds: {
    // Allowing up to 3 seconds for 95% of requests during the spike
    'http_req_duration': ['p(95)<3000'], 
    // Allowing up to 10% failure rate during the spike (to ensure service doesn't crash completely)
    'http_req_failed': ['rate<0.10'],    
  },
};

export default function () {
  // Hit the CPU test endpoint
  const res = http.get(`${BASE_URL}/test-cpu`);

  check(res, { 
    'status is 200': (r) => r.status === 200,
    // Check for the CPU task confirmation text
    'body confirms task started': (r) => r.body && r.body.includes('Started a CPU performance test task')
  });
  
  // Using 1-second sleep to increase the intensity of the spike
  sleep(1);
}
