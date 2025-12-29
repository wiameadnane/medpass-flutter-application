import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../models/medical_file_model.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common_widgets.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<MedicalFileModel> _searchResults = [];
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus the search field when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    final userProvider = context.read<UserProvider>();
    setState(() {
      _hasSearched = query.isNotEmpty;
      _searchResults = userProvider.searchFiles(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundCard(context),
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ),
        ),
        title: Text(
          'Search',
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark(context),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.all(AppSizes.paddingL),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundCard(context),
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _performSearch,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textDark(context),
                ),
                decoration: InputDecoration(
                  hintText: 'Search files, prescriptions, reports...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.textSecondary(context),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.primary,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: AppTheme.textSecondary(context),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppTheme.backgroundCard(context),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingM,
                    vertical: AppSizes.paddingM,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),

          // Results
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (!_hasSearched) {
      return _buildInitialState();
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final file = _searchResults[index];
        return _buildResultItem(file, index);
      },
    );
  }

  Widget _buildInitialState() {
    return Builder(
      builder: (context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: AppTheme.textSecondary(context).withAlpha((0.3 * 255).round()),
            ),
            const SizedBox(height: AppSizes.paddingM),
            Text(
              'Search your medical files',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary(context),
              ),
            ),
            const SizedBox(height: AppSizes.paddingS),
            Text(
              'Type to search by name, category, or description',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary(context).withAlpha((0.7 * 255).round()),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 500.ms),
    );
  }

  Widget _buildEmptyState() {
    return Builder(
      builder: (context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: AppTheme.textSecondary(context).withAlpha((0.5 * 255).round()),
            ),
            const SizedBox(height: AppSizes.paddingM),
            Text(
              'No results found',
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary(context),
              ),
            ),
            const SizedBox(height: AppSizes.paddingS),
            Text(
              'Try different keywords',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildResultItem(MedicalFileModel file, int index) {
    IconData icon;
    Color color;

    switch (file.category) {
      case FileCategory.allergyReport:
        icon = Icons.warning_amber_rounded;
        color = AppColors.warning;
        break;
      case FileCategory.prescription:
        icon = Icons.receipt_long_rounded;
        color = AppColors.accent;
        break;
      case FileCategory.birthCertificate:
        icon = Icons.description_rounded;
        color = AppColors.primary;
        break;
      case FileCategory.medicalAnalysis:
        icon = Icons.science_rounded;
        color = AppColors.primaryLight;
        break;
      case FileCategory.other:
        icon = Icons.folder_rounded;
        color = AppColors.textSecondary;
        break;
    }

    return Builder(
      builder: (ctx) => GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/file-viewer',
            arguments: file.category,
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSizes.paddingM),
          padding: const EdgeInsets.all(AppSizes.paddingM),
          decoration: BoxDecoration(
            color: AppTheme.backgroundCard(ctx),
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
            border: Border.all(
              color: AppTheme.divider(ctx),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadow(ctx),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingS),
                decoration: BoxDecoration(
                  color: color.withAlpha((0.1 * 255).round()),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: AppSizes.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark(ctx),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      file.categoryName,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.textSecondary(ctx),
                      ),
                    ),
                    if (file.description != null && file.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          file.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppTheme.textSecondary(ctx).withAlpha((0.7 * 255).round()),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (file.isImportant)
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
              const SizedBox(width: AppSizes.paddingS),
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textSecondary(ctx).withAlpha((0.5 * 255).round()),
                size: 16,
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: Duration(milliseconds: 200 + (index * 50))).slideX(begin: 0.1),
    );
  }
}
