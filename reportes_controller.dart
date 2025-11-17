import 'package:flutter/material.dart';
import 'package:invent/services/productos_service.dart';
import '../services/reportes_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ReporteController extends ChangeNotifier {
  final ReportesService _reportesService = ReportesService();
  //final VentasService _ventasService = VentasService();
  //final InventarioService _inventarioService = InventarioService();
  final ProductosService _productosService = ProductosService();
  bool cargando2 = false;

  final ReportesService _service = ReportesService();

  bool _cargando = false;
  List<Map<String, dynamic>> _reportes = [];
  List<Map<String, dynamic>> _detallesVenta = [];
  List<Map<String, dynamic>> ventasTodas = [];

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

  Future<void> generarFacturaPDF({
    required Map<String, dynamic> ventaSeleccionada,
    required List<dynamic> detalles,
  }) async {
    try {
      await _reportesService.generarFacturaPDF(
        ventaSeleccionada: ventaSeleccionada,
        detalles: detalles,
      );
    } catch (e) {
      print('❌ Error al generar PDF: $e');
    }
  }

  Future<void> cargarVentasTodas() async {
    _cargando = true;
    notifyListeners();

    ventasTodas = await _reportesService.obtenerVentasTodas();

    _cargando = false;
    notifyListeners();
  }

  Future<File> generarPDFVentas() async {
    cargando2 = true;
    notifyListeners();

    // ✅ Usar el servicio correcto
    final ventas = await _reportesService.obtenerVentasTodas();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build:
            (context) => [
              pw.Text(
                "REPORTE DE TODAS LAS VENTAS",
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ["ID", "Cliente", "Empleado", "Total", "Fecha"],
                data:
                    ventas.map((v) {
                      return [
                        v['id_venta'].toString(),
                        v['nombre_cliente'] ?? '',
                        v['nombre_empleado'] ?? '',
                        v['total'].toString(),
                        v['fecha_venta'].toString(),
                      ];
                    }).toList(),
              ),
            ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/todas_las_ventas.pdf");
    await file.writeAsBytes(await pdf.save());

    cargando2 = false;
    notifyListeners();
    return file;
  }

  Future<File> generarPDFInventario() async {
    cargando2 = true;
    notifyListeners();

    final productos = await _productosService.obtenerProductos(); // REUTILIZADO

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build:
            (context) => [
              pw.Text(
                "INVENTARIO COMPLETO",
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ["Producto", "Precio", "Stock", "Categoría"],
                data:
                    productos.map((p) {
                      return [
                        p.nombre,
                        p.precio.toString(),
                        p.stock.toString(),
                        p.categoria,
                      ];
                    }).toList(),
              ),
            ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/inventario_completo.pdf");
    await file.writeAsBytes(await pdf.save());

    cargando2 = false;
    notifyListeners();
    return file;
  }
}
