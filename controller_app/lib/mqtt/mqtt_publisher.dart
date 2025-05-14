import 'dart:convert';

import 'package:mqtt_client/mqtt_client.dart';

/// Returns UTC timestamp in yyyymmddHHMMSS format
String _utcTimestamp() {
  final now = DateTime.now().toUtc();
  return '${now.year.toString().padLeft(4, '0')}' +
      '${now.month.toString().padLeft(2, '0')}' +
      '${now.day.toString().padLeft(2, '0')}' +
      '${now.hour.toString().padLeft(2, '0')}' +
      '${now.minute.toString().padLeft(2, '0')}' +
      '${now.second.toString().padLeft(2, '0')}';
}

class MqttPublisher {
  final MqttClient client;

  static const String _topicRequest = "request/process";

  MqttPublisher(this.client);

  /// Publish an order to the MQTT broker
  String publishOrder({
    required double liters,
    required int temperature,
    int line = 1,
  }) {
    // Generate a unique lot number (currently using UTC timestamp)
    final lotNumber = _utcTimestamp();

    // Create the order object
    final order = <String, dynamic>{
      'liters': liters,
      'temperature': temperature,
      'lot_number': lotNumber,
      'line': line,
    };

    // Convert the order to JSON
    final builder = MqttClientPayloadBuilder()..addString(json.encode(order));
    client.publishMessage(
      _topicRequest,
      MqttQos.atLeastOnce,
      builder.payload!,
    );

    return lotNumber;
  }

  /// Publish a stop signal to the MQTT broker
  void publishStop(String lotNumber) {
    final stopPayload = json.encode({'lot_number': lotNumber});
    final builder = MqttClientPayloadBuilder()..addString(stopPayload);
    client.publishMessage(
      _topicRequest,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }
}
