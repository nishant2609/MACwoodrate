import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'cft_calculator_screen.dart';
import 'settings_screen.dart';
import 'order_history_screen.dart';
import '../providers/auth_provider.dart';
import '../services/order_service.dart';
import '../models/order.dart' as app_models;
import 'auth/login_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Map<String, dynamic> _stats = {
    'totalOrders': 0,
    'totalRevenue': 0.0,
    'totalCft': 0.0,
  };
  bool _loadingStats = true;
  List<app_models.Order> _recentOrders = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final authProvider =
    Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentCompany != null) {
      final orderService = OrderService();
      final stats = await orderService
          .getOrderStats(authProvider.currentCompany!.id);
      final orders = await orderService
          .getOrders(authProvider.currentCompany!.id);
      if (mounted) {
        setState(() {
          _stats = stats;
          _recentOrders = orders.take(3).toList();
          _loadingStats = false;
        });
      }
    } else {
      setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final authProvider = Provider.of<AuthProvider>(context);

    final companyName =
        authProvider.currentCompany?.companyName ?? 'WoodRate Pro';
    final ownerName =
        authProvider.currentCompany?.ownerName ?? '';

    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: FittedBox(
          child: Text(
            companyName,
            style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
          ),
        ),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SettingsScreen()),
              );
              _loadStats();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text(
                      'Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, true),
                      child: const Text('Logout',
                          style:
                          TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                if (!context.mounted) return;
                await authProvider.signOut();
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                      const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: isSmallScreen ? 8 : 16),

                // ═══════════════════════════════
                // WELCOME CARD
                // ═══════════════════════════════
                Container(
                  width: double.infinity,
                  padding:
                  EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.brown[700]!,
                        Colors.brown[500]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.brown.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color:
                          Colors.white.withOpacity(0.2),
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.carpenter,
                          size: 35,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              companyName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (ownerName.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                ownerName,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.brown[100],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 20 : 24),

                // ═══════════════════════════════
                // OVERVIEW STATS
                // ═══════════════════════════════
                Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown[800],
                  ),
                ),

                const SizedBox(height: 12),

                _loadingStats
                    ? const Center(
                    child: CircularProgressIndicator())
                    : Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Total Orders',
                        value:
                        '${_stats['totalOrders']}',
                        icon: Icons.receipt_long,
                        color: Colors.blue[700]!,
                        isSmallScreen: isSmallScreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Wood CFT',
                        value:
                        '${(_stats['totalCft'] as double).toStringAsFixed(1)}',
                        icon: Icons.forest,
                        color: Colors.green[700]!,
                        isSmallScreen: isSmallScreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Product Revenue',
                        value:
                        'Rs.${_formatNumber(_stats['totalRevenue'] as double)}',
                        icon: Icons.currency_rupee,
                        color: Colors.orange[700]!,
                        isSmallScreen: isSmallScreen,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: isSmallScreen ? 20 : 24),

                // ═══════════════════════════════
                // CALCULATORS
                // ═══════════════════════════════
                Text(
                  'Calculators',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown[800],
                  ),
                ),

                const SizedBox(height: 12),

                _buildCalculatorCard(
                  context,
                  title: 'CFT Calculator',
                  subtitle:
                  'Calculate wood volume in CFT\nBulk quantity calculations',
                  icon: Icons.calculate,
                  color: Colors.blue[700]!,
                  isSmallScreen: isSmallScreen,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const CftCalculatorScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                _buildCalculatorCard(
                  context,
                  title: 'Wood Cost Estimator',
                  subtitle:
                  'Complete product cost calculation\nMaterials, labor, profit & more',
                  icon: Icons.handyman,
                  color: Colors.green[700]!,
                  isSmallScreen: isSmallScreen,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const HomeScreen(),
                      ),
                    );
                  },
                ),

                SizedBox(height: isSmallScreen ? 20 : 24),

                // ═══════════════════════════════
                // RECENT ORDERS
                // ═══════════════════════════════
                _buildRecentOrdersCard(isSmallScreen),

                SizedBox(height: isSmallScreen ? 16 : 24),

                // Footer
                Center(
                  child: Text(
                    'WoodRate Pro • by NishantCreation',
                    style: TextStyle(
                      color: Colors.brown[400],
                      fontSize: isSmallScreen ? 10 : 12,
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(1)}L';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? 15 : 17,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 9 : 10,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersCard(bool isSmallScreen) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                        Colors.brown.withOpacity(0.1),
                        borderRadius:
                        BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.history,
                        color: Colors.brown[700],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Recent Orders',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800],
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                          const OrderHistoryScreen()),
                    );
                    _loadStats();
                  },
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: Colors.brown[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (_recentOrders.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.receipt_long,
                        size: 40, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No orders yet',
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create your first order using\nWood Cost Estimator',
                      style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              ..._recentOrders
                  .map((order) =>
                  _buildOrderTile(order, isSmallScreen))
                  .toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTile(
      app_models.Order order, bool isSmallScreen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.brown.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.chair,
                color: Colors.brown[600], size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.itemDescription,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  order.orderId,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.date.day}/${order.date.month}/${order.date.year}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 11,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs.${order.total.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${order.totalCft.toStringAsFixed(1)} CFT',
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 11,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required bool isSmallScreen,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}