import 'dart:async';
import 'package:controller_app/controller/pasteurization_base.dart';
import '../model/enum/LineStatus.dart';
import '../model/line.dart';
import '../mqtt/mqtt_manager.dart';
import '../mqtt/mqtt_publisher.dart';
import '../mqtt/mqtt_watcher.dart';
import '../mqtt/device_status.dart';

/// PasteurizationController is responsible for activation and deactivation of production lines,
/// along with publishing and listening for progress of orders.
class PasteurizationController extends PasteurizationBase {
  /// Static list of lines - should be replaced with a dynamic one.
  final List<Line> _lines = [];

  List<Line> get lines => List.unmodifiable(_lines);

  /// MQTT manager responsible for establishing and maintaining the MQTT connection.
  final MqttManager _manager;
  /// MQTT publisher used to send orders to the production lines.
  late final MqttPublisher _publisher;

  late final DeviceStatusService _deviceStatusService;

  /// Active watchers keyed by line ID, used to monitor progress of each order.
  final Map<String, MqttWatcher> _watchers = {};
  /// Mapping of line IDs to active lot numbers for tracking order progress.
  final Map<String, String> _lotForLine = {};

  PasteurizationController(String brokerUrl, String clientId)
      : _manager = MqttManager(brokerUrl, clientId) {
    _init();
  }

  /// Initialize the MQTT connection and set up the publisher.
  Future<void> _init() async {
    await _manager.connect();
    if (_manager.mqttClient == null) {
      print("MQTT connect failed – no client object.");
      return;
    }
    _publisher = MqttPublisher(_manager.mqttClient!);

    // start listening for CDA statuses
    _deviceStatusService = DeviceStatusService(_manager);
    await _deviceStatusService.init();
    _deviceStatusService.statusStream.listen(_onDeviceStatusUpdate);
  }

  /// Map a line ID string to its identifier for MQTT.
  int _lineNumberFromId(String id) {
    switch (id) {
      case 'line_a':
        return 1;
      default:
        return 1;
    }
  }

  void activateLine(String lineId, double temp, double amount) {
    // Validate line status before activation.
    final line = getLineById(lineId);
    if (line == null) return;

    // If a line is busy, ignore request.
    if (line.status != LineStatus.stopped &&
        line.status != LineStatus.error) {
      print("Line ${line.name} already busy – activation ignored.");
      return;
    }

    // Reset readings & set targets
    line.targetTemp = temp;
    line.targetAmount = amount;
    line.currentTemp = null;
    line.processedAmount = null;
    line.status = LineStatus.filling;
    notifyListeners();

    // Publish order to the line.
    final lot = _publisher.publishOrder(
        liters: amount,
        temperature: temp.toInt(),
        line: _lineNumberFromId(lineId));

    _lotForLine[lineId] = lot;

    // Set up a watcher to monitor progress
    final watcher = MqttWatcher(client: _manager.mqttClient!, lotNumber: lot);
    _watchers[lineId] = watcher;
    watcher.progressStream.listen((evt) => _applyProgress(lineId, evt));
    watcher.onDone.then((_) => _finalizeLine(lineId));
  }

  /// Stop and clean up resources for the specified production line.
  void deactivateLine(String lineId) {
    // Check line status before deactivation
    final line = getLineById(lineId);
    if (line == null) return;

    // Publish stop signal for the active lot
    final lotNumber = _lotForLine[lineId];
    if (lotNumber != null && _manager.mqttClient != null) {
      _publisher.publishStop(lotNumber);
    }

    // If line is not busy, ignore request
    _watchers[lineId]?.dispose();
    _watchers.remove(lineId);
    _lotForLine.remove(lineId);

    // Reset line status
    line.status = LineStatus.stopped;
    notifyListeners();
  }

  /// Handle incoming MQTT progress events and update the corresponding line's state in the UI
  void _applyProgress(String lineId, Map<String, dynamic> evt) {
    // Check if the line is still active
    final line = getLineById(lineId);
    if (line == null) return;

    // Get relevant data from the event
    final stage = evt['stage'] as String;
    final data = evt['data'] as Map<String, dynamic>;
    final isFinal = evt['final'] == true;

    // Update line status based on the stage of the process
    if (stage == 'flow') {
      // If in stage flow, update the line status and processed amount
      final lit = data['liters'] ?? data['volume'] ?? data['value'];
      if (lit != null) line.processedAmount = (lit as num).toDouble();
      if (isFinal) line.status = LineStatus.heating;
    } else if (stage == 'temp') {
      // If in stage temp, update the line status and current temperature
      final t = data['temperature'] ?? data['temp'] ?? data['value'];
      if (t != null) line.currentTemp = (t as num).toDouble();
      if (isFinal) _finalizeLine(lineId);
    }
    notifyListeners();
  }

  /// Finalize processing for a line: stop watchers, clear lot mapping, and reset status.
  void _finalizeLine(String lineId) {
    // Check if the line is still active
    _watchers[lineId]?.dispose();
    _watchers.remove(lineId);
    _lotForLine.remove(lineId);

    // Reset line status
    final line = getLineById(lineId);
    if (line != null) {
      line.status = LineStatus.stopped;
      notifyListeners();
    }
  }

  /// Map availability to our UI status.
  LineStatus _mapAvailability(DeviceAvailability avail) {
    switch (avail) {
      case DeviceAvailability.available:
        return LineStatus.stopped;
      case DeviceAvailability.occupied:
        return LineStatus.filling;
      case DeviceAvailability.offline:
        return LineStatus.offline;
      case DeviceAvailability.error:
        return LineStatus.error;
    }
  }

  /// Handle an incoming status update.
  void _onDeviceStatusUpdate(DeviceStatus status) {
    final idx = _lines.indexWhere((l) => l.id == status.deviceId);
    if (idx >= 0) {
      // update existing line
      _lines[idx].status = _mapAvailability(status.availability);
    } else {
      // add new device
      _lines.add(Line(
        id: status.deviceId,
        name: 'CDA ${status.deviceId}',
        status: _mapAvailability(status.availability),
      ));
    }
    notifyListeners();
  }

  /// Clean up all MQTT watchers and disconnect manager when controller is disposed.
  @override
  void dispose() {
    for (final w in _watchers.values) {
      w.dispose();
    }
    _manager.disconnect();
    super.dispose();
  }
}