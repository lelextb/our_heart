// lib/core/utils/pin_utils.dart

import 'dart:convert';
import 'dart:math';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

class PinUtils {
  PinUtils._();

  static final _random = Random.secure();

  static String generateSalt() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return hex.encode(bytes);
  }

  static String hashPin(String pin, String salt) {
    final bytes = utf8.encode('$pin$salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static bool verifyPin(String pin, String salt, String storedHash) {
    final computed = hashPin(pin, salt);
    return _constantTimeEquals(computed, storedHash);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}