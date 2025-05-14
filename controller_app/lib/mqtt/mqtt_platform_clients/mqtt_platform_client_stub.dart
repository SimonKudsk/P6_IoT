import 'package:mqtt_client/mqtt_client.dart';

MqttClient getPlatformMqttClient(String brokerUrl, identifier) {
  throw UnsupportedError(
      'MQTT connection failed, due to unsupported platform.');
}