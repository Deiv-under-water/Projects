import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../services/inventario_service.dart';

class InventarioController extends ChangeNotifier {
  final InventarioService _inventarioService = InventarioService();

  List<Producto> _inventario = [];
  List<Producto> _bajoStock = [];
  bool _cargando = false;

  List<Producto> get inventario => _inventario;
  List<Producto> get bajoStock => _bajoStock;
  bool get cargando => _cargando;

  /// Cargar inventario completo
  Future<void> cargarInventario() async {
    _cargando = true;
    notifyListeners();

    try {
      _inventario = await _inventarioService.obtenerInventario();
      _bajoStock = await _inventarioService.obtenerStockBajo();
    } catch (e) {
      debugPrint('❌ Error al cargar inventario: $e');
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Actualizar stock de un producto
  Future<void> actualizarStock(Producto producto, int nuevaCantidad) async {
    await _inventarioService.actualizarStock(producto, nuevaCantidad);
    await cargarInventario();
  }
}
