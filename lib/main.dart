import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';

void main() {
  runApp(const TroclyApp());
}

class TroclyApp extends StatelessWidget {
  const TroclyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trocly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeCheckPage(),
    );
  }
}

/// Écran temporaire pour vérifier que le projet démarre
class HomeCheckPage extends StatelessWidget {
  const HomeCheckPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trocly'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz, size: 72, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Trocly',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Échangez sans argent',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Ça marche'),
            ),
          ],
        ),
      ),
    );
  }
}