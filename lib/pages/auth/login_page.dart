import 'dart:math';
import 'package:attendance/widgets/pp_button.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailC = TextEditingController();
  final _passwordC = TextEditingController();
  bool _loading = false;
  String? _error;

  // theme toggle
  bool _isDark = false;

  // animation controllers
  late final AnimationController _cardController;
  late final Animation<double> _cardScale;
  late final Animation<double> _cardFade;

  // shake animation for error
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnim;

  late final AnimationController _bgController; // drives background blobs

  @override
  void initState() {
    super.initState();

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _cardScale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack),
    );
    _cardFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeIn));

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: -18.0,
        ).chain(CurveTween(curve: Curves.ease)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -18.0,
          end: 14.0,
        ).chain(CurveTween(curve: Curves.ease)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 14.0,
          end: -10.0,
        ).chain(CurveTween(curve: Curves.ease)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -10.0,
          end: 6.0,
        ).chain(CurveTween(curve: Curves.ease)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 6.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.ease)),
        weight: 1,
      ),
    ]).animate(_shakeController);

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    // intro
    _cardController.forward();
  }

  @override
  void dispose() {
    _emailC.dispose();
    _passwordC.dispose();
    _cardController.dispose();
    _bgController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // call this to trigger shake + subtle haptic/cue when login fails
  void _triggerFailureAnimation() {
    _shakeController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    // two theme palettes (light/dark)
    final lightA = Colors.deepPurple.shade600;
    final lightB = Colors.indigo.shade400;
    final lightC = Colors.pink.shade400;

    final darkA = Colors.indigo.shade900;
    final darkB = Colors.deepPurple.shade900;
    final darkC = Colors.teal.shade700;

    final colorA = _isDark ? darkA : lightA;
    final colorB = _isDark ? darkB : lightB;
    final colorC = _isDark ? darkC : lightC;

    final cardColor =
        _isDark
            ? Colors.grey[900]!.withOpacity(0.95)
            : Colors.white.withOpacity(0.98);
    final textColor = _isDark ? Colors.white : Colors.black87;

    return Scaffold(
      // set system background color to match theme subtlely
      backgroundColor: _isDark ? Colors.black : Colors.white,
      body: Stack(
        children: [
          // animated gradient background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, child) {
                final v = _bgController.value;
                final a1 = Alignment(-1.0 + v * 2, -0.5 + v * 1.0);
                final a2 = Alignment(1.0 - v * 2, 0.5 - v * 1.0);

                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: a1,
                      end: a2,
                      colors: [
                        colorA.withOpacity(_isDark ? 0.85 : 0.95),
                        colorB.withOpacity(_isDark ? 0.82 : 0.9),
                        colorC.withOpacity(_isDark ? 0.78 : 0.85),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),

          // decorative soft blobs
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _BlobsPainter(animation: _bgController, dark: _isDark),
              ),
            ),
          ),

          // top-right small controls: theme toggle + version
          Positioned(
            top: 18,
            right: 20,
            child: Row(
              children: [
                Icon(
                  Icons.brightness_6,
                  color: textColor.withOpacity(0.8),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Switch(
                  value: _isDark,
                  onChanged: (v) => setState(() => _isDark = v),
                  activeColor: Colors.white,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.black26,
                ),
              ],
            ),
          ),

          // main content centered, card shakes on failure
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 36),
              child: AnimatedBuilder(
                animation: _shakeAnim,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnim.value, 0),
                    child: child,
                  );
                },
                child: ScaleTransition(
                  scale: _cardScale,
                  child: FadeTransition(
                    opacity: _cardFade,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 540),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 22,
                        color: cardColor,
                        child: Padding(
                          padding: const EdgeInsets.all(26),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // header row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [colorB, colorC],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(
                                            _isDark ? 0.45 : 0.12,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.school_outlined,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Attendance System',
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Sign in — master or faculty',
                                          style: TextStyle(
                                            color: textColor.withOpacity(0.7),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              // form
                              AppTextField(controller: _emailC, label: 'Email'),
                              const SizedBox(height: 12),
                              AppTextField(
                                controller: _passwordC,
                                label: 'Password',
                                obscure: true,
                              ),
                              const SizedBox(height: 12),

                              // error + micro interaction
                              if (_error != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.redAccent,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 10),

                              // primary action: gradient button centered
                              SizedBox(
                                width: double.infinity,
                                child: GestureDetector(
                                  onTap:
                                      _loading
                                          ? null
                                          : () async {
                                            setState(() {
                                              _loading = true;
                                              _error = null;
                                            });
                                            try {
                                              final user = await AuthService
                                                  .instance
                                                  .signIn(
                                                    _emailC.text.trim(),
                                                    _passwordC.text,
                                                  );
                                              if (user == null) {
                                                setState(() {
                                                  _error =
                                                      'Invalid credentials or user config';
                                                });
                                                _triggerFailureAnimation();
                                              } else {
                                                if (!mounted) return;
                                                if (user.role == 'master') {
                                                  Navigator.pushReplacementNamed(
                                                    context,
                                                    '/master',
                                                  );
                                                } else {
                                                  Navigator.pushReplacementNamed(
                                                    context,
                                                    '/faculty',
                                                  );
                                                }
                                              }
                                            } catch (e) {
                                              setState(() {
                                                _error = e.toString();
                                              });
                                              _triggerFailureAnimation();
                                            } finally {
                                              if (mounted)
                                                setState(
                                                  () => _loading = false,
                                                );
                                            }
                                          },
                                  child: AbsorbPointer(
                                    absorbing: _loading,
                                    child: Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        // fixed: use withOpacity instead of .shade700 which doesn't exist on Color
                                        gradient: LinearGradient(
                                          colors:
                                              _isDark
                                                  ? [
                                                    colorB.withOpacity(0.92),
                                                    colorC.withOpacity(0.92),
                                                  ]
                                                  : [colorB, colorC],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              _isDark ? 0.5 : 0.12,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child:
                                            _loading
                                                ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.4,
                                                    valueColor:
                                                        AlwaysStoppedAnimation(
                                                          Colors.white,
                                                        ),
                                                  ),
                                                )
                                                : Text(
                                                  'Login',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // footer row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Need help?',
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.75),
                                    ),
                                  ),
                                  Text(
                                    'v0.1',
                                    style: TextStyle(
                                      color: textColor.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter draws soft animated blobs using animated alignment and color shifts.
class _BlobsPainter extends CustomPainter {
  final Animation<double> animation;
  final bool dark;
  _BlobsPainter({required this.animation, this.dark = false})
    : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final v = animation.value;

    Paint blobPaint(Color c, double opacity) =>
        Paint()
          ..shader = RadialGradient(
            colors: [c.withOpacity(opacity), c.withOpacity(0.0)],
            radius: 0.6,
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: 200));

    final cx = size.width;
    final cy = size.height;

    final center1 = Offset(
      cx * (0.18 + 0.15 * sin(2 * pi * v)),
      cy * (0.24 + 0.12 * cos(2 * pi * v)),
    );
    final center2 = Offset(
      cx * (0.82 - 0.15 * cos(2 * pi * v)),
      cy * (0.72 - 0.12 * sin(2 * pi * v)),
    );
    final center3 = Offset(
      cx * (0.5 + 0.2 * sin(pi * v)),
      cy * (0.5 + 0.15 * cos(pi * v)),
    );

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    if (!dark) {
      canvas.drawCircle(
        center1,
        max(size.width, size.height) * 0.28,
        blobPaint(const Color(0xFFD6BCFA), 0.20),
      );
      canvas.drawCircle(
        center2,
        max(size.width, size.height) * 0.32,
        blobPaint(const Color(0xFFB3E5FC), 0.18),
      );
      canvas.drawCircle(
        center3,
        max(size.width, size.height) * 0.22,
        blobPaint(const Color(0xFFFFC1E3), 0.14),
      );
    } else {
      canvas.drawCircle(
        center1,
        max(size.width, size.height) * 0.28,
        blobPaint(const Color(0xFF7C4DFF), 0.12),
      );
      canvas.drawCircle(
        center2,
        max(size.width, size.height) * 0.32,
        blobPaint(const Color(0xFF4DD0E1), 0.10),
      );
      canvas.drawCircle(
        center3,
        max(size.width, size.height) * 0.22,
        blobPaint(const Color(0xFF80CBC4), 0.08),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BlobsPainter oldDelegate) => true;
}
