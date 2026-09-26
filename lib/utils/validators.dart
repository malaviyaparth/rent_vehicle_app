/// Comprehensive input validators for the rental application.
class Validators {
  /// Validates an email address ensuring proper format and standard domain extensions.
  /// Explicitly disallows invalid domain extensions such as `abc@gmail.dom`
  /// and ensures recognized provider formats (e.g. Gmail must end with @gmail.com).
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final email = value.trim();

    // Standard RFC 5322 pattern check
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    final parts = email.split('@');
    if (parts.length != 2) {
      return 'Please enter a valid email address';
    }

    final domain = parts[1].toLowerCase();
    final domainParts = domain.split('.');
    if (domainParts.length < 2) {
      return 'Email must include a valid domain extension';
    }

    final tld = domainParts.last;

    // Recognized top-level domain extensions
    const validTlds = {
      'com', 'org', 'net', 'edu', 'gov', 'mil', 'in', 'co', 'io', 'ai',
      'app', 'dev', 'me', 'info', 'biz', 'us', 'uk', 'ca', 'au', 'de',
      'fr', 'jp', 'online', 'store', 'tech', 'site', 'xyz', 'live', 'global',
      'int', 'co.in', 'ac.in', 'gov.in'
    };

    if (!validTlds.contains(tld)) {
      return 'Invalid domain extension (e.g. use .com, .in, .org)';
    }

    // Provider-specific domain validations to catch typos like @gmail.dom
    final provider = domainParts[0];
    if (provider == 'gmail' && tld != 'com') {
      return 'Gmail must end with @gmail.com (not .$tld)';
    }

    if (provider == 'yahoo') {
      final validYahooTlds = {'com', 'in', 'co.in'};
      final ext = domainParts.skip(1).join('.');
      if (!validYahooTlds.contains(ext) && !validYahooTlds.contains(tld)) {
        return 'Yahoo must end with @yahoo.com or @yahoo.in';
      }
    }

    if ((provider == 'outlook' || provider == 'hotmail') && tld != 'com') {
      return '$provider address must end with .com';
    }

    return null;
  }
}
