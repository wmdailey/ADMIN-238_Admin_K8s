import http from 'k6/http';
import { check, sleep } from 'k6';
//spike-test-cpu

// Options for the spike test. We define stages that simulate a sudden surge in traffic.
export let options = {
  // Define the stages for the test.
  // This is where we control the number of virtual users (VUs) over time.
  stages: [
    { duration: '30s', target: 20 },  // Stage 1: Ramp up to a baseline load of 20 VUs in 30 seconds.
    { duration: '10s', target: 100 }, // Stage 2: Spike! Immediately ramp up to 100 VUs in just 10 seconds.
    { duration: '1m', target: 100 },  // Stage 3: Hold the spike for 1 minute.
    { duration: '10s', target: 20 },  // Stage 4: Ramp down from the spike to the baseline load.
    { duration: '30s', target: 20 },  // Stage 5: Hold at the baseline for recovery analysis.
    { duration: '10s', target: 0 },   // Stage 6: Ramp down to 0 VUs.
  ],
  // Ignore checks to continue execution even if requests fail, as we expect errors
  // to occur as the system breaks.
  noConnectionReuse: false,
};

// The main function that k6 executes for each virtual user.
export default function () {
  // Send a GET request to the CPU-intensive endpoint.
  // The URL assumes your container is running on localhost, mapped to port 8080.
  const res = http.get('http://localhost:8080/test-cpu');

  // Check the response status to see if the request was successful.
  // We expect this to start failing as the server becomes overloaded.
  check(res, {
    'status is 200': (r) => r.status === 200,
  });

  // Pause for a moment to simulate real-world behavior and prevent a "thundering herd" problem.
  sleep(1);
}
