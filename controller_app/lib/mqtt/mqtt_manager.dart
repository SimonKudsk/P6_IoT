import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttClientWrapper {
  late MqttServerClient client;

MqttClientWrapper(String brokerAddress, int port, String clientId){
  client = MqttServerClient.withPort(brokerAddress, clientId, port);

  client.keepAlivePeriod = 60;
  client.logging(on: true);

  final connMessage = MqttConnectMessage()
  .withWillTopic('willTopic')
  .withWillMessage('willMessage')
  .startClean()
  .withWillQos(MqttQos.atLeastOnce);

  client.connectionMessage = connMessage;
}
  Future<void> connect() async {
    try {
      print('Connecting');
      await client.connect();
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
    }
    print("connected");
  }
}
