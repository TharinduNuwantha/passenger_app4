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
		fmt.Printf("\n=== Template ID: %s (Total Seats: %d) ===\n", t.ID, t.TotalSeats)
		
		type RowInfo struct {
			Row      int    `db:"row_number"`
			ColList  string `db:"cols"`
			Count    int    `db:"cnt"`
		}
		var rows []RowInfo
		err = db.Select(&rows, `
			SELECT row_number, string_agg(position::text, ',' ORDER BY position) as cols, count(*) as cnt 
			FROM bus_seat_layout_seats 
			WHERE template_id = $1 
			GROUP BY row_number 
			ORDER BY row_number`, t.ID)
		if err != nil {
			log.Fatalf("Query rows failed: %v", err)
		}

		for _, r := range rows {
			fmt.Printf("  Row %2d: Positions [%s] (Count: %d)\n", r.Row, r.ColList, r.Count)
		}
	}
}
