// lib/service_catalog/screens/services_screen.dart
//
// "Our Services" list — mirrors the website's services grid. Tapping a card
// opens [ServiceDetailScreen], which carries the enquiry form.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../navigation/app_header.dart';
import '../../news/widgets/net_image.dart';
import '../../point/routes/app_routes.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/responsive.dart';
import '../models/service_model.dart';
import '../services/service_catalog_service.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _api = ServiceCatalogService();

  List<ServiceOffering> _services = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _api.getServices();
    if (!mounted) return;
    setState(() {
      _services = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppHeader(),
        Expanded(
          // AppBar always reserves MediaQuery.padding.top for the status bar
          // itself, regardless of what's already above it — without this,
          // AppHeader's own safe area plus the AppBar's would double up.
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 0,
              title: Text(
                'Services',
                style: GoogleFonts.montserrat(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ),
            body: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _services.isEmpty
                      ? _empty()
                      : ContentWidth(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _services.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, i) => _ServiceCard(service: _services[i]),
                          ),
                        ),
            ),
          ),
          ),
        ),
      ],
    );
  }

  Widget _empty() => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
        children: [
          Icon(Icons.handyman_outlined, size: 44, color: AppColors.textSubtle),
          const SizedBox(height: 14),
          Text(
            'No services listed yet',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pull down to refresh.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(fontSize: 12.5, color: AppColors.textSubtle),
          ),
        ],
      );
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});

  final ServiceOffering service;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: () => Get.toNamed(AppRoutes.serviceDetail, arguments: service.slug),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (service.image != null && service.image!.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.card),
                ),
                child: NetImage(
                  url: service.image,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          service.name,
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      if (service.isFeatured)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                          ),
                          child: Text(
                            'Featured',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (service.description != null && service.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      service.description!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 12.5,
                        height: 1.45,
                        color: AppColors.textSubtle,
                      ),
                    ),
                  ],
                  if (service.basePrice != null && service.basePrice!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'From KES ${service.basePrice}',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
