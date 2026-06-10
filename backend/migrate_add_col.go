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
		log.Fatalln(err)
	}
	defer db.Close()

	_, err = db.Exec("ALTER TABLE public.transport_bookings ADD COLUMN IF NOT EXISTS lounge_transport_type VARCHAR(50);")
	if err != nil {
		log.Fatalln(err)
	}

	fmt.Println("Successfully added column lounge_transport_type to transport_bookings")
}
