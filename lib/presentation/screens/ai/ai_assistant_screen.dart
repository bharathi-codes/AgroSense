import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';

class AiAssistantScreen extends StatelessWidget {
  const AiAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Assistant', style: AppTextStyles.h2.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ask AgroSense AI', style: AppTextStyles.h3),
            SizedBox(height: 8.h),
            Text(
              'Get instant farming advice powered by Gemini AI',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Icon(Icons.smart_toy, size: 64.sp, color: AppColors.primary),
                  SizedBox(height: 16.h),
                  Text(
                    'Coming Soon',
                    style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Chat with AI assistant for personalized farming advice, pest management, and crop recommendations.',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Features:',
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12.h),
                  _buildFeatureItem('🤖 Gemini AI powered'),
                  _buildFeatureItem('💬 Natural language chat'),
                  _buildFeatureItem('🌾 Crop recommendations'),
                  _buildFeatureItem('🐛 Pest management advice'),
                  _buildFeatureItem('📊 Data-driven insights'),
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
