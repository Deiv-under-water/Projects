import 'package:flutter/material.dart';
import '../models/venta.dart';
import '../services/ventas_service.dart';
import '../models/producto.dart';
import '../models/detalle_venta.dart';
import '../models/cliente.dart';
import '../models/empleado.dart';
import '../services/productos_service.dart';

class VentasController extends ChangeNotifier {
  final List<DetalleVenta> productosSeleccionados = [];
  final VentasService _ventasService = VentasService();
  final ProductosService _productosService =
      ProductosService(); // ✅ Faltaba esta línea

  List<Venta> _ventas = [];
  bool _cargando = false;

  List<Venta> get ventas => _ventas;
  bool get cargando => _cargando;

  /// Registrar una nueva venta
  Future<void> registrarVenta(
    String nombreCliente,
    int cedulaCliente,
    List<DetalleVenta> detalles,
    double total,
  ) async {
    _cargando = true;
    notifyListeners();

    try {
      final cliente = Cliente(cedula: cedulaCliente, nombre: nombreCliente);

      final empleado = Empleado(cedula: 987654321, nombre: 'Empleado 1');

      final nuevaVenta = Venta(
        cliente: cliente,
        encargado: empleado,
        detalles: detalles,
      );

      nuevaVenta.calcularValor();

      final exito = await _ventasService.registrarVenta(nuevaVenta);

      if (exito) {
        _ventas.add(nuevaVenta);
        print('✅ Venta registrada correctamente en el backend');
      } else {
        print('❌ Error al registrar la venta');
      }
    } catch (e) {
      print('❌ Error al registrar la venta: $e');
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Verificar stock disponible antes de registrar o aumentar cantidades
  Future<String?> validarStock(List<DetalleVenta> detalles) async {
    for (final detalle in detalles) {
      final stock = await _productosService.obtenerStock(
        detalle.producto.idProducto,
      );

      if (stock == null) {
        return 'No se pudo verificar el stock para ${detalle.producto.nombre}.';
      }

      if (detalle.cantidad > stock) {
        return 'Stock insuficiente para ${detalle.producto.nombre}. '
            'Disponible: $stock, solicitado: ${detalle.cantidad}.';
      }
    }

    return null; // ✅ Todo bien
  }

  /// Intenta agregar un producto verificando el stock disponible
  Future<bool> agregarProductoConValidacion(
    List<DetalleVenta> lista,
    Producto producto,
  ) async {
    final stock = await _productosService.obtenerStock(producto.idProducto);

    if (stock == null) {
      throw Exception('No se pudo obtener el stock de ${producto.nombre}');
    }

    // Verificar si ya está en la lista
    final existente = lista.firstWhere(
      (d) => d.producto.idProducto == producto.idProducto,
      orElse: () => DetalleVenta(producto: producto, cantidad: 0),
    );

    final nuevaCantidad = existente.cantidad + 1;

    if (nuevaCantidad > stock) {
      throw Exception(
        'Stock insuficiente para ${producto.nombre}. Disponible: $stock',
      );
    }

    // Si todo bien, agregar o aumentar
    if (existente.cantidad == 0) {
      lista.add(DetalleVenta(producto: producto, cantidad: 1));
    } else {
      existente.cantidad = nuevaCantidad;
    }

    notifyListeners();
    return true;
  }

  void agregarProducto(Producto producto) {
    final index = productosSeleccionados.indexWhere(
      (detalle) => detalle.producto.idProducto == producto.idProducto,
    );

    if (index != -1) {
      final detalleActual = productosSeleccionados[index];
      final nuevaCantidad = detalleActual.cantidad + 1;
      productosSeleccionados[index] = DetalleVenta(
        producto: detalleActual.producto,
        cantidad: nuevaCantidad,
      );
    } else {
      productosSeleccionados.add(DetalleVenta(producto: producto, cantidad: 1));
    }

    notifyListeners();
  }
}
