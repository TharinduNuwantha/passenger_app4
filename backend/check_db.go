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

	fmt.Println("Checking for Jaffna routes...")
	
	// 1. Check if any stops match 'Jaffna'
	var stopNames []string
	err = db.Select(&stopNames, "SELECT DISTINCT stop_name FROM master_route_stops WHERE stop_name ILIKE '%Jaffna%'")
	if err != nil {
		log.Fatalf("Select stops failed: %v", err)
	}
	fmt.Printf("Found %d stops matching 'Jaffna': %v\n", len(stopNames), stopNames)

	// 2. Check for routes involving Jaffna and Kandy
	var routes []string
	query := `
		SELECT DISTINCT mr.route_name 
		FROM master_routes mr
		JOIN master_route_stops s1 ON s1.master_route_id = mr.id
		JOIN master_route_stops s2 ON s2.master_route_id = mr.id
		WHERE s1.stop_name ILIKE '%Jaffna%' 
		  AND s2.stop_name ILIKE '%Kandy%'
		  AND s1.stop_order < s2.stop_order
	`
	err = db.Select(&routes, query)
	if err != nil {
		log.Fatalf("Select routes failed: %v", err)
	}
	fmt.Printf("Found %d direct/order-preserving routes for Jaffna -> Kandy: %v\n", len(routes), routes)
}
