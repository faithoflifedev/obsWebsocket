import 'package:obs_websocket/obs_websocket.dart';
import 'package:universal_io/io.dart';
import 'package:yaml/yaml.dart';

void main(List<String> args) async {
  //get connection infomration from the config.yaml file
  final config = loadYaml(File('config.yaml').readAsStringSync());

  ObsWebSocket obsWebSocket = await ObsWebSocket.connect(
      connectUrl: config['host'],
      fallbackEvent: (BaseEvent event) {
        print('event: ${event.rawEvent}');
      });

  obsWebSocket.addHandler<RecordingStateEvent>(
      (RecordingStateEvent recordingStateEvent) =>
          print('recording state: ${recordingStateEvent.type}'));

  obsWebSocket.addHandler<SceneItemEvent>((SceneItemEvent sceneItemEvent) =>
      print('scene item: ${sceneItemEvent.itemName}'));

  obsWebSocket.addHandler<SceneItemStateEvent>(
      (SceneItemStateEvent sceneItemState) =>
          print('scene item state: ${sceneItemState.type}'));

  obsWebSocket.addHandler<StreamStateEvent>(
      (StreamStateEvent streamStateEvent) =>
          print('stream state: ${streamStateEvent.type}'));

  obsWebSocket.addHandler<StreamStatusEvent>((StreamStatusEvent streamStatus) =>
      print('stream status (total frames): ${streamStatus.numTotalFrames}'));

  final authRequired = await obsWebSocket.getAuthRequired();

  if (authRequired.status) {
    await obsWebSocket.authenticate(authRequired, config['password']);
  }

  final status = await obsWebSocket.getStreamStatus();

  if (!status.streaming) {
    final setting = StreamSetting.fromJson({
      'type': 'rtmp_custom',
      'settings': {'server': '[rtmp_url]', 'key': '[stream_key]'}
    });

    await obsWebSocket.setStreamSettings(setting);

    obsWebSocket.startStreaming();
  }

  final streamSettings = await obsWebSocket.getStreamSettings();

  await obsWebSocket.startStopRecording();

  //using the old v1.x lower lovel methods
  // final response = await obsWebSocket.command('StopStreaming');

  // if (response != null) {
  //   print(response.status);
  // }

  //Alternatively, the helper method could be used
  await obsWebSocket.stopStreaming();

  print(streamSettings.settings.toString());

  obsWebSocket.close();
}
