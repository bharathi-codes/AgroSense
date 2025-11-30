import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';

class SchemesScreen extends StatelessWidget {
  const SchemesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Government Schemes', style: AppTextStyles.h2.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Agricultural Schemes', style: AppTextStyles.h3),
            SizedBox(height: 8.h),
            Text(
              'Explore government benefits and subsidies for farmers',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.secondary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Icon(Icons.account_balance, size: 64.sp, color: AppColors.secondary),
                  SizedBox(height: 16.h),
                  Text(
                    'Coming Soon',
                    style: AppTextStyles.h3.copyWith(color: AppColors.secondary),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Browse government schemes, check eligibility, and apply directly from the app.',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Features:',
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12.h),
                  _buildFeatureItem('🏛️ Central & State schemes'),
                  _buildFeatureItem('✅ Eligibility checker'),
                  _buildFeatureItem('📋 Application tracking'),
                  _buildFeatureItem('🔔 New scheme alerts'),
                  _buildFeatureItem('📄 Document requirements'),
                  _buildFeatureItem('🌐 Multilingual support'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          SizedBox(width: 8.w),
          Text(text, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
