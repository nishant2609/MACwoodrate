import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'cft_calculator_screen.dart';
import 'settings_screen.dart';
import '../utils/company_profile.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _companyName = 'WoodRate Pro';

  @override
  void initState() {
    super.initState();
    _loadCompanyName();
  }

  Future<void> _loadCompanyName() async {
    final name = await CompanyProfile.getCompanyName();
    if (mounted) {
      setState(() {
        _companyName = name ?? 'WoodRate Pro';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: FittedBox(
          child: Text(
            _companyName,
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
            ),
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
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                    builder: (context) => const SettingsScreen()),
              );
              if (updated == true) {
                _loadCompanyName();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Column(
            children: [
              SizedBox(height: isSmallScreen ? 20 : 40),

              // Welcome Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.carpenter,
                      size: isSmallScreen ? 50 : 60,
                      color: Colors.brown[700],
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    Text(
                      _companyName,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 8),
                    Text(
                      'Choose your calculation type',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: Colors.brown[600],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isSmallScreen ? 30 : 40),

              // Calculator Options
              Expanded(
                child: isSmallScreen
                    ? Column(
                  children: [
                    Expanded(
                      child: _buildCalculatorCard(
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
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 20),
                    Expanded(
                      child: _buildCalculatorCard(
                        context,
                        title: 'Rate Finder',
                        subtitle:
                        'Complete cost calculation\nWith materials, labor & profits',
                        icon: Icons.monetization_on,
                        color: Colors.green[700]!,
                        isSmallScreen: isSmallScreen,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomeScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                )
                    : Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildCalculatorCard(
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
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildCalculatorCard(
                              context,
                              title: 'Rate Finder',
                              subtitle:
                              'Complete cost calculation\nWith materials, labor & profits',
                              icon: Icons.monetization_on,
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Footer
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Text(
                  'WoodRate Pro • by NishantCreation',
                  style: TextStyle(
                    color: Colors.brown[400],
                    fontSize: isSmallScreen ? 10 : 12,
                  ),
                ),
              ),
            ],
          ),
        ),
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
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
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
          child: isSmallScreen
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: isSmallScreen ? 32 : 40,
                  color: color,
                ),
              ),
              SizedBox(height: isSmallScreen ? 12 : 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallScreen ? 6 : 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              Icon(
                Icons.arrow_forward,
                color: color,
                size: isSmallScreen ? 16 : 20,
              ),
            ],
          )
              : Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}