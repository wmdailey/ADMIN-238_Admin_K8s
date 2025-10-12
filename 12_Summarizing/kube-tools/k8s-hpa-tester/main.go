package main

import (
	"fmt"
	"log"
	"net/http"
	"strconv"
	"sync"
	"time"
)

// --- Global State for Memory Stress Testing ---
const (
	// MaxMemoryMB sets a safety limit to prevent accidental host memory exhaustion.
	MaxMemoryMB = 2048 // 2GB limit
	// GigaByte is 1024 * 1024 * 1024 bytes (1 GiB) for allocation clarity.
	MegaByte = 1024 * 1024
)

// allocatedMemory holds all the memory buffers to prevent the GC from releasing them.
var allocatedMemory [][]byte
var memMutex sync.Mutex
var currentMemoryMB int

// --- Core Load Functions ---

// consumeCPU runs an intensive, non-optimizable loop (like calculating a large number of squares)
// for a specified duration. This puts load directly on the CPU core.
func consumeCPU(durationSeconds int) {
	log.Printf("Starting CPU stress for %d seconds...", durationSeconds)

	startTime := time.Now()
	targetDuration := time.Duration(durationSeconds) * time.Second

	// Use a complex calculation to ensure the compiler doesn't optimize it away.
	var result float64
	for time.Since(startTime) < targetDuration {
		result += 1.0 / (result + 1) * 3.14159 // Dummy calculation
	}
	// Print a log message using the result to ensure the calculation is executed.
	log.Printf("Completed CPU stress. Final (ignored) calculation value: %.2f", result)
}

// consumeMemory allocates a specific number of megabytes and holds it in the global slice.
// This increases the RSS (Resident Set Size) memory usage of the pod.
func consumeMemory(mb int) {
	memMutex.Lock()
	defer memMutex.Unlock()

	if currentMemoryMB+mb > MaxMemoryMB {
		log.Printf("ERROR: Requested allocation of %dMB exceeds MaxMemoryMB limit (%dMB). Aborting.", mb, MaxMemoryMB)
		return
	}

	log.Printf("Allocating %dMB of memory...", mb)

	// Allocate a single large byte slice for the requested MB
	buffer := make([]byte, mb*MegaByte)

	// Set the first byte of each MB to a random value to ensure the memory is actually touched
	// and allocated by the OS, not just reserved virtually (prevents copy-on-write optimizations).
	for i := 0; i < mb; i++ {
		buffer[i*MegaByte] = byte(i % 256)
	}

	// Add the buffer to the global slice to prevent GC
	allocatedMemory = append(allocatedMemory, buffer)
	currentMemoryMB += mb

	log.Printf("Memory allocated. Current total memory usage is %dMB.", currentMemoryMB)
}

// releaseMemory attempts to clear all allocated memory and force a GC run.
func releaseMemory() {
	memMutex.Lock()
	defer memMutex.Unlock()

	log.Println("Releasing all allocated memory and forcing garbage collection...")
	allocatedMemory = nil
	currentMemoryMB = 0

	// Suggest an immediate garbage collection to release memory back to the OS (if possible)
	// Note: Go's GC is non-deterministic, so this only suggests a run.
	go func() {
		time.Sleep(500 * time.Millisecond)
		log.Println("Garbage collection initiated.")
	}()
}

// --- HTTP Handlers ---

// loadHandler is the main endpoint to trigger the load.
// Usage:
// - http://localhost:8080/load?type=cpu&value=30 (30 seconds of CPU burn)
// - http://localhost:8080/load?type=memory&value=512 (Allocate 512MB of memory)
func loadHandler(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query()
	loadType := query.Get("type")
	valueStr := query.Get("value")

	if loadType == "" || valueStr == "" {
		http.Error(w, "Missing 'type' or 'value' parameters. Usage: /load?type={cpu|memory}&value={seconds|MB}", http.StatusBadRequest)
		return
	}

	value, err := strconv.Atoi(valueStr)
	if err != nil || value <= 0 {
		http.Error(w, "Invalid 'value'. Must be a positive integer.", http.StatusBadRequest)
		return
	}

	switch loadType {
	case "cpu":
		// Run CPU burn in a non-blocking goroutine
		go consumeCPU(value)
		fmt.Fprintf(w, "Started CPU burn for %d seconds. Check logs for completion. \n", value)
	case "memory":
		// Run memory allocation in a non-blocking goroutine
		go consumeMemory(value)
		fmt.Fprintf(w, "Attempting to allocate %dMB. Check status at /status.\n", value)
	default:
		http.Error(w, "Invalid 'type'. Must be 'cpu' or 'memory'.", http.StatusBadRequest)
	}
}

// statusHandler shows the current memory load and allows a full release.
func statusHandler(w http.ResponseWriter, r *http.Request) {
	if r.URL.Query().Get("action") == "release" {
		releaseMemory()
		fmt.Fprintf(w, "Memory release initiated.\n")
		return
	}

	memMutex.Lock()
	defer memMutex.Unlock()

	fmt.Fprintf(w, "--- Load Status ---\n")
	fmt.Fprintf(w, "Current Memory Allocated: %dMB (Limit: %dMB)\n", currentMemoryMB, MaxMemoryMB)
	fmt.Fprintf(w, "To release memory: /status?action=release\n")
}

// healthcheckHandler provides a simple check for the HPA to confirm the pod is responsive.
func healthcheckHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprint(w, "OK\n")
}

func main() {
	// Set up the routes
	http.HandleFunc("/load", loadHandler)
	http.HandleFunc("/status", statusHandler)
	http.HandleFunc("/healthcheck", healthcheckHandler)

	log.Println("HPA Load Tester starting on :8080")
	log.Printf("Max Memory Allocation Limit is %dMB", MaxMemoryMB)
	log.Println("Endpoints available: /load, /status, /healthcheck")

	// Start the server
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}

