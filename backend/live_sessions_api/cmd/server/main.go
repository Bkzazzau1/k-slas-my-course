package main

import (
	"log"
	"net/http"
	"os"
	"time"

	"live_sessions_api/internal/api"
	"live_sessions_api/internal/service"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	svc := service.NewContractService()
	handler := api.NewRouter(svc)

	server := &http.Server{
		Addr:              ":" + port,
		Handler:           handler,
		ReadHeaderTimeout: 5 * time.Second,
	}

	log.Printf("live sessions API listening on :%s", port)
	log.Fatal(server.ListenAndServe())
}
