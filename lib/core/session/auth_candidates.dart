import 'package:mybike_app/core/security/secure_key_manager.dart';

class AuthVariant {
  final String label;
  final String pairingToken;
  final String password;

  const AuthVariant(this.label, this.pairingToken, this.password);
}

List<AuthVariant> buildAuthVariants({
  String pairingToken = '',
  String password = '',
}) {
  final token = pairingToken.isNotEmpty
      ? pairingToken
      : SecureKeyManager.defaultPairingToken;
  final out = <AuthVariant>[];
  void add(String label, String pw) {
    if (out.any((v) => v.password == pw)) return;
    out.add(AuthVariant(label, token, pw));
  }

  if (password.isNotEmpty) {
    add('user-input', password);
  }

  add('preset-primary', SecureKeyManager.presetPrimaryPassword);
  add('preset-secondary', SecureKeyManager.presetSecondaryPassword);
  add('preset-default', SecureKeyManager.defaultPassword);
  add('empty', '');
  return out;
}

String bytesToHex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
