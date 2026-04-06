package main

import (
	"database/sql"
	"fmt"
	"log"

	_ "github.com/lib/pq"
)

func main() {
	dbURL := "postgresql://postgres.pttatcukzpceljcrwehk:KQ95tJUYdFX251VR@aws-1-us-east-1.pooler.supabase.com:6543/postgres"
	db, err := sql.Open("postgres", dbURL)
	if err != nil {
		log.Fatalf("Unable to connect: %v\n", err)
	}
	defer db.Close()

	rows, err := db.Query("SELECT id, name, latitude, longitude FROM lounge_transport_locations LIMIT 10")
	if err != nil {
		log.Fatalf("Query failed: %v\n", err)
	}
	defer rows.Close()

	for rows.Next() {
		var id, name string
		var lat, lng sql.NullFloat64
		if err := rows.Scan(&id, &name, &lat, &lng); err != nil {
			continue
		}
		fmt.Printf("id: %s, Name: %v, Lat: %v, Lng: %v\n", id, name, lat.Float64, lng.Float64)
	}
	fmt.Println("Done")
}
