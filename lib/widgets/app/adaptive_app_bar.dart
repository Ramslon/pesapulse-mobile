import 'package:flutter/material.dart';

class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool centerTitle;

  const AdaptiveAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return AppBar(
      toolbarHeight: isLandscape ? 24 : 34,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,

      title:
          titleWidget ??
          (title == null
              ? null
              : Text(
                  title!,
                  style: TextStyle(
                    fontSize: isLandscape ? 14 : 17,
                    fontWeight: FontWeight.bold,
                  ),
                )),

      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(34);
}
