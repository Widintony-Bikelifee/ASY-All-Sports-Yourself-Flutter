import 'package:flutter/material.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_tabs.dart';
import '../widgets/custom_text_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthTabs(isLogin: true),
          
          const Text(
            'BIENVENIDO DE VUELTA',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingresa tus credenciales para acceder a tu cuenta.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7C6B),
            ),
          ),
          const SizedBox(height: 30),
          
          const CustomTextField(
            label: 'Correo Electrónico',
            hint: 'correo@ejemplo.com',
            icon: Icons.email_outlined,
          ),
          
          const CustomTextField(
            label: 'Contraseña',
            hint: 'Tu contraseña',
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(
                  color: Color(0xFF2ECC50),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC50),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: const Text(
              'INICIAR SESIÓN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '¿No tienes cuenta? ',
                style: TextStyle(color: Color(0xFF6B7C6B)),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/register');
                },
                child: const Text(
                  'Regístrate',
                  style: TextStyle(
                    color: Color(0xFF2ECC50),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          Center(
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF4A5A4A)),
              label: const Text(
                'Volver al inicio',
                style: TextStyle(color: Color(0xFF4A5A4A), fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
