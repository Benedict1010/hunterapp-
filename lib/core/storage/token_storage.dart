import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStorage {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();
}

abstract class SecureStorageWrapper {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class DefaultSecureStorageWrapper implements SecureStorageWrapper {
  final FlutterSecureStorage _storage;

  DefaultSecureStorageWrapper([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class SecureTokenStorage implements TokenStorage {
  final SecureStorageWrapper _wrapper;
  final TokenStorage? legacyStorage;
  final String key;

  SecureTokenStorage({
    SecureStorageWrapper? wrapper,
    FlutterSecureStorage? flutterSecureStorage,
    this.legacyStorage,
    this.key = 'hunter_auth_token',
  }) : _wrapper =
           wrapper ??
           (flutterSecureStorage != null
               ? DefaultSecureStorageWrapper(flutterSecureStorage)
               : DefaultSecureStorageWrapper());

  @override
  Future<void> saveToken(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return;
    try {
      await _wrapper.write(key, trimmed);
    } catch (_) {}
    if (legacyStorage != null) {
      try {
        await legacyStorage!.clearToken();
      } catch (_) {}
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      final secureToken = await _wrapper.read(key);
      if (secureToken != null && secureToken.trim().isNotEmpty) {
        return secureToken.trim();
      }
    } catch (_) {
      // Ignore secure storage read errors and attempt fallback to legacy
    }

    if (legacyStorage != null) {
      try {
        final legacyToken = await legacyStorage!.getToken();
        if (legacyToken == null || legacyToken.trim().isEmpty) {
          return null;
        }

        final trimmedLegacy = legacyToken.trim();
        // Attempt secure write and verification before deleting legacy file
        try {
          await _wrapper.write(key, trimmedLegacy);
          final verified = await _wrapper.read(key);
          if (verified != null && verified.trim() == trimmedLegacy) {
            await legacyStorage!.clearToken();
          }
        } catch (_) {
          // Write/verify failed: preserve legacy token
        }

        return trimmedLegacy;
      } catch (_) {}
    }

    return null;
  }

  @override
  Future<void> clearToken() async {
    try {
      await _wrapper.delete(key);
    } catch (_) {}
    if (legacyStorage != null) {
      try {
        await legacyStorage!.clearToken();
      } catch (_) {}
    }
  }
}

class InMemoryTokenStorage implements TokenStorage {
  String? _token;

  InMemoryTokenStorage([this._token]);

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }

  @override
  Future<String?> getToken() async {
    return _token;
  }

  @override
  Future<void> clearToken() async {
    _token = null;
  }
}

class FileTokenStorage implements TokenStorage {
  final String fileName;

  FileTokenStorage({this.fileName = '.hunter_auth_token'});

  File get _file {
    final dir = Directory.systemTemp;
    return File('${dir.path}/$fileName');
  }

  @override
  Future<void> saveToken(String token) async {
    try {
      final file = _file;
      await file.writeAsString(token.trim());
    } catch (_) {}
  }

  @override
  Future<String?> getToken() async {
    try {
      final file = _file;
      if (await file.exists()) {
        final token = await file.readAsString();
        if (token.trim().isNotEmpty) {
          return token.trim();
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> clearToken() async {
    try {
      final file = _file;
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
