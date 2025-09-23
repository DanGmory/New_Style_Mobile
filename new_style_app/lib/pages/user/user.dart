import 'package:flutter/material.dart';
import '../../widgets/appbar.dart';
import '../../models/register_model.dart'; // 🔹 Importamos ApiUser

class UserScreen extends StatelessWidget {
  final ApiUser user;

  const UserScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          const CustomAppBar(title: 'Perfil de Usuario', showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, size: 70, color: Colors.white),
              ),
            ),
            const SizedBox(height: 30),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow('ID:', user.id.toString()),
                    const SizedBox(height: 15),
                    _buildInfoRow('Usuario:', user.name),
                    const SizedBox(height: 15),
                    _buildInfoRow('Email:', user.email),
                    const SizedBox(height: 15),
                    _buildInfoRow('Rol:', user.role.toString()),
                    const SizedBox(height: 15),
                    _buildInfoRow('Estado:', user.state.toString()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Aquí iría navegación a pantalla de edición de perfil
              },
              child: const Text('Editar Perfil'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
