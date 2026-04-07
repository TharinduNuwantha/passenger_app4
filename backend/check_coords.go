package main

import (
	"context"
	"fmt"
	"log"

	"github.com/jackc/pgx/v5"
)

func main() {
	connUrl := "postgresql://postgres.pttatcukzpceljcrwehk:KQ95tJUYdFX251VR@aws-1-us-east-1.pooler.supabase.com:6543/postgres"
	conn, err := pgx.Connect(context.Background(), connUrl)
	if err != nil {
		log.Fatalf("Unable to connect to database: %v", err)
	}
	defer conn.Close(context.Background())

	fmt.Println("Checking stops for Route ID: 0739d921-5215-48b0-a584-243ec4c761d8 (Colombo - Kandy)")
	rows, _ := conn.Query(context.Background(), `
		SELECT stop_name, stop_order, latitude, longitude
		FROM master_route_stops
		WHERE master_route_id = '0739d921-5215-48b0-a584-243ec4c761d8'
		ORDER BY stop_order
	`)
	for rows.Next() {
		var name string
		var order int
		var lat, lng *float64
		rows.Scan(&name, &order, &lat, &lng)
		if lat == nil || lng == nil {
			fmt.Printf("%d. %s | LAT/LNG: NULL\n", order, name)
		} else {
			fmt.Printf("%d. %s | LAT/LNG: %f, %f\n", order, name, *lat, *lng)
		}
	}
}
