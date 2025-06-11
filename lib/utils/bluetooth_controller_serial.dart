import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothController {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  BluetoothConnection? _connection;
  bool isConnected = false;

  // 수신 이벤트 콜백 등록 가능하게 하기 위해 Stream 리스너
  void Function(String message)? onDataReceived;

  // 블루투스 장치에 연결
  Future<void> connectToArduino() async {
    // 블루투스 활성화 여부 확인
    bool isEnabled = await _bluetooth.isEnabled ?? false;
    if (!isEnabled) {
      print('⚠️ 블루투스가 꺼져 있습니다.');
      return;
    }

    List<BluetoothDevice> bondedDevices = await _bluetooth.getBondedDevices();

    for (BluetoothDevice device in bondedDevices) {
      if (['무드등등'].contains(device.name)) {
        try {
          print('🔌 ${device.name} (${device.address})에 연결 시도 중...');
          _connection = await BluetoothConnection.toAddress(device.address);
          isConnected = true;
          print('✅ 연결 성공: ${device.name}');

          // 데이터 수신 처리
          _connection!.input?.listen((Uint8List data) {
            String message = utf8.decode(data);
            print('📥 수신됨: $message');
            if (onDataReceived != null) {
              onDataReceived!(message);
            }
          }).onDone(() {
            print('⛔ 연결이 종료되었습니다.');
            disconnect();
          });

          return;
        } catch (e) {
          print('❌ 연결 실패: $e');
        }
      }
    }

    print('🔍 HC-06 또는 Arduino 장치를 찾을 수 없습니다.');
  }

  // 색상 코드 전송
  Future<void> sendEmotionColor(String colorCode) async {
    if (_connection == null || !_connection!.isConnected) {
      print('⚠️ 블루투스에 연결되어 있지 않습니다.');
      return;
    }

    try {
      final message = colorCode.trim() + '\n'; // ✅ 여기에서만 \n 붙이기
      print('📤 전송할 메시지: $message');
      _connection!.output.add(utf8.encode(message));
      await _connection!.output.allSent;
      print('🎨 색상 코드 전송 완료: $message');
    } catch (e) {
      print('❌ 전송 실패: $e');
    }
  }

  // 연결 해제
  Future<void> disconnect() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
      isConnected = false;
      print('🔌 연결 해제됨');
    }
  }
}
