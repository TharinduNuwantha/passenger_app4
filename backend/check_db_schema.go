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
		log.Fatal(err)
	}
	defer db.Close()

	tables := []string{"bookings", "users"}
	for _, t := range tables {
		rows, err := db.Query(fmt.Sprintf(`
			SELECT column_name, data_type 
			FROM information_schema.columns 
			WHERE table_name = '%s'
			ORDER BY ordinal_position
		`, t))
		if err != nil {
			log.Fatal(err)
		}
		defer rows.Close()

		fmt.Printf("\nColumns in %s:\n", t)
		for rows.Next() {
			var name, dtype string
			if err := rows.Scan(&name, &dtype); err != nil {
				log.Fatal(err)
			}
			fmt.Printf("- %s (%s)\n", name, dtype)
		}
	}
}

