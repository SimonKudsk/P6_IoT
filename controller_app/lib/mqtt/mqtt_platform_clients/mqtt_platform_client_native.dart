import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttClient getPlatformMqttClient(String brokerUrl, identifier) {
  MqttServerClient client = MqttServerClient(brokerUrl, identifier);
  client.useWebSocket = true;
  return client;
}