import 'package:flutter/material.dart';
import '../services/reportes_service.dart';

class ReporteController extends ChangeNotifier {
  final ReportesService _service = ReportesService();

  bool _cargando = false;
  List<Map<String, dynamic>> _reportes = [];
  List<Map<String, dynamic>> _detallesVenta = [];

  bool get cargando => _cargando;
  List<Map<String, dynamic>> get reportes => _reportes;
  List<Map<String, dynamic>> get detallesVenta => _detallesVenta;

  /// Buscar reportes por cliente o rango de fechas
  Future<void> buscarReportes({
    String? cliente,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    _cargando = true;
    notifyListeners();

    try {
      _reportes = await _service.obtenerReportes(
        cliente: cliente,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );
    } catch (e) {
      print('❌ Error al buscar reportes: $e');
      _reportes = [];
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Obtener los detalles de una venta específica
  Future<void> obtenerDetallesVenta(int idVenta) async {
    _cargando = true;
    notifyListeners();

    try {
      _detallesVenta = await _service.obtenerDetallesVenta(idVenta);
    } catch (e) {
      print('❌ Error al obtener detalles: $e');
      _detallesVenta = [];
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
