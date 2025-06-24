import 'dart:io';
import 'dart:convert'; // Required for JSON encoding
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';

/// Function to search for specific text within a designated section of a website's HTML.
///
/// [url]: The URL of the website to fetch HTML from.
/// [searchText]: The specific text to search for (e.g., "Electrical Power System").
/// [sectionIdentifier]: The text that identifies the desired section (e.g., "Winter 2024").
///
/// Returns `true` if the [searchText] is found within the identified [sectionIdentifier],
/// `false` otherwise, or if any error occurs.
Future<bool> searchTextInWebsiteHtml(String url, String searchText, String sectionIdentifier) async {
  try {
    // 1. Fetch the HTML content from the given URL
    final response = await http.get(Uri.parse(url));

    // Check if the request was successful (status code 200)
    if (response.statusCode == 200) {
      // 2. Parse the HTML content
      final Document document = parse(response.body);

      String sectionContent = '';
      bool sectionFound = false;

      // 3. Iterate through all elements to find the section identifier
      // We are looking for any element whose text content contains the sectionIdentifier.
      // This is a robust way to find a section without knowing its exact tag or class.
      for (final element in document.querySelectorAll('*')) {
        if (element.text.toLowerCase().contains(sectionIdentifier.toLowerCase())) {
          // If the section is found, capture its entire text content (including children's text)
          sectionContent = element.text;
          sectionFound = true;
          stderr.writeln('Found section: "$sectionIdentifier". Extracting content for further search.'); // Use stderr for logs
          // Once the section is found, we can break the loop
          break;
        }
      }

      if (!sectionFound) {
        stderr.writeln('Section "$sectionIdentifier" not found on the page.'); // Use stderr for logs
        return false;
      }

      // 4. Search for the specified text within the content of the identified section
      // We'll convert both to lowercase to make the search case-insensitive
      if (sectionContent.toLowerCase().contains(searchText.toLowerCase())) {
        stderr.writeln('Found "$searchText" within the "$sectionIdentifier" section.'); // Use stderr for logs
        return true;
      } else {
        stderr.writeln('"$searchText" not found within the "$sectionIdentifier" section.'); // Use stderr for logs
        return false;
      }
    } else {
      // Handle HTTP error status codes
      stderr.writeln('Failed to load page: ${response.statusCode}. Status: ${response.statusCode}'); // Use stderr for logs
      return false;
    }
  } catch (e) {
    // Handle any other errors (e.g., network issues, invalid URL)
    stderr.writeln('An error occurred: $e'); // Use stderr for logs
    return false;
  }
}

/// A standalone function to find specific <a> tags within a <div> identified by its ID.
///
/// [url]: The URL of the website to fetch HTML from.
/// [divId]: The ID of the <div> element to search within (e.g., "v-pills-all-1").
/// [linkTextToFind]: The partial or exact text content of the <a> tags to find (e.g., "Fifth Semester").
///
/// Returns a `List<Element>` containing all <a> tags that match the criteria.
/// Returns an empty list if the div is not found, or no matching links are found, or an error occurs.
Future<List<Element>> findSpecificLinksInDiv(String url, String divId, String linkTextToFind) async {
  try {
    // 1. Fetch the HTML content from the given URL
    final response = await http.get(Uri.parse(url));

    // Check if the request was successful (status code 200)
    if (response.statusCode == 200) {
      // 2. Parse the HTML content
      final Document document = parse(response.body);

      // 3. Find the div element by its ID
      final Element? targetDiv = document.getElementById(divId);

      if (targetDiv == null) {
        stderr.writeln('Div with ID "$divId" not found on the page.'); // Use stderr for logs
        return []; // Return empty list if div not found
      }

      // 4. Find all <a> tags within the target div
      // .querySelectorAll('a') will find all <a> descendants of targetDiv
      final List<Element> allAnchorTagsInDiv = targetDiv.querySelectorAll('a');

      // 5. Filter the <a> tags based on their text content (now supporting partial match)
      final List<Element> matchingLinks = allAnchorTagsInDiv.where((anchor) {
        // Trim whitespace from anchor text and convert both to lowercase for case-insensitive partial matching
        return anchor.text.trim().toLowerCase().contains(linkTextToFind.toLowerCase());
      }).toList();

      if (matchingLinks.isEmpty) {
        stderr.writeln('No <a> tags with text containing "$linkTextToFind" found inside div "$divId".'); // Use stderr for logs
      } else {
        stderr.writeln('Found ${matchingLinks.length} matching <a> tags inside div "$divId".'); // Use stderr for logs
      }

      return matchingLinks;
    } else {
      // Handle HTTP error status codes
      stderr.writeln('Failed to load page: ${response.statusCode}. Status: ${response.statusCode}'); // Use stderr for logs
      return []; // Return empty list on HTTP error
    }
  } catch (e) {
    // Handle any other errors (e.g., network issues, invalid URL)
    stderr.writeln('An error occurred: $e'); // Use stderr for logs
    return []; // Return empty list on general error
  }
}

void main() async {
  // Appwrite function input handling (keeping it for future extensibility)
  String? inputData = Platform.environment['APPWRITE_FUNCTION_DATA'];
  if (inputData == null || inputData.isEmpty) {
    try {
      inputData = stdin.readLineSync();
    } catch (e) {
      stderr.writeln('Error reading from stdin: $e');
      inputData = '{}'; // Default to empty JSON
    }
  }

  Map<String, dynamic> requestPayload = {};
  if (inputData != null && inputData.isNotEmpty) {
    try {
      requestPayload = json.decode(inputData) as Map<String, dynamic>;
    } catch (e) {
      stderr.writeln('Error parsing input JSON: $e');
      requestPayload = {'error': 'Invalid JSON input'};
    }
  }

  // Use values from payload if provided, otherwise use hardcoded defaults
  const String defaultTargetUrl = 'https://gug.digitaluniversity.ac/results';
  const String defaultDivIdToSearch = 'v-pills-all-2';
  const String defaultLinkTextToMatch = 'M.Tech';

  String targetUrl = requestPayload['url'] ?? defaultTargetUrl;
  String divIdToSearch = requestPayload['divId'] ?? defaultDivIdToSearch;
  String linkTextToMatch = requestPayload['linkText'] ?? defaultLinkTextToMatch;

  List<Element> foundLinks = await findSpecificLinksInDiv(targetUrl, divIdToSearch, linkTextToMatch);

  String resultString;
  List<Map<String, String>> linksDetails = [];

  if (foundLinks.isNotEmpty) {
    resultString = 'Found links matching the criteria.';
    for (var link in foundLinks) {
      linksDetails.add({'text': link.text.trim(), 'href': link.attributes['href'] ?? 'N/A'});
    }
  } else {
    resultString = 'No links found matching the criteria.';
  }

  // Prepare the final JSON response
  Map<String, dynamic> response = {
    'status': 'success',
    'message': resultString,
    'query_parameters': {
      'url': targetUrl,
      'divId': divIdToSearch,
      'linkText': linkTextToMatch,
    },
    'found_links': linksDetails,
    'timestamp': DateTime.now().toIso8601String(),
  };

  // Encode the response map to a JSON string and print it to stdout.
  stdout.writeln(json.encode(response));
}
