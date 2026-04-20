package services

import (
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
	"github.com/smarttransit/sms-auth-backend/internal/database"
	"github.com/smarttransit/sms-auth-backend/internal/models"
)

// SearchService handles business logic for trip search
type SearchService struct {
	repo   *database.SearchRepository
	logger *logrus.Logger
}

// NewSearchService creates a new search service
func NewSearchService(repo *database.SearchRepository, logger *logrus.Logger) *SearchService {
	return &SearchService{
		repo:   repo,
		logger: logger,
	}
}

// radiusSteps defines the incremental search radius expansion in meters.
// The algorithm tries each radius in sequence until lounges are found on both sides.
// Steps: 3km, 6km, 16km, 26km, 36km
var radiusSteps = []float64{3000, 6000, 16000, 26000, 36000}

// SearchTrips implements the Lounge-centric Direct Route Discovery algorithm.
// It uses a single-query approach with incremental radius expansion to find
// direct bus paths between the nearest candidate lounges.
func (s *SearchService) SearchTrips(
	req *models.SearchRequest,
	userID *uuid.UUID,
	ipAddress string,
) (*models.SearchResponse, error) {
	startTime := time.Now()

	// Validate request
	if err := req.Validate(); err != nil {
		return nil, err
	}

	// Coordinates are REQUIRED for lounge-centric search.
	if req.FromLat == nil || req.FromLng == nil || req.ToLat == nil || req.ToLng == nil {
		return &models.SearchResponse{
			Status:  "error",
			Message: "Coordinates (from_lat, from_lng, to_lat, to_lng) are required for lounge-centric search.",
			Results: []models.TripResult{},
		}, nil
	}

	s.logger.WithFields(logrus.Fields{
		"from":     req.From,
		"to":       req.To,
		"from_lat": *req.FromLat,
		"from_lng": *req.FromLng,
		"to_lat":   *req.ToLat,
		"to_lng":   *req.ToLng,
	}).Info("=== SearchService: Starting Lounge-centric Direct Route Discovery ===")

	searchTime := req.GetSearchDateTime()

	// --- INCREMENTAL RADIUS EXPANSION LOOP ---
	// Tries progressively larger radii until results are found or max radius is exhausted.
	var results []models.TripResult
	var usedRadius float64
	var err error

	for _, radius := range radiusSteps {
		usedRadius = radius
		s.logger.WithField("radius_m", radius).Info("Attempting lounge discovery at radius")

		results, err = s.repo.FindLoungeDirectRoutes(
			*req.FromLat, *req.FromLng,
			*req.ToLat, *req.ToLng,
			radius,
			searchTime,
			req.Limit,
		)
		if err != nil {
			s.logger.WithError(err).WithField("radius_m", radius).Error("Error during lounge route discovery")
			return nil, fmt.Errorf("lounge route discovery failed at radius %.0fm: %w", radius, err)
		}

		if len(results) > 0 {
			s.logger.WithFields(logrus.Fields{
				"radius_m":      radius,
				"results_found": len(results),
			}).Info("Lounge-centric routes discovered successfully")
			break
		}

		// --- NEW: Try Lounge-to-Stop (Origin Lounge Only) ---
		s.logger.WithField("radius_m", radius).Info("Trying Lounge-to-Stop discovery...")
		results, err = s.repo.FindLoungeOriginRoutes(
			*req.FromLat, *req.FromLng,
			req.To,
			radius,
			searchTime,
			req.Limit,
		)
		if err == nil && len(results) > 0 {
			s.logger.WithFields(logrus.Fields{
				"radius_m":      radius,
				"results_found": len(results),
			}).Info("Lounge-to-Stop routes discovered successfully")
			break
		}

		s.logger.WithField("radius_m", radius).Info("No lounges found at this radius, expanding...")
	}

	// --- FALLBACK TO REGULAR SEARCH IF NO LOUNGES FOUND ---
	searchType := "lounge_direct"
	fallbackMessage := ""

	if len(results) == 0 {
		s.logger.Info("No lounges found, falling back to regular stop-to-stop search")

		pair, err := s.repo.FindStopPairOnSameRoute(req.From, req.To)
		if err == nil && pair.Matched {
			results, err = s.repo.FindDirectTrips(pair.FromID, pair.ToID, searchTime, req.Limit)
			if err == nil && len(results) > 0 {
				searchType = "stop_direct"
				fallbackMessage = fmt.Sprintf("No lounges found near your locations. Found %d regular schedules from '%s' to '%s' instead.", len(results), pair.FromStop.Name, pair.ToStop.Name)
				s.logger.WithField("results_found", len(results)).Info("Regular stop-to-stop routes discovered as fallback")
			}
		}
	}

	// Build the response
	response := &models.SearchResponse{
		Status: "success",
		SearchDetails: models.SearchDetails{
			FromStop: models.StopInfo{
				OriginalInput: req.From,
				Matched:       len(results) > 0,
			},
			ToStop: models.StopInfo{
				OriginalInput: req.To,
				Matched:       len(results) > 0,
			},
			SearchType: searchType,
		},
		Results: results,
	}

	if len(results) == 0 {
		response.Status = "success"
		response.Message = fmt.Sprintf(
			"No routes found from '%s' to '%s' even after expanding search radius to %.0fkm. Please try a different date or time.",
			req.From, req.To, usedRadius/1000,
		)
	} else if fallbackMessage != "" {
		response.Message = fallbackMessage
	} else {
		response.Message = fmt.Sprintf(
			"Found %d direct lounge route(s) from '%s' to '%s' (search radius: %.0fkm).",
			len(results), req.From, req.To, usedRadius/1000,
		)
	}

	// Log timing
	responseTime := time.Since(startTime)
	response.SearchTimeMs = responseTime.Milliseconds()

	// Async analytics logging
	s.logSearch(req, response, userID, &ipAddress, responseTime)

	s.logger.WithFields(logrus.Fields{
		"results":     len(results),
		"radius_used": usedRadius,
		"response_ms": response.SearchTimeMs,
	}).Info("=== SearchService: Lounge-centric search completed ===")

	return response, nil
}

