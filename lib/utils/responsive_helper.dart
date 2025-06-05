import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Sistema centralizado de responsividade para o Oraculum
/// Suporta todos os tamanhos populares de celulares automaticamente
class ResponsiveHelper {
  /// Obter dimensões responsivas baseadas no tamanho da tela
  static ResponsiveDimensions getDimensions(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    // Calcular categoria do dispositivo
    final category = _getDeviceCategory(width, height);

    return ResponsiveDimensions(
      screenWidth: width,
      screenHeight: height,
      category: category,

      // Paddings adaptáveis
      screenPadding: _getScreenPadding(category),
      cardPadding: _getCardPadding(category),
      sectionSpacing: _getSectionSpacing(category),
      itemSpacing: _getItemSpacing(category),

      // Tamanhos de fonte adaptáveis
      titleSize: _getTitleSize(category),
      subtitleSize: _getSubtitleSize(category),
      bodySize: _getBodySize(category),
      captionSize: _getCaptionSize(category),
      buttonSize: _getButtonSize(category),

      // Tamanhos de elementos
      iconSize: _getIconSize(category),
      avatarSize: _getAvatarSize(category),
      buttonHeight: _getButtonHeight(category),
      appBarHeight: _getAppBarHeight(category),

      // Grid e listas
      gridCrossAxisCount: _getGridCrossAxisCount(category, width),
      gridAspectRatio: _getGridAspectRatio(category),
      listItemHeight: _getListItemHeight(category),

      // Helpers booleanos
      isSmallScreen: category == DeviceCategory.small,
      isMediumScreen: category == DeviceCategory.medium,
      isLargeScreen: category == DeviceCategory.large,
      isTablet: category == DeviceCategory.tablet,
    );
  }

  /// Determinar categoria do dispositivo
  static DeviceCategory _getDeviceCategory(double width, double height) {
    if (width >= 768) return DeviceCategory.tablet;
    if (width >= 414) return DeviceCategory.large;
    if (width >= 375) return DeviceCategory.medium;
    return DeviceCategory.small;
  }

  // Métodos privados para calcular dimensões específicas
  static double _getScreenPadding(DeviceCategory category) {
    switch (category) {
      case DeviceCategory.small: return 12.0;
      case DeviceCategory.medium: return 16.0;
      case DeviceCategory.large: return 20.0;
      case DeviceCategory.tablet: return 24.0;
    }
  }

  static double _getCardPadding(DeviceCategory category) {
    switch (category) {
      case DeviceCategory.small: return 16.0;
      case DeviceCategory.medium: return 20.0;
      case DeviceCategory.large: return 24.0;
      case DeviceCategory.tablet: return 28.0;
    }
  }

  static double _getSectionSpacing(DeviceCategory category) {
    switch (category) {
      case DeviceCategory.small: return 16.0;
      case DeviceCategory.medium: return 20.0;
      case DeviceCategory.large: return 24.0;
      case DeviceCategory.tablet: return 32.0;
    }
  }

  static double _getItemSpacing(DeviceCategory category) {
    switch (category) {
      case DeviceCategory.small: return 8.0;
      case DeviceCategory.medium: return 12.0;
      case DeviceCategory.large: return 16.0;
      case DeviceCategory.tablet: return 20.0;
    }
  }

  static double _getTitleSize(DeviceCategory category) {
    switch (category) {
      case DeviceCategory.small: return 20.0;
      case DeviceCategory.medium: return 24.0;
      case DeviceCategory.large: return 28.0;
      case DeviceCategory.tablet: return 32.0;
    }
  }

  static double _getSubtitleSize(DeviceCategory category) {
    switch (category) {
      case DeviceCategory.small: return 16.0;
      case DeviceCategory.medium: return 18.0;
      case DeviceCategory.large: return 20.0;
      case DeviceCategory.tablet: return 22.0;
    }
  }

  static double _getBodySize(DeviceCategory category) {
    switch (category) {
      case DeviceCategory.small: return 14.0;
      case DeviceCategory.medium: return 15.0;
      case DeviceCategory.large: return 16.0;
      case DeviceCategory.tablet: return 17.0;
    }
  }

  static double _getCaptionSize(DeviceCategory category) {
    switch (category) {
      case DeviceCategory.small: return 12.0;
      case DeviceCategory.medium: return 13.0;
      case DeviceCategory.large: return 14.0;
      case DeviceCategory.tablet: return 15.0;
    }
  }

  static double _getButtonSize(DeviceCategory category) {
    switch (category) {
      case DeviceCategory.small: return 14.0;
      case DeviceCategory.medium: return 16.0;
      case DeviceCategory.large: return 18.0;
      case DeviceCategory.tablet: return 20.0;
    }
  }

  static double _getIconSize(DeviceCategory category) {
    switch (category) {
      case DeviceCategory.small: return 20.0;
      case DeviceCategory.medium: return 24.0;
      case DeviceCategory.large: return 28.0;
      case DeviceCategory.tablet: return 32.0;
    }
  }

