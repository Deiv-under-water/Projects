import 'package:flutter/material.dart';
import '../../controllers/reportes_controller.dart';

class VentasTodasScreen extends StatelessWidget {
  final ReporteController controller;

  const VentasTodasScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Todas las ventas")),
      body:
          controller.ventasTodas.isEmpty
              ? const Center(child: Text("No hay ventas registradas"))
              : ListView.builder(
                itemCount: controller.ventasTodas.length,
                itemBuilder: (_, i) {
                  final v = controller.ventasTodas[i];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text(
                        "${v['nombre_cliente']} - \$${v['total']}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Atendido por: ${v['nombre_empleado']} • ${v['fecha_venta']}",
                      ),
                      trailing: const Icon(Icons.receipt),
                    ),
                  );
                },
              ),
    );
  }
}
