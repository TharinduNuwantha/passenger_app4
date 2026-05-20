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

	fmt.Println("--- Trip Details for 57 Seat Trips ---")
	type TripDetails struct {
		TripID     string `db:"id"`
		BusId      string `db:"bus_id"`
		TemplateId string `db:"template_id"`
		TotalSeats int    `db:"total_seats"`
	}
	var results []TripDetails
	err = db.Select(&results, `
		SELECT t.id, t.bus_id, b.template_id, tm.total_seats
		FROM scheduled_trips t
		JOIN buses b ON t.bus_id = b.id
		JOIN bus_seat_layout_templates tm ON b.template_id = tm.id
		WHERE t.id IN ('99e7f4e9-0ed4-46b8-9544-232c5f4ab9e8', 'aac7be18-76bd-4b63-bd4d-d31f49d6206a', 'd3583d1a-7395-4e65-a9ed-1417679b4551')
	`)
	if err != nil {
		log.Fatalf("Query failed: %v", err)
	}

	for _, r := range results {
		fmt.Printf("Trip ID: %s | Bus ID: %s | Template ID: %s | Total Seats: %d\n", r.TripID, r.BusId, r.TemplateId, r.TotalSeats)
	}
}
