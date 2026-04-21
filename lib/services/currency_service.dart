import 'package:intl/intl.dart';

/// Service for handling multi-currency formatting and conversion
class CurrencyService {
  CurrencyService._();

  /// Currency symbol lookup table
  static const Map<String, String> _currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'CNY': '¥',
    'CAD': 'C\$',
    'AUD': 'A\$',
    'CHF': 'CHF ',
    'INR': '₹',
    'KRW': '₩',
    'BRL': 'R\$',
    'MXN': 'MX\$',
    'ZAR': 'R ',
    'SGD': 'S\$',
    'HKD': 'HK\$',
    'NOK': 'kr ',
    'SEK': 'kr ',
    'DKK': 'kr ',
    'PLN': 'zł ',
    'RUB': '₽',
    'TRY': '₺',
    'AED': 'د.إ ',
    'SAR': '﷼ ',
    'THB': '฿ ',
    'IDR': 'Rp ',
    'MYR': 'RM ',
    'PHP': '₱ ',
    'VND': '₫ ',
    'NGN': '₦ ',
    'EGP': 'E£ ',
    'ILS': '₪ ',
    'CZK': 'Kč ',
    'HUF': 'Ft ',
    'RON': 'lei ',
    'BGN': 'лв ',
    'HRK': 'kn ',
    'NZD': 'NZ\$ ',
    'CLP': 'CL\$ ',
    'COP': 'COL\$ ',
    'PEN': 'S/ ',
    'ARS': '\$ ',
    'TWD': 'NT\$ ',
    'PKR': '₨ ',
  };

  /// Currency name lookup table (optional, for display)
  static const Map<String, String> _currencyNames = {
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
    'CNY': 'Chinese Yuan',
    'CAD': 'Canadian Dollar',
    'AUD': 'Australian Dollar',
    'CHF': 'Swiss Franc',
    'INR': 'Indian Rupee',
    'KRW': 'South Korean Won',
    'BRL': 'Brazilian Real',
    'MXN': 'Mexican Peso',
    'ZAR': 'South African Rand',
    'SGD': 'Singapore Dollar',
    'HKD': 'Hong Kong Dollar',
    'NOK': 'Norwegian Krone',
    'SEK': 'Swedish Krona',
    'DKK': 'Danish Krone',
    'PLN': 'Polish Złoty',
    'RUB': 'Russian Ruble',
    'TRY': 'Turkish Lira',
    'AED': 'UAE Dirham',
    'SAR': 'Saudi Riyal',
    'THB': 'Thai Baht',
    'IDR': 'Indonesian Rupiah',
    'MYR': 'Malaysian Ringgit',
    'PHP': 'Philippine Peso',
    'VND': 'Vietnamese Dong',
    'NGN': 'Nigerian Naira',
    'EGP': 'Egyptian Pound',
    'ILS': 'Israeli Shekel',
    'CZK': 'Czech Koruna',
    'HUF': 'Hungarian Forint',
    'RON': 'Romanian Leu',
    'BGN': 'Bulgarian Lev',
    'HRK': 'Croatian Kuna',
    'NZD': 'New Zealand Dollar',
    'CLP': 'Chilean Peso',
    'COP': 'Colombian Peso',
    'PEN': 'Peruvian Sol',
    'ARS': 'Argentine Peso',
    'TWD': 'Taiwan Dollar',
    'PKR': 'Pakistani Rupee',
  };

  /// Commonly used currencies (for dropdowns)
  static const List<String> commonCurrencies = [
    'USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', 'INR',
  ];

  /// Get currency symbol for a given currency code
  static String getSymbol(String currencyCode) {
    final upperCode = currencyCode.toUpperCase();
    return _currencySymbols[upperCode] ?? currencyCode;
  }

  /// Get currency name for a given currency code
  static String getName(String currencyCode) {
    final upperCode = currencyCode.toUpperCase();
    return _currencyNames[upperCode] ?? currencyCode;
  }

  /// Format an amount with currency symbol
  static String format(
    double amount, {
    String currencyCode = 'USD',
    int decimalDigits = 0,
    bool showSymbol = true,
  }) {
    final upperCode = currencyCode.toUpperCase();
    final symbol = showSymbol ? getSymbol(upperCode) : '';

    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalDigits,
      name: upperCode,
      locale: _getLocaleForCurrency(upperCode),
    );

    return formatter.format(amount);
  }

  /// Format without symbol (code only)
  static String formatWithCode(
    double amount, {
    String currencyCode = 'USD',
    int decimalDigits = 0,
  }) {
    final upperCode = currencyCode.toUpperCase();
    final formatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: decimalDigits,
      name: upperCode,
    );
    return '${formatter.format(amount)} $upperCode';
  }

  /// Compact format for large numbers (e.g., $1.2M, $450K)
  static String formatCompact(
    double amount, {
    String currencyCode = 'USD',
  }) {
    final upperCode = currencyCode.toUpperCase();
    final symbol = getSymbol(upperCode);

    if (amount.abs() >= 1000000) {
      return '$symbol${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount.abs() >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(0)}K';
    }
    return format(amount, currencyCode: currencyCode);
  }

  /// Get locale for a given currency code (for proper number formatting)
  static String _getLocaleForCurrency(String currencyCode) {
    const localeMap = {
      'USD': 'en_US',
      'EUR': 'de_DE',
      'GBP': 'en_GB',
      'JPY': 'ja_JP',
      'CNY': 'zh_CN',
      'CAD': 'en_CA',
      'AUD': 'en_AU',
      'CHF': 'de_CH',
      'INR': 'en_IN',
      'KRW': 'ko_KR',
      'BRL': 'pt_BR',
      'MXN': 'es_MX',
      'ZAR': 'en_ZA',
      'SGD': 'en_SG',
      'HKD': 'zh_HK',
      'NOK': 'nb_NO',
      'SEK': 'sv_SE',
      'DKK': 'da_DK',
      'PLN': 'pl_PL',
      'RUB': 'ru_RU',
      'TRY': 'tr_TR',
      'AED': 'ar_AE',
      'SAR': 'ar_SA',
      'THB': 'th_TH',
      'IDR': 'id_ID',
      'MYR': 'ms_MY',
      'PHP': 'en_PH',
      'VND': 'vi_VN',
      'NGN': 'en_NG',
      'EGP': 'ar_EG',
      'ILS': 'he_IL',
      'CZK': 'cs_CZ',
      'HUF': 'hu_HU',
      'RON': 'ro_RO',
      'BGN': 'bg_BG',
      'HRK': 'hr_HR',
      'NZD': 'en_NZ',
      'CLP': 'es_CL',
      'COP': 'es_CO',
      'PEN': 'es_PE',
      'ARS': 'es_AR',
      'TWD': 'zh_TW',
      'PKR': 'ur_PK',
    };
    return localeMap[currencyCode] ?? 'en_US';
  }

  /// Validate if a currency code is supported
  static bool isValidCurrency(String currencyCode) {
    return _currencySymbols.containsKey(currencyCode.toUpperCase());
  }

  /// Get all supported currency codes
  static List<String> getAllCurrencies() {
    return _currencySymbols.keys.toList()..sort();
  }

  /// Parse amount from formatted string (basic implementation)
  static double? parse(String formattedAmount) {
    // Remove currency symbols and spaces, then parse
    final cleaned = formattedAmount
        .replaceAll(RegExp(r'[\$\€\£\¥\₹\₩\₽\₺\฿\₱\₫\₦\£\₪\₡\₢]'), '')
        .replaceAll(RegExp(r'[a-zA-Z]'), '')
        .replaceAll(',', '')
        .trim();
    return double.tryParse(cleaned);
  }
}

/// Extension for double to easily format as currency
extension CurrencyFormat on double {
  String toCurrency({String currencyCode = 'USD', int decimalDigits = 0}) {
    return CurrencyService.format(
      this,
      currencyCode: currencyCode,
      decimalDigits: decimalDigits,
    );
  }

  String toCompactCurrency({String currencyCode = 'USD'}) {
    return CurrencyService.formatCompact(
      this,
      currencyCode: currencyCode,
    );
  }
}
