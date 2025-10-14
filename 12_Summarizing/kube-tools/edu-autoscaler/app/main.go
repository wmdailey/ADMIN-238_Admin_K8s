package main

import (
	"fmt"
	"log"
	"net/http"
	"runtime"
	"strconv"
	"sync"
	"time"
)

// --- Global State for Memory Stress Testing ---
const (
	// MaxMemoryMB sets a safety limit to prevent accidental host memory exhaustion.
	MaxMemoryMB = 2048 // 2GB limit
	// MegaByte is 1024 * 1024 bytes (1 MiB) for allocation clarity.
	MegaByte = 1024 * 1024
)

// allocatedMemory holds all the memory buffers to prevent the GC from releasing them.
var allocatedMemory [][]byte
var memMutex sync.Mutex
var currentMemoryMB int

// --- Core Load Functions ---

// consumeCPU runs an intensive, non-optimizable loop on a specific number of cores.
func consumeCPU(durationSeconds int, cores int) {
	log.Printf("Starting CPU stress on %d cores for %d seconds...", cores, durationSeconds)

	// Use a WaitGroup to ensure all goroutines complete before the function returns.
	var wg sync.WaitGroup
	wg.Add(cores)

	for i := 0; i < cores; i++ {
		go func() {
			defer wg.Done()
			startTime := time.Now()
			targetDuration := time.Duration(durationSeconds) * time.Second
			var result float64
			for time.Since(startTime) < targetDuration {
				// Use a complex calculation to ensure the compiler doesn't optimize it away.
				result += 1.0 / (result + 1) * 3.14159 // Dummy calculation
			}
			log.Printf("Completed a single-core CPU stress goroutine. Final value: %.2f", result)
		}()
	}
	wg.Wait()
	log.Println("All CPU stress goroutines completed.")
}

// consumeMemory allocates a specific number of megabytes and holds it in the global slice.
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
	go func() {
		time.Sleep(500 * time.Millisecond)
		runtime.GC()
		log.Println("Garbage collection initiated.")
	}()
}

// --- HTTP Handlers ---

// loadHandler is the main endpoint to trigger the load.
// Usage:
// - http://localhost:8080/load?type=cpu&value=30&cores=4 (30 seconds of CPU burn on 4 cores)
// - http://localhost:8080/load?type=memory&value=512 (Allocate 512MB of memory)
func loadHandler(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query()
	loadType := query.Get("type")
	valueStr := query.Get("value")
	coresStr := query.Get("cores") // New parameter for CPU load

	if loadType == "" || valueStr == "" {
		http.Error(w, "Missing 'type' or 'value' parameters. Usage: /load?type={cpu|memory}&value={seconds|MB}&cores={1..N}", http.StatusBadRequest)
		return
	}

	value, err := strconv.Atoi(valueStr)
	if err != nil || value <= 0 {
		http.Error(w, "Invalid 'value'. Must be a positive integer.", http.StatusBadRequest)
		return
	}

	switch loadType {
	case "cpu":
		cores := runtime.NumCPU()
		if coresStr != "" {
			if parsedCores, err := strconv.Atoi(coresStr); err == nil && parsedCores > 0 {
				cores = parsedCores
			}
		}
		// Run CPU burn in a non-blocking goroutine
		go consumeCPU(value, cores)
		fmt.Fprintf(w, "Started CPU burn on %d cores for %d seconds. Check logs for completion.\n", cores, value)
	case "memory":
		// Run memory allocation in a non-blocking goroutine
		go consumeMemory(value)
		fmt.Fprintf(w, "Attempting to allocate %dMB. Check status at /status.\n", value)
	default:
		http.Error(w, "Invalid 'type'. Must be 'cpu' or 'memory'.", http.StatusBadRequest)
	}
}

// statusHandler shows the current memory load and includes CPU metrics.
func statusHandler(w http.ResponseWriter, r *http.Request) {
	if r.URL.Query().Get("action") == "release" {
		releaseMemory()
		fmt.Fprintf(w, "Memory release initiated.\n")
		return
	}

	memMutex.Lock()
	defer memMutex.Unlock()

	// Get memory stats from the Go runtime
	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	fmt.Fprintf(w, "--- Load Tester Status ---\n")
	fmt.Fprintf(w, "Current Memory Allocated (App State): %dMB (Limit: %dMB)\n", currentMemoryMB, MaxMemoryMB)
	fmt.Fprintf(w, "Number of CPU Cores (container limit): %d\n", runtime.NumCPU())
	fmt.Fprintf(w, "Goroutines Running: %d\n", runtime.NumGoroutine())
	// fmt.Fprintf(w, "\nTo release memory: /status?action=release\n")
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

	log.Println("HPA/VPA Load Tester starting on :8080")
	log.Printf("Max Memory Allocation Limit is %dMB", MaxMemoryMB)
	log.Println("Endpoints available: /load, /status, /healthcheck")

	// Start the server
	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}
