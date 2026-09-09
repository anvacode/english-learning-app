import 'package:flutter/material.dart';
import '../utils/responsive.dart';

/// Contenedor responsive que limita el ancho máximo en desktop
/// y centra el contenido horizontalmente.
/// 
/// Útil para envolver el contenido de pantallas principales
/// y asegurar que no se vea excesivamente ancho en pantallas grandes.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final bool addHorizontalPadding;
  final double? maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.addHorizontalPadding = true,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    // Aplicar maxWidth si se especifica
    if (maxWidth != null) {
      content = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth!),
          child: content,
        ),
      );
    }

    // Agregar padding horizontal responsive si está habilitado
    if (addHorizontalPadding) {
      content = Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.horizontalPadding(context),
        ),
        child: content,
      );
    }

    // Aplicar padding adicional si se especifica
    if (padding != null) {
      content = Padding(
        padding: padding!,
        child: content,
      );
    }

    // Aplicar color de fondo si se especifica
    if (backgroundColor != null) {
      content = Container(
        color: backgroundColor,
        child: content,
      );
    }

    return content;
  }
}

/// Scaffold responsive que envuelve el body con ResponsiveContainer
class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Color? backgroundColor;
  final bool addHorizontalPadding;
  final double? maxWidth;

  const ResponsiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
    this.backgroundColor,
    this.addHorizontalPadding = true,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: ResponsiveContainer(
        addHorizontalPadding: addHorizontalPadding,
        maxWidth: maxWidth,
        child: body,
      ),
    );
  }
}

/// Grid responsive que ajusta el número de columnas según el dispositivo
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double? childAspectRatio;
  final double? mainAxisSpacing;
  final double? crossAxisSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.childAspectRatio,
    this.mainAxisSpacing,
    this.crossAxisSpacing,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
  });

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.gridColumns(
      context,
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
    );

    final spacing = crossAxisSpacing ?? Responsive.gridSpacing(context);
    final mainSpacing = mainAxisSpacing ?? spacing;

    return GridView.count(
      crossAxisCount: columns,
      childAspectRatio: childAspectRatio ?? Responsive.cardAspectRatio(context),
      crossAxisSpacing: spacing,
      mainAxisSpacing: mainSpacing,
      children: children,
    );
  }
}

/// SliverGrid responsive
class ResponsiveSliverGrid extends StatelessWidget {
  final List<Widget> children;
  final double? childAspectRatio;
  final double? mainAxisSpacing;
  final double? crossAxisSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  const ResponsiveSliverGrid({
    super.key,
    required this.children,
    this.childAspectRatio,
    this.mainAxisSpacing,
    this.crossAxisSpacing,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
  });

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.gridColumns(
      context,
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
    );

    final spacing = crossAxisSpacing ?? Responsive.gridSpacing(context);
    final mainSpacing = mainAxisSpacing ?? spacing;

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: childAspectRatio ?? Responsive.cardAspectRatio(context),
        crossAxisSpacing: spacing,
        mainAxisSpacing: mainSpacing,
      ),
      delegate: SliverChildListDelegate(children),
    );
  }
}

/// Widget que agrega efectos hover en desktop/web
class HoverableWidget extends StatefulWidget {
  final Widget child;
  final Widget Function(bool isHovered)? builder;
  final VoidCallback? onTap;
  final double hoverElevation;
  final double normalElevation;

  const HoverableWidget({
    super.key,
    required this.child,
    this.builder,
    this.onTap,
    this.hoverElevation = 8,
    this.normalElevation = 2,
  });

  @override
  State<HoverableWidget> createState() => _HoverableWidgetState();
}

class _HoverableWidgetState extends State<HoverableWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hasHover = Responsive.hasHover(context);

    Widget content = widget.builder != null 
        ? widget.builder!(_isHovered && hasHover)
        : widget.child;

    if (!hasHover) {
      // En móvil, solo usar tap sin efectos hover
      if (widget.onTap != null) {
        return GestureDetector(
          onTap: widget.onTap,
          child: content,
        );
      }
      return content;
    }

    // En desktop/web, agregar efectos hover
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: content,
        ),
      ),
    );
  }
}
