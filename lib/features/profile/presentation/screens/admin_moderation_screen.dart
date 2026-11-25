import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../../controllers/auth_controller.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/trocly_bottom_nav.dart';
import '../../../../core/widgets/trocly_brand_header.dart';

/// Phase 2.5 — Panneau d'Administration & Modération moderne (KPIs + traitement des signalements)
class AdminModerationScreen extends StatefulWidget {
  const AdminModerationScreen({Key? key}) : super(key: key);

  @override
  State<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends State<AdminModerationScreen> {
  final AuthController _auth = Get.find<AuthController>();
  bool _loading = true;
  Map<String, dynamic>? _stats;
  List<dynamic> _reports = [];
  List<dynamic> _categories = [];

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        if (_auth.authToken.value.isNotEmpty)
          'Authorization': 'Bearer ${_auth.authToken.value}',
      };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final base = ApiConstants.baseUrl;
      final res = await Future.wait([
        http.get(Uri.parse('$base/admin/dashboard'), headers: _headers()),
        http.get(Uri.parse('$base/admin/pending-reports'), headers: _headers()),
        http.get(Uri.parse('$base/admin/popular-categories'),
            headers: _headers()),
      ]);
      if (res[0].statusCode == 200) {
        _stats = jsonDecode(res[0].body) as Map<String, dynamic>;
      }
      if (res[1].statusCode == 200) {
        final decoded = jsonDecode(res[1].body);
        _reports = decoded is List ? decoded : [];
      }
      if (res[2].statusCode == 200) {
        final decoded = jsonDecode(res[2].body);
        _categories = decoded is List ? decoded : [];
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resolveReport(String reportId, {required bool archive}) async {
    try {
      final resp = await http.patch(
        Uri.parse('${ApiConstants.baseUrl}/admin/reports/$reportId/resolve'),
        headers: _headers(),
        body: jsonEncode({
          'status': 'resolved',
          'archiveListing': archive,
        }),
      );
      if (resp.statusCode == 200) {
        Get.snackbar(
          'Signalement traité',
          archive
              ? 'Annonce archivée et signalement résolu.'
              : 'Signalement classé sans suite.',
        );
        await _loadAll();
      }
    } catch (_) {
      Get.snackbar('Erreur', 'Impossible de traiter le signalement.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalOffers = (_stats?['offers']?['total'] ?? 0) as num;
    final validatedMeetings = (_stats?['meetings']?['validated'] ?? 0) as num;
    final convRate = totalOffers > 0
        ? ((validatedMeetings / totalOffers) * 100).toStringAsFixed(0)
        : '0';

    return Scaffold(
      backgroundColor: AppColors.paper,
      bottomNavigationBar: const TroclyBottomNav(currentIndex: 4),
      appBar: AppBar(
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: TroclyCircleIconBtn(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Get.back(),
            ),
          ),
        ),
        title: const TroclyAppBarTitle(pageTitle: 'Admin & Modération'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: TroclyCircleIconBtn(
                icon: Icons.refresh_rounded,
                onTap: _loadAll,
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const ListingGridSkeleton(count: 4)
          : RefreshIndicator(
              onRefresh: _loadAll,
              color: AppColors.accent,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Text('INDICATEURS DE LA PLATEFORME',
                      style: AppTypography.eyebrow(color: AppColors.accent)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _kpiCard(
                          'Membres',
                          '${_stats?['users']?['total'] ?? 0}',
                          Icons.people_outline_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _kpiCard(
                          'Annonces actives',
                          '${_stats?['listings']?['active'] ?? 0}',
                          Icons.inventory_2_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _kpiCard(
                          'RDV QR validés',
                          '$validatedMeetings',
                          Icons.qr_code_scanner_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _kpiCard(
                          'Conversion QR',
                          '$convRate%',
                          Icons.trending_up_rounded,
                          highlight: true,
                        ),
                      ),
                    ],
                  ),
                  if (_categories.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    Text('CATÉGORIES POPULAIRES',
                        style: AppTypography.eyebrow()),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Column(
                        children: _categories.take(5).map((c) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  c['category']?.toString() ?? 'Autre',
                                  style: AppTypography.sans(
                                      size: 13.5, weight: FontWeight.w600),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${c['count'] ?? 0}',
                                    style: AppTypography.sans(
                                      size: 12,
                                      weight: FontWeight.w700,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Text(
                    'FILE DE MODÉRATION (${_reports.length})',
                    style: AppTypography.eyebrow(),
                  ),
                  const SizedBox(height: 10),
                  if (_reports.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Center(
                        child: Text(
                          'Aucun signalement en attente.',
                          style: AppTypography.sans(
                              size: 13.5, color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ..._reports.map((r) {
                      final id = r['id']?.toString() ?? '';
                      final reason = r['reportType']?.toString() ?? 'Autre';
                      final desc = r['description']?.toString() ?? '';
                      final listingTitle =
                          r['reportedListing']?['title']?.toString();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorLight,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    reason.toUpperCase(),
                                    style: AppTypography.sans(
                                      size: 11,
                                      weight: FontWeight.w700,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                                if (listingTitle != null)
                                  Flexible(
                                    child: Text(
                                      listingTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.sans(
                                          size: 12.5, weight: FontWeight.w700),
                                    ),
                                  ),
                              ],
                            ),
                            if (desc.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(desc,
                                  style: AppTypography.sans(
                                      size: 13,
                                      color: AppColors.textSecondary)),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: PrimaryButton(
                                    label: 'Ignorer',
                                    height: 40,
                                    isOutlined: true,
                                    onPressed: () =>
                                        _resolveReport(id, archive: false),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: PrimaryButton(
                                    label: 'Archiver annonce',
                                    height: 40,
                                    backgroundColor: AppColors.error,
                                    onPressed: () =>
                                        _resolveReport(id, archive: true),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon,
      {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? AppColors.accent : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: highlight ? AppColors.coralShadow : AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 20, color: highlight ? Colors.white : AppColors.accent),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.serif(
              size: 24,
              color: highlight ? Colors.white : AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.sans(
              size: 12,
              color: highlight
                  ? Colors.white.withValues(alpha: 0.9)
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
