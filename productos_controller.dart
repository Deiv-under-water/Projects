import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../services/productos_service.dart';

class ProductosController extends ChangeNotifier {
  final ProductosService _productosService = ProductosService();

  List<Producto> _productos = [];
  bool _cargando = false;

  List<Producto> get productos => _productos;
  bool get cargando => _cargando;

  /// Cargar productos desde el backend
  Future<void> cargarProductos() async {
    _cargando = true;
    notifyListeners();

    try {
      _productos = await _productosService.obtenerProductos();
    } catch (e) {
      debugPrint('❌ Error al cargar productos: $e');
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Agregar un nuevo producto
  Future<bool> agregarProducto(Producto producto) async {
    final exito = await _productosService.registrarProducto(producto);
    if (exito) await cargarProductos();
    return exito;
  }

  /// Actualizar producto existente
  Future<bool> actualizarProducto(Producto producto) async {
    final exito = await _productosService.actualizarProducto(producto);
    if (exito) await cargarProductos();
    return exito;
  }
}
