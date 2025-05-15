import 'enum/LineStatus.dart';

class Line {
  final String id;
  String name;
  LineStatus status;
  double? targetTemp;
  double? targetAmount;
  double? currentTemp;
  double? processedAmount;
  String? lotNumber;
  String? errorMsg;

  Line({
    required this.id,
    required this.name,
    this.status = LineStatus.stopped,
    this.targetTemp = null,
    this.targetAmount = null,
    this.currentTemp = null,
    this.processedAmount = null,
    this.lotNumber = null,
    this.errorMsg = null,
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
      case LineStatus.offline:
        return "Offline";
      case LineStatus.available:
        return "Available";
    }
  }

  String get displayTemp =>
      currentTemp == null ? '-' : currentTemp!.toStringAsFixed(1);
  String get displayAmount =>
      processedAmount == null ? '-' : processedAmount!.toStringAsFixed(1);
  String get displayTargetTemp =>
      targetTemp == null ? '-' : targetTemp!.toStringAsFixed(1);
  String get displayTargetAmount =>
      targetAmount == null ? '-' : targetAmount!.toStringAsFixed(1);
  String get displayLotNumber =>
      lotNumber == null ? '-' : lotNumber!;
  String get displayErrorMsg =>
      errorMsg == null ? '-' : errorMsg!;
}