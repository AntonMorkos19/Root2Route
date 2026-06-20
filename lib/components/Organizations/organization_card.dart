import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:root2route/features/organizations/data/models/organization_model.dart';
import 'package:root2route/features/organizations/ui/organization_details_screen.dart';
import 'package:root2route/core/utils/image_utils.dart';

class OrganizationCard extends StatelessWidget {
  final OrganizationModel organization;
  final VoidCallback? onDeleted;
  final bool isMyOrganization;

  const OrganizationCard({
    super.key,
    required this.organization,
    this.onDeleted,
    this.isMyOrganization = false,
  });

  @override
  Widget build(BuildContext context) {
    final String imageUrl = organization.logoUrl.fullImageUrl;
    final bool hasImage = imageUrl.isNotEmpty;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrganizationDetailsScreen(
              organization: organization,
              isMyOrganization: isMyOrganization,
            ),
          ),
        ).then((_) {
          if (onDeleted != null) onDeleted!();
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
             Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: const Color(0xff0F4C5C),
                shape: BoxShape.circle,
                image: hasImage
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),  
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {
                          debugPrint('Error loading image: $exception');
                        },
                      )
                    : null,
              ),
               child: !hasImage
                  ? Center(
                      child: Text(
                        organization.name.length >= 2
                            ? organization.name.substring(0, 2).toUpperCase()
                            : (organization.name.isNotEmpty
                                ? organization.name.toUpperCase()
                                : 'OR'),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20.sp,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          organization.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp,
                            color: Theme.of(context).textTheme.titleMedium?.color ?? const Color(0xff2D3748),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          organization.contactEmail ?? 'No email provided',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}