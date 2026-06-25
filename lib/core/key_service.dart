import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';

class KeyService {
  static final KeyService _instance = KeyService._internal();
  factory KeyService() => _instance;
  KeyService._internal();

  final _storage = const FlutterSecureStorage();

  static const _privateKeyKey = 'ecdsa_private_key';
  static const _publicKeyXKey = 'ecdsa_public_key_x';
  static const _publicKeyYKey = 'ecdsa_public_key_y';

  // ── Generate key pair ──────────────────────────────────────────────────────

  Future<({String publicKeyX, String publicKeyY})>
  generateAndSaveKeyPair() async {
    // Setup P-256 curve (sama dengan Go elliptic.P256())
    final domainParams = ECDomainParameters('prime256v1');
    final keyParams = ECKeyGeneratorParameters(domainParams);

    final secureRandom = _buildSecureRandom();
    final generator = ECKeyGenerator()
      ..init(ParametersWithRandom(keyParams, secureRandom));

    final keyPair = generator.generateKeyPair();
    final privateKey = keyPair.privateKey as ECPrivateKey;
    final publicKey = keyPair.publicKey as ECPublicKey;

    // Serialize private key (D value) sebagai hex
    final privateKeyHex = hex.encode(_bigIntToBytes(privateKey.d!, 32));

    // Serialize public key (X, Y coordinates) sebagai hex
    final publicKeyXHex = hex.encode(
      _bigIntToBytes(publicKey.Q!.x!.toBigInteger()!, 32),
    );
    final publicKeyYHex = hex.encode(
      _bigIntToBytes(publicKey.Q!.y!.toBigInteger()!, 32),
    );

    // Simpan ke secure storage
    await _storage.write(key: _privateKeyKey, value: privateKeyHex);
    await _storage.write(key: _publicKeyXKey, value: publicKeyXHex);
    await _storage.write(key: _publicKeyYKey, value: publicKeyYHex);

    return (publicKeyX: publicKeyXHex, publicKeyY: publicKeyYHex);
  }

  // ── Load public key ────────────────────────────────────────────────────────

  Future<({String publicKeyX, String publicKeyY})?> getPublicKey() async {
    final x = await _storage.read(key: _publicKeyXKey);
    final y = await _storage.read(key: _publicKeyYKey);
    if (x == null || y == null) return null;
    return (publicKeyX: x, publicKeyY: y);
  }

  // ── Cek apakah key pair sudah ada ─────────────────────────────────────────

  Future<bool> hasKeyPair() async {
    final privateKey = await _storage.read(key: _privateKeyKey);
    return privateKey != null && privateKey.isNotEmpty;
  }

  // ── Sign data dengan private key ──────────────────────────────────────────
  // Dipakai saat klaim item dan verifikasi kepemilikan

  Future<({String signatureR, String signatureS})> sign(String data) async {
    final privateKeyHex = await _storage.read(key: _privateKeyKey);
    if (privateKeyHex == null) {
      throw Exception('Private key tidak ditemukan — generate key pair dulu');
    }

    // Load private key
    final domainParams = ECDomainParameters('prime256v1');
    final d = _bytesToBigInt(Uint8List.fromList(hex.decode(privateKeyHex)));
    final privateKey = ECPrivateKey(d, domainParams);

    // Hash data (SHA-256) — sama dengan Go HashProductData
    final digest = SHA256Digest();
    final dataBytes = Uint8List.fromList(data.codeUnits);
    final hash = Uint8List(digest.digestSize);
    digest
      ..update(dataBytes, 0, dataBytes.length)
      ..doFinal(hash, 0);

    // Sign
    final signer = ECDSASigner(null, HMac(SHA256Digest(), 32));
    final signerParams = ParametersWithRandom(
      PrivateKeyParameter<ECPrivateKey>(privateKey),
      _buildSecureRandom(),
    );
    signer.init(true, signerParams);

    final signature = signer.generateSignature(hash) as ECSignature;

    final rHex = hex.encode(_bigIntToBytes(signature.r, 32));
    final sHex = hex.encode(_bigIntToBytes(signature.s, 32));

    return (signatureR: rHex, signatureS: sHex);
  }

  // ── Hapus key pair (saat logout) ──────────────────────────────────────────

  Future<void> clearKeyPair() async {
    await _storage.delete(key: _privateKeyKey);
    await _storage.delete(key: _publicKeyXKey);
    await _storage.delete(key: _publicKeyYKey);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  SecureRandom _buildSecureRandom() {
    final secureRandom = FortunaRandom();
    final seedSource = Random.secure();
    final seeds = List<int>.generate(32, (_) => seedSource.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  Uint8List _bigIntToBytes(BigInt number, int length) {
    final bytes = Uint8List(length);
    var temp = number;
    for (var i = length - 1; i >= 0; i--) {
      bytes[i] = (temp & BigInt.from(0xff)).toInt();
      temp = temp >> 8;
    }
    return bytes;
  }

  BigInt _bytesToBigInt(Uint8List bytes) {
    var result = BigInt.zero;
    for (final byte in bytes) {
      result = (result << 8) | BigInt.from(byte);
    }
    return result;
  }
}
