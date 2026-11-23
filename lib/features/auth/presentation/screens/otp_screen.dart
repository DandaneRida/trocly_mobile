import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/trocly_bottom_nav.dart';
import '../../../../core/widgets/trocly_brand_header.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({Key? key}) : super(key: key);

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _countdown = 45;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _countdown = 45;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        if (mounted) setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  void _verify() {
    final code = _otpCode;
    if (code.length < 6) {
      _authController.errorMessage.value = 'Entrez les 6 chiffres du code.';
      return;
    }
    _authController.verifyOTP(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      bottomNavigationBar: const TroclyBottomNav(currentIndex: 4),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Get.back(),
        ),
        title: const TroclyAppBarTitle(pageTitle: 'Étape 2/3'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: const LinearProgressIndicator(
                  value: 2 / 3,
                  minHeight: 3,
                  backgroundColor: AppColors.line,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
                ),
              ),
              const SizedBox(height: 32),
              Text('Vérifiez votre numéro', style: AppTypography.serif(size: 28)),
              const SizedBox(height: 8),
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Code envoyé au ${_authController.phone.value}',
                        style: AppTypography.sans(size: 13.5, color: AppColors.textSecondary),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Text(
                        'Modifier',
                        style: AppTypography.sans(
                          size: 13,
                          weight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 46,
                    height: 54,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: AppTypography.sans(size: 20, weight: FontWeight.w600),
                      decoration: const InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (val.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        if (_otpCode.length == 6) {
                          _verify();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Obx(() {
                if (_authController.errorMessage.value.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _authController.errorMessage.value,
                    style: AppTypography.sans(
                      size: 12.5,
                      color: AppColors.error,
                      weight: FontWeight.w500,
                    ),
                  ),
                );
              }),
              Center(
                child: _countdown > 0
                    ? Text(
                        'Renvoyer dans 00:${_countdown.toString().padLeft(2, '0')}',
                        style: AppTypography.sans(size: 12.5, color: AppColors.textHint),
                      )
                    : TextButton(
                        onPressed: () {
                          _startTimer();
                          _authController.sendOTP(_authController.phone.value);
                        },
                        child: Text(
                          'Renvoyer un nouveau code',
                          style: AppTypography.sans(
                            size: 13,
                            weight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
              ),
              const Spacer(),
              Obx(
                () => PrimaryButton(
                  label: 'Valider et continuer',
                  isLoading: _authController.isLoading.value,
                  onPressed: _verify,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
