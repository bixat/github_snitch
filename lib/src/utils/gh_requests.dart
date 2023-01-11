import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';

import 'gh_response.dart';

class GhRequest {
  GhRequest(this.token);
  final String token;
  final String baseUrl = "https://api.github.com/repos/";
  final Map<String, String> headers = {
    "Accept": "application/vnd.github+json",
  };
  Future request(String method, String endpoint, String body) async {
    headers[HttpHeaders.authorizationHeader] = "Bearer $token";
    Uri url = Uri.parse(baseUrl + endpoint);
    Request request = Request(method, url);
    request.body = body;
    request.headers.addAll(headers);
    StreamedResponse response = await request.send();
    var decodeResponse = json.decode(await response.stream.bytesToString());
    return GhResponse(response.statusCode, decodeResponse);
  }
}
