/// A class that represents a response from the GitHub API.
///
/// This class contains the response status code and the decoded response body.
class GhResponse {
  final int statusCode;
  final dynamic response;

  GhResponse(this.statusCode, this.response);
}
