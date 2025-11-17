import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  final usuarioCtrl = TextEditingController();
  final claveCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);

    return Scaffold(
      appBar: AppBar(title: Text("Inicio de sesión")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: usuarioCtrl,
              decoration: InputDecoration(labelText: "Usuario"),
            ),
            TextField(
              controller: claveCtrl,
              decoration: InputDecoration(labelText: "Clave"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final ok = await auth.login(
                  usuarioCtrl.text.trim(),
                  claveCtrl.text.trim(),
                );

                if (ok) {
                  Navigator.pushReplacementNamed(context, '/home');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Credenciales incorrectas")),
                  );
                }
              },
              child: Text("Ingresar"),
            ),
          ],
        ),
      ),
    );
  }
}
