import 'package:flutter/material.dart';
import 'package:gamesarena/shared/utils/utils.dart';

class CustomGrid extends StatelessWidget {
  final List items;
  final int gridSize;
  final double? width;
  final double? height;
  final Axis axis;
  final Alignment alignment;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final Widget Function(int index) itemBuilder;
  const CustomGrid({
    super.key,
    required this.items,
    required this.gridSize,
    this.width,
    this.height,
    this.axis = Axis.vertical,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    required this.itemBuilder,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: alignment,
      child: items.isEmpty
          ? null
          : ColumnOrRow(
              column: axis == Axis.vertical,
              mainAxisAlignment: mainAxisAlignment,
              crossAxisAlignment: crossAxisAlignment,
              children:
                  List.generate((items.length / gridSize).ceil(), (colindex) {
                final colSize = (items.length / gridSize).ceil();
                final remainder = items.length % gridSize;
                return ColumnOrRow(
                  mainAxisSize: MainAxisSize.min,
                  //mainAxisAlignment: mainAxisAlignment,
                  column: axis != Axis.vertical,
                  children: List.generate(
                      colindex == colSize - 1 && remainder > 0
                          ? remainder
                          : gridSize,
                      (rowindex) => itemBuilder(
                          convertToPosition([rowindex, colindex], gridSize))),
                );
              }),
            ),
    );
  }
}

class ColumnOrRow extends StatelessWidget {
  final bool column;
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  const ColumnOrRow({
    super.key,
    required this.column,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
  });

  @override
  Widget build(BuildContext context) {
    return column
        ? Column(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: mainAxisSize,
            children: children,
          )
        : Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            mainAxisSize: mainAxisSize,
            children: children,
          );
  }
}
