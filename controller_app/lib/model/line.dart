import 'enum/LineStatus.dart';

class Line {
  final String id;
  String name;
  LineStatus status;
  double? targetTemp;
  double? targetAmount;
  double? currentTemp;
  double? processedAmount;

  Line({
    required this.id,
    required this.name,
    this.status = LineStatus.stopped,
    this.targetTemp = null,
    this.targetAmount = null,
    this.currentTemp = null,
    this.processedAmount = null,
  });

  String get statusString {
    switch (status) {
      case LineStatus.stopped:
        return "Stopped";
      case LineStatus.running:
        return "Running";
      case LineStatus.filling:
        return "Filling";
      case LineStatus.heating:
        return "Heating";
      case LineStatus.error:
        return "Error";
    }
  }

  String get displayTemp =>
      currentTemp == null ? '-' : currentTemp!.toStringAsFixed(1);
  String get displayAmount =>
      processedAmount == null ? '-' : processedAmount!.toStringAsFixed(1);
}