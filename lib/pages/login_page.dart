import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Definición de colores basados en tu imagen
    const Color backgroundColor = Color(0xFF121212);
    const Color cardColor = Color(0xFF1E1E1E);
    const Color accentColor = Color(0xFFFF5722); // Naranja

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SizedBox(
          width: 350,
          child: Card(
            color: cardColor,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.local_fire_department, color: accentColor, size: 40),
                  const SizedBox(height: 16),
                  const Text(
                    "La Brasa",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'serif',
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
                  
                  // Campo Correo
                  const Text("Correo electrónico", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  _buildTextField(hintText: "correo@labraza.com"),
                  
                  const SizedBox(height: 20),
                  
                  // Campo Contraseña
                  const Text("Contraseña", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  _buildTextField(hintText: "********", obscureText: true),
                  
                  const SizedBox(height: 32),
                  
                  // Botón Entrar
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Entrar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para mantener los campos consistentes
  Widget _buildTextField({required String hintText, bool obscureText = false}) {
    return TextField(
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