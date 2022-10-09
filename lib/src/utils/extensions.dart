import '../report_issue.dart';
import 'gh_reporeter_delegate.dart';

extension GHReporterExtension on Object {
  GhReporter get ghReporter => GhReporterDelegate.instance;
}
