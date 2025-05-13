
import 'dart:async';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';


/* Server connection
//https://www.emqx.com/en/blog/using-mqtt-in-flutter
class MqttClientWrapper {
// The ? signifies that the variable client is nullable – meaning it is allowed to hold the value null
  MqttClient? client;
  MqttClientWrapper(String brokerAddress, int brokerPort, String clientId) {
    print('Initializing MqttServerClient...');
    client = MqttServerClient.withPort(brokerAddress, clientId, brokerPort);
*/
class MqttClientWrapper {
  MqttClient? client;
  final String identifier;

  // Topics from Python script
  static const String TOPIC_L = "sensor/liters";
  static const String TOPIC_T = "sensor/temperature";
  static const String TOPIC_F = "sensor/progress";

  // For managing the "done" signal from TOPIC_F
  Completer<String?>? _doneCompleter;

  MqttClientWrapper(String brokerUrl, this.identifier) {
    client = MqttBrowserClient(brokerUrl, identifier);
    client!.logging(on: true);
    client!.keepAlivePeriod = 60;
    client!.port = 443; //change for server if needed
    client!.autoReconnect = true;

    //Callbacks
    client!.onConnected = onConnected;
    client!.onDisconnected = onDisconnected;
    client!.onSubscribed = onSubscribed;
    client!.onSubscribeFail = onSubscribeFail;
    client!.onUnsubscribed = onUnsubscribed;
    client!.pongCallback = pong;

    client!.updates?.listen((
        List<MqttReceivedMessage<MqttMessage?>>? messages) {
      if (messages != null && messages.isNotEmpty) {
        final MqttReceivedMessage<MqttMessage?> recMessage = messages[0];
        final MqttPublishMessage pubMessage = recMessage
            .payload as MqttPublishMessage;
        final String payload = MqttPublishPayload.bytesToStringAsString(
            pubMessage.payload.message);
        final String topic = recMessage.topic;

        print('MESSAGE_RX::Received message: "$payload" from topic: $topic');

        // Check for the "done" message on TOPIC_F
        if (topic == TOPIC_F && payload.startsWith("done:")) {
          print('MESSAGE_RX::"Done" signal received: $payload');
          if (_doneCompleter != null && !_doneCompleter!.isCompleted) {
            _doneCompleter!.complete(payload);
          }
        }
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

  bool get isConnected => client?.connectionStatus?.state == MqttConnectionState.connected;

  //asynchronous method to implement logic from Python script:
  //publishing sensor data and then waiting for a "done" signal.
  Future<void> executeWaterGuysProcess() async {
    if (!isConnected || client == null) {
      print('Client not connected. Cannot execute process.');
      return;
    }

    _doneCompleter = Completer<String?>();

    print('Subscribing to progress topic: $TOPIC_F');
    client!.subscribe(TOPIC_F, MqttQos.atLeastOnce);
    // Small delay to allow subscription to propagate, though onSubscribed callback is better
    await Future.delayed(const Duration(milliseconds: 500));


    print('Publishing to $TOPIC_L: "0.1"');
    final builderL = MqttClientPayloadBuilder();
    builderL.addString("0.1");
    client!.publishMessage(TOPIC_L, MqttQos.atLeastOnce, builderL.payload!);

    await Future.delayed(const Duration(milliseconds: 100)); // Simulating time.sleep(0.1)

    print('Publishing to $TOPIC_T: "5"');
    final builderT = MqttClientPayloadBuilder();
    builderT.addString("5");
    client!.publishMessage(TOPIC_T, MqttQos.atLeastOnce, builderT.payload!);

    print('Waiting for "done" message on $TOPIC_F with a 5-second timeout...');
    try {
      // Wait for the done message or timeout
      final String? finalResult = await _doneCompleter!.future.timeout(const Duration(seconds: 5));
      if (finalResult != null) {
        print('Modtaget slutresultat → $finalResult');
      } else {
        // This case might not be hit if timeout throws TimeoutException first
        print('"Done" message received but result was null (should not happen with current logic).');
      }
    } on TimeoutException {
      print('Timeout – intet slutresultat modtaget on $TOPIC_F.');
    } catch (e) {
      print('Error waiting for "done" message: $e');
    } finally {
      // Clean up: Unsubscribe from TOPIC_F if desired, or leave it for the session
      // client!.unsubscribe(TOPIC_F);
      _doneCompleter = null; // Clear the completer
    }
    print('Testbeskeder sendt (initial publishes).');
  }

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