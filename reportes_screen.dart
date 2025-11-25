import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controladores/auth_controller.dart';
import 'inventario/inventario_screen.dart';
import 'ventas/ventas_screen.dart';
import 'reportes/reportes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    InventarioScreen(),
    VentasScreen(),
    ReportesScreen(),
  ];

  final List<_MenuItem> _menuItems = const [
    _MenuItem(icon: Icons.inventory_2_outlined, title: "Inventario"),
    _MenuItem(icon: Icons.point_of_sale, title: "Ventas"),
    _MenuItem(icon: Icons.bar_chart_rounded, title: "Reportes"),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFF9B71),
        title: const Text(
          "InventFact",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: "Menú",
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: "Cerrar sesión",
            onPressed: () => _showLogoutDialog(context, auth),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            // Header del drawer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF9B71), Color(0xFFFFB591)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFFFF9B71),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    auth.empleadoActual?.nombre ?? "Usuario",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    auth.empleadoActual?.usuario ?? "Rol",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Opciones del menú
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  final isSelected = _selectedIndex == index;

                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFFFF9B71).withOpacity(0.1)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        item.icon,
                        color:
                            isSelected
                                ? const Color(0xFFFF9B71)
                                : Colors.grey[600],
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          color:
                              isSelected
                                  ? const Color(0xFFFF9B71)
                                  : Colors.grey[800],
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        setState(() => _selectedIndex = index);
                        Navigator.pop(context);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Footer
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.grey),
              title: const Text("Acerca de"),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_selectedIndex],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthController auth) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Cerrar sesión"),
            content: const Text("¿Estás seguro de que deseas salir?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () {
                  auth.logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9B71),
                ),
                child: const Text("Salir"),
              ),
            ],
          ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: "InventFact",
      applicationVersion: "1.0.0",
      applicationIcon: const Icon(
        Icons.inventory_2,
        size: 48,
        color: Color(0xFFFF9B71),
      ),
      children: [const Text("Sistema de gestión de inventario y facturación")],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;

  const _MenuItem({required this.icon, required this.title});
}
