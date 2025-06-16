import 'dart:convert';

import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:travel_lens/core/errors/app_exception.dart';
import 'package:travel_lens/core/services/api_config.dart';

class WikipediaService {
  final http.Client _client;

  WikipediaService({http.Client? client}) : _client = client ?? http.Client();

  Future<String> getInformation(String query) async {
    try {
      // First search Wikipedia for the query
      final searchUrl = Uri.parse(
          '${ApiConfig.wikipediaBaseUrl}/page/search/title?q=${Uri.encodeComponent(query)}&limit=1');

      final searchResponse = await _client.get(
        searchUrl,
        headers: {'User-Agent': 'TravelLens/1.0'},
      ).timeout(const Duration(seconds: ApiConfig.defaultTimeout));

      if (searchResponse.statusCode != 200) {
        throw AppException(
          'Wikipedia search failed with status: ${searchResponse.statusCode}',
        );
      }

      final searchResults = json.decode(searchResponse.body);

      if (searchResults['pages']?.isEmpty ?? true) {
        return 'No information found about $query.';
      }

      final pageTitle = searchResults['pages'][0]['title'];

      // Now get the summary for the page
      final summaryUrl = Uri.parse(
          '${ApiConfig.wikipediaBaseUrl}/page/summary/${Uri.encodeComponent(pageTitle)}');

      final summaryResponse = await _client.get(
        summaryUrl,
        headers: {'User-Agent': 'TravelLens/1.0'},
      ).timeout(const Duration(seconds: ApiConfig.defaultTimeout));

      if (summaryResponse.statusCode != 200) {
        throw AppException(
          'Wikipedia summary failed with status: ${summaryResponse.statusCode}',
        );
      }

      final summaryResult = json.decode(summaryResponse.body);

      // Extract and clean the extract text
      String extract = summaryResult['extract'] ?? '';

      // Parse HTML and extract plain text if needed
      if (extract.contains('<')) {
        final document = parse(extract);
        extract = document.body?.text ?? extract;
      }

      return extract.isNotEmpty
          ? extract
          : 'No detailed information found about $query.';
    } catch (e) {
      if (e is AppException) {
        rethrow;
      } else {
        throw AppException('Failed to get information: $e');
      }
    }
  }
}
