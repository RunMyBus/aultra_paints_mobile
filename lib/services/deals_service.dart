import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/deal.dart';
import 'config.dart';

class DealsService {
  /// Fetch the list of currently-active deals for the logged-in user.
  ///
  /// The server resolves the dealer's category from the JWT and filters
  /// server-side. We just pass the bearer token along.
  ///
  /// On success returns the parsed list (which can be empty). On error
  /// (network drop, 4xx/5xx, malformed JSON) returns an empty list — the
  /// caller treats this as "no deals to show" and skips the dialog. We
  /// never want a flaky deals call to interrupt the post-login UX.
  static Future<List<Deal>> fetchActiveDeals(String bearerToken) async {
    try {
      final response = await http
          .get(
            Uri.parse('$BASE_URL$GET_ACTIVE_DEALS'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': bearerToken,
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return const [];
      final body = json.decode(response.body);
      if (body is! List) return const [];
      return body
          .whereType<Map<String, dynamic>>()
          .map(Deal.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}
