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
var isLive atomic.Bool

// isReady represents the Readiness state. If false, the pod is unhealthy and should be taken out of service.
var isReady atomic.Bool

// --- Handlers ---

// livenessHandler responds to the Liveness probe (/livez).
// If isLive is false, it returns HTTP 500 (Internal Server Error), simulating a fatal error.
func livenessHandler(w http.ResponseWriter, r *http.Request) {
	if isLive.Load() {
		w.WriteHeader(http.StatusOK)
		// Change 1: Update Liveness OK message
		fmt.Fprint(w, "Liveness: OK (Application is alive)\n")
	} else {
		w.WriteHeader(http.StatusInternalServerError)
		// Fix 3: Ensure /livez reports failure when isLive is false
		fmt.Fprint(w, "Liveness: FAILED (Simulating Crash)\n")
		// NOTE: In a real K8s scenario, a 500 status on the Liveness probe will cause K8s to restart the container.
	}
}

// readinessHandler responds to the Readiness probe (/readyz).
// If isReady is false, it returns HTTP 503 (Service Unavailable), simulating a temporary issue.
func readinessHandler(w http.ResponseWriter, r *http.Request) {
	if isReady.Load() {
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, "Readiness: OK (Ready to serve traffic)\n")
	} else {
		// Fix 4: Ensure /readyz reports NOT READY when isReady is false
		w.WriteHeader(http.StatusServiceUnavailable)
		fmt.Fprint(w, "Readiness: NOT READY (Temporary Issue)\n")
	}
}

// stateHandler reports the current state of Liveness and Readiness for the application.
func stateHandler(w http.ResponseWriter, r *http.Request) {
	liveStatus := "ALIVE"
	if !isLive.Load() {
		liveStatus = "FAILED"
	}

	readyStatus := "READY"
	if !isReady.Load() {
		readyStatus = "NOT READY"
	}

	w.WriteHeader(http.StatusOK)
	// Output must be: --- Application State --- Liveness: ALIVE Readiness: READY
	fmt.Fprintf(w, "--- Application State ---\nLiveness: %s\nReadiness: %s\n", liveStatus, readyStatus)
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
	// Fix 3 & 4: The successful toggle print already reports the final state ('true' or 'false')
	fmt.Fprintf(w, "%s state successfully toggled to: %t\n", stateName, newState)
	log.Printf("%s state toggled to %t by user request.", stateName, newState)
}

// infoHandler reports the usage statement.
func infoHandler(w http.ResponseWriter, r *http.Request) {
	// Change 2: Update usage statement
	fmt.Fprint(w, "Welcome to the Probe Tester.\nEndpoints:\n- / (Current Application State)\n- /livez (Liveness Probe)\n- /readyz (Readiness Probe)\n- /toggle/<state> (Toggle on/off for Liveness/Readiness. e.g., /toggle/liveness)\n")
}

func main() {
	// Initialize states: both are healthy and ready by default
	isLive.Store(true)
	isReady.Store(true)

	// Set up routes
	http.HandleFunc("/livez", livenessHandler)
	http.HandleFunc("/readyz", readinessHandler)
	http.HandleFunc("/toggle/", toggleHandler)
	http.HandleFunc("/", stateHandler)
	http.HandleFunc("/info", infoHandler) // Usage statement moved to /info

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
