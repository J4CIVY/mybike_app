class AuthVariant {
  final String label;
  final String pairingToken;
  final String password;

  const AuthVariant(this.label, this.pairingToken, this.password);
}

/// Genera variantes de autenticación para negociación BLE
List<AuthVariant> buildAuthVariants({
  String pairingToken = '',
  String password = '',
}) {
  final token = pairingToken.isNotEmpty
      ? pairingToken
      : 'c97eb99d-c695-4b5f-8a99-7b24ff2a7980';
  final out = <AuthVariant>[];
  void add(String label, String pw) {
    if (out.any((v) => v.password == pw)) return;
    out.add(AuthVariant(label, token, pw));
  }

  if (password.isNotEmpty) {
    add('user-input', password);
  }
  add('token-12 "5bMO8m3wF9q3"', '5bMO8m3wF9q3');
  add('motor "304396"', '304396');
  add('default "58607"', '58607');
  add('empty (sin password)', '');
  return out;
}

String bytesToHex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
