import 'package:flutter/material.dart';
import 'package:invent/models/detalle_venta.dart';
import 'package:provider/provider.dart';
import '../../controllers/ventas_controller.dart';
import '../../services/scanner_service.dart';
import '../../services/productos_service.dart';
import '../../controllers/auth_controller.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  final TextEditingController clienteController = TextEditingController();
  final TextEditingController cedulaController = TextEditingController();
  final List<DetalleVenta> productosSeleccionados = [];
  double total = 0.0;

  void actualizarTotal() {
    setState(() {
      total = productosSeleccionados.fold(
        0.0,
        (sum, item) => sum + item.calcularSubtotal(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ventaController = Provider.of<VentasController>(context);
    final auth = Provider.of<AuthController>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar venta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: clienteController,
              decoration: const InputDecoration(
                labelText: 'Nombre del cliente',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: cedulaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cédula del cliente',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 10),

            // 🔹 Botón para escanear productos
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                shadowColor: Colors.orangeAccent.withOpacity(0.5),
                elevation: 3,
              ),
              onPressed: () async {
                final codigo = await ScannerService.escanearCodigo(context);
                if (codigo == null) return;

                final producto = await ProductosService().obtenerPorCodigo(
                  codigo,
                );

                if (producto == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Producto no encontrado')),
                  );
                  return;
                }

                try {
                  await ventaController.agregarProductoConValidacion(
                    productosSeleccionados,
                    producto,
                  );
                  setState(() => actualizarTotal());
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Producto agregado: ${producto.nombre}'),
                    ),
                  );
                } catch (e) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        title: Row(
                          children: const [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.amber,
                              size: 30,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Stock insuficiente',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        content: Text(
                          e.toString().replaceAll('Exception:', '').trim(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Entendido'),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              label: const Text(
                'Escanear producto',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Productos agregados:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),

            // 🔹 Lista de productos
            if (productosSeleccionados.isEmpty)
              const Text('No hay productos agregados aún.')
            else
              Column(
                children:
                    productosSeleccionados.map((item) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 🔹 Nombre y precio
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.producto.nombre,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Precio: \$${item.producto.precio.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 🔹 Controles de cantidad
                            Expanded(
                              flex: 2,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    onPressed: () {
                                      if (item.cantidad > 1) {
                                        setState(() {
                                          item.cantidad--;
                                          actualizarTotal();
                                        });
                                      } else {
                                        setState(() {
                                          productosSeleccionados.remove(item);
                                          actualizarTotal();
                                        });
                                      }
                                    },
                                  ),
                                  Text('${item.cantidad}'),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () async {
                                      try {
                                        await ventaController
                                            .agregarProductoConValidacion(
                                              productosSeleccionados,
                                              item.producto,
                                            );
                                        setState(() => actualizarTotal());
                                      } catch (e) {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              title: Row(
                                                children: const [
                                                  Icon(
                                                    Icons.warning_amber_rounded,
                                                    color: Colors.amber,
                                                    size: 30,
                                                  ),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    'Stock insuficiente',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              content: Text(
                                                e
                                                    .toString()
                                                    .replaceAll(
                                                      'Exception:',
                                                      '',
                                                    )
                                                    .trim(),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                      ),
                                                  child: const Text(
                                                    'Entendido',
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // 🔹 Subtotal
                            Expanded(
                              flex: 2,
                              child: Text(
                                '\$${item.calcularSubtotal().toStringAsFixed(2)}',
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),

            const Divider(),
            Text(
              'Total: \$${total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // 🔹 Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(140, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    shadowColor: Colors.green.withOpacity(0.5),
                    elevation: 3,
                  ),
                  onPressed: () async {
                    if (productosSeleccionados.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Debe agregar al menos un producto.'),
                        ),
                      );
                      return;
                    }

                    await ventaController.registrarVenta(
                      clienteController.text.trim(),
                      int.tryParse(cedulaController.text.trim()) ?? 0,
                      productosSeleccionados,
                      total,
                      auth.empleadoActual!,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Venta registrada con éxito en memoria.'),
                      ),
                    );

                    setState(() {
                      clienteController.clear();
                      cedulaController.clear();
                      productosSeleccionados.clear();
                      total = 0.0;
                    });
                  },
                  child: const Text(
                    'Guardar venta',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
