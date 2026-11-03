import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_info.dart';
import '../../core/l10n/strings.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_type.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/brand_mark.dart';
import '../../core/responsive/form_factor.dart';
import '../../core/widgets/ambient_background.dart';
import '../../core/widgets/orbit_ring.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/quick_toggles.dart';
import 'auth_controller.dart';
import 'auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  late final AnimationController _ring;

  bool _remember = true;
  bool _loading = false;
  AuthFailure? _failure;

  @override
  void initState() {
    super.initState();
    _ring = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _ring.value = 1;
      } else {
        _ring.forward();
      }
    });
  }

  @override
  void dispose() {
    _ring.dispose();
    _username.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _failure = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).signIn(
            username: _username.text.trim(),
            password: _password.text,
            remember: _remember,
          );
      TextInput.finishAutofillContext();
    } on AuthException catch (e) {
      if (mounted) setState(() => _failure = e.failure);
    } catch (_) {
      if (mounted) setState(() => _failure = AuthFailure.network);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _failureText(S s, AuthFailure f) => switch (f) {
        AuthFailure.invalidCredentials => s.errInvalidCredentials,
        AuthFailure.network => s.errNetwork,
      };

  @override
  Widget build(BuildContext context) {
    final wide = context.formFactor.isDesktop || MediaQuery.sizeOf(context).width >= 960;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: wide
              ? Row(
                  children: [
                    Expanded(
                      flex: 11,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _BrandPanel(ring: _ring),
                      ),
                    ),
                    Expanded(flex: 9, child: _formSide(context, compact: false)),
                  ],
                )
              : _formSide(context, compact: true),
        ),
      ),
    );
  }

  Widget _formSide(BuildContext context, {required bool compact}) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              LanguageToggle(),
              SizedBox(width: 8),
              AppearanceMenuButton(),
              SizedBox(width: 8),
              ThemeToggleButton(),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _form(context, compact: compact),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _form(BuildContext context, {required bool compact}) {
    final s = S.of(context);
    final t = context.tokens;

    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (compact) ...[
              Center(child: OrbitRing(animation: _ring)),
              const SizedBox(height: 14),
              Text(
                AppInfo.name,
                textAlign: TextAlign.center,
                style: AppType.title.copyWith(color: t.textPrimary, fontSize: 18),
              ),
              const SizedBox(height: 32),
            ],
            Text(s.loginTitle, style: AppType.headline.copyWith(color: t.textPrimary, fontSize: 26)),
            const SizedBox(height: 6),
            Text(s.loginSubtitle, style: AppType.body.copyWith(color: t.textMuted)),
            const SizedBox(height: 28),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: AlignmentDirectional.topStart,
              child: _failure == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _ErrorBanner(message: _failureText(s, _failure!)),
                    ),
            ),
            AppTextField(
              label: s.username,
              hint: s.usernameHint,
              controller: _username,
              icon: Icons.person_outline_rounded,
              enabled: !_loading,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              onSubmitted: (_) => _passwordFocus.requestFocus(),
              validator: (v) => (v == null || v.trim().isEmpty) ? s.errUsernameRequired : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: s.password,
              hint: s.passwordHint,
              controller: _password,
              focusNode: _passwordFocus,
              icon: Icons.lock_outline_rounded,
              obscure: true,
              enabled: !_loading,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _submit(),
              validator: (v) => (v == null || v.length < 6) ? s.errPasswordShort : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Flexible(
                  child: _RememberToggle(
                    label: s.rememberMe,
                    value: _remember,
                    onChanged: (v) => setState(() => _remember = v),
                  ),
                ),
                const SizedBox(width: 8),
                const Spacer(),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: t.accent,
                    textStyle: AppType.label,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(s.forgotPasswordHelp))),
                  child: Text(s.forgotPassword),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(label: s.signIn, loading: _loading, onPressed: _submit),
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              Text(
                s.demoHint,
                textAlign: TextAlign.center,
                style: AppType.caption.copyWith(color: t.textFaint),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Left side on desktop: brand, the ring, and what the app does.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.ring});

  final Animation<double> ring;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final s = S.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: t.glassEnabled ? t.borderSoft : t.border),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            t.accentDark.withValues(alpha: t.isDark ? 0.75 : 0.18),
            t.railTop.withValues(alpha: t.glassEnabled ? 0.55 : 1),
            (t.glassEnabled ? t.glass : t.surface),
          ],
          stops: const [0, 0.5, 1],
        ),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BrandMark(size: 38),
              const SizedBox(width: 12),
              Text(AppInfo.name, style: AppType.title.copyWith(color: t.textPrimary, fontSize: 18)),
            ],
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: OrbitRing(animation: ring, size: 300, markSize: 80),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(s.brandHeadline, style: AppType.display.copyWith(color: t.textPrimary)),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(s.brandBody, style: AppType.body.copyWith(color: t.textMuted, fontSize: 15)),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FeatureChip(icon: Icons.lock_outline_rounded, label: s.featureEncrypted),
              _FeatureChip(icon: Icons.public_rounded, label: s.featureCountries),
              _FeatureChip(icon: Icons.bolt_rounded, label: s.featureOneTap),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: t.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: t.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: t.accent),
          const SizedBox(width: 6),
          Text(label, style: AppType.label.copyWith(color: t.textPrimary)),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: t.danger.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: t.danger.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, size: 18, color: t.danger),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: AppType.label.copyWith(color: t.textPrimary))),
          ],
        ),
      ),
    );
  }
}

class _RememberToggle extends StatelessWidget {
  const _RememberToggle({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      checked: value,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: value ? t.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: value ? t.accent : t.borderStrong, width: 1.5),
                ),
                child: value ? Icon(Icons.check_rounded, size: 13, color: t.onAccent) : null,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.label.copyWith(color: t.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
