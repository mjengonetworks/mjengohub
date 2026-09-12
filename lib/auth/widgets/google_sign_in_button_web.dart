import 'package:flutter/widgets.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';

/// Renders Google Identity Services' own sign-in button.
///
/// google_sign_in_web has no imperative `authenticate()` support — GIS
/// requires its button to be rendered and clicked directly, and the result
/// arrives via `GoogleSignIn.instance.authenticationEvents`
/// (see `MjengoAuthController._handleGoogleAuthEvent`), not a return value
/// from this widget.
class GoogleWebSignInButton extends StatelessWidget {
  const GoogleWebSignInButton({super.key});

  @override
  Widget build(BuildContext context) {
    final plugin = GoogleSignInPlatform.instance as GoogleSignInPlugin;
    return plugin.renderButton(
      configuration: GSIButtonConfiguration(
        type: GSIButtonType.standard,
        theme: GSIButtonTheme.outline,
        size: GSIButtonSize.large,
        text: GSIButtonText.continueWith,
        shape: GSIButtonShape.rectangular,
      ),
    );
  }
}
