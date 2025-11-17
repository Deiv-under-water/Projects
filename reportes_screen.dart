import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controllers/reportes_controller.dart';
import 'package:open_filex/open_filex.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final clienteController = TextEditingController();
  DateTime? fechaInicio;
  DateTime? fechaFin;
  final dateFormat = DateFormat('yyyy-MM-dd');

  Future<void> seleccionarFecha(BuildContext context, bool esInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (esInicio) {
          fechaInicio = picked;
        } else {
          fechaFin = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ReporteController>(context);

    // Agrupar ventas por id_venta
    final ventasAgrupadas = <String, List<Map<String, dynamic>>>{};
    for (var r in controller.reportes) {
      final id = r['id_venta'].toString();
      ventasAgrupadas.putIfAbsent(id, () => []);
      ventasAgrupadas[id]!.add(r);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: clienteController,
              decoration: const InputDecoration(
                labelText: 'Nombre del cliente',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      fechaInicio == null
                          ? 'Fecha inicio'
                          : dateFormat.format(fechaInicio!),
                    ),
                    onPressed: () => seleccionarFecha(context, true),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      fechaFin == null
                          ? 'Fecha fin'
                          : dateFormat.format(fechaFin!),
                    ),
                    onPressed: () => seleccionarFecha(context, false),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            ///
            /// 🔥 🔥 AQUI AGREGO LOS 2 BOTONES DE PDFs 🔥 🔥
            ///
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.inventory),
                    label: const Text("PDF Inventario"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    onPressed: () async {
                      final file = await controller.generarPDFInventario();
                      OpenFilex.open(file.path);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("PDF Ventas"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () async {
                      final file = await controller.generarPDFVentas();
                      OpenFilex.open(file.path);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                    ),
                    onPressed: () async {
                      // Aquí ya no abrimos pantalla nueva
                      // Ya generas un PDF de inventario con el botón de arriba
                    },
                    child: Text("Inventario actual"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                    onPressed: () async {
                      await controller.cargarVentasTodas();
                    },
                    child: Text("Todas las ventas"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Buscar'),
              onPressed:
                  () => controller.buscarReportes(
                    cliente: clienteController.text,
                    fechaInicio:
                        fechaInicio != null
                            ? dateFormat.format(fechaInicio!)
                            : null,
                    fechaFin:
                        fechaFin != null ? dateFormat.format(fechaFin!) : null,
                  ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child:
                  controller.cargando
                      ? const Center(child: CircularProgressIndicator())
                      : ventasAgrupadas.isEmpty
                      ? const Center(child: Text('No hay reportes'))
                      : ListView(
                        children:
                            ventasAgrupadas.entries.map((entry) {
                              final venta = entry.value.first;
                              final idVenta = int.parse(venta['id_venta']);

                              return Card(
                                child: ListTile(
                                  title: Text(
                                    '${venta['nombre_cliente']} - \$${venta['total']}',
                                  ),
                                  subtitle: Text(
                                    'Fecha: ${venta['fecha_venta']}',
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios),
                                  onTap: () async {
                                    await controller.obtenerDetallesVenta(
                                      idVenta,
                                    );
                                    mostrarDetalleVenta(
                                      context,
                                      controller,
                                      venta,
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  void mostrarDetalleVenta(
    BuildContext context,
    ReporteController controller,
    Map<String, dynamic> venta,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final detalles = controller.detallesVenta;

        return Padding(
          padding: const EdgeInsets.all(16),
          child:
              detalles.isEmpty
                  ? const Center(child: Text('Sin detalles'))
                  : ListView(
                    children: [
                      const Text(
                        'Detalles de la venta',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      ...detalles.map((d) {
                        return ListTile(
                          title: Text(d['producto']),
                          subtitle: Text(
                            'Cantidad: ${d['cantidad']} | Precio: \$${d['precio_unitario']}',
                          ),
                          trailing: Text('Subtotal: \$${d['subtotal']}'),
                        );
                      }),
                      const Divider(),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Exportar a PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                        ),
                        onPressed: () async {
                          await controller.generarFacturaPDF(
                            ventaSeleccionada: venta,
                            detalles: controller.detallesVenta,
                          );
                        },
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
        );
      },
    );
  }
}
