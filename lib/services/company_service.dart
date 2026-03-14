import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/company.dart';

class CompanyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create company
  Future<Map<String, dynamic>> createCompany({
    required String companyName,
    required String ownerName,
    required String email,
    required String phone,
    required String address,
    String? gstin,
    String? website,
  }) async {
    try {
      final docRef = _firestore.collection('companies').doc();

      final company = Company(
        id: docRef.id,
        companyName: companyName,
        ownerName: ownerName,
        email: email,
        phone: phone,
        address: address,
        gstin: gstin,
        website: website,
        createdAt: DateTime.now(),
      );

      await docRef.set(company.toJson());

      return {
        'success': true,
        'message': 'Company created successfully',
        'companyId': docRef.id,
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get company by ID
  Future<Company?> getCompany(String companyId) async {
    try {
      final doc =
      await _firestore.collection('companies').doc(companyId).get();
      if (!doc.exists) return null;
      return Company.fromJson(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  // Update company
  Future<Map<String, dynamic>> updateCompany({
    required String companyId,
    required String companyName,
    required String ownerName,
    required String phone,
    required String address,
    String? gstin,
    String? website,
  }) async {
    try {
      await _firestore.collection('companies').doc(companyId).update({
        'companyName': companyName,
        'ownerName': ownerName,
        'phone': phone,
        'address': address,
        'gstin': gstin,
        'website': website,
      });
      return {'success': true, 'message': 'Company updated successfully'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Check if company exists for user
  Future<bool> hasCompany(String companyId) async {
    try {
      final doc =
      await _firestore.collection('companies').doc(companyId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }
}