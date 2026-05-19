import 'package:flutter/material.dart';

class AuthTabs extends StatelessWidget {
  final bool isLogin;
  
  const AuthTabs({super.key, required this.isLogin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!isLogin) Navigator.pushReplacementNamed(context, '/login');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isLogin ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: isLogin ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Iniciar Sesión',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isLogin ? Colors.black87 : const Color(0xFF6B7C6B),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isLogin) Navigator.pushReplacementNamed(context, '/register');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isLogin ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: !isLogin ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Registrarse',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: !isLogin ? Colors.black87 : const Color(0xFF6B7C6B),
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
