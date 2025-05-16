import 'dart:async';
import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';

import 'mqtt_manager.dart';

/// Listens to progress/final topics for a specific lot number
class MqttWatcher {
  final MqttClient client;
  final String lotNumber;

  static const String _topicFlowFinal = "sensor/flow_gauge/final";
  static const String _topicTempFinal = "sensor/temp_sensor/final";
  static const String _topicFlowProgress = "sensor/flow_gauge/progress";
  static const String _topicTempProgress = "sensor/temp_sensor/progress";

  /// Broadcasts maps in the format:
  /// `{stage: 'flow'|'temp', data: <json>, final: bool?}`
  final StreamController<Map<String, dynamic>> _progressCtrl =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get progressStream => _progressCtrl.stream;

  /// Completes when both stages have delivered their FINAL reading.
  final Completer<void> _done = Completer<void>();
  // A future that completes when the process is done
  Future<void> get onDone => _done.future;

  // The current stage of the process - defaults to flow, as the first stage
  String _stage = 'flow';

  MqttWatcher({required this.client, required this.lotNumber}) {
    // Ensure we receive messages
    client.updates?.listen(_handleMessages);

    // Subscribe to relevant topics
    for (final t in const [
      _topicFlowFinal,
      _topicTempFinal,
      _topicFlowProgress,
      _topicTempProgress,
    ]) {
      client.subscribe(t, MqttQos.atLeastOnce);
    }
  }

  void _handleMessages(List<MqttReceivedMessage<MqttMessage?>>? msgs) {
    // Ignore null or empty messages
    if (msgs == null || msgs.isEmpty) return;

    // Extract the first message
    final rec = msgs.first;
    final payloadStr = MqttPublishPayload.bytesToStringAsString(
        (rec.payload as MqttPublishMessage).payload.message);

    // Parse the payload as JSON
    Map<String, dynamic> data;
    try {
      // Decode the payload string to a Map
      data = json.decode(payloadStr) as Map<String, dynamic>;
    } on FormatException {
      return; // ignore if not json
    }

    // Ignore messages that are not for our order
    if (data['lot_number'] != lotNumber) return;

    // Extract the topic
    final topic = rec.topic;

    // If we are in the flow stage, check for flow progress or final
    if (_stage == 'flow') {
      if (topic == _topicFlowProgress) {
        _progressCtrl.add({'stage': _stage, 'data': data});
      } else if (topic == _topicFlowFinal) {
        _progressCtrl.add({'stage': _stage, 'data': data, 'final': true});
        _stage = 'temp';
      }
    // If we are in the temp stage, check for temp progress or final
    } else if (_stage == 'temp') {
      if (topic == _topicTempProgress) {
        _progressCtrl.add({'stage': _stage, 'data': data});
      } else if (topic == _topicTempFinal) {
        _progressCtrl.add({'stage': _stage, 'data': data, 'final': true});
        _stage = 'done';
        if (!_done.isCompleted) _done.complete();
      }
    }
  }

  /// When the process is done, unsubscribe from all topics
  void dispose() {
    if (!_done.isCompleted) _done.complete();
    _progressCtrl.close();
  }
}
