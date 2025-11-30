import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';

class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Farm Diary', style: AppTextStyles.h2.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Farm Diary', style: AppTextStyles.h3),
            SizedBox(height: 8.h),
            Text(
              'Record daily activities, observations, and expenses',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.warning.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Icon(Icons.book, size: 64.sp, color: AppColors.warning),
                  SizedBox(height: 16.h),
                  Text(
                    'Coming Soon',
                    style: AppTextStyles.h3.copyWith(color: AppColors.warning),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Digital diary to track farming activities, crop observations, expenses, and harvest records.',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Features:',
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12.h),
                  _buildFeatureItem('📝 Daily activity logs'),
                  _buildFeatureItem('📷 Photo attachments'),
                  _buildFeatureItem('💰 Expense tracking'),
                  _buildFeatureItem('🌾 Crop observations'),
                  _buildFeatureItem('📅 Calendar view'),
                  _buildFeatureItem('☁️ Cloud backup'),
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
