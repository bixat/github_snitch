extension RemoveLastLine on String {
  String removeLastLine() {
    int index = lastIndexOf('\n');
    if (index != -1) {
      return substring(0, index);
    }
    return this;
  }
}
