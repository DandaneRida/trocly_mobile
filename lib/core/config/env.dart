/// Trocly environment configuration
class Env {
  /// Backend API base URL (no trailing slash)
  static const String apiUrl = 'http://10.0.2.2:3000'; // Android emulator → host
  // static const String apiUrl = 'http://localhost:3000'; // iOS simulator / web

  /// WebSocket URL for real-time chat
  static const String wsUrl = 'ws://10.0.2.2:3000';

  /// OTP dev bypass code
  static const String devOtpCode = '123456';

  /// OTP TTL in seconds
  static const int otpTtlSeconds = 300; // 5 min

  /// OTP resend cooldown in seconds
  static const int otpResendCooldown = 60;

  /// Meeting expiration offset (hours after scheduled_at)
  static const int meetingExpiryHours = 2;

  /// Max photos per listing
  static const int maxPhotosPerListing = 5;

  /// Moroccan phone prefix
  static const String phonePrefix = '+212';

  /// Phone regex (after +212)
  static final RegExp phoneRegex = RegExp(r'^[67]\d{8}$');
}
