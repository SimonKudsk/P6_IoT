import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

MqttClient getPlatformMqttClient(String brokerUrl, identifier) {
  return MqttBrowserClient(brokerUrl, identifier);
}