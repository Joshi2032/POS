import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    const Color backgroundColor = Color(0xFF121212);
    const Color cardColor = Color(0xFF1E1E1E);
    const Color accentColor = Color(0xFFFF5722);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SizedBox(
          width: 350,
          child: Card(
            color: cardColor,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: accentColor,
                    size: 40,
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    "La Brasa",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "PARRILLA & GRILL",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    "Correo electrónico",
                    style: TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 8),

                  _buildTextField(
                    controller: emailCtrl,
                    hintText: "correo@labrasa.com",
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Contraseña",
                    style: TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 8),

                  _buildTextField(
                    controller: passwordCtrl,
                    hintText: "********",
                    obscureText: true,
                  ),

                  const SizedBox(height: 20),

                  if (auth.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        auth.error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  ElevatedButton(
                    onPressed: auth.isLoading
                        ? null
                        : () async {
                            final routeContext = context;
                            final ok = await auth.login(
                              emailCtrl.text.trim(),
                              passwordCtrl.text.trim(),
                            );

                            if (!mounted || !routeContext.mounted) return;

                            if (ok) {
                              routeContext.go('/dashboard');
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Entrar",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black45,
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white24),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}