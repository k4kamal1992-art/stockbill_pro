import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppIcons {
  static const String grocerySvg = '''<svg viewBox="0 0 40 40" fill="none">
    <path d="M8 12h24l-2 20H10L8 12z" fill="currentColor" opacity="0.9"/>
    <path d="M12 12l2-6h12l2 6" stroke="currentColor" stroke-width="2.5" fill="none"/>
    <circle cx="16" cy="28" r="2" fill="currentColor"/>
    <circle cx="24" cy="28" r="2" fill="currentColor"/>
  </svg>''';

  static const String pharmacySvg = '''<svg viewBox="0 0 40 40" fill="none">
    <rect x="10" y="6" width="20" height="28" rx="4" fill="currentColor" opacity="0.9"/>
    <path d="M18 14h4v6h6v4h-6v6h-4v-6h-6v-4h6z" fill="#007aff"/>
  </svg>''';

  static const String autoSvg = '''<svg viewBox="0 0 40 40" fill="none">
    <circle cx="20" cy="20" r="14" stroke="currentColor" stroke-width="3" fill="none"/>
    <circle cx="20" cy="20" r="6" fill="currentColor" opacity="0.9"/>
    <path d="M20 6v6M20 28v6M6 20h6M28 20h6" stroke="currentColor" stroke-width="2.5"/>
  </svg>''';

  static const String garmentsSvg = '''<svg viewBox="0 0 40 40" fill="none">
    <path d="M14 8h4l-1 4h6l-1-4h4l4 6-3 2v18H13V16l-3-2 4-6z" fill="currentColor" opacity="0.9"/>
  </svg>''';

  static const String electronicsSvg = '''<svg viewBox="0 0 40 40" fill="none">
    <rect x="10" y="4" width="20" height="32" rx="4" fill="currentColor" opacity="0.9"/>
    <rect x="13" y="8" width="14" height="22" rx="2" fill="#5ac8fa" opacity="0.3"/>
    <circle cx="20" cy="30" r="2" fill="currentColor" opacity="0.7"/>
  </svg>''';

  static const String hardwareSvg = '''<svg viewBox="0 0 40 40" fill="none">
    <rect x="8" y="14" width="24" height="10" rx="2" fill="currentColor" opacity="0.9"/>
    <path d="M12 14V10a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v4" stroke="currentColor" stroke-width="2.5" fill="none"/>
    <path d="M14 24v4a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2v-4" stroke="currentColor" stroke-width="2.5" fill="none"/>
  </svg>''';

  static const String generalSvg = '''<svg viewBox="0 0 40 40" fill="none">
    <path d="M6 16L10 8h20l4 8v14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V16z" fill="currentColor" opacity="0.9"/>
    <path d="M6 16h28" stroke="currentColor" stroke-width="2"/>
    <rect x="14" y="22" width="12" height="8" rx="1" fill="currentColor" opacity="0.3"/>
  </svg>''';

  static const String customSvg = '''<svg viewBox="0 0 40 40" fill="none">
    <circle cx="20" cy="20" r="14" fill="currentColor" opacity="0.15" stroke="currentColor" stroke-width="2"/>
    <path d="M20 10v20M10 20h20" stroke="currentColor" stroke-width="3" stroke-linecap="round"/>
    <circle cx="20" cy="20" r="4" fill="#5856d6"/>
  </svg>''';

  static String getBusinessSvg(String businessType) {
    switch (businessType) {
      case 'grocery': return grocerySvg;
      case 'pharmacy': return pharmacySvg;
      case 'automobile': return autoSvg;
      case 'garments': return garmentsSvg;
      case 'electronics': return electronicsSvg;
      case 'hardware': return hardwareSvg;
      case 'general': return generalSvg;
      case 'custom': return customSvg;
      default: return grocerySvg;
    }
  }
}

class SvgIcon extends StatelessWidget {
  final String svgString;
  final double size;
  final Color? color;
  final BoxDecoration? background;

  const SvgIcon({
    super.key,
    required this.svgString,
    this.size = 24,
    this.color,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    Widget icon = SvgPicture.string(
      svgString,
      width: size,
      height: size,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
    if (background != null) {
      return Container(
        width: size + 16,
        height: size + 16,
        decoration: background,
        child: Center(child: icon),
      );
    }
    return icon;
  }
}

class IconPill extends StatelessWidget {
  final String svgString;
  final double size;
  final Gradient gradient;
  final double radius;

  const IconPill({
    super.key,
    required this.svgString,
    this.size = 20,
    required this.gradient,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 16,
      height: size + 16,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: (gradient.colors.first as Color).withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: SvgPicture.string(
          svgString,
          width: size,
          height: size,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    );
  }
}
