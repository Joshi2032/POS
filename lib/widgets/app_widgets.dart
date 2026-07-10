import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Envuelve un modal/panel que se agrega y quita del árbol con una condición
/// booleana (`if (showModal) ...[FadeScaleIn(child: ...)]`) en vez de con
/// `showDialog`/`Navigator`, para darle una entrada suave (fade + escala) en
/// vez de aparecer de golpe. Como el widget se vuelve a insertar en el árbol
/// cada vez que la condición pasa de false a true, la animación se reinicia
/// solita cada vez que el modal se abre.
class FadeScaleIn extends StatelessWidget {
  const FadeScaleIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 220),
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.94 + (0.06 * value),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Fondo oscuro semitransparente detrás de un modal/panel, con fade-in en
/// vez de aparecer de golpe. Mismo `onTap` que un `GestureDetector` normal
/// (`onTap` es opcional: pásalo como null si el fondo no debe cerrar nada
/// al tocarlo).
class FadeInBarrier extends StatelessWidget {
  const FadeInBarrier({
    super.key,
    this.onTap,
    this.duration = const Duration(milliseconds: 220),
  });

  final VoidCallback? onTap;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: duration,
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Container(
            color: Colors.black.withValues(alpha: 0.54 * value),
          );
        },
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: padding ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        // Consumimos el color del tema actual en vez de congelarlo en blanco estático
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.2 : 0.04,
            ),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        final titleBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.darkTextMuted
                      : AppTheme.lightTextMuted,
                ),
              ),
            ],
          ],
        );

        final actionButton = actionLabel != null && onAction != null
            ? ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(actionLabel!),
              )
            : const SizedBox.shrink();

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleBlock,
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 12),
                actionButton,
              ],
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleBlock),
            if (actionLabel != null && onAction != null) actionButton,
          ],
        );
      },
    );
  }
}
