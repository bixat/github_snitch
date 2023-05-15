extension RemoveLastLine on String {
  String removeLastLine() {
    return substring(0, lastIndexOf("\n"));
  }
}
