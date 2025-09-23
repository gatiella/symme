import 'dart:convert';
import 'dart:math';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/export.dart';
import 'package:asn1lib/asn1lib.dart';

class CryptoService {
  // Generate RSA key pair for secure message exchange
  static Map<String, String> generateKeyPair() {
    final keyGen = RSAKeyGenerator();
    final secureRandom = FortunaRandom();

    // Seed the random number generator
    final seedSource = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(255));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    // Set up key generation parameters
    final params = RSAKeyGeneratorParameters(
      BigInt.parse('65537'), // Public exponent
      2048, // Key size in bits
      64, // Certainty for prime generation
    );

    keyGen.init(ParametersWithRandom(params, secureRandom));
    final keyPair = keyGen.generateKeyPair();

    final publicKey = keyPair.publicKey as RSAPublicKey;
    final privateKey = keyPair.privateKey as RSAPrivateKey;

    return {
      'public': _encodePublicKeyToPem(publicKey),
      'private': _encodePrivateKeyToPem(privateKey),
    };
  }

  // Generate unique message encryption key
  static String generateMessageKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  // FIXED: Generate decryption combination (special key for receiver)
  static Map<String, String> generateDecryptionCombination(
    String messageKey,
    String receiverPublicKey,
  ) {
    try {
      // Generate a unique combination ID
      final combinationId = _generateCombinationId();

      // Create the decryption data
      final decryptionData = {
        'messageKey': messageKey,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'combinationId': combinationId,
        'version': '1.0', // Add version for future compatibility
      };

      print('Creating decryption combination with data: $decryptionData');

      // Encrypt the decryption data with receiver's public key
      final publicKey = _parsePublicKeyFromPem(receiverPublicKey);
      final encrypter = Encrypter(RSA(publicKey: publicKey));

      final encryptedCombination = encrypter.encrypt(
        jsonEncode(decryptionData),
      );

      print('Encrypted combination created successfully');

      return {
        'combinationId': combinationId,
        'encryptedCombination': encryptedCombination.base64,
        'messageKey': messageKey,
      };
    } catch (e, stackTrace) {
      print('Error generating decryption combination: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // FIXED: Decrypt message using combination and private key
  static String? decryptMessageWithCombination(
    String encryptedMessage,
    String encryptedCombination,
    String privateKey,
  ) {
    try {
      print('Starting message decryption...');
      print('Encrypted message length: ${encryptedMessage.length}');
      print('Encrypted combination length: ${encryptedCombination.length}');

      // Step 1: Decrypt the combination using private key
      final privKey = _parsePrivateKeyFromPem(privateKey);
      final rsaDecrypter = Encrypter(RSA(privateKey: privKey));

      print('Attempting to decrypt combination...');
      final decryptedCombination = rsaDecrypter.decrypt(
        Encrypted.fromBase64(encryptedCombination),
      );
      print('Combination decrypted: $decryptedCombination');

      final combinationData =
          jsonDecode(decryptedCombination) as Map<String, dynamic>;
      final messageKey = combinationData['messageKey'] as String;

      print('Extracted message key, length: ${messageKey.length}');

      // Step 2: Decrypt the message using the message key
      final key = Key(base64Decode(messageKey));
      final messageEncrypter = Encrypter(AES(key));

      // Use the same IV that was used during encryption (all zeros)
      final iv = IV.fromLength(16); // This matches the IV used in encryption

      print('Attempting to decrypt message with AES...');

      try {
        final decryptedMessage = messageEncrypter.decrypt(
          Encrypted.fromBase64(encryptedMessage),
          iv: iv, // IMPORTANT: Use the same IV as during encryption
        );

        print(
          'Message decrypted successfully: ${decryptedMessage.substring(0, math.min(50, decryptedMessage.length))}...',
        );
        return decryptedMessage;
      } catch (e) {
        print('AES decryption failed: $e');
        return null;
      }
    } catch (e, stackTrace) {
      print('Error decrypting message with combination: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  // FIXED: Encrypt message with unique key and proper IV handling
  static Map<String, String> encryptMessage(
    String message,
    String receiverPublicKey,
  ) {
    try {
      print('Starting message encryption...');
      print('Message length: ${message.length}');

      // Generate unique message key
      final messageKey = generateMessageKey();
      print('Generated message key');

      // Encrypt message with AES using a fixed IV for simplicity
      // In production, you might want to use a random IV and store it
      final key = Key(base64Decode(messageKey));
      final encrypter = Encrypter(AES(key));
      final iv = IV.fromLength(16); // Use default IV (all zeros)

      final encryptedMessage = encrypter.encrypt(message, iv: iv);
      print('Message encrypted successfully');

      // Generate decryption combination
      final combination = generateDecryptionCombination(
        messageKey,
        receiverPublicKey,
      );

      final result = {
        'encryptedMessage': encryptedMessage.base64,
        'iv': iv.base64,
        'combinationId': combination['combinationId']!,
        'encryptedCombination': combination['encryptedCombination']!,
        'messageKey': messageKey, // For sender's copy
      };

      print('Encryption result created successfully');
      return result;
    } catch (e, stackTrace) {
      print('Error encrypting message: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static String _generateCombinationId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Encode(bytes).substring(0, 12);
  }

  static String generateMessageId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  static String generateRoomId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    final combined = ids.join('');
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  // IMPROVED: Helper methods for PEM encoding/decoding with better error handling
  static String _encodePublicKeyToPem(RSAPublicKey publicKey) {
    try {
      final algorithmSeq = ASN1Sequence();
      final algorithmAsn1Obj = ASN1Object.fromBytes(
        Uint8List.fromList([
          0x6,
          0x9,
          0x2a,
          0x86,
          0x48,
          0x86,
          0xf7,
          0xd,
          0x1,
          0x1,
          0x1,
        ]),
      );
      final paramsAsn1Obj = ASN1Object.fromBytes(
        Uint8List.fromList([0x5, 0x0]),
      );
      algorithmSeq.add(algorithmAsn1Obj);
      algorithmSeq.add(paramsAsn1Obj);

      final publicKeySeq = ASN1Sequence();
      publicKeySeq.add(ASN1Integer(publicKey.modulus!));
      publicKeySeq.add(ASN1Integer(publicKey.exponent!));
      final publicKeySeqBitString = ASN1BitString(publicKeySeq.encodedBytes);

      final topLevelSeq = ASN1Sequence();
      topLevelSeq.add(algorithmSeq);
      topLevelSeq.add(publicKeySeqBitString);

      final dataBase64 = base64.encode(topLevelSeq.encodedBytes);
      return '-----BEGIN PUBLIC KEY-----\n${_formatPemString(dataBase64)}\n-----END PUBLIC KEY-----';
    } catch (e) {
      print('Error encoding public key to PEM: $e');
      rethrow;
    }
  }

  static String _encodePrivateKeyToPem(RSAPrivateKey privateKey) {
    try {
      final version = ASN1Integer(BigInt.from(0));
      final algorithm = ASN1Sequence();
      final algorithmAsn1Obj = ASN1Object.fromBytes(
        Uint8List.fromList([
          0x6,
          0x9,
          0x2a,
          0x86,
          0x48,
          0x86,
          0xf7,
          0xd,
          0x1,
          0x1,
          0x1,
        ]),
      );
      final paramsAsn1Obj = ASN1Object.fromBytes(
        Uint8List.fromList([0x5, 0x0]),
      );
      algorithm.add(algorithmAsn1Obj);
      algorithm.add(paramsAsn1Obj);

      final privateKeySeq = ASN1Sequence();
      privateKeySeq.add(ASN1Integer(BigInt.from(0)));
      privateKeySeq.add(ASN1Integer(privateKey.modulus!));
      privateKeySeq.add(ASN1Integer(privateKey.exponent!));
      privateKeySeq.add(ASN1Integer(privateKey.privateExponent!));
      privateKeySeq.add(ASN1Integer(privateKey.p!));
      privateKeySeq.add(ASN1Integer(privateKey.q!));

      final dmp1 = privateKey.privateExponent! % (privateKey.p! - BigInt.one);
      final dmq1 = privateKey.privateExponent! % (privateKey.q! - BigInt.one);
      final iqmp = privateKey.q!.modInverse(privateKey.p!);

      privateKeySeq.add(ASN1Integer(dmp1));
      privateKeySeq.add(ASN1Integer(dmq1));
      privateKeySeq.add(ASN1Integer(iqmp));

      final privateKeyOctetString = ASN1OctetString(privateKeySeq.encodedBytes);

      final topLevelSeq = ASN1Sequence();
      topLevelSeq.add(version);
      topLevelSeq.add(algorithm);
      topLevelSeq.add(privateKeyOctetString);

      final dataBase64 = base64.encode(topLevelSeq.encodedBytes);
      return '-----BEGIN PRIVATE KEY-----\n${_formatPemString(dataBase64)}\n-----END PRIVATE KEY-----';
    } catch (e) {
      print('Error encoding private key to PEM: $e');
      rethrow;
    }
  }

  static RSAPublicKey _parsePublicKeyFromPem(String pem) {
    try {
      final keyData = pem
          .replaceAll('-----BEGIN PUBLIC KEY-----', '')
          .replaceAll('-----END PUBLIC KEY-----', '')
          .replaceAll('\n', '')
          .replaceAll('\r', '');

      final keyBytes = base64.decode(keyData);
      final asn1Parser = ASN1Parser(keyBytes);
      final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;

      final publicKeyBitString = topLevelSeq.elements[1] as ASN1BitString;
      final publicKeyAsn1 = ASN1Parser(publicKeyBitString.contentBytes());
      final publicKeySeq = publicKeyAsn1.nextObject() as ASN1Sequence;

      final modulus = publicKeySeq.elements[0] as ASN1Integer;
      final exponent = publicKeySeq.elements[1] as ASN1Integer;

      return RSAPublicKey(
        modulus.valueAsBigInteger,
        exponent.valueAsBigInteger,
      );
    } catch (e) {
      print('Error parsing public key from PEM: $e');
      rethrow;
    }
  }

  static RSAPrivateKey _parsePrivateKeyFromPem(String pem) {
    try {
      final keyData = pem
          .replaceAll('-----BEGIN PRIVATE KEY-----', '')
          .replaceAll('-----END PRIVATE KEY-----', '')
          .replaceAll('\n', '')
          .replaceAll('\r', '');

      final keyBytes = base64.decode(keyData);
      final asn1Parser = ASN1Parser(keyBytes);
      final topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;

      final privateKeyOctetString = topLevelSeq.elements[2] as ASN1OctetString;
      final privateKeyAsn1 = ASN1Parser(privateKeyOctetString.contentBytes());
      final privateKeySeq = privateKeyAsn1.nextObject() as ASN1Sequence;

      final modulus = privateKeySeq.elements[1] as ASN1Integer;
      final privateExponent = privateKeySeq.elements[3] as ASN1Integer;
      final p = privateKeySeq.elements[4] as ASN1Integer;
      final q = privateKeySeq.elements[5] as ASN1Integer;

      return RSAPrivateKey(
        modulus.valueAsBigInteger,
        privateExponent.valueAsBigInteger,
        p.valueAsBigInteger,
        q.valueAsBigInteger,
      );
    } catch (e) {
      print('Error parsing private key from PEM: $e');
      rethrow;
    }
  }

  static String _formatPemString(String data) {
    final regex = RegExp('.{1,64}');
    final matches = regex.allMatches(data);
    return matches.map((match) => match.group(0)).join('\n');
  }
}
