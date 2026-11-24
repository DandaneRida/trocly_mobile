import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/trocly_bottom_nav.dart';
import '../../../../core/widgets/trocly_brand_header.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final AuthController _authController = Get.find<AuthController>();
  String? _errorText;

  void _submit() {
    final raw = _phoneController.text.trim().replaceAll(' ', '');
    final regex = RegExp(r'^[67]\d{8}$');
    if (!regex.hasMatch(raw)) {
      setState(() {
        _errorText = 'Entrez un numéro marocain valide (9 chiffres commençant par 6 ou 7).';
      });
      return;
    }
    setState(() => _errorText = null);
    _authController.sendOTP('+212$raw');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      bottomNavigationBar: const TroclyBottomNav(currentIndex: 4),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Get.back(),
        ),
        title: const TroclyAppBarTitle(pageTitle: 'Étape 1/3'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thin progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: const LinearProgressIndicator(
                  value: 1 / 3,
                  minHeight: 4,
                  backgroundColor: AppColors.line,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Votre numéro WhatsApp',
                style: AppTypography.serif(size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                'Nous vous envoyons un code à 6 chiffres sur WhatsApp pour vérifier votre compte.',
                style: AppTypography.sans(
                  size: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Numéro de téléphone',
                style: AppTypography.sans(
                  size: 12.5,
                  weight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.line),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '+212',
                      style: AppTypography.sans(size: 14.5, weight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        hintText: '6 12 34 56 78',
                      ),
                    ),
                  ),
                ],
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorText!,
                  style: AppTypography.sans(size: 12, color: AppColors.error, weight: FontWeight.w500),
                ),
              ],
              const Spacer(),
              Obx(
                () => PrimaryButton(
                  label: 'Recevoir le code',
                  isLoading: _authController.isLoading.value,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
