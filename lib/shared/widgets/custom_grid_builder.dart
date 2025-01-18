import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CustomGridBuilder extends StatelessWidget {
  final int gridCount;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final bool? shrinkWrap;
  final Axis? scrollDirection;
  final ScrollPhysics? physics;
  final double? mainAxisSpacing;
  final double? crossAxisSpacing;
  final bool expandedHeight;
  final bool expandedWidth;
  final bool showAllItems;

  //final CrossAxisAlignment? crossAxisAlignment;
  final MainAxisAlignment? mainAxisAlignment;

  const CustomGridBuilder(
      {super.key,
      required this.gridCount,
      required this.itemCount,
      required this.itemBuilder,
      this.shrinkWrap,
      this.scrollDirection,
      this.mainAxisAlignment,
      this.physics,
      this.mainAxisSpacing,
      this.crossAxisSpacing,
      this.expandedHeight = false,
      this.expandedWidth = false,
      this.showAllItems = false});

  @override
  Widget build(BuildContext context) {
    final gridItemCount = (itemCount / gridCount).ceil();
    if (showAllItems || expandedHeight) {
      return Column(
        children: List.generate(gridItemCount, (index) {
          return Expanded(
            flex: expandedHeight ? 1 : 0,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: index == gridItemCount - 1
                    ? 0
                    : (crossAxisSpacing == null ? 0 : crossAxisSpacing! / 2),
                top: index == 0
                    ? 0
                    : (crossAxisSpacing == null ? 0 : crossAxisSpacing! / 2),
              ),
              child: Row(
                mainAxisAlignment:
                    mainAxisAlignment ?? MainAxisAlignment.center,
                children: List.generate(gridCount, (gridIndex) {
                  final actualIndex = (index * gridCount) + gridIndex;
                  return actualIndex < itemCount
                      ? Expanded(
                          flex: expandedWidth ? 1 : 0,
                          child: Padding(
                            padding: EdgeInsets.only(
                              right:
                                  gridIndex == 0 || gridIndex == gridCount - 1
                                      ? 0
                                      : (mainAxisSpacing == null
                                          ? 0
                                          : mainAxisSpacing! / 2),
                              left: gridIndex == 0 || gridIndex == gridCount - 1
                                  ? 0
                                  : (mainAxisSpacing == null
                                      ? 0
                                      : mainAxisSpacing! / 2),
                            ),
                            child: itemBuilder(context, actualIndex),
                          ),
                        )
                      : Container();
                }),
              ),
            ),
          );
        }),
      );
    }
    return ListView.separated(
      scrollDirection: scrollDirection ?? Axis.vertical,
      shrinkWrap: shrinkWrap ?? true,
      physics: physics,
      itemCount: gridItemCount,
      itemBuilder: (context, index) {
        return Row(
          mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.center,
          children: List.generate(gridCount, (gridIndex) {
            final actualIndex = (index * gridCount) + gridIndex;
            return actualIndex < itemCount
                ? Expanded(
                    flex: expandedWidth ? 1 : 0,
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: gridIndex < gridCount
                            ? (mainAxisSpacing == null
                                ? 0
                                : mainAxisSpacing! / 2)
                            : 0,
                        left: gridIndex == 0
                            ? 0
                            : (mainAxisSpacing == null
                                ? 0
                                : mainAxisSpacing! / 2),
                      ),
                      child: itemBuilder(context, actualIndex),
                    ),
                  )
                : Container();
          }),
        );
      },
      separatorBuilder: (context, index) {
        return SizedBox(
          height: crossAxisSpacing ?? 0,
        );
      },
    );
  }
}
