
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

    client?.logging(on: true);
    client?.keepAlivePeriod = 120;

  final connMessage = MqttConnectMessage()
  //authentication here if needed
  .withWillTopic('willTopic')
  .withWillMessage('willMessage')
  .startClean()
  .withWillQos(MqttQos.atLeastOnce);


*/
class MqttClientWrapper {
  MqttClient? client;
  final String identifier;

  MqttClientWrapper(String brokerUrl, this.identifier) {
    print('Initializing MqttBrowserClient for $identifier...');
    client = MqttBrowserClient(brokerUrl, identifier);

    client?.port = 8084;
    client?.logging(on: true);
    client?.keepAlivePeriod = 60;


    //Callbacks
    client?.onConnected = onConnected;
    client?.onDisconnected = onDisconnected;
    client?.onSubscribed = onSubscribed;
    client?.onSubscribeFail = onSubscribeFail;
    client?.onUnsubscribed = onUnsubscribed;
    client?.pongCallback = pong;

    final String username = 'test';
    final String password = '1234';

    print('Attempting authentication with Username: $username');
    final connMessage = MqttConnectMessage()
        .authenticateAs(username, password)
        .withWillTopic('willTopic/$identifier')
        .withWillMessage('Client $identifier Disconnected Unexpectedly')
        .startClean() // Non persistent session for testing
        .withWillQos(MqttQos.atLeastOnce);

    client?.connectionMessage = connMessage;
  }
  Future<void> connect() async {
    if (client == null) {
      print('MQTT Client not initialized.');
      return;
    }

    if (client?.connectionStatus?.state == MqttConnectionState.connected) {
      print('Already connected.');
      return;
    }
    try {
      print('MQTT Client connecting...');
      await client?.connect();
    } on NoConnectionException catch (e) {
      print('MQTT Client exception - No connection: $e');
      client?.disconnect();
    } on Exception catch (e) {
      print('MQTT Client exception: $e');
      client?.disconnect();
    }
    if (client?.connectionStatus?.state != MqttConnectionState.connected) {
      print('Connection failed.');
    }
    client?.published!.listen((MqttPublishMessage message) {
      final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
      print('Published message: payload $payload is published to ${message.variableHeader!.topicName} with Qos ${message.header!.qos}');
    });
  }

//connected callback
  void onConnected() {
    print('Successfully connected to mqtt broker');
  }
  //disconnected callback
  void onDisconnected() {
    print('Disconnecting MQTT client');
  }

  //subscribed callback
  void onSubscribed(String topic) {
    print('Subscribed topic: $topic');
  }

// Subscribed failed callback
  void onSubscribeFail(String topic) {
    print('Failed to subscribe $topic');
  }

// Unsubscribed callback
  void onUnsubscribed(String? topic) {
    print('Unsubscribed topic: $topic');
  }

// Ping callback
  void pong() {
    print('Ping response client callback invoked');
  }

}