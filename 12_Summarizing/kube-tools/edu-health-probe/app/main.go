package main

import (
	"fmt"
	"log"
	"net/http"
	"sync/atomic"
	"time"
)

// --- Global State ---
var isLive atomic.Bool
var isReady atomic.Bool

// --- Handlers ---

// livenessHandler responds to the Liveness probe (/livez).
func livenessHandler(w http.ResponseWriter, r *http.Request) {
	if isLive.Load() {
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, "Liveness: OK (Application is alive)\n")
	} else {
		w.WriteHeader(http.StatusInternalServerError)
		// Change the Liveness failure output message back to the original
		fmt.Fprint(w, "Liveness: FAILED (Simulating Crash)\n") 
		// This 500 status is what tells Kubernetes the pod is unhealthy and needs a restart.
	}
}

// readinessHandler responds to the Readiness probe (/readyz).
func readinessHandler(w http.ResponseWriter, r *http.Request) {
	if isReady.Load() {
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, "Readiness: OK (Ready to serve traffic)\n")
	} else {
		// Ensures /readyz reports NOT READY when isReady is false
		w.WriteHeader(http.StatusServiceUnavailable)
		fmt.Fprint(w, "Readiness: NOT READY (Temporary Issue)\n")
	}
}

// stateHandler reports the current state of Liveness and Readiness for the application.
func stateHandler(w http.ResponseWriter, r *http.Request) {
	liveStatus := "ALIVE"
	if !isLive.Load() {
		// Updated state for the root path: use FAILED to match the livez handler's intent
		liveStatus = "FAILED" 
	}

	readyStatus := "READY"
	if !isReady.Load() {
		readyStatus = "NOT READY"
	}

	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "--- Application State ---\nLiveness: %s\nReadiness: %s\n", liveStatus, readyStatus)
}

// toggleHandler handles requests to flip the state of either liveness or readiness.
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

// infoHandler reports the usage statement.
func infoHandler(w http.ResponseWriter, r *http.Request) {
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
	http.HandleFunc("/info", infoHandler)

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