  static double _getAvatarSize(DeviceCategory category) {
    switch (category) {
      case DeviceCategory.small: return 50.0;
      case DeviceCategory.medium: return 60.0;
      case DeviceCategory.large: return 70.0;
      case DeviceCategory.tablet: return 80.0;
    }
  }

  static double _getButtonHeight(DeviceCategory category) {
    switch (category) {
      case DeviceCategory.small: return 44.0;
      case DeviceCategory.medium: return 48.0;
      case DeviceCategory.large: return 52.0;
      case DeviceCategory.tablet: return 56.0;
    }
  }

  static double _getAppBarHeight(DeviceCategory category) {
    switch (category) {
      case DeviceCategory.small: return 56.0;
      case DeviceCategory.medium: return 60.0;
      case DeviceCategory.large: return 64.0;
      case DeviceCategory.tablet: return 68.0;
    }
  }

  static int _getGridCrossAxisCount(DeviceCategory category, double width) {
    if (category == DeviceCategory.tablet) {
      return width > 1000 ? 4 : 3;
    }
    return 2;
  }

  static double _getGridAspectRatio(DeviceCategory category) {
    switch (category) {
      case DeviceCategory.small: return 1.4;
      case DeviceCategory.medium: return 1.6;
      case DeviceCategory.large: return 1.8;
      case DeviceCategory.tablet: return 2.0;
    }
  }

  static double _getListItemHeight(DeviceCategory category) {
    switch (category) {
      case DeviceCategory.small: return 70.0;
      case DeviceCategory.medium: return 80.0;
      case DeviceCategory.large: return 90.0;
      case DeviceCategory.tablet: return 100.0;
    }
  }
}

/// Extensão para facilitar o uso do ResponsiveHelper
extension ResponsiveContext on BuildContext {
  ResponsiveDimensions get responsive => ResponsiveHelper.getDimensions(this);
}

/// Extensão para GetX
extension ResponsiveGetX on GetInterface {
  ResponsiveDimensions get responsive => ResponsiveHelper.getDimensions(Get.context!);
}

/// Categorias de dispositivos suportados
enum DeviceCategory {
  small,    // < 375px (iPhone SE, Android pequenos)
  medium,   // 375px - 413px (iPhone padrão, maioria Android)
  large,    // 414px - 767px (iPhone Plus/Pro Max, Android grandes)
  tablet,   // >= 768px (iPads, tablets Android)
}

/// Classe que contém todas as dimensões responsivas
class ResponsiveDimensions {
  // Dimensões da tela
  final double screenWidth;
  final double screenHeight;
  final DeviceCategory category;

  // Espaçamentos
  final double screenPadding;
  final double cardPadding;
  final double sectionSpacing;
  final double itemSpacing;

  // Tamanhos de fonte
  final double titleSize;
  final double subtitleSize;
  final double bodySize;
  final double captionSize;
  final double buttonSize;

  // Tamanhos de elementos
  final double iconSize;
  final double avatarSize;
  final double buttonHeight;
  final double appBarHeight;

  // Grid e listas
  final int gridCrossAxisCount;
  final double gridAspectRatio;
  final double listItemHeight;

  // Helpers
  final bool isSmallScreen;
  final bool isMediumScreen;
  final bool isLargeScreen;
  final bool isTablet;

  const ResponsiveDimensions({
    required this.screenWidth,
    required this.screenHeight,
    required this.category,
    required this.screenPadding,
    required this.cardPadding,
    required this.sectionSpacing,
    required this.itemSpacing,
    required this.titleSize,
    required this.subtitleSize,
    required this.bodySize,
    required this.captionSize,
    required this.buttonSize,
    required this.iconSize,
    required this.avatarSize,
    required this.buttonHeight,
    required this.appBarHeight,
    required this.gridCrossAxisCount,
    required this.gridAspectRatio,
    required this.listItemHeight,
    required this.isSmallScreen,
    required this.isMediumScreen,
    required this.isLargeScreen,
    required this.isTablet,
  });

  @override
  String toString() {
    return 'ResponsiveDimensions(${category.name}: ${screenWidth.toInt()}x${screenHeight.toInt()})';
  }
}

/// Widget helper para aplicar responsividade facilmente
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveDimensions responsive) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, context.responsive);
  }
}

/// Widget para espaçamentos responsivos
class ResponsiveSpacing {
  static Widget vertical(BuildContext context, {double? multiplier}) {
    final responsive = context.responsive;
    return SizedBox(height: responsive.sectionSpacing * (multiplier ?? 1.0));
  }

  static Widget horizontal(BuildContext context, {double? multiplier}) {
    final responsive = context.responsive;
    return SizedBox(width: responsive.itemSpacing * (multiplier ?? 1.0));
  }

