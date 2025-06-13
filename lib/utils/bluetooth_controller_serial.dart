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

  // ✅ 로그 함수 통합
  void log(String message) {
    print('[BluetoothController] $message');
  }

  /// ✅ 권한 요청
  Future<bool> _requestBluetoothPermissions() async {
    final status = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    final allGranted = status.values.every((s) => s.isGranted);
    if (!allGranted) {
      log('❌ 권한 거부됨');
      return false;
    }
    return true;
  }

  /// ✅ 아두이노 또는 HC-06 장치에 연결
  Future<bool> connectToArduino({List<String> targetNames = const ['무드등등', 'HC-06']}) async {
    if (!await _requestBluetoothPermissions()) {
      log('❌ 필요한 권한 부족으로 연결 중단');
      return false;
    }

    if (_connection?.isConnected ?? false) {
      log('⚠️ 이미 연결됨');
      return true;
    }

    final isEnabled = await _bluetooth.isEnabled ?? false;
    if (!isEnabled) {
      log('⚠️ 블루투스 꺼짐');
      return false;
    }

    try {
      final bondedDevices = await _bluetooth.getBondedDevices();
      for (final device in bondedDevices) {
        if (targetNames.contains(device.name)) {
          try {
            log('🔌 ${device.name}(${device.address}) 연결 시도');
            _connection = await BluetoothConnection.toAddress(device.address);

            if (_connection!.isConnected) {
              isConnected = true;
              log('✅ 연결 성공');

              _connection!.input?.listen(_handleIncomingData).onDone(() {
                log('⛔ 연결 종료');
                disconnect();
              });

              return true;
            }
          } catch (e) {
            log('❌ 연결 실패: $e');
          }
        }
      }

      log('🔍 타겟 장치(${targetNames.join(', ')})를 찾을 수 없음');
      return false;
    } catch (e) {
      log('❌ 기기 검색 중 오류: $e');
      return false;
    }
  }

  /// ✅ 수신 데이터 처리
  void _handleIncomingData(Uint8List data) {
    try {
      final message = utf8.decode(data);
      log('📥 수신: $message');
      onDataReceived?.call(message);
    } catch (e) {
      log('⚠️ 데이터 디코딩 오류: $e');
    }
  }

  /// ✅ 색상 코드 전송
  Future<void> sendEmotionColor(String colorCode) async {
    if (!(_connection?.isConnected ?? false)) {
      log('⚠️ 연결 안 됨');
      return;
    }

    final message = '${colorCode.trim()}\n'; // 아두이노는 \n 기준으로 파싱
    try {
      _connection!.output.add(utf8.encode(message));
      await _connection!.output.allSent;
      log('🎨 전송 완료: $message');
    } catch (e) {
      log('❌ 전송 실패: $e');
    }
  }

  /// ✅ 연결 해제
  Future<void> disconnect() async {
    try {
      await _connection?.close();
      _connection = null;
      isConnected = false;
      log('🔌 연결 해제 완료');
    } catch (e) {
      log('⚠️ 연결 해제 오류: $e');
    }
  }
}
