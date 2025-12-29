import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../core/constants.dart';
import '../../models/medical_file_model.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common_widgets.dart';

class UploadFileScreen extends StatefulWidget {
  final PlatformFile initialFile;

  const UploadFileScreen({super.key, required this.initialFile});

  @override
  State<UploadFileScreen> createState() => _UploadFileScreenState();
}

class _UploadFileScreenState extends State<UploadFileScreen> {
  FileCategory _category = FileCategory.other;
  late TextEditingController _nameController;
  final _descController = TextEditingController();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialFile.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _upload() async {
    final userProvider = context.read<UserProvider>();
    final uid = userProvider.firebaseUser?.uid ?? userProvider.user?.id;

    if (uid == null) {
      AppSnackBar.showError(context, "User not logged in");
      return;
    }

    setState(() => _isUploading = true);

    try {
      final basename = widget.initialFile.name;
      final storagePath = 'users/$uid/medical_files/${DateTime.now().millisecondsSinceEpoch}_$basename';
      final ref = FirebaseStorage.instance.ref().child(storagePath);

      UploadTask uploadTask;
      if (kIsWeb || widget.initialFile.path == null) {
        uploadTask = ref.putData(widget.initialFile.bytes!, SettableMetadata(contentType: _guessMimeType(basename)));
      } else {
        uploadTask = ref.putFile(File(widget.initialFile.path!), SettableMetadata(contentType: _guessMimeType(basename)));
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      final model = MedicalFileModel(
        id: '',
        name: _nameController.text.trim(),
        category: _category,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        fileUrl: downloadUrl,
        uploadedAt: DateTime.now(),
      );

      await userProvider.addMedicalFile(model);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) AppSnackBar.showError(context, "Upload Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight(context),
      appBar: AppBar(
        title: Text('Save Document', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: AppTheme.textDark(context))),
        backgroundColor: AppTheme.backgroundCard(context),
        foregroundColor: AppTheme.textDark(context),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header
            Text(
              'Document Details',
              style: GoogleFonts.dmSans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a category and name for your document',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary(context),
              ),
            ),
            const SizedBox(height: AppSizes.paddingL),

            // File Preview Card
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingM),
              decoration: BoxDecoration(
                color: AppTheme.backgroundCard(context),
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadow(context),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    ),
                    child: Icon(
                      widget.initialFile.name.toLowerCase().endsWith('.pdf')
                          ? Icons.picture_as_pdf_rounded
                          : Icons.image_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.initialFile.name,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(widget.initialFile.size / 1024).toStringAsFixed(1)} KB',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle, color: AppColors.success, size: 24),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.paddingL),

            // Form Card
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingL),
              decoration: BoxDecoration(
                color: AppTheme.backgroundCard(context),
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadow(context),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Dropdown
                  Text(
                    'Category',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.divider(context)),
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<FileCategory>(
                        value: _category,
                        isExpanded: true,
                        dropdownColor: AppTheme.backgroundCard(context),
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary(context)),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: AppTheme.textDark(context),
                        ),
                        items: FileCategory.values.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Row(
                              children: [
                                Icon(_getCategoryIcon(c), size: 20, color: AppColors.primary),
                                const SizedBox(width: 12),
                                Text(
                                  _categoryName(c),
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: AppTheme.textDark(context),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _category = v ?? FileCategory.other),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingL),

                  // Display Name
                  Text(
                    'Display Name',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textDark(context)),
                    decoration: InputDecoration(
                      hintText: 'Enter document name',
                      hintStyle: GoogleFonts.inter(color: AppTheme.textMuted(context)),
                      filled: true,
                      fillColor: AppTheme.backgroundCard(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                        borderSide: BorderSide(color: AppTheme.divider(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                        borderSide: BorderSide(color: AppTheme.divider(context)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingL),

                  // Description
                  Text(
                    'Description (optional)',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descController,
                    style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textDark(context)),
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Add a description...',
                      hintStyle: GoogleFonts.inter(color: AppTheme.textMuted(context)),
                      filled: true,
                      fillColor: AppTheme.backgroundCard(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                        borderSide: BorderSide(color: AppTheme.divider(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                        borderSide: BorderSide(color: AppTheme.divider(context)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.paddingXL),

            // Upload Progress
            if (_isUploading) ...[
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingM),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundCard(context),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: Column(
                  children: [
                    const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Uploading to cloud...',
                      style: GoogleFonts.inter(color: AppTheme.textSecondary(context)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.paddingL),
            ],

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _upload,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(
                  _isUploading ? 'Uploading...' : 'Save to Cloud',
                  style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(FileCategory c) {
    switch (c) {
      case FileCategory.allergyReport:
        return Icons.warning_amber_rounded;
      case FileCategory.prescription:
        return Icons.medication_rounded;
      case FileCategory.medicalAnalysis:
        return Icons.analytics_rounded;
      case FileCategory.birthCertificate:
        return Icons.cake_rounded;
      case FileCategory.other:
        return Icons.folder_rounded;
    }
  }

  String _categoryName(FileCategory c) {
    switch (c) {
      case FileCategory.allergyReport:
        return 'Allergy Report';
      case FileCategory.prescription:
        return 'Prescription';
      case FileCategory.medicalAnalysis:
        return 'Medical Analysis';
      case FileCategory.birthCertificate:
        return 'Birth Certificate';
      case FileCategory.other:
        return 'Other';
    }
  }

  String _guessMimeType(String filename) =>
      filename.toLowerCase().endsWith('.pdf') ? 'application/pdf' : 'image/jpeg';
}
