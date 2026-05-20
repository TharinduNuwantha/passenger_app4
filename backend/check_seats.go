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

	fmt.Println("--- Scheduled Trips and their Seat Counts ---")
	type TripInfo struct {
		TripID      string `db:"trip_id"`
		RouteName   string `db:"route_name"`
		TotalSeats  int    `db:"total_seats"`
		TemplateID  string `db:"seat_layout_id"`
		TemplateName string `db:"template_name"`
	}
	var trips []TripInfo
	query := `
		SELECT 
			st.id as trip_id, 
			mr.route_name, 
			bslt.total_seats, 
			st.seat_layout_id, 
			bslt.template_name
		FROM scheduled_trips st
		JOIN master_routes mr ON st.route_id = mr.id
		JOIN buses b ON st.bus_id = b.id
		JOIN bus_seat_layout_templates bslt ON b.seat_layout_id = bslt.id
	`
	err = db.Select(&trips, query)
	if err != nil {
		log.Fatalf("Query trips failed: %v", err)
	}

	for _, t := range trips {
		fmt.Printf("Trip ID: %s | Route: %s | Template Seats: %d (%s)\n", t.TripID, t.RouteName, t.TotalSeats, t.TemplateName)
		
		// Count trip seats in trip_seats table
		var count int
		err = db.Get(&count, "SELECT COUNT(*) FROM trip_seats WHERE scheduled_trip_id = $1", t.TripID)
		if err != nil {
			log.Fatalf("Count trip seats failed: %v", err)
		}
		fmt.Printf("  -> Actual seats in trip_seats table: %d\n", count)

		// List seats in trip_seats
		type Seat struct {
			SeatNumber string `db:"seat_number"`
			RowNumber  int    `db:"row_number"`
			Position   int    `db:"position"`
		}
		var seats []Seat
		err = db.Select(&seats, "SELECT seat_number, row_number, position FROM trip_seats WHERE scheduled_trip_id = $1 ORDER BY row_number, position", t.TripID)
		if err != nil {
			log.Fatalf("Select trip seats failed: %v", err)
		}
		for _, s := range seats {
			fmt.Printf("    Seat: %s | Row: %d | Pos: %d\n", s.SeatNumber, s.RowNumber, s.Position)
		}
	}
}
