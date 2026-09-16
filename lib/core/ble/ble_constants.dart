/// Bluetooth Low Energy GATT and communication parameters for SBA Gas Detector.
class BleConstants {
  static const String deviceName = "SBA GAS DETECTOR";
  static const String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String characteristicUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  
  /// Target MTU negotiated upon connection to ensure phone rosters are not truncated.
  static const int targetMtu = 512;
}
