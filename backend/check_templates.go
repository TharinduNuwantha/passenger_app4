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

	fmt.Println("--- Bus Seat Layout Templates ---")
	type Template struct {
		ID         string `db:"id"`
		TotalSeats int    `db:"total_seats"`
	}
	var templates []Template
	err = db.Select(&templates, "SELECT id, total_seats FROM bus_seat_layout_templates")
	if err != nil {
		log.Fatalf("Query failed: %v", err)
	}

	for _, t := range templates {
		fmt.Printf("Template ID: %s | Total Seats: %d\n", t.ID, t.TotalSeats)
	}
}
