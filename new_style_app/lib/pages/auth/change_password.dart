import 'package:flutter/material.dart';
import '../../widgets/appbar.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar:
          const CustomAppBar(title: 'Cambiar Contraseña', showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña actual',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu contraseña actual';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nueva contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa una nueva contraseña';
                  }
                  if (value.length < 8 || value.length > 16) {
                    return 'Debe tener entre 8 y 16 caracteres';
                  }
                  if (!RegExp(r'[0-9]').hasMatch(value)) {
                    return 'Debe contener al menos un número';
                  }
                  if (!RegExp(r'[a-z]').hasMatch(value)) {
                    return 'Debe contener una minúscula';
                  }
                  if (!RegExp(r'[A-Z]').hasMatch(value)) {
                    return 'Debe contener una mayúscula';
                  }
                  if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(value)) {
                    return 'Debe contener un carácter especial';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar nueva contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_reset),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirma tu nueva contraseña';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Aquí iría la lógica para cambiar la contraseña
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Contraseña cambiada correctamente'),
                        ),
                      );
                    }
                  },
                  child: const Text('Cambiar Contraseña'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}