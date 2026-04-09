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

// SearchTrips searches for available trips between two locations
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

	s.logger.WithFields(logrus.Fields{
		"from":    req.From,
		"to":      req.To,
		"user_id": userID,
	}).Info("=== SearchService: Processing search request ===")

	// Initialize response
	response := &models.SearchResponse{
		Status: "success",
		SearchDetails: models.SearchDetails{
			FromStop: models.StopInfo{
				OriginalInput: req.From,
				Matched:       false,
			},
			ToStop: models.StopInfo{
				OriginalInput: req.To,
				Matched:       false,
			},
			SearchType: "exact",
		},
		Results: []models.TripResult{},
	}

	// Step 1: Find stop pair on same route with fuzzy matching
	stopPair, err := s.repo.FindStopPairOnSameRoute(req.From, req.To)
	if err != nil {
		s.logger.WithError(err).Error("Error finding stop pair")
		return nil, fmt.Errorf("error searching for stops: %w", err)
	}

	response.SearchDetails.FromStop = *stopPair.FromStop
	response.SearchDetails.ToStop = *stopPair.ToStop

	// Check if stop pair was found
	if !stopPair.Matched {
		// FALLBACK: Intelligent Intercept Discovery
		s.logger.Info("Direct route not found, attempting Intelligent Intercept Discovery...")
		
		// Use provided coordinates if available, otherwise fallback to repository resolution
		var interceptPair *database.StopPairResult
		var interceptErr error
		
		interceptPair, interceptErr = s.repo.FindInterceptStopPair(req.From, req.To, req.FromLat, req.FromLng)
		
		if interceptErr != nil {
			s.logger.WithError(interceptErr).Error("Error finding intercept pair")
		} else if interceptPair != nil && interceptPair.Matched {
			s.logger.WithFields(logrus.Fields{
				"intercept_from": interceptPair.FromStop.Name,
				"intercept_to":   interceptPair.ToStop.Name,
				"route":          interceptPair.RouteName,
			}).Info("Successfully discovered intercept stop for route segment")
			
			// Override stopPair with our intelligent intercept pair
			stopPair = interceptPair
			response.SearchDetails.FromStop = *stopPair.FromStop
			response.SearchDetails.ToStop = *stopPair.ToStop
			response.SearchDetails.SearchType = "intercept"
			response.SearchDetails.InterceptInfo = &models.InterceptInfo{
				UserInput:       req.From,
				NearestStopName: interceptPair.FromStop.Name,
				DistanceKm:      interceptPair.DistanceKm,
				DistanceStr:     interceptPair.DistanceStr,
				RouteName:       interceptPair.RouteName,
			}
			response.Message = fmt.Sprintf(
				"No direct bus from %s to %s. You can join the '%s' service at '%s' (%s from your location).",
				req.From,
				req.To,
				stopPair.RouteName,
				stopPair.FromStop.Name,
				interceptPair.DistanceStr,
			)

		}

		if !stopPair.Matched {
			// If even the intercept approach failed, return the partial failure
			response.Status = "partial"
			if !stopPair.FromStop.Matched && !stopPair.ToStop.Matched {
				response.Message = fmt.Sprintf(
					"Could not find stops '%s' and '%s' on any active route. Please check spelling or try nearby locations.",
					req.From,
					req.To,
				)
			} else if !stopPair.FromStop.Matched {
				response.Message = fmt.Sprintf(
					"Origin stop '%s' not found on any route to '%s' (nor any intercept points could be found).",
					req.From,
					req.To,
				)
			} else {
				response.Message = fmt.Sprintf(
					"Destination stop '%s' not found on any route from '%s'.",
					req.To,
					req.From,
				)
			}
			response.SearchDetails.SearchType = "failed"
			s.logSearch(req, response, userID, &ipAddress, time.Since(startTime))
			return response, nil
		}
	}

	s.logger.WithFields(logrus.Fields{
		"from_stop": stopPair.FromStop.Name,
		"to_stop":   stopPair.ToStop.Name,
		"route":     stopPair.RouteName,
		"route_id":  stopPair.RouteID,
	}).Info("Found stop pair on same route")

	// Step 2: Get search datetime (default to now if not provided)
	searchTime := req.GetSearchDateTime()

	// Step 3: Find available trips
	s.logger.WithFields(logrus.Fields{
		"from_stop_id": stopPair.FromID.String(),
		"to_stop_id":   stopPair.ToID.String(),
		"search_time":  searchTime,
		"limit":        req.Limit,
	}).Info("Querying database for trips...")

	trips, err := s.repo.FindDirectTrips(stopPair.FromID, stopPair.ToID, searchTime, req.Limit)
	if err != nil {
		s.logger.WithError(err).Error("Error finding trips from database")
		return nil, fmt.Errorf("error searching for trips: %w", err)
	}

	s.logger.WithField("trips_found", len(trips)).Info("Database query completed successfully")

	// Step 4: Fetch route stops for each trip (for passenger to select boarding/alighting)
	for i := range trips {
		// Debug: Log master_route_id for each trip
		if trips[i].MasterRouteID != nil {
			s.logger.WithFields(logrus.Fields{
				"trip_id":         trips[i].TripID,
				"master_route_id": *trips[i].MasterRouteID,
			}).Info("Trip has master_route_id")
			stops, err := s.repo.GetRouteStopsForTrip(*trips[i].MasterRouteID, trips[i].BusOwnerRouteID)
			if err != nil {
				s.logger.WithError(err).WithField("trip_id", trips[i].TripID).Warn("Failed to fetch route stops for trip")
				// Continue without stops - not a fatal error
			} else {
				trips[i].RouteStops = stops
			}
		} else {
			s.logger.WithField("trip_id", trips[i].TripID).Warn("Trip has NULL master_route_id!")
		}
	}

	response.Results = trips

	// Step 5: Build appropriate message
	if len(trips) == 0 {
		response.Status = "success"
		response.Message = fmt.Sprintf(
			"No direct trips found from %s to %s for the selected date. Showing potential route details.",
			stopPair.FromStop.Name,
			stopPair.ToStop.Name,
		)

		// Create a skeleton TripResult to show the route details
		skeletonID := uuid.New()
		skeletonTrip := models.TripResult{
			TripID:        skeletonID,
			RouteName:     stopPair.RouteName,
			RouteNumber:   &stopPair.RouteNumber,
			BoardingPoint: stopPair.FromStop.Name,
			DroppingPoint: stopPair.ToStop.Name,
			IsBookable:    false, // IMPORTANT: mark as not bookable
			BusType:       "Unknown",
		}

		// Fetch route stops for the skeleton trip
		routeIDStr := stopPair.RouteID.String()
		stops, err := s.repo.GetRouteStopsForTrip(routeIDStr, nil)
		if err == nil {
			skeletonTrip.RouteStops = stops
		}

		response.Results = append(response.Results, skeletonTrip)
	} else {
		response.Status = "success"
		response.Message = fmt.Sprintf(
			"Found %d trip(s) from %s to %s",
			len(trips),
			stopPair.FromStop.Name,
			stopPair.ToStop.Name,
		)
	}

	// Step 7: Calculate search time
	responseTime := time.Since(startTime)
	response.SearchTimeMs = responseTime.Milliseconds()

	// Step 8: Log search for analytics
	s.logSearch(req, response, userID, &ipAddress, responseTime)

	s.logger.WithFields(logrus.Fields{
		"from":        req.From,
		"to":          req.To,
		"results":     len(trips),
		"response_ms": response.SearchTimeMs,
	}).Info("Search completed successfully")

	s.logger.Info("=== SearchService: Returning response (JSON marshaling will happen next) ===")

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

	// If no popular routes from analytics, return hardcoded popular routes
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

// logSearch logs the search request for analytics
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

	// Add stop IDs if matched
	if response.SearchDetails.FromStop.ID != nil {
		log.FromStopID = response.SearchDetails.FromStop.ID
	}
	if response.SearchDetails.ToStop.ID != nil {
		log.ToStopID = response.SearchDetails.ToStop.ID
	}

	// Log asynchronously to not block response
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
