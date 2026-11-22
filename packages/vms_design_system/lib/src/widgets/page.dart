import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

class Crumb {
  const Crumb(this.label, {this.onTap});
  final String label;
  final VoidCallback? onTap;
}

/// Standard page frame inside the shell: 56 px breadcrumb bar, then a
/// scrollable, width-capped column with the page header and body.
class VmsPage extends StatelessWidget {
  const VmsPage({
    super.key,
    required this.crumbs,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions = const [],
    this.below,
    this.maxWidth = VmsSize.contentList,
    this.scrollController,
  });

  final List<Crumb> crumbs;
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  /// Extra content under the title (e.g. keyboard hints).
  final Widget? below;
  final Widget body;
  final double maxWidth;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Breadcrumbs(crumbs: crumbs),
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.symmetric(
              horizontal: narrow ? VmsSpace.s4 : VmsSpace.s6,
              vertical: narrow ? VmsSpace.s5 : VmsSpace.s6,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PageHeader(title: title, subtitle: subtitle, actions: actions),
                    if (below != null) below!,
                    const SizedBox(height: VmsSpace.s5),
                    body,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Breadcrumbs extends StatelessWidget {
  const _Breadcrumbs({required this.crumbs});

  final List<Crumb> crumbs;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < crumbs.length; i++) {
      final c = crumbs[i];
      final last = i == crumbs.length - 1;
      if (i > 0) {
        children.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Text('›', style: TextStyle(fontSize: 14, color: VmsColors.textMeta)),
        ));
      }
      final text = Text(
        c.label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          fontWeight: last ? FontWeight.w600 : FontWeight.w500,
          color: last ? VmsColors.text : VmsColors.primaryAccessible,
        ),
      );
      children.add(c.onTap != null && !last
          ? InkWell(onTap: c.onTap, borderRadius: BorderRadius.circular(6), child: text)
          : Flexible(child: Semantics(header: last, child: text)));
    }
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: VmsSpace.s6),
      decoration: const BoxDecoration(
        color: VmsColors.surface,
        border: Border(bottom: BorderSide(color: VmsColors.borderCard)),
      ),
      child: Semantics(
        label: 'Breadcrumb',
        container: true,
        child: Row(children: children),
      ),
    );
  }
}

/// Large title + one-line subtitle left, actions right (secondary then primary).
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.actions = const []});

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: VmsSpace.s4,
      runSpacing: VmsSpace.s4,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(header: true, child: Text(title, style: VmsText.title)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: const TextStyle(fontSize: 15, color: VmsColors.textMeta)),
            ],
          ],
        ),
        if (actions.isNotEmpty)
          Wrap(spacing: VmsSpace.s3, runSpacing: VmsSpace.s3, children: actions),
      ],
    );
  }
}

/// White card with a hairline border and no shadow.
class VmsCard extends StatelessWidget {
  const VmsCard({super.key, required this.child, this.padding = EdgeInsets.zero, this.title, this.trailing});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: VmsColors.surface,
        border: Border.all(color: VmsColors.borderCard),
        borderRadius: BorderRadius.circular(VmsRadius.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
              child: Row(
                children: [
                  Expanded(child: Semantics(header: true, child: Text(title!, style: VmsText.h2))),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
