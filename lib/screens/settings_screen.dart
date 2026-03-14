import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/company_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _gstinController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  void _loadCompanyData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final company = authProvider.currentCompany;
    if (company != null) {
      _companyNameController.text = company.companyName;
      _ownerNameController.text = company.ownerName;
      _phoneController.text = company.phone;
      _addressController.text = company.address;
      _gstinController.text = company.gstin ?? '';
      _websiteController.text = company.website ?? '';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final companyService = CompanyService();

    if (authProvider.currentCompany != null) {
      final result = await companyService.updateCompany(
        companyId: authProvider.currentCompany!.id,
        companyName: _companyNameController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        gstin: _gstinController.text.trim().isEmpty
            ? null
            : _gstinController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
      );

      if (!mounted) return;

      if (result['success']) {
        // Refresh company data in provider
        await authProvider.refreshCompanyData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.brown,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.brown,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 35,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authProvider.currentUser?.name ?? 'User',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown[800],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                authProvider.currentUser?.email ?? '',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 13 : 14,
                                  color: Colors.brown[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: isSmallScreen ? 20 : 24),

                Text(
                  'Company Profile',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown[800],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 4 : 6),

                Text(
                  'This information appears on all your PDFs and reports.',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    color: Colors.brown[600],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 16 : 20),

                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    child: Column(
                      children: [
                        // Company Name
                        TextFormField(
                          controller: _companyNameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Company Name *',
                            prefixIcon: const Icon(Icons.business),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter company name';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: isSmallScreen ? 14 : 16),

                        // Owner Name
                        TextFormField(
                          controller: _ownerNameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Owner Name *',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter owner name';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: isSmallScreen ? 14 : 16),

                        // Phone
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone Number *',
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter phone number';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: isSmallScreen ? 14 : 16),

                        // Address
                        TextFormField(
                          controller: _addressController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Address *',
                            prefixIcon: const Icon(Icons.location_on),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter address';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: isSmallScreen ? 14 : 16),

                        // GSTIN
                        TextFormField(
                          controller: _gstinController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'GSTIN (Optional)',
                            prefixIcon: const Icon(Icons.receipt),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            hintText: 'e.g., 27AAPFU0939F1ZV',
                          ),
                          validator: (value) {
                            if (value != null &&
                                value.trim().isNotEmpty &&
                                value.trim().length != 15) {
                              return 'GSTIN must be 15 characters';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: isSmallScreen ? 14 : 16),

                        // Website
                        TextFormField(
                          controller: _websiteController,
                          keyboardType: TextInputType.url,
                          decoration: InputDecoration(
                            labelText: 'Website (Optional)',
                            prefixIcon: const Icon(Icons.language),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            hintText: 'e.g., www.yourcompany.com',
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 20 : 24),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 14 : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: isSmallScreen ? 32 : 40),

                Center(
                  child: Text(
                    'WoodRate Pro v1.0.0 • by NishantCreation',
                    style: TextStyle(
                      color: Colors.brown[400],
                      fontSize: isSmallScreen ? 11 : 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    _websiteController.dispose();
    super.dispose();
  }
}