package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"sync"
)

// The global slice to hold the allocated memory.
// We use a slice of byte slices to avoid a single massive allocation
// and to allow for incremental memory consumption.
var allocatedMemory [][]byte

// Mutex to ensure thread-safe access to the global `allocatedMemory` slice.
var mu sync.Mutex

// healthCheckHandler is the HTTP handler for the base URL /.
// It's a simple health check to confirm the service is up.
func healthCheckHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Run http://localhost:8080/test-memory?mb=100")
	log.Println("Health check request received. Responded with OK.")
}

// allocateMemoryHandler is the HTTP handler for the /test-memory endpoint.
// It accepts a query parameter "mb" to specify the amount of memory to allocate in megabytes.
// Example: http://localhost:8080/test-memory?mb=100
func allocateMemoryHandler(w http.ResponseWriter, r *http.Request) {
	// Acknowledge the request
	log.Println("Received request to allocate memory.")

	// Get the "mb" query parameter. Default to 10 if not provided.
	mbStr := r.URL.Query().Get("mb")
	mb, err := strconv.Atoi(mbStr)
	if err != nil || mb <= 0 {
		mb = 10
	}

	// Calculate the number of bytes to allocate.
	bytesToAllocate := mb * 1024 * 1024

	// Lock the mutex to ensure only one goroutine allocates memory at a time.
	mu.Lock()
	// Use `defer` to ensure the mutex is unlocked when the function exits.
	defer mu.Unlock()

	log.Printf("Allocating %d MB of memory...\n", mb)

	// Allocate the memory slice and add it to our global slice.
	newChunk := make([]byte, bytesToAllocate)

	// "Dirty" the memory by writing to it, forcing the OS to commit the pages.
	for i := range newChunk {
		newChunk[i] = byte(i % 256)
	}

	allocatedMemory = append(allocatedMemory, newChunk)

	log.Printf("Successfully allocated %d MB. Total allocated: %d MB.\n", mb, len(allocatedMemory)*mb)
	fmt.Fprintf(w, "Allocated %d MB of memory. Total allocated: %d MB.\n", mb, len(allocatedMemory)*mb)
}

func main() {
	// Register the handlers for both endpoints.
	http.HandleFunc("/test-memory", allocateMemoryHandler)
	http.HandleFunc("/", healthCheckHandler)

	// Start the HTTP server on port 8080.
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Starting server on port %s...\n", port)
	err := http.ListenAndServe(":"+port, nil)
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}

