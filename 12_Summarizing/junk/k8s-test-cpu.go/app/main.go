// main.go
package main

import (
	"fmt"
	"log"
	"net/http"
	"runtime"
)

// fibonacci calculates the nth Fibonacci number recursively.
// This is a CPU-intensive operation designed to consume CPU cycles.
func fibonacci(n int) int {
	if n <= 1 {
		return n
	}
	return fibonacci(n-1) + fibonacci(n-2)
}

// A CPU-intensive function using a computational loop.
//function compute() {
//      let result = 0;
//      for (let i = 0; i < 5000000000; i++) {
//        result += Math.sqrt(Math.random());
//      }
//      return result;
//}

// homeHandler provides a simple introduction endpoint.
func homeHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprint(w, "Run http://localhost:8080/test-cpu or http://localhost:8080/healthcheck\n")
}

// cpuHandler is the HTTP handler for the /test-cpu endpoint.
// It initiates a CPU-intensive task in a separate goroutine.
func cpuHandler(w http.ResponseWriter, r *http.Request) {
	log.Println("Received request to /test-cpu. Starting CPU-intensive task...")

	// This number can be increased or decreased to change the load.
	// A higher number means a longer, more CPU-intensive calculation.
	const fibonacciNumber = 1000

	// Start the CPU task in a new goroutine to avoid blocking the HTTP server.
	go func() {
		result := fibonacci(fibonacciNumber)
		// We use the result to prevent the compiler from optimizing the function call away.
		_ = result
		log.Printf("Completed CPU-intensive task.")
	}()

	// Respond immediately to the user, indicating that the task has begun.
	w.Header().Set("Content-Type", "text/plain")
	fmt.Fprint(w, "Started a CPU performance test task. Check the server logs for completion.\n")
}

// healthHandler provides a simple, non-intensive health check endpoint.
func healthHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprint(w, "OK\n")
}

func main() {
	// Set the number of threads to the number of available CPU cores.
	// This ensures the application can fully utilize the CPU.
	runtime.GOMAXPROCS(runtime.NumCPU())

	// Set up the HTTP server and define the routes.
	http.HandleFunc("/test-cpu", cpuHandler)
	http.HandleFunc("/healthcheck", healthHandler)
	http.HandleFunc("/", homeHandler)

	// Listen for incoming HTTP requests on port 8080.
	port := "8080"
	log.Printf("Server starting on port %s...", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}

