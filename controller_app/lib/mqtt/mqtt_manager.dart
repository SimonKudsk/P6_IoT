import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import of platform-specific MQTT client implementations
import 'mqtt_platform_clients/mqtt_platform_client_stub.dart'
  if (dart.library.html) 'mqtt_platform_clients/mqtt_platform_client_web.dart'
  if (dart.library.io) 'mqtt_platform_clients/mqtt_platform_client_native.dart';

/// Manages an MQTT client connection
class MqttManager {
  MqttClient? client;
  /// Unique identifier for this client
  final String identifier;

  /// Constructs the MqttManager and configures the MQTT client with provided settings
  MqttManager(this.identifier) {
    // Build the broker URL using secure WebSocket protocol and the domain from .env file.
    String brokerUrl = 'wss://${dotenv.env['MQTT_DOMAIN']}';
    // Obtain a platform-specific MQTT client instance for connecting.
    // This makes it compatible with web and native platforms.
    client = getPlatformMqttClient(brokerUrl, identifier);
    // Enable detailed client logging for debugging purposes.
    client!.logging(on: true);
    // Set the keep-alive interval (seconds) to maintain connection.
    client!.keepAlivePeriod = 60;
    // Configure the network port to 443 for secure WebSockets.
    client!.port = 443;
    // Allow automatic reconnection on network interruptions.
    client!.autoReconnect = true;

    // Register connection event callbacks.
    client!.onConnected = onConnected;
    client!.onDisconnected = onDisconnected;
    client!.onSubscribed = onSubscribed;
    client!.onSubscribeFail = onSubscribeFail;
    client!.onUnsubscribed = onUnsubscribed;
    client!.pongCallback = pong;

    // Listen to incoming MQTT messages and handle payloads.
    client!.updates?.listen((
        List<MqttReceivedMessage<MqttMessage?>>? messages) {
      // Process only when there are messages to handle.
      if (messages != null && messages.isNotEmpty) {
        // Handle incoming messages
        final MqttReceivedMessage<MqttMessage?> recMessage = messages[0];
        // Check if the message is a publish message.
        final MqttPublishMessage pubMessage = recMessage
            .payload as MqttPublishMessage;
        // Extract the payload and topic from the received message.
        final String payload = MqttPublishPayload.bytesToStringAsString(
            pubMessage.payload.message);
        // Decode the payload to a string.
        final String topic = recMessage.topic;

        // Log received message payload and topic for telemetry.
        print('MESSAGE_RX::Received message: "$payload" from topic: $topic');
      }
    });

    // Begin MQTT connect message configuration.
    print('Configuring connection with no authentication.');
    // Prepare the connection message with clean session and will topic.
    MqttConnectMessage connMessage;
    // Set the client identifier and will.
    // The will message is sent by the broker if the client disconnects unexpectedly.
    // This isn't that important for this app, as it simply shows data, but is is good practice. nbb<
    connMessage = MqttConnectMessage()
        .withClientIdentifier(identifier)
        .withWillTopic('willTopic/$identifier')
        .withWillMessage('Client $identifier Disconnected Unexpectedly')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    // Assign the configured connect message to the client.
    client!.connectionMessage = connMessage;
    print(' Browser Client Initialized and Configured.');
  }

  /// Connects to the MQTT broker, handling initial state and exceptions.
  Future<void> connect() async {
    // Ensure the MQTT client is initialized before attempting connection.
    if (client == null) {
      print('Client not initialized.');
      return;
    }
    // Avoid reconnecting if already connected.
    if (isConnected) {
      print('Already connected.');
      return;
    }
    // Log the start of the connection attempt.
    try {
      print('Attempting to connect...');
      // Initiate the network connection to the broker.
      await client!.connect();
    }
    // Handle failure to establish a network connection.
    on NoConnectionException catch (e) {
      print('NoConnectionException: $e');

    }
    // Handle unexpected errors during connection.
    on Exception catch (e) {
      print('Exception during connect: $e');
      // client!.disconnect();
    }
    // Check final state and log failure if not connected.
    if (!isConnected) {
      print('Connection failed. Final state: ${client!.connectionStatus?.state}');
    }
  }

  /// Returns true if the client is currently connected to the broker.
  bool get isConnected => client?.connectionStatus?.state == MqttConnectionState.connected;

  /// Exposes the underlying MQTT client for direct subscription/publishing.
  MqttClient? get mqttClient => client;

  /// Callback for when the client successfully connects.
  void onConnected() {
    print('Successfully connected to mqtt broker');
  }

  /// Callback for when the client disconnects.
  void onDisconnected() {
    print('Disconnecting MQTT client');
  }

  /// Callback for when the client subscribes to a topic.
  void onSubscribed(String topic) {
    print('Subscribed topic: $topic');
  }

  /// Callback for when the client fails to subscribe to a topic.
  void onSubscribeFail(String topic) {
    print('Failed to subscribe $topic');
  }

  /// Callback for when the client unsubscribes from a topic.
  void onUnsubscribed(String? topic) {
    print('Unsubscribed topic: $topic');
  }

  /// Callback for when a ping response is received from the broker.
  void pong() {
    print('Ping received');
  }

  /// Disconnects the client from the MQTT broker.
  void disconnect() {
    print('Disconnecting client...');
    // Perform the disconnect operation on the client.
    client?.disconnect();
  }
}