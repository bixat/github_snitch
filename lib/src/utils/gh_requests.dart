import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';

import 'gh_response.dart';

class GhRequest {
  /// A class for making authenticated HTTP requests to the GitHub API.
  ///
  /// This class takes a GitHub personal access token as a parameter when instantiated.
  /// The token is used to authenticate the requests made to the GitHub API.
  ///
  /// Example usage:
  ///
  /// ```
  /// GhRequest ghRequest = GhRequest('your_github_token_here');
  /// ```
  GhRequest(this.token);

  final String token;
  final String baseUrl = "https://api.github.com/repos/";
  final Map<String, String> headers = {
    "Accept": "application/vnd.github+json",
  };

  /// Sends an HTTP request to the GitHub API with the specified method, endpoint, and optional body.
  ///
  /// This method returns a `Future<GhResponse>` object that contains the response status code and the decoded response body.
  ///
  /// Example usage:
  ///
  /// ```
  /// GhResponse response = await ghRequest.request('GET', 'owner/repo/issues');
  /// ```
  Future<GhResponse> request(String method, String endpoint,
      {String? body}) async {
    headers[HttpHeaders.authorizationHeader] = "Bearer $token";
    Uri url = Uri.parse(baseUrl + endpoint);
    Request request = Request(method, url);
    request.body = body ?? "";
    request.headers.addAll(headers);
    StreamedResponse response = await request.send();
    var decodeResponse = json.decode(await response.stream.bytesToString());
    return GhResponse(response.statusCode, decodeResponse);
  }
}