import 'package:flutter/material.dart';

import 'app_tab_item.dart';

class AppBottomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final List<IconData> icons;
  final List<int>? badgeCounts;
  final void Function(int index) onTap;
  const AppBottomNavigationBar(
      {super.key,
      this.currentIndex = 0,
      required this.onTap,
      required this.icons,
      this.badgeCounts});

  @override
  State<AppBottomNavigationBar> createState() => _AppBottomNavigationBarState();
}

class _AppBottomNavigationBarState extends State<AppBottomNavigationBar> {
  int _currentIndex = 0;
  List<IconData> _icons = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _icons = widget.icons;
    _currentIndex = widget.currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 20, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_icons.length, (index) {
          return AppTabItem(
            icon: _icons[index],
            badgeCount: widget.badgeCounts == null ||
                    index >= widget.badgeCounts!.length
                ? 0
                : widget.badgeCounts![index],
            selected: _currentIndex == index,
            onPressed: () {
              setState(() {
                _currentIndex = index;
                widget.onTap(index);
              });
            },
          );
        }),
      ),
    );
  }
}
