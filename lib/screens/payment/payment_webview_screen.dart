import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_intent_provider.dart';
import '../../theme/app_colors.dart';
import '../bus_booking/booking_intent_flow_screen.dart';

/// WebView screen for payment gateway integration
///
/// This screen:
/// 1. Loads the payment gateway URL
/// 2. Monitors for success/failure redirects
/// 3. Returns PaymentResult to caller
class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String paymentReference;
  final double amount;
  final String intentId;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.paymentReference,
    required this.amount,
    required this.intentId,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  final Logger _logger = Logger();
  late WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  // URLs to watch for payment completion
  static const _successPatterns = [
    '/payment/success',
    '/payment-success',
    '/payment-return',
    '/payments/return',  // PAYable return URL
    'status=success',
    'status=SUCCESS',
    'status-view',
    'result=approved',
    'result=success',
    'SUCCESS',
    'payable.lk/success',
    'paymentstatus=success',
  ];

  static const _failurePatterns = [
    '/payment/failed',
    '/payment/failure',
    '/payment-failed',
    'status=failed',
    'status=failure',
    'status=error',
    'error',
    'result=declined',
    'result=failed',
  ];

  static const _cancelPatterns = [
    '/payment/cancel',
    '/payment-cancel',
    'status=cancelled',
    'status=canceled',
    'status=CANCELLED',
    'CANCELLED',
  ];

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            _logger.d('Loading: $progress%');
          },
          onPageStarted: (String url) {
            _logger.i('Page started: $url');
            setState(() => _isLoading = true);
            _checkPaymentStatus(url);
          },
          onPageFinished: (String url) {
            _logger.i('Page finished: $url');
            setState(() => _isLoading = false);
            _checkPaymentStatus(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            _logger.i('Navigation request: ${request.url}');

            // Check if this is a payment result URL
            final result = _checkPaymentStatus(request.url);
            if (result != null) {
              // Don't navigate, we'll handle the result
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            _logger.e('Web error: ${error.description}');
            setState(() {
              _errorMessage = 'Failed to load payment page';
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  /// Check URL for payment status and return result if found
  PaymentResult? _checkPaymentStatus(String url) {
    final lowerUrl = url.toLowerCase();

    // Check for success
    for (final pattern in _successPatterns) {
      if (lowerUrl.contains(pattern)) {
        _logger.i('Payment SUCCESS detected: $url');
        _handlePaymentSuccess();
        return PaymentResult(
          success: true,
          paymentReference: widget.paymentReference,
        );
      }
    }

    // Check for failure
    for (final pattern in _failurePatterns) {
      if (lowerUrl.contains(pattern)) {
        _logger.w('Payment FAILED detected: $url');
        _handlePaymentFailure('Payment was declined');
        return PaymentResult(
          success: false,
          paymentReference: widget.paymentReference,
          errorMessage: 'Payment was declined',
        );
      }
    }

    // Check for cancel
    for (final pattern in _cancelPatterns) {
      if (lowerUrl.contains(pattern)) {
        _logger.w('Payment CANCELLED detected: $url');
        _handlePaymentFailure('Payment was cancelled');
        return PaymentResult(
          success: false,
          paymentReference: widget.paymentReference,
          errorMessage: 'Payment was cancelled',
        );
      }
    }

    return null;
  }

  void _handlePaymentSuccess() {
    if (!mounted) return;

    Navigator.pop(
      context,
      PaymentResult(
        success: true,
        paymentReference: widget.paymentReference,
      ),
    );
  }

  void _handlePaymentFailure(String message) {
    if (!mounted) return;

    Navigator.pop(
      context,
      PaymentResult(
        success: false,
        paymentReference: widget.paymentReference,
        errorMessage: message,
      ),
    );
  }

  Future<void> _cancelPayment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text(
          'Are you sure you want to cancel? Your seat reservation will still be held until it expires.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue Payment'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      Navigator.pop(
        context,
        PaymentResult(
          success: false,
          paymentReference: widget.paymentReference,
          errorMessage: 'Payment cancelled by user',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _cancelPayment();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _cancelPayment,
          ),
          title: const Text(
            'Complete Payment',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          actions: [
            // Refresh button
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => _controller.reload(),
            ),
          ],
        ),
        body: Column(
          children: [
            // Payment info bar
            _buildPaymentInfoBar(),

            // Timer from provider
            _buildTimerBar(),

            // WebView
            Expanded(
              child: Stack(
                children: [
                  if (_errorMessage != null)
                    _buildErrorView()
                  else
                    WebViewWidget(controller: _controller),

                  // Loading overlay
                  if (_isLoading)
                    Container(
                      color: Colors.white.withOpacity(0.8),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.primary.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.payment, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ref: ${widget.paymentReference}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary.withOpacity(0.7),
                  ),
                ),
                Text(
                  'LKR ${widget.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'PENDING',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBar() {
    return Consumer<BookingIntentProvider>(
      builder: (context, provider, _) {
        final remaining = provider.remainingSeconds;
        if (remaining <= 0) {
          // Auto-close on expiry
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pop(
                context,
                PaymentResult(
                  success: false,
                  paymentReference: widget.paymentReference,
                  errorMessage: 'Session expired',
                ),
              );
            }
          });
        }

        final minutes = remaining ~/ 60;
        final seconds = remaining % 60;
        final isLow = remaining <= 120;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isLow ? Colors.red.shade100 : Colors.green.shade100,
          child: Row(
            children: [
              Icon(
                Icons.timer,
                size: 18,
                color: isLow ? Colors.red : Colors.green.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Time remaining: $minutes:${seconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isLow ? Colors.red : Colors.green.shade700,
                ),
              ),
              if (isLow) ...[
                const Spacer(),
                Text(
                  'Complete payment quickly!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _isLoading = true;
                });
                _controller.reload();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
