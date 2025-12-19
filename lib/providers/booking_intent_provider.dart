import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../models/booking_intent_models.dart';
import '../services/booking_intent_service.dart';

/// Provider for managing booking intent state (Intent → Payment → Confirm flow)
///
/// This provider manages the entire booking orchestration lifecycle:
/// - Creating intents and holding seats
/// - Countdown timer for TTL
/// - Payment initiation
/// - Booking confirmation
class BookingIntentProvider with ChangeNotifier {
  final BookingIntentService _service = BookingIntentService();
  final Logger _logger = Logger();

  // ============================================================================
  // STATE
  // ============================================================================

  // Current intent state
  BookingIntentResponse? _currentIntent;
  IntentStatusResponse? _currentStatus;
  InitiatePaymentResponse? _paymentInfo;
  ConfirmBookingResponse? _confirmedBooking;

  // Loading states
  bool _isCreatingIntent = false;
  bool _isLoadingStatus = false;
  bool _isInitiatingPayment = false;
  bool _isConfirmingBooking = false;
  bool _isCancellingIntent = false;

  // Error state
  String? _errorMessage;
  PartialAvailabilityError? _partialAvailabilityError;

  // Timer for countdown
  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  // Intent list (for history)
  List<BookingIntentListItem> _myIntents = [];
  bool _loadingIntents = false;

  // ============================================================================
  // GETTERS
  // ============================================================================

  BookingIntentResponse? get currentIntent => _currentIntent;
  IntentStatusResponse? get currentStatus => _currentStatus;
  InitiatePaymentResponse? get paymentInfo => _paymentInfo;
  ConfirmBookingResponse? get confirmedBooking => _confirmedBooking;

  bool get isCreatingIntent => _isCreatingIntent;
  bool get isLoadingStatus => _isLoadingStatus;
  bool get isInitiatingPayment => _isInitiatingPayment;
  bool get isConfirmingBooking => _isConfirmingBooking;
  bool get isCancellingIntent => _isCancellingIntent;
  bool get isLoading =>
      _isCreatingIntent ||
      _isLoadingStatus ||
      _isInitiatingPayment ||
      _isConfirmingBooking ||
      _isCancellingIntent;

  String? get errorMessage => _errorMessage;
  PartialAvailabilityError? get partialAvailabilityError =>
      _partialAvailabilityError;
  bool get hasError => _errorMessage != null;
  bool get hasPartialAvailability => _partialAvailabilityError != null;

