import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/theme/app_theme.dart';

class FieldsScreen extends StatelessWidget {
  const FieldsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Fields', style: AppTextStyles.h2.copyWith(color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'GIS Field Management',
              style: AppTextStyles.h3,
            ),
            SizedBox(height: 8.h),
            Text(
              'Map your fields with GPS polygons',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: 24.h),

            // Coming Soon Card
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Icon(Icons.map, size: 64.sp, color: AppColors.primary),
                  SizedBox(height: 16.h),
                  Text(
                    'Coming Soon',
                    style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Interactive GIS map with GPS field mapping, polygon drawing, and crop area calculation.',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'Features:',
                    style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12.h),
                  _buildFeatureItem('📍 GPS polygon mapping'),
                  _buildFeatureItem('🗺️ Interactive map view'),
                  _buildFeatureItem('📐 Area calculation'),
                  _buildFeatureItem('🌾 Crop management per field'),
                  _buildFeatureItem('☁️ Offline sync support'),
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
