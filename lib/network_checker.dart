import 'dart:io';

class NetworkChecker {
  Future<bool> isConnected() async {
    try {
      final socket = await Socket.connect(
        '8.8.8.8', // Google's public DNS server
        53,
        timeout: const Duration(seconds: 3),
      );
      socket.destroy();
      return true;
    } on SocketException catch (_) {
      return false;
    }
  }
}
