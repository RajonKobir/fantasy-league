import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fantasyleague/constance/constance.dart';
import 'package:fantasyleague/widgets/top_bar_clipare.dart';

class AvatarImage extends StatelessWidget {
  final double? sizeValue;
  final bool? isAssets;
  final String? imageUrl;
  final double? radius;
  final isCircle;
  final isProgressPrimaryColor;
  // Entity type controls fallback when image is missing: 'user'|'player'|'tournament'|'team'
  final String entityType;

  const AvatarImage({
    super.key,
    this.imageUrl,
    this.isProgressPrimaryColor = false,
    this.sizeValue = 10,
    this.radius = 10,
    this.isCircle = false,
    this.isAssets = false,
    this.entityType = 'user',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: sizeValue,
        height: sizeValue,
        child: ClipPath(
          clipper: isCircle
              ? TopBarClipper(
                  topLeft: true,
                  topRight: true,
                  bottomLeft: true,
                  bottomRight: true,
                  radius: radius!,
                )
              : null,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: Container(
              child: imageUrl == null || imageUrl == ''
                  ? _buildFallback(context)
                  : isAssets!
                      ? Image.asset(imageUrl!)
                      : _buildCachedNetworkImage(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCachedNetworkImage() {
    return CachedNetworkImage(
      imageUrl: imageUrl ?? '',
      placeholder: (context, url) => Center(
        child: Container(
          padding: EdgeInsets.all(sizeValue! * 0.3),
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3EB489)),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        child: _buildFallback(context),
      ),
      fit: BoxFit.cover,
    );
  }

  Widget _buildFallback(BuildContext context) {
    switch (entityType) {
      case 'player':
        // Player-specific placeholder
        return Padding(
          padding: EdgeInsets.all(sizeValue! * 0.15),
          child: Image.asset(ConstanceData.palyerProfilePic),
        );
      case 'tournament':
      case 'team':
        // Generic tournament/team placeholder
        return Padding(
          padding: EdgeInsets.all(sizeValue! * 0.15),
          child: Image.asset(ConstanceData.lineups),
        );
      case 'user':
      default:
        // Show a person icon for users with primary color background for contrast
        return CircleAvatar(
          radius: radius ?? (sizeValue! / 2),
          backgroundColor: Theme.of(context).primaryColor,
          child: Icon(
            Icons.person,
            size: sizeValue! * 0.5,
            color: Colors.white,
          ),
        );
    }
  }
}