  int get remainingSeconds => _remainingSeconds;
  String get formattedRemainingTime {
    if (_remainingSeconds <= 0) return '0:00';
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  bool get isExpired => _remainingSeconds <= 0;
  bool get hasActiveIntent =>
      _currentIntent != null && !isExpired && _currentIntent!.status.isPending;

  List<BookingIntentListItem> get myIntents => _myIntents;
  bool get loadingIntents => _loadingIntents;

  // Flow state helpers
  BookingFlowState get flowState {
    if (_confirmedBooking != null) return BookingFlowState.confirmed;
    if (_paymentInfo != null) return BookingFlowState.awaitingPayment;
    if (_currentIntent != null && !isExpired) {
      return BookingFlowState.intentCreated;
    }
    if (_currentIntent != null && isExpired) {
      return BookingFlowState.expired;
    }
    return BookingFlowState.initial;
  }

  // ============================================================================
  // CREATE INTENT
  // ============================================================================

  /// Create a new booking intent
  ///
  /// For bus-only booking:
  /// ```dart
  /// await provider.createBusIntent(
  ///   scheduledTripId: 'trip-123',
  ///   seats: [IntentSeatRequest(seatNumber: '1A', passengerName: 'John', nic: '...')],
  ///   boardingStopId: 'stop-1',
  ///   alightingStopId: 'stop-2',
  /// );
  /// ```
  Future<bool> createIntent(CreateBookingIntentRequest request) async {
    _isCreatingIntent = true;
    _errorMessage = null;
    _partialAvailabilityError = null;
    notifyListeners();

    try {
      _logger.i('Creating intent: ${request.intentType.displayName}');

      final response = await _service.createIntent(request);

      _currentIntent = response;
      _paymentInfo = null;
      _confirmedBooking = null;

      // Start countdown timer
      _startCountdownTimer(response.expiresAt);

      _isCreatingIntent = false;
      notifyListeners();

      _logger.i('Intent created successfully: ${response.intentId}');
      return true;
    } on PartialAvailabilityException catch (e) {
      _logger.w('Partial availability: ${e.error.displayMessage}');
      _partialAvailabilityError = e.error;
      _isCreatingIntent = false;
      notifyListeners();
      return false;
    } catch (e) {
      _logger.e('Error creating intent: $e');
      _errorMessage = e.toString();
      _isCreatingIntent = false;
      notifyListeners();
      return false;
    }
  }

  /// Convenience method for bus-only booking
  Future<bool> createBusIntent({
    required String scheduledTripId,
    required List<IntentSeatRequest> seats,
    required String boardingStopId,
    required String alightingStopId,
    required String boardingStopName,
    required String alightingStopName,
    required String passengerName,
    required String passengerPhone,
    String? passengerEmail,
  }) async {
    final request = CreateBookingIntentRequest(
      intentType: IntentType.busOnly,
      bus: BusIntentRequest(
        scheduledTripId: scheduledTripId,
        seats: seats,
        boardingStopId: boardingStopId,
        alightingStopId: alightingStopId,
        boardingStopName: boardingStopName,
        alightingStopName: alightingStopName,
        passengerName: passengerName,
        passengerPhone: passengerPhone,
        passengerEmail: passengerEmail,
      ),
    );
    return createIntent(request);
  }

  /// Convenience method for bus + lounge booking
  Future<bool> createBusWithLoungeIntent({
    required String scheduledTripId,
    required List<IntentSeatRequest> seats,
    required String boardingStopId,
    required String alightingStopId,
    required String boardingStopName,
    required String alightingStopName,
    required String passengerName,
    required String passengerPhone,
    String? passengerEmail,
    LoungeIntentRequest? preTripLounge,
    LoungeIntentRequest? postTripLounge,
  }) async {
    IntentType type = IntentType.busOnly;
    if (preTripLounge != null && postTripLounge != null) {
      type = IntentType.busWithBothLounges;
    } else if (preTripLounge != null) {
      type = IntentType.busWithPreLounge;
    } else if (postTripLounge != null) {
      type = IntentType.busWithPostLounge;
    }

    final request = CreateBookingIntentRequest(
      intentType: type,
      bus: BusIntentRequest(
        scheduledTripId: scheduledTripId,
        seats: seats,
        boardingStopId: boardingStopId,
        alightingStopId: alightingStopId,
        boardingStopName: boardingStopName,
        alightingStopName: alightingStopName,
        passengerName: passengerName,
        passengerPhone: passengerPhone,
        passengerEmail: passengerEmail,
      ),
      preTripLounge: preTripLounge,
      postTripLounge: postTripLounge,
    );
    return createIntent(request);
  }

  /// Convenience method for lounge-only booking
  Future<bool> createLoungeOnlyIntent({
    required LoungeIntentRequest loungeIntent,
  }) async {
    final request = CreateBookingIntentRequest.loungeOnly(
      preTripLounge: loungeIntent,
    );
    return createIntent(request);
  }

  // ============================================================================
  // ADD LOUNGE TO INTENT
  // ============================================================================

  /// Add lounge to existing bus-only intent
  ///
  /// Use this after creating a bus-only intent when user wants to add lounges.
  /// This extends the hold timer and updates pricing.
  Future<bool> addLoungeToIntent({
    LoungeIntentRequest? preTripLounge,
    LoungeIntentRequest? postTripLounge,
  }) async {
    if (_currentIntent == null) {
      _errorMessage = 'No active intent to add lounge to';
      notifyListeners();
      return false;
    }

    if (isExpired) {
      _errorMessage = 'Intent has expired';
      notifyListeners();
      return false;
    }

    if (preTripLounge == null && postTripLounge == null) {
      _logger.i('No lounges to add, skipping');
      return true; // Nothing to add, just continue
    }

    _isCreatingIntent = true; // Reuse loading state
    _errorMessage = null;
    notifyListeners();

    try {
      _logger.i('Adding lounge to intent: ${_currentIntent!.intentId}');

      final response = await _service.addLoungeToIntent(
        intentId: _currentIntent!.intentId,
        preTripLounge: preTripLounge,
        postTripLounge: postTripLounge,
      );

      // Update current intent with new data
      _currentIntent = response;

      // Restart countdown with extended expiry
      _startCountdownTimer(response.expiresAt);

      _isCreatingIntent = false;
      notifyListeners();

      _logger.i('Lounge added, new total: ${response.pricing.formattedTotal}');
      return true;
    } catch (e) {
      _logger.e('Error adding lounge: $e');
      _errorMessage = e.toString();
      _isCreatingIntent = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================================================
  // GET STATUS
  // ============================================================================

  /// Refresh status of current intent
  Future<void> refreshIntentStatus() async {
    if (_currentIntent == null) return;

    _isLoadingStatus = true;
    notifyListeners();

    try {
      final status = await _service.getIntentStatus(_currentIntent!.intentId);
      _currentStatus = status;

      // Update remaining time
      _remainingSeconds = status.remainingSeconds;

      // If expired or not pending, stop timer
      if (status.isExpired || !status.status.isPending) {
        _stopCountdownTimer();
      }

      _isLoadingStatus = false;
      notifyListeners();

      _logger.i('Status refreshed: ${status.status.displayName}');
    } catch (e) {
      _logger.e('Error refreshing status: $e');
      _isLoadingStatus = false;
      notifyListeners();
    }
  }

  // ============================================================================
  // INITIATE PAYMENT
  // ============================================================================

  /// Initiate payment for current intent
  Future<bool> initiatePayment() async {
    if (_currentIntent == null) {
      _errorMessage = 'No active intent';
      notifyListeners();
      return false;
    }

    if (isExpired) {
      _errorMessage = 'Intent has expired';
      notifyListeners();
      return false;
    }

    _isInitiatingPayment = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _logger.i('Initiating payment for: ${_currentIntent!.intentId}');

      final response =
          await _service.initiatePayment(_currentIntent!.intentId);
      _paymentInfo = response;

      _isInitiatingPayment = false;
      notifyListeners();

      _logger.i('Payment initiated: ${response.paymentReference}');
      return true;
    } catch (e) {
      _logger.e('Error initiating payment: $e');
      _errorMessage = e.toString();
      _isInitiatingPayment = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================================================
  // CONFIRM BOOKING
  // ============================================================================

  /// Confirm booking after payment success
  Future<bool> confirmBooking(String paymentReference) async {
    if (_currentIntent == null) {
      _errorMessage = 'No active intent';
      notifyListeners();
      return false;
    }

    _isConfirmingBooking = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _logger.i('Confirming booking: ${_currentIntent!.intentId}');
      _logger.i('Payment reference: $paymentReference');

      final response = await _service.confirmBooking(
        intentId: _currentIntent!.intentId,
        paymentReference: paymentReference,
      );

      _confirmedBooking = response;
      _stopCountdownTimer();

      _isConfirmingBooking = false;
      notifyListeners();

      _logger.i('Booking confirmed: ${response.masterReference}');
      _logger.i('Has bus: ${response.busBooking != null}, Has pre-lounge: ${response.preLoungeBooking != null}, Has post-lounge: ${response.postLoungeBooking != null}');
      if (response.preLoungeBooking != null) {
        _logger.i('Pre-lounge in provider: ${response.preLoungeBooking!.reference}');
      }
      if (response.postLoungeBooking != null) {
        _logger.i('Post-lounge in provider: ${response.postLoungeBooking!.reference}');
      }
      return true;
    } on IntentExpiredException catch (e) {
      _logger.e('Intent expired: $e');
      _errorMessage = 'Your session has expired. Please try again.';
      _stopCountdownTimer();
      _isConfirmingBooking = false;
      notifyListeners();
      return false;
    } on SeatsNoLongerAvailableException catch (e) {
      _logger.e('Seats unavailable: $e');
      _errorMessage = 'Selected seats are no longer available';
      _isConfirmingBooking = false;
      notifyListeners();
      return false;
    } catch (e) {
      _logger.e('Error confirming booking: $e');
      _errorMessage = e.toString();
      _isConfirmingBooking = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================================================
  // CANCEL INTENT
  // ============================================================================

  /// Cancel current intent and release holds
  Future<bool> cancelIntent() async {
    if (_currentIntent == null) return true;

    _isCancellingIntent = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _logger.i('Cancelling intent: ${_currentIntent!.intentId}');

      await _service.cancelIntent(_currentIntent!.intentId);

      // Clear state
      _currentIntent = null;
      _currentStatus = null;
      _paymentInfo = null;
      _stopCountdownTimer();

      _isCancellingIntent = false;
      notifyListeners();

      _logger.i('Intent cancelled successfully');
      return true;
    } catch (e) {
      _logger.e('Error cancelling intent: $e');
      _errorMessage = e.toString();
      _isCancellingIntent = false;
      notifyListeners();
      return false;
    }
  }

  // ============================================================================
  // GET MY INTENTS
  // ============================================================================

  /// Load user's intent history
  Future<void> loadMyIntents({int limit = 20, int offset = 0}) async {
    _loadingIntents = true;
    notifyListeners();

    try {
      _myIntents = await _service.getMyIntents(limit: limit, offset: offset);
      _loadingIntents = false;
      notifyListeners();

      _logger.i('Loaded ${_myIntents.length} intents');
    } catch (e) {
      _logger.e('Error loading intents: $e');
      _loadingIntents = false;
      notifyListeners();
    }
  }

  // ============================================================================
  // TIMER MANAGEMENT
  // ============================================================================

  void _startCountdownTimer(DateTime expiresAt) {
    _stopCountdownTimer();

    // Calculate initial remaining time (expiresAt is UTC, so use UTC now)
    _remainingSeconds = expiresAt.difference(DateTime.now().toUtc()).inSeconds;
    if (_remainingSeconds < 0) _remainingSeconds = 0;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _stopCountdownTimer();
        _logger.w('Intent expired');
        notifyListeners();
      }
    });

    _logger.i('Countdown started: $_remainingSeconds seconds');
  }

  void _stopCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  // ============================================================================
  // RESET / CLEANUP
  // ============================================================================

  /// Reset all state for new booking
  void reset() {
    _stopCountdownTimer();
    _currentIntent = null;
    _currentStatus = null;
    _paymentInfo = null;
    _confirmedBooking = null;
    _errorMessage = null;
    _partialAvailabilityError = null;
    _remainingSeconds = 0;
    notifyListeners();

    _logger.i('BookingIntentProvider reset');
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    _partialAvailabilityError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopCountdownTimer();
    super.dispose();
  }
}

// ============================================================================
// BOOKING FLOW STATE ENUM
// ============================================================================

/// Represents the current state of the booking flow
enum BookingFlowState {
  /// No intent created yet
  initial,

  /// Intent created, seats held
  intentCreated,

  /// Payment initiated, waiting for completion
  awaitingPayment,

  /// Booking confirmed
  confirmed,

  /// Intent expired
  expired,
}

extension BookingFlowStateExtension on BookingFlowState {
  String get displayName {
    switch (this) {
      case BookingFlowState.initial:
        return 'Select Seats';
      case BookingFlowState.intentCreated:
        return 'Proceed to Payment';
      case BookingFlowState.awaitingPayment:
        return 'Complete Payment';
      case BookingFlowState.confirmed:
        return 'Booking Confirmed';
      case BookingFlowState.expired:
        return 'Session Expired';
    }
  }

  bool get canProceedToPayment => this == BookingFlowState.intentCreated;
  bool get canConfirm => this == BookingFlowState.awaitingPayment;
  bool get isComplete => this == BookingFlowState.confirmed;
}
