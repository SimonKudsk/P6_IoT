import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

class MqttClientWrapper {
  MqttClient? client;

  MqttClientWrapper(String brokerAddress, int brokerPort, String clientId, {required String websocketUrl}) {
    client = MqttBrowserClient(websocketUrl, clientId);
    if (kIsWeb) {
      // Running on the web, use MqttBrowserClient with the websocket URL
      print('Initializing MqttBrowserClient for web...');
      client = MqttBrowserClient(websocketUrl, clientId);
    } else {
      // Running on native platforms (mobile, tablet), use MqttServerClient
      print('Initializing MqttServerClient for native...');
      client = MqttServerClient.withPort(brokerAddress, clientId, brokerPort);
    }

    client?.logging(on: true);
    client?.keepAlivePeriod = 120;

  final connMessage = MqttConnectMessage()
  .withWillTopic('willTopic')
  .withWillMessage('willMessage')
  .startClean()
  .withWillQos(MqttQos.atLeastOnce);

  client?.connectionMessage = connMessage;
}
  Future<void> connect() async {
    try {
      print('Connecting');
      await client?.connect();
    } catch (e) {
      print('Exception: $e');
      client?.disconnect();
    }
    print("connected");
  }
  void disconnect() {
    print('Disconnecting MQTT client');
    client?.disconnect();
  }
}
