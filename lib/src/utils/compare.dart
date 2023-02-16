double compare(String txt1, String txt2) {
  List splitTxt1 = txt1.split(" ");
  List splitTxt2 = txt2.split(" ");
  List result = [];
  for (var e in splitTxt1) {
    for (String i in splitTxt2) {
      if (e == i) {
        result.add(e);
      }
    }
  }
  double n = (splitTxt1.toSet().length + splitTxt2.toSet().length) / 2;
  double percent = (result.toSet().length * 100) / n;
  return percent;
}
