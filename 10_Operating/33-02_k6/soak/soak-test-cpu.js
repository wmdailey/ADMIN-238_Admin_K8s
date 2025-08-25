//Exercise 33-02 v3.3.0
//
import http from 'k6/http';
import { check, sleep } from 'k6';
// soak-test-cpu.js

// Options for the soak test. Define stages that simulate a long, consistent load.
export let options = {
  // Define the stages for the test.
  // This is where we control the number of virtual users (VUs) over time.
  stages: [
    // Stage 1: Ramp up to a baseline load over a few minutes.
    { duration: '2m', target: 20 },  
    // Stage 2: Hold the load at a constant level for a long duration.
    // For a real-world soak test, this duration should be hours or days.
    { duration: '10m', target: 20 }, 
    // Stage 3: Ramp down to 0 VUs.
    { duration: '2m', target: 0 },   
  ],
  // We still expect errors to occur after a long period, so we can keep this setting.
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
