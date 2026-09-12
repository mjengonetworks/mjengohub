import 'package:flutter/widgets.dart';

/// Non-web fallback — never actually rendered since callers gate on [kIsWeb],
/// but the conditional-import target must still compile on every platform.
class GoogleWebSignInButton extends StatelessWidget {
  const GoogleWebSignInButton({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
