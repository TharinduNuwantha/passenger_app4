package main

import (
	"fmt"
	"log"

	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
)

func main() {
	dbUrl := "postgresql://postgres.pttatcukzpceljcrwehk:KQ95tJUYdFX251VR@aws-1-us-east-1.pooler.supabase.com:6543/postgres"
	db, err := sqlx.Connect("postgres", dbUrl)
	if err != nil {
		log.Fatalf("Connect failed: %v", err)
	}
	defer db.Close()

	fmt.Println("--- Trip Seats Count by Trip ---")
	type TripSeatCount struct {
		TripID string `db:"scheduled_trip_id"`
		Count  int    `db:"count"`
	}
	var results []TripSeatCount
	err = db.Select(&results, "SELECT scheduled_trip_id, count(*) FROM trip_seats GROUP BY scheduled_trip_id")
	if err != nil {
		log.Fatalf("Query failed: %v", err)
	}

	for _, r := range results {
		fmt.Printf("Trip ID: %s | Seat Count: %d\n", r.TripID, r.Count)
	}
}
