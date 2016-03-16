package main

import (
	"io"
	"log"
	"net/http"
)

func main() {
	http.HandleFunc("/api/v2/core/ping", func(w http.ResponseWriter, r *http.Request) {
		io.WriteString(w, `{"status":"happy"}`)
	})

	http.HandleFunc("/api/v2/core/users", func(w http.ResponseWriter, r *http.Request) {
		log.Println(r.FormValue("page"), r.FormValue("per_page"))
		io.WriteString(w, `[{"id":1,"name":"user1"},{"id":2,"name":"user2"}]`)
	})

	log.Fatal(http.ListenAndServe(":8080", nil))
}
