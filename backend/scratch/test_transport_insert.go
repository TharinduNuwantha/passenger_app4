package main

import (
	"fmt"
	"log"
	"os"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
	"github.com/joho/godotenv"

	"github.com/smarttransit/sms-auth-backend/internal/database"
	"github.com/smarttransit/sms-auth-backend/internal/models"
)

func main() {
	if err := godotenv.Load(".env"); err != nil {
		log.Println("No .env file found")
	}

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		log.Fatal("DATABASE_URL is required")
	}

	db, err := sqlx.Connect("postgres", dbURL)
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	repo := database.NewTransportBookingRepository(db)

	ref, err := repo.GenerateTransportBookingReference()
	if err != nil {
		log.Fatal(err)
	}

	bookingID := uuid.New().String()
	userID := uuid.New().String()
	loungeID := uuid.New().String()
	pickupLocID := uuid.New().String()
	loungeTransportType := "user_to_lounge"

	booking := &models.TransportBooking{
		BookingID:        &bookingID,
		UserID:           userID,
		LoungeID:         &loungeID,
		PickupLocationID: &pickupLocID,
		VehicleType:      "car",
		VehicleQuantity:  1,
		TransportPrice:   1500.00,
		TransportDate:    time.Now(),
		TransportTime:    time.Now(),
		BookingReference: &ref,
		Status:           models.TransportBookingPending,
		PaymentStatus:    models.TransportPaymentPaid,
		LoungeTransportType: &loungeTransportType,
	}

	err = repo.CreateTransportBooking(booking)
	if err != nil {
		fmt.Printf("ERROR creating transport booking: %v\n", err)
	} else {
		fmt.Printf("SUCCESS! Created transport booking with ID: %s\n", booking.ID)
	}
}
