import 'dart:io';

abstract class TokenStorage {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();
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
