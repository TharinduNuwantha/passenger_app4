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

	fmt.Println("--- Trip Seats for Trip ID: bcd12e34-5678-490a-bcde-f0123456789a ---")
	type TripSeat struct {
		SeatNumber string `db:"seat_number"`
		RowNumber  int    `db:"row_number"`
		Position   int    `db:"position"`
		Status     string `db:"status"`
	}
	var seats []TripSeat
	err = db.Select(&seats, "SELECT seat_number, row_number, position, status FROM trip_seats WHERE scheduled_trip_id = 'bcd12e34-5678-490a-bcde-f0123456789a' ORDER BY row_number, position")
	if err != nil {
		log.Fatalf("Query failed: %v", err)
	}

	for _, s := range seats {
		fmt.Printf("Seat: %s | Row: %d | Pos: %d | Status: %s\n", s.SeatNumber, s.RowNumber, s.Position, s.Status)
	}
	fmt.Printf("Total: %d seats\n", len(seats))
}
