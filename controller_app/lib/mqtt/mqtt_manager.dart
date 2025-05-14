import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

class MqttManager {
  MqttClient? client;
  final String identifier;

  MqttManager(String brokerUrl, this.identifier) {
    // Create a new MQTT client instance
    client = MqttBrowserClient(brokerUrl, identifier);
    client!.logging(on: true);
    client!.keepAlivePeriod = 60;
    client!.port = 443; //change for server if needed
    client!.autoReconnect = true;

    // Callbacks
    client!.onConnected = onConnected;
    client!.onDisconnected = onDisconnected;
    client!.onSubscribed = onSubscribed;
    client!.onSubscribeFail = onSubscribeFail;
    client!.onUnsubscribed = onUnsubscribed;
    client!.pongCallback = pong;

    // Set the connection status
    client!.updates?.listen((
        List<MqttReceivedMessage<MqttMessage?>>? messages) {
      if (messages != null && messages.isNotEmpty) {
        // Handle incoming messages
        final MqttReceivedMessage<MqttMessage?> recMessage = messages[0];
        final MqttPublishMessage pubMessage = recMessage
            .payload as MqttPublishMessage;
        final String payload = MqttPublishPayload.bytesToStringAsString(
            pubMessage.payload.message);
        final String topic = recMessage.topic;

        print('MESSAGE_RX::Received message: "$payload" from topic: $topic');
      }
    });

    //Connection Message
    MqttConnectMessage connMessage;
    print('Configuring connection with no authentication.');
    connMessage = MqttConnectMessage()
        .withClientIdentifier(identifier)
        .withWillTopic('willTopic/$identifier')
        .withWillMessage('Client $identifier Disconnected Unexpectedly')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client!.connectionMessage = connMessage;
    print(' Browser Client Initialized and Configured.');
  }

  /// Connect to the MQTT broker
  Future<void> connect() async {
    if (client == null) {
      print('Client not initialized.');
      return;
    }
    if (isConnected) {
      print('Already connected.');
      return;
    }
    try {
      print('Attempting to connect...');
      await client!.connect();
    } on NoConnectionException catch (e) {
      print('NoConnectionException: $e');

    } on Exception catch (e) {
      print('Exception during connect: $e');
      // client!.disconnect();
    }
    if (!isConnected) {
      print('Connection failed. Final state: ${client!.connectionStatus?.state}');
    }
  }

  /// Check if the client is connected
  bool get isConnected => client?.connectionStatus?.state == MqttConnectionState.connected;

  /// Expose the underlying MQTT client so other helper classes can
  /// subscribe / publish without re‑opening the connection.
  MqttClient? get mqttClient => client;

  void onConnected() {
    print('Successfully connected to mqtt broker');
  }

  void onDisconnected() {
    print('Disconnecting MQTT client');
  }

  void onSubscribed(String topic) {
    print('Subscribed topic: $topic');
  }

  void onSubscribeFail(String topic) {
    print('Failed to subscribe $topic');
  }

  void onUnsubscribed(String? topic) {
    print('Unsubscribed topic: $topic');
  }

  void pong() {
    print('Ping received');
  }

  void disconnect() {
    print('Disconnecting client...');
    client?.disconnect();
  }
}