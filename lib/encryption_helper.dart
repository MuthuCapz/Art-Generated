import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';

class EncryptionHelper {
  static final String passphrase =
      "ltVaek1ZaAsbJ8YehI5J"; //This passphrase is not the key itself but is used to generate a strong AES key.

  // Generate a 32-byte AES key using SHA-256
  static Key generateKey() {
    var key = sha256.convert(utf8.encode(passphrase)).bytes;
    return Key(Uint8List.fromList(key));
  }

  // Encrypt Data
  static String encryptData(String plainText) {
    final key = generateKey();
    final iv = IV.fromLength(16); // Generate random IV

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Combine IV + Encrypted Data
    final encryptedBytes = iv.bytes + encrypted.bytes;
    return base64.encode(encryptedBytes);
  }

  // Decrypt Data
  static String decryptData(String encryptedText) {
    try {
      final key = generateKey();
      final decodedData = base64.decode(encryptedText);

      final iv =
          IV(Uint8List.fromList(decodedData.sublist(0, 16))); // Extract IV
      final encryptedBytes = decodedData.sublist(16);

      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      final decrypted = encrypter
          .decrypt(Encrypted(Uint8List.fromList(encryptedBytes)), iv: iv);

      return decrypted;
    } catch (e) {
      return "Error: Invalid decryption";
    }
  }
}
