import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../theme/theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'user'; // 'user' | 'admin_cancha'
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _lastnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los términos y condiciones.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Crear usuario en Auth
      final user = await AuthService.instance.registerUserAuth(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nombre: _nameController.text.trim(),
        apellido: _lastnameController.text.trim(),
      );

      if (user == null) {
        throw Exception('No se pudo crear el usuario.');
      }

      // 2. Crear perfil en base de datos
      await AuthService.instance.insertUserProfile(
        userId: user.id,
        email: _emailController.text.trim(),
        nombre: _nameController.text.trim(),
        apellido: _lastnameController.text.trim(),
        telefono: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        rol: _selectedRole,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.primaryColor),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Registro exitoso. Revisa tu correo para confirmar tu cuenta.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.surfaceColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppTheme.primaryColor, width: 1),
          ),
          duration: const Duration(seconds: 4),
        ),
      );

      // Redirigir a login
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        context.go('/login');
      });
    } catch (e) {
      if (!mounted) return;

      String errorMsg = e.toString();
      if (errorMsg.startsWith('Exception: ')) {
        errorMsg = errorMsg.replaceFirst('Exception: ', '');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.redAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  errorMsg,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.surfaceColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Colors.redAccent, width: 1),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 900;

    return Scaffold(
      body: Row(
        children: [
          // Lado izquierdo visual (Solo en pantallas anchas)
          if (isWideScreen)
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    'https://images.unsplash.com/photo-1522778119026-d647f0596c20?q=80&w=2070&auto=format',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.backgroundColor.withOpacity(0.85),
                          AppTheme.backgroundColor.withOpacity(0.4),
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      margin: const EdgeInsets.symmetric(horizontal: 50),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/Logo-ASY.png',
                            height: 120,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'All Sports Yourself',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'La plataforma líder para reservar espacios deportivos en Ipiales.\nÚnete a la comunidad deportiva hoy mismo.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Lado derecho: Formulario de Registro
          Expanded(
            flex: isWideScreen ? 5 : 9,
            child: Container(
              color: AppTheme.backgroundColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 24.0,
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!isWideScreen) ...[
                            Center(
                              child: Image.asset(
                                'assets/images/Logo-ASY.png',
                                height: 70,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Tabs: Iniciar Sesión / Registrarse
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => context.go('/login'),
                                  child: const Column(
                                    children: [
                                      Text(
                                        'Iniciar Sesión',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white38,
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                    ],
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text(
                                      'Registrarse',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      height: 2,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          const Text(
                            'Crea tu Cuenta',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Únete a la comunidad deportiva de Ipiales.',
                            style: TextStyle(color: Colors.white60),
                          ),
                          const SizedBox(height: 24),

                          // Fila Nombre y Apellido
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Nombre',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _nameController,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'Tu nombre',
                                      ),
                                      validator: (value) =>
                                          value == null || value.trim().isEmpty
                                          ? 'Obligatorio'
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Apellido',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _lastnameController,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'Tu apellido',
                                      ),
                                      validator: (value) =>
                                          value == null || value.trim().isEmpty
                                          ? 'Obligatorio'
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Teléfono
                          const Text(
                            'Teléfono (opcional)',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: '300 123 4567',
                              prefixIcon: Icon(
                                Icons.phone_outlined,
                                color: Colors.white30,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Correo
                          const Text(
                            'Correo Electrónico',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'correo@ejemplo.com',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: Colors.white30,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty)
                                return 'El correo es obligatorio.';
                              final regex = RegExp(
                                r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                              );
                              if (!regex.hasMatch(value.trim()))
                                return 'Formato inválido.';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Contraseña
                          const Text(
                            'Contraseña',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Mínimo 8 caracteres',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: Colors.white30,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.white30,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'La contraseña es obligatoria.';
                              if (value.length < 8)
                                return 'Debe tener al menos 8 caracteres.';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Confirmar Contraseña
                          const Text(
                            'Confirmar Contraseña',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Repite tu contraseña',
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: Colors.white30,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.white30,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value != _passwordController.text)
                                return 'Las contraseñas no coinciden.';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Selector de Rol (Deportista vs Administrador)
                          const Text(
                            '¿Cómo usarás la plataforma?',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Deportista Card
                              Expanded(
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _selectedRole = 'user'),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'user'
                                          ? AppTheme.primaryColor.withOpacity(
                                              0.1,
                                            )
                                          : AppTheme.surfaceColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _selectedRole == 'user'
                                            ? AppTheme.primaryColor
                                            : Colors.white10,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      children: const [
                                        Text(
                                          '🏃',
                                          style: TextStyle(fontSize: 24),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Deportista',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Reservar canchas',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white38,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Administrador Card
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(
                                    () => _selectedRole = 'admin_cancha',
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'admin_cancha'
                                          ? AppTheme.primaryColor.withOpacity(
                                              0.1,
                                            )
                                          : AppTheme.surfaceColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _selectedRole == 'admin_cancha'
                                            ? AppTheme.primaryColor
                                            : Colors.white10,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      children: const [
                                        Text(
                                          '🏟️',
                                          style: TextStyle(fontSize: 24),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Administrador',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Ofrecer mi cancha',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white38,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Checkbox de Términos
                          Row(
                            children: [
                              Checkbox(
                                value: _acceptTerms,
                                activeColor: AppTheme.primaryColor,
                                onChanged: (value) => setState(
                                  () => _acceptTerms = value ?? false,
                                ),
                              ),
                              Expanded(
                                child: Wrap(
                                  children: [
                                    const Text(
                                      'Acepto los ',
                                      style: TextStyle(color: Colors.white60),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        // Mostrar términos
                                      },
                                      child: const Text(
                                        'términos y condiciones',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Submit Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.backgroundColor,
                                      ),
                                    ),
                                  )
                                : const Text('Crear Cuenta'),
                          ),
                          const SizedBox(height: 16),

                          // Switch a login
                          Center(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  '¿Ya tienes cuenta? ',
                                  style: TextStyle(color: Colors.white60),
                                ),
                                TextButton(
                                  onPressed: () => context.go('/login'),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Inicia sesión',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Volver al Inicio
                          Center(
                            child: TextButton.icon(
                              onPressed: () => context.go('/'),
                              icon: const Icon(
                                Icons.arrow_back,
                                size: 16,
                                color: Colors.white38,
                              ),
                              label: const Text(
                                'Volver al inicio',
                                style: TextStyle(color: Colors.white38),
                              ),
                            ),
                          ),
                        ],
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