  static EdgeInsets screen(BuildContext context) {
    final responsive = context.responsive;
    return EdgeInsets.all(responsive.screenPadding);
  }

  static EdgeInsets card(BuildContext context) {
    final responsive = context.responsive;
    return EdgeInsets.all(responsive.cardPadding);
  }

  static EdgeInsets symmetric(BuildContext context, {bool horizontal = true, bool vertical = false}) {
    final responsive = context.responsive;
    return EdgeInsets.symmetric(
      horizontal: horizontal ? responsive.screenPadding : 0,
      vertical: vertical ? responsive.sectionSpacing : 0,
    );
  }
}

/// Estilos de texto responsivos
class ResponsiveText {
  static TextStyle title(BuildContext context, {Color? color, FontWeight? fontWeight}) {
    final responsive = context.responsive;
    return TextStyle(
      fontSize: responsive.titleSize,
      fontWeight: fontWeight ?? FontWeight.bold,
      color: color,
    );
  }

  static TextStyle subtitle(BuildContext context, {Color? color, FontWeight? fontWeight}) {
    final responsive = context.responsive;
    return TextStyle(
      fontSize: responsive.subtitleSize,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color,
    );
  }

  static TextStyle body(BuildContext context, {Color? color, FontWeight? fontWeight}) {
    final responsive = context.responsive;
    return TextStyle(
      fontSize: responsive.bodySize,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color,
    );
  }

  static TextStyle caption(BuildContext context, {Color? color, FontWeight? fontWeight}) {
    final responsive = context.responsive;
    return TextStyle(
      fontSize: responsive.captionSize,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color,
    );
  }

  static TextStyle button(BuildContext context, {Color? color, FontWeight? fontWeight}) {
    final responsive = context.responsive;
    return TextStyle(
      fontSize: responsive.buttonSize,
      fontWeight: fontWeight ?? FontWeight.w600,
      color: color,
    );
  }
}

/// Componentes responsivos prontos
class ResponsiveComponents {
  /// AppBar responsiva
  static PreferredSizeWidget appBar(
      BuildContext context, {
        required String title,
        List<Widget>? actions,
        Widget? leading,
        bool centerTitle = true,
      }) {
    final responsive = context.responsive;

    return AppBar(
      title: Text(
        title,
        style: ResponsiveText.subtitle(context, color: Colors.white),
      ),
      centerTitle: centerTitle,
      leading: leading,
      actions: actions,
      toolbarHeight: responsive.appBarHeight,
    );
  }

  /// Botão responsivo
  static Widget button(
      BuildContext context, {
        required String text,
        required VoidCallback? onPressed,
        bool isLoading = false,
        Color? backgroundColor,
        Color? textColor,
        IconData? icon,
      }) {
    final responsive = context.responsive;

    return SizedBox(
      height: responsive.buttonHeight,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? SizedBox(
          height: responsive.iconSize * 0.7,
          width: responsive.iconSize * 0.7,
          child: const CircularProgressIndicator(strokeWidth: 2),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: responsive.iconSize * 0.8),
              SizedBox(width: responsive.itemSpacing * 0.5),
            ],
            Text(
              text,
              style: ResponsiveText.button(context, color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  /// Card responsivo
  static Widget card(
      BuildContext context, {
        required Widget child,
        Color? color,
        double? elevation,
        EdgeInsets? margin,
      }) {
    final responsive = context.responsive;

    return Card(
      color: color,
      elevation: elevation ?? (responsive.isTablet ? 6 : 4),
      margin: margin ?? EdgeInsets.symmetric(vertical: responsive.itemSpacing * 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(responsive.isTablet ? 20 : 16),
      ),
      child: Padding(
        padding: ResponsiveSpacing.card(context),
        child: child,
      ),
    );
  }

  /// Avatar responsivo
  static Widget avatar(
      BuildContext context, {
        String? imageUrl,
        IconData? icon,
        Color? backgroundColor,
        Color? iconColor,
        double? size,
      }) {
    final responsive = context.responsive;
    final avatarSize = size ?? responsive.avatarSize;

    return CircleAvatar(
      radius: avatarSize / 2,
      backgroundColor: backgroundColor,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
      child: imageUrl == null && icon != null
          ? Icon(
        icon,
        size: avatarSize * 0.6,
        color: iconColor,
      )
          : null,
    );
  }

  /// Grid responsivo
  static Widget grid(
      BuildContext context, {
        required List<Widget> children,
        double? childAspectRatio,
        double? spacing,
      }) {
    final responsive = context.responsive;

    return GridView.count(
      crossAxisCount: responsive.gridCrossAxisCount,
      childAspectRatio: childAspectRatio ?? responsive.gridAspectRatio,
      crossAxisSpacing: spacing ?? responsive.itemSpacing,
      mainAxisSpacing: spacing ?? responsive.itemSpacing,
      children: children,
    );
  }
}