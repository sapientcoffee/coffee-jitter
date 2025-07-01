package main

import (
	"encoding/json"
	"log"
	"math/rand"
	"net/http"
)

type Pun struct {
	Pun string `json:"pun"`
}

var puns = []Pun{
	{Pun: "I like my coffee like I like my women... in a plastic cup."},
	{Pun: "What do you call a sad cup of coffee? A depresso."},
	{Pun: "Coffee, because adulting is hard."},
	{Pun: "A yawn is a silent scream for coffee."},
	{Pun: "I'm not addicted to coffee, we're just in a committed relationship."},
}

var leakySlice []Pun

func punHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Access-Control-Allow-Origin", "*")
	pun := puns[rand.Intn(len(puns))]
	for i := 0; i < 1000000; i++ {
		leakySlice = append(leakySlice, pun)
	}
	json.NewEncoder(w).Encode(pun)
}

func main() {
	http.HandleFunc("/api/pun", punHandler)
	log.Println("Starting server on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
