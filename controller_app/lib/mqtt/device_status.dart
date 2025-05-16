import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import '../model/enum/LineStatus.dart';
import 'mqtt_manager.dart';

/// Model for the current status of a device, as reported by the MQTT broker
class DeviceStatus {
  /// CDA Device ID
  final String deviceId;
  /// Current status of the device, in the form of a LineStatus enum
  final LineStatus status;
  /// Lot number for the current job of the device, if applicable
  final String? lotNumber;
  /// Error message reported by device, if any
  final String? errorMsg;

  DeviceStatus({
    required this.deviceId,
    required this.status,
    this.lotNumber,
    this.errorMsg,
  });
}

/// Service for watching and managing device status updates via MQTT
class DeviceStatusService {
  /// Base MQTT Manager class, with methods for connecting and subscribing to topics
  final MqttManager _manager;
  /// Stream controller for broadcasting device status updates.
  final StreamController<DeviceStatus> _controller =
      StreamController<DeviceStatus>.broadcast();

  /// Public broadcast stream that sends DeviceStatus updates.
  /// Used by UI components to listen for changes in device status.
  Stream<DeviceStatus> get statusStream => _controller.stream;

  /// Creates a DeviceStatusService using the provided MQTT manager instance
  DeviceStatusService(this._manager);

  /// Starts the service by subscribing to the wildcard status topic
  /// and registering message handler.
  Future<void> init() async {
    final client = _manager.mqttClient;
    if (client == null) {
      throw Exception('MQTT client not initialized');
    }
    // Subscribe to all device status topics using wildcard 'devices/+/status'.
    client.subscribe('devices/+/status', MqttQos.atLeastOnce);
    // Register callback to process incoming MQTT messages.
    client.updates?.listen(_onMessage);
  }

  /// Filters messages by topic to ensure they match the expected format.
  /// Decode JSON, extract relevant info and send events to stream.
  void _onMessage(List<MqttReceivedMessage<MqttMessage?>>? msgs) {
    // Ignore empty message lists.
    if (msgs == null || msgs.isEmpty) return;
    final rec = msgs.first;
    final topic = rec.topic;
    // Split topic string to verify it matches 'devices/{deviceId}/status'.
    final parts = topic.split('/');
    // Filter out messages on unexpected topics.
    if (parts.length != 3 || parts[0] != 'devices' || parts[2] != 'status') {
      return;
    }
    final deviceId = parts[1];
    // Convert payload bytes to string and decode JSON to a Map.
    final payloadBytes = (rec.payload as MqttPublishMessage).payload.message;
    final payloadString = MqttPublishPayload.bytesToStringAsString(payloadBytes);
    Map<String, dynamic> data;
    try {
      data = json.decode(payloadString) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    // Extract relevant fields from JSON.
    final raw = data['status'] as String? ?? '';
    final lot = data['lot_number'] as String?;
    final error = data['error_message'] as String?;
    // Map raw status string to LineStatus enum.
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
    // Send the DeviceStatus event to all registered listeners.
    _controller.add(DeviceStatus(
      deviceId: deviceId,
      status: status,
      lotNumber: lot,
      errorMsg: error,
    ));
  }

  /// Disposes the service by closing the broadcast stream controller
  void dispose() {
    // Close the stream controller to prevent resource leaks.
    _controller.close();
  }
}
