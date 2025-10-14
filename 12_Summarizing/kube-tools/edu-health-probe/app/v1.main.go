package main

import (
	"fmt"
	"log"
	"net/http"
	"sync/atomic"
	"time"
)

// --- Global State ---

// isLive represents the Liveness state. If false, the pod is considered unhealthy and should be restarted.
// We use atomic values for safe concurrency, though a simple bool would suffice for this example.
var isLive atomic.Bool

// isReady represents the Readiness state. If false, the pod is unhealthy and should be taken out of service.
var isReady atomic.Bool

// --- Handlers ---

// livenessHandler responds to the Liveness probe (/healthz).
// If isLive is false, it returns HTTP 500 (Internal Server Error), simulating a fatal error.
func livenessHandler(w http.ResponseWriter, r *http.Request) {
	if isLive.Load() {
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, "Liveness: OK (Alive)\n")
	} else {
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprint(w, "Liveness: FAILED (Simulating Crash)\n")
		// In a real application, a failed liveness check would often lead to the process exiting.
		// For this simulation, we just return 500.
	}
}

// readinessHandler responds to the Readiness probe (/readyz).
// If isReady is false, it returns HTTP 503 (Service Unavailable), simulating a temporary issue.
func readinessHandler(w http.ResponseWriter, r *http.Request) {
	if isReady.Load() {
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, "Readiness: OK (Ready to serve traffic)\n")
	} else {
		w.WriteHeader(http.StatusServiceUnavailable)
		fmt.Fprint(w, "Readiness: NOT READY (Temporary Issue)\n")
	}
}

// toggleHandler handles requests to flip the state of either liveness or readiness.
// Usage: /toggle/liveness or /toggle/readiness
func toggleHandler(w http.ResponseWriter, r *http.Request) {
	stateType := r.URL.Path[len("/toggle/"):]

	var state *atomic.Bool
	var stateName string

	switch stateType {
	case "liveness":
		state = &isLive
		stateName = "Liveness"
	case "readiness":
		state = &isReady
		stateName = "Readiness"
	default:
		http.Error(w, "Invalid state type. Use /toggle/liveness or /toggle/readiness", http.StatusBadRequest)
		return
	}

	// Atomically swap the state
	newState := !state.Swap(!state.Load())
	
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "%s state successfully toggled to: %t\n", stateName, newState)
	log.Printf("%s state toggled to %t by user request.", stateName, newState)
}

func main() {
	// Initialize states: both are healthy and ready by default
	isLive.Store(true)
	isReady.Store(true)

	// Set up routes
	http.HandleFunc("/healthz", livenessHandler)
	http.HandleFunc("/readyz", readinessHandler)
	http.HandleFunc("/toggle/", toggleHandler)
	
	// Default informational endpoint
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprint(w, "Welcome to the Probe Tester. Check /healthz, /readyz, or use /toggle/<state>.\n")
	})

	port := ":8080"
	log.Printf("Starting Probe Test Server on port %s", port)
	
	// Use a non-blocking goroutine to log current state periodically
	go func() {
		for {
			log.Printf("Current State: Liveness=%t, Readiness=%t", isLive.Load(), isReady.Load())
			time.Sleep(10 * time.Second)
		}
	}()

	// Start the server
	if err := http.ListenAndServe(port, nil); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}

