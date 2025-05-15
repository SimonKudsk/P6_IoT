import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'mqtt_manager.dart';

/// Represents a device's current availability state.
enum DeviceAvailability { available, occupied, offline, error }

/// Carries a status update for a device.
class DeviceStatus {
  final String deviceId;
  final DeviceAvailability availability;
  final String? lotNumber;

  DeviceStatus({
    required this.deviceId,
    required this.availability,
    this.lotNumber,
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
    DeviceAvailability avail;
    switch (raw) {
      case 'occupied':
        avail = DeviceAvailability.occupied;
        break;
      case 'error':
        avail = DeviceAvailability.error;
        break;
      case 'available':
        avail = DeviceAvailability.available;
        break;
      case 'offline':
      default:
        avail = DeviceAvailability.offline;
    }
    _controller.add(DeviceStatus(
      deviceId: deviceId,
      availability: avail,
      lotNumber: lot,
    ));
  }

  /// Clean up.
  void dispose() {
    _controller.close();
  }
}
