import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import '../model/enum/LineStatus.dart';
import 'mqtt_manager.dart';

/// Carries a status update for a device.
class DeviceStatus {
  final String deviceId;
  final LineStatus status;
  final String? lotNumber;
  final String? errorMsg;

  DeviceStatus({
    required this.deviceId,
    required this.status,
    this.lotNumber,
    this.errorMsg,
  });
}

/// Subscribes to `devices/+/status` and emits DeviceStatus events.
class DeviceStatusService {
  final MqttManager _manager;
  final StreamController<DeviceStatus> _controller =
      StreamController<DeviceStatus>.broadcast();

  /// Stream of status updates.
  Stream<DeviceStatus> get statusStream => _controller.stream;

  DeviceStatusService(this._manager);

  /// Call after [_manager.connect] completes.
  Future<void> init() async {
    final client = _manager.mqttClient;
    if (client == null) {
      throw Exception('MQTT client not initialized');
    }
    // Subscribe to wildcard status topic.
    client.subscribe('devices/+/status', MqttQos.atLeastOnce);
    // Listen for all incoming messages.
    client.updates?.listen(_onMessage);
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage?>>? msgs) {
    if (msgs == null || msgs.isEmpty) return;
    final rec = msgs.first;
    final topic = rec.topic;
    // Only handle status topics.
    final parts = topic.split('/');
    if (parts.length != 3 || parts[0] != 'devices' || parts[2] != 'status') {
      return;
    }
    final deviceId = parts[1];
    // Decode JSON payload.
    final payloadBytes = (rec.payload as MqttPublishMessage).payload.message;
    final payloadString = MqttPublishPayload.bytesToStringAsString(payloadBytes);
    Map<String, dynamic> data;
    try {
      data = json.decode(payloadString) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final raw = data['status'] as String? ?? '';
    final lot = data['lot_number'] as String?;
    final error = data['error_message'] as String?;
    LineStatus status;
    switch (raw) {
      case 'occupied':
        status = LineStatus.running;
        break;
      case 'error':
        status = LineStatus.error;
        break;
      case 'available':
        status = LineStatus.available;
        break;
      case 'offline':
      default:
        status = LineStatus.offline;
    }
    _controller.add(DeviceStatus(
      deviceId: deviceId,
      status: status,
      lotNumber: lot,
      errorMsg: error,
    ));
  }

  /// Clean up.
  void dispose() {
    _controller.close();
  }
}
