import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class SettingsLoadingSkeleton extends StatelessWidget {
  const SettingsLoadingSkeleton({super.key});

  Widget _skeletonBox({
    required double width,
    required double height,
    double? radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(radius ?? 8),
      ),
    );
  }

  Widget _buildSectionSkeleton(BuildContext context) {
    final spacing = ResponsiveHelper.spacing(context);
    final cardPadding = ResponsiveHelper.cardPadding(context);

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.sectionSpacing(context)),
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.useCompactLayout(context) ? 14 : 16,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _skeletonBox(
                width: ResponsiveHelper.useCompactLayout(context) ? 40 : 44,
                height: ResponsiveHelper.useCompactLayout(context) ? 40 : 44,
                radius: ResponsiveHelper.useCompactLayout(context) ? 10 : 12,
              ),

              SizedBox(width: spacing),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _skeletonBox(
                      width: ResponsiveHelper.isMobile(context) ? 145 : 180,
                      height: ResponsiveHelper.isMobile(context) ? 15 : 17,
                      radius: 6,
                    ),

                    SizedBox(height: spacing * 0.55),

                    _skeletonBox(
                      width: ResponsiveHelper.isMobile(context) ? 210 : 280,
                      height: ResponsiveHelper.isMobile(context) ? 11 : 13,
                      radius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: ResponsiveHelper.sectionSpacing(context) * 0.7),

          _skeletonBox(
            width: double.infinity,
            height: ResponsiveHelper.isMobile(context) ? 50 : 54,
            radius: 12,
          ),

          SizedBox(height: spacing),

          _skeletonBox(
            width: double.infinity,
            height: ResponsiveHelper.isMobile(context) ? 50 : 54,
            radius: 12,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSkeleton(BuildContext context) {
    final spacing = ResponsiveHelper.spacing(context);
    final cardPadding = ResponsiveHelper.cardPadding(context);

    final avatarSize = ResponsiveHelper.isMobile(context) ? 58.0 : 68.0;

    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.sectionSpacing(context)),
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.useCompactLayout(context) ? 16 : 18,
        ),
      ),
      child: Row(
        children: [
          _skeletonBox(
            width: avatarSize,
            height: avatarSize,
            radius: avatarSize / 2,
          ),

          SizedBox(
            width: ResponsiveHelper.isMobile(context)
                ? spacing
                : spacing * 1.25,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _skeletonBox(
                  width: ResponsiveHelper.isMobile(context) ? 160 : 200,
                  height: ResponsiveHelper.isMobile(context) ? 17 : 20,
                  radius: 6,
                ),

                SizedBox(height: spacing * 0.6),

                _skeletonBox(
                  width: ResponsiveHelper.isMobile(context) ? 210 : 300,
                  height: ResponsiveHelper.isMobile(context) ? 12 : 14,
                  radius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final contentMaxWidth = ResponsiveHelper.contentMaxWidth(context);

    final topSpacing = ResponsiveHelper.sectionSpacing(context);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topSpacing,
        horizontalPadding,
        topSpacing,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileSkeleton(context),

              _buildSectionSkeleton(context),

              _buildSectionSkeleton(context),

              _buildSectionSkeleton(context),

              _buildSectionSkeleton(context),

              _buildSectionSkeleton(context),

              _buildSectionSkeleton(context),

              _buildSectionSkeleton(context),

              _buildSectionSkeleton(context),

              _buildSectionSkeleton(context),
            ],
          ),
        ),
      ),
    );
  }
}
