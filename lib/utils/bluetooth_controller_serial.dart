import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothController {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;
  bool isConnected = false;

  // 외부에서 수신 메시지를 받을 수 있도록 콜백 정의
  void Function(String message)? onDataReceived;

  /// ✅ 권한 요청 (Android 6~13+ 대응)
  Future<bool> _requestBluetoothPermissions() async {
    final status = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final denied = status.entries.where(
          (e) => e.value.isDenied || e.value.isPermanentlyDenied,
    );

    if (denied.isNotEmpty) {
      print('❌ 블루투스 권한 거부됨: ${denied.map((e) => e.key).join(', ')}');
      return false;
    }
    return true;
  }

  /// ✅ 블루투스 장치와 연결 (HC-06 또는 "무드등등")
  Future<bool> connectToArduino() async {
    if (!await _requestBluetoothPermissions()) return false;

    // 블루투스 켜기
    if (!(await _bluetooth.isEnabled ?? false)) {
      print('⚠️ 블루투스가 꺼져 있습니다.');
      return false;
    }

    // 이미 연결되어 있다면 스킵
    if (_connection != null && _connection!.isConnected) {
      print('🔁 이미 연결됨.');
      return true;
    }

    // 페어링된 장치 목록 가져오기
    List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();
    final targetDevice = devices.firstWhere(
          (d) => d.name == 'HC-06' || d.name == '무드등등',
      orElse: () => BluetoothDevice(name: '', address: ''),
    );

    if (targetDevice.name == '') {
      print('🔍 대상 장치(HC-06 또는 무드등등) 없음');
      return false;
    }

    // 연결 시도
    try {
      print('🔌 연결 시도: ${targetDevice.name} (${targetDevice.address})');
      _connection = await BluetoothConnection.toAddress(targetDevice.address);
      isConnected = true;
      print('✅ 연결 성공!');

      // 수신 대기
      _connection!.input?.listen((Uint8List data) {
        try {
          final message = utf8.decode(data);
          print('📥 수신: $message');
          onDataReceived?.call(message);
        } catch (e) {
          print('⚠️ 데이터 디코딩 오류: $e');
        }
      }).onDone(() {
        print('⛔ 연결 종료됨');
        disconnect();
      });

      return true;
    } catch (e) {
      print('❌ 연결 실패: $e');
      return false;
    }
  }

  /// ✅ 색상 데이터 전송
  Future<void> sendEmotionColor(String colorCode) async {
    if (!isConnected || _connection == null) {
      print('⚠️ 연결되지 않음. 전송 불가');
      return;
    }

    try {
      final message = colorCode.trim() + '\n';
      _connection!.output.add(utf8.encode(message));
      await _connection!.output.allSent;
      print('🎨 색상 전송 완료: $message');
    } catch (e) {
      print('❌ 색상 전송 실패: $e');
    }
  }

  /// ✅ 연결 해제
  Future<void> disconnect() async {
    if (_connection != null) {
      try {
        await _connection!.close();
        print('🔌 연결 해제됨');
      } catch (e) {
        print('⚠️ 연결 해제 중 오류: $e');
      } finally {
        _connection = null;
        isConnected = false;
      }
    }
  }
}
