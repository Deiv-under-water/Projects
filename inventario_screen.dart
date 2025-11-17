import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/inventario_controller.dart';
import '../../models/producto.dart';
import '../../services/productos_service.dart';
import '../../services/scanner_service.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  @override
  void initState() {
    super.initState();

    // ✅ Evita llamar notifyListeners() durante el build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InventarioController>(
        context,
        listen: false,
      ).cargarInventario();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<InventarioController>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Escanear producto',
            onPressed: () => _abrirEscaner(context),
          ),
        ],
      ),

      body:
          controller.cargando
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: controller.cargarInventario,
                child: ListView.builder(
                  itemCount: controller.inventario.length,
                  itemBuilder: (context, index) {
                    final producto = controller.inventario[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: Text(producto.nombre),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stock: ${producto.stock} | Precio: \$${producto.precio}',
                            ),
                            if (producto.stock == 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Agotado',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        trailing: Row(
                          mainAxisSize:
                              MainAxisSize
                                  .min, // 👈 evita que el Row ocupe todo el ancho
                          children: [
                            if (producto.stock < 5)
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red,
                              ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.orangeAccent,
                              ),
                              onPressed: () {
                                _mostrarFormularioEdicion(context, producto);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

      // 🟠 BOTÓN FLOTANTE (Registrar nuevo producto)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orangeAccent,
        child: const Icon(Icons.add),
        onPressed: () {
          _mostrarFormularioNuevoProducto(context);
        },
      ),
    );
  }

  void _mostrarFormularioNuevoProducto(
    BuildContext context, {
    String? codigoInicial,
  }) {
    final TextEditingController codigoController = TextEditingController(
      text: codigoInicial ?? '',
    );
    final TextEditingController nombreController = TextEditingController();
    final TextEditingController descripcionController = TextEditingController();
    final TextEditingController precioController = TextEditingController();
    final TextEditingController stockController = TextEditingController();
    final TextEditingController categoriaController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Registrar nuevo producto'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: codigoController,
                    decoration: const InputDecoration(
                      labelText: 'Código de producto',
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                  ),
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  TextField(
                    controller: descripcionController,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                  TextField(
                    controller: precioController,
                    decoration: const InputDecoration(labelText: 'Precio'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: stockController,
                    decoration: const InputDecoration(labelText: 'Stock'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: categoriaController,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final nuevoProducto = Producto(
                    idProducto: 0,
                    nombre: nombreController.text.trim(),
                    descripcion: descripcionController.text.trim(),
                    precio: double.tryParse(precioController.text) ?? 0.0,
                    stock: int.tryParse(stockController.text) ?? 0,
                    categoria: categoriaController.text.trim(),
                    codigo: codigoController.text.trim(),
                  );

                  final exito = await ProductosService().registrarProducto(
                    nuevoProducto,
                  );

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        exito
                            ? '✅ Producto registrado correctamente'
                            : '❌ Error al registrar el producto',
                      ),
                    ),
                  );
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
  }

  void _mostrarFormularioEdicion(BuildContext context, Producto producto) {
    final nombreController = TextEditingController(text: producto.nombre);
    final descripcionController = TextEditingController(
      text: producto.descripcion ?? '',
    );
    final precioController = TextEditingController(
      text: producto.precio.toString(),
    );
    final stockController = TextEditingController(
      text: producto.stock.toString(),
    );
    final categoriaController = TextEditingController(
      text: producto.categoria ?? '',
    );
    final TextEditingController codigoController = TextEditingController(
      text: producto.codigo,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar producto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                TextField(
                  controller: precioController,
                  decoration: const InputDecoration(labelText: 'Precio'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: stockController,
                  decoration: const InputDecoration(labelText: 'Stock'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: categoriaController,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final productoActualizado = Producto(
                  idProducto: producto.idProducto,
                  nombre: nombreController.text.trim(),
                  descripcion: descripcionController.text.trim(),
                  precio: double.tryParse(precioController.text) ?? 0.0,
                  stock: int.tryParse(stockController.text) ?? 0,
                  categoria: categoriaController.text.trim(),
                  fechaRegistro: producto.fechaRegistro,
                  codigo: codigoController.text.trim(),
                );

                final exito = await ProductosService().actualizarProducto(
                  productoActualizado,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  if (exito) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Producto actualizado correctamente'),
                      ),
                    );

                    // 🔁 Recargar la lista de productos
                    final controller = Provider.of<InventarioController>(
                      context,
                      listen: false,
                    );
                    controller.cargarInventario();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error al actualizar el producto'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Guardar cambios'),
            ),
          ],
        );
      },
    );
  }

  void _abrirEscaner(BuildContext context) async {
    final codigo = await ScannerService.escanearCodigo(context);

    if (codigo == null) return;

    final productoExistente = await ProductosService().obtenerPorCodigo(codigo);

    if (productoExistente != null) {
      // ✅ Producto encontrado → abrir formulario de edición
      _mostrarFormularioEdicion(context, productoExistente);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Producto encontrado: ${productoExistente.nombre}'),
        ),
      );
    } else {
      // 🆕 Producto nuevo → abrir formulario de registro con código precargado
      _mostrarFormularioNuevoProducto(context, codigoInicial: codigo);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nuevo código detectado: $codigo')),
      );
    }
  }

  //Funcion para eliminar produc
}