// GetPopularRoutes returns popular routes for quick selection
func (s *SearchService) GetPopularRoutes(limit int) ([]models.PopularRoute, error) {
	if limit <= 0 {
		limit = 10
	}
	if limit > 50 {
		limit = 50
	}

	routes, err := s.repo.GetPopularRoutes(limit)
	if err != nil {
		s.logger.WithError(err).Error("Error getting popular routes")
		return nil, fmt.Errorf("error retrieving popular routes: %w", err)
	}

	if len(routes) == 0 {
		routes = s.getDefaultPopularRoutes()
	}

	return routes, nil
}

// GetStopAutocomplete returns stop suggestions for autocomplete
func (s *SearchService) GetStopAutocomplete(searchTerm string, limit int) ([]models.StopAutocomplete, error) {
	if searchTerm == "" || len(searchTerm) < 2 {
		return []models.StopAutocomplete{}, nil
	}

	if limit <= 0 {
		limit = 10
	}
	if limit > 50 {
		limit = 50
	}

	suggestions, err := s.repo.GetStopAutocomplete(searchTerm, limit)
	if err != nil {
		s.logger.WithError(err).Error("Error getting autocomplete suggestions")
		return nil, fmt.Errorf("error retrieving suggestions: %w", err)
	}

	return suggestions, nil
}

// GetSearchAnalytics returns search analytics for admin dashboard
func (s *SearchService) GetSearchAnalytics(days int) (map[string]interface{}, error) {
	if days <= 0 {
		days = 7
	}
	if days > 90 {
		days = 90
	}

	analytics, err := s.repo.GetSearchAnalytics(days)
	if err != nil {
		s.logger.WithError(err).Error("Error getting search analytics")
		return nil, fmt.Errorf("error retrieving analytics: %w", err)
	}

	return analytics, nil
}

// logSearch logs the search request for analytics asynchronously.
func (s *SearchService) logSearch(
	req *models.SearchRequest,
	response *models.SearchResponse,
	userID *uuid.UUID,
	ipAddress *string,
	responseTime time.Duration,
) {
	log := &models.SearchLog{
		FromInput:      req.From,
		ToInput:        req.To,
		ResultsCount:   len(response.Results),
		ResponseTimeMs: responseTime.Milliseconds(),
		UserID:         userID,
		IPAddress:      ipAddress,
	}

	go func() {
		if err := s.repo.LogSearch(log); err != nil {
			s.logger.WithError(err).Warn("Failed to log search")
		}
	}()
}

// getDefaultPopularRoutes returns hardcoded popular routes for Sri Lanka
func (s *SearchService) getDefaultPopularRoutes() []models.PopularRoute {
	return []models.PopularRoute{
		{FromStopName: "Colombo Fort", ToStopName: "Kandy", RouteCount: 0},
		{FromStopName: "Colombo Fort", ToStopName: "Galle", RouteCount: 0},
		{FromStopName: "Colombo Fort", ToStopName: "Anuradhapura", RouteCount: 0},
		{FromStopName: "Kandy", ToStopName: "Nuwara Eliya", RouteCount: 0},
		{FromStopName: "Galle", ToStopName: "Matara", RouteCount: 0},
		{FromStopName: "Colombo Fort", ToStopName: "Jaffna", RouteCount: 0},
		{FromStopName: "Colombo Fort", ToStopName: "Trincomalee", RouteCount: 0},
		{FromStopName: "Kandy", ToStopName: "Ella", RouteCount: 0},
		{FromStopName: "Negombo", ToStopName: "Colombo Fort", RouteCount: 0},
		{FromStopName: "Colombo Fort", ToStopName: "Katunayake", RouteCount: 0},
	}
}
