import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../controladores/reportes_controller.dart';
//import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';

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
                      try {
                        final pdf =
                            await controller.generarPDFInventarioDocumento();
                        await Printing.layoutPdf(
                          onLayout: (format) async => pdf.save(),
                        );
                      } catch (e) {
                        mostrarError(
                          context,
                          "No se pudo generar el PDF. Revise su conexión.",
                        );
                      }
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
                      try {
                        final pdf =
                            await controller.generarPDFVentasDocumento();
                        await Printing.layoutPdf(
                          onLayout: (format) async => pdf.save(),
                        );
                      } catch (e) {
                        mostrarError(
                          context,
                          "Error al generar PDF de ventas.",
                        );
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            //const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Buscar'),
              onPressed: () async {
                try {
                  await controller.buscarReportes(
                    cliente: clienteController.text,
                    fechaInicio:
                        fechaInicio != null
                            ? dateFormat.format(fechaInicio!)
                            : null,
                    fechaFin:
                        fechaFin != null ? dateFormat.format(fechaFin!) : null,
                  );
                } catch (e) {
                  mostrarError(context, e.toString());
                }
              },
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        final detalles = controller.detallesVenta;

        return DraggableScrollableSheet(
          initialChildSize: 0.70,
          maxChildSize: 0.90,
          minChildSize: 0.40,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 10,
                    color: Colors.black26,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child:
                  detalles.isEmpty
                      ? const Center(
                        child: Text(
                          'Sin detalles',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                      : ListView(
                        controller: scrollController,
                        children: [
                          // Barra de arrastre elegante
                          Center(
                            child: Container(
                              width: 40,
                              height: 5,
                              margin: const EdgeInsets.only(bottom: 15),
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),

                          // Título
                          const Text(
                            'Detalles de la Venta',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),
                          Text(
                            "Cliente: ${venta['nombre_cliente']}",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            "Fecha: ${venta['fecha_venta']}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 10),

                          const Divider(),

                          // Lista de productos con estilo
                          ...detalles.map((d) {
                            return Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                title: Text(
                                  d['producto'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  "Cantidad: ${d['cantidad']}\nPrecio unit.: \$${d['precio_unitario']}",
                                ),
                                trailing: Text(
                                  "Subtotal\n\$${d['subtotal']}",
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                              ),
                            );
                          }),

                          const Divider(),

                          // Total general mejor visualizado
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "Total: \$${venta['total']}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Botón PDF
                          ElevatedButton.icon(
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Exportar a PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                255,
                                255,
                                255,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                            onPressed: () async {
                              await controller.generarFacturaPDF(
                                ventaSeleccionada: venta,
                                detalles: controller.detallesVenta,
                              );
                            },
                          ),

                          const SizedBox(height: 10),

                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Cerrar',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
            );
          },
        );
      },
    );
  }

  void mostrarError(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
