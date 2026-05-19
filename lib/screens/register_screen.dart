import 'package:flutter/material.dart';
import '../widgets/auth_layout.dart';
import '../widgets/auth_tabs.dart';
import '../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String _selectedRole = 'user';
  bool _acceptedTerms = false;

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthTabs(isLogin: false),
          
          const Text(
            'CREA TU CUENTA',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Únete a la comunidad deportiva de Ipiales.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7C6B),
            ),
          ),
          const SizedBox(height: 30),
          
          Row(
            children: const [
              Expanded(
                child: CustomTextField(
                  label: 'Nombre',
                  hint: 'Tu nombre',
                  icon: Icons.person_outline,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'Apellido',
                  hint: 'Tu apellido',
                  icon: Icons.person_outline,
                ),
              ),
            ],
          ),
          
          const CustomTextField(
            label: 'Teléfono (opcional)',
            hint: '300 123 4567',
            icon: Icons.phone_outlined,
          ),
          
          const CustomTextField(
            label: 'Correo Electrónico',
            hint: 'correo@ejemplo.com',
            icon: Icons.email_outlined,
          ),
          
          const CustomTextField(
            label: 'Contraseña',
            hint: 'Mínimo 8 caracteres',
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          
          const CustomTextField(
            label: 'Confirmar Contraseña',
            hint: 'Repite tu contraseña',
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          
          // ROLE SELECTOR
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text(
              '¿CÓMO USARÁS LA PLATAFORMA?',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Color(0xFF4A5A4A),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _RoleCard(
                  title: 'Deportista',
                  desc: 'Quiero reservar canchas',
                  icon: '🏃',
                  isSelected: _selectedRole == 'user',
                  onTap: () => setState(() => _selectedRole = 'user'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _RoleCard(
                  title: 'Administrador',
                  desc: 'Quiero ofrecer mi cancha',
                  icon: '🏟️',
                  isSelected: _selectedRole == 'admin_cancha',
                  onTap: () => setState(() => _selectedRole = 'admin_cancha'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // TERMS
          Row(
            children: [
              Checkbox(
                value: _acceptedTerms,
                activeColor: const Color(0xFF2ECC50),
                onChanged: (val) {
                  setState(() {
                    _acceptedTerms = val ?? false;
                  });
                },
              ),
              Expanded(
                child: Wrap(
                  children: [
                    const Text('Acepto los '),
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        'términos y condiciones',
                        style: TextStyle(
                          color: Color(0xFF2ECC50),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
              'CREAR CUENTA',
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
                '¿Ya tienes cuenta? ',
                style: TextStyle(color: Color(0xFF6B7C6B)),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text(
                  'Inicia sesión',
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

class _RoleCard extends StatelessWidget {
  final String title;
  final String desc;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.desc,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2ECC50).withOpacity(0.05) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF2ECC50) : Colors.grey[300]!,
            width: isSelected ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
