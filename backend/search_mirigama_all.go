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

	tables := []string{"master_route_stops", "lounges", "passengers", "master_routes", "lounge_transport_locations", "districts"}
	found := false
	for _, t := range tables {
		rows, err := db.Query(fmt.Sprintf("SELECT count(*) FROM %s::text t WHERE t::text ILIKE '%%mirigama%%'", t))
		if err != nil {
			fmt.Printf("Error querying %s: %v\n", t, err)
			continue
		}
		var count int
		for rows.Next() {
			if err := rows.Scan(&count); err == nil && count > 0 {
				fmt.Printf("Found %d matches in table %s\n", count, t)
				found = true
			}
		}
		rows.Close()
	}
	if !found {
		fmt.Println("No matches found in any tables.")
	}
}
