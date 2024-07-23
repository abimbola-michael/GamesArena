// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:gamesarena/shared/views/error_or_success_view.dart';
import 'package:gamesarena/shared/views/loading_view.dart';

enum ListAction { addBottom, addTop, insert, remove, modify, replace }

class ListValue<T> {
  T value;
  int? index;
  ListValue({
    required this.value,
    this.index,
  });
}

class ListResult<T> {
  ListAction action;
  List<T> list;
  List<ListValue>? listValues;
  ListResult({
    this.action = ListAction.addBottom,
    this.listValues,
    required this.list,
  });
}

class ListResponse<T> {
  int? totalCount;
  int? itemCount;
  int? page;
  int? start;
  int? end;
  List<T> list;
  ListResponse({
    this.totalCount,
    this.itemCount,
    this.page,
    this.start,
    this.end,
    required this.list,
  });
}

class AsyncListView<T> extends StatefulWidget {
  final Future<List<T>> Function(
      List<T> list, int? start, int? end, int? page, bool isEnd)? onLoadLess;
  final Future<List<T>> Function(
      List<T> list, int? start, int? end, int? page, bool isEnd)? onLoadMore;
  final Future<ListResponse<T>> Function(
      StreamController<ListResult<T>> listController) onLoadInitial;

  final Stream<ListResult<T>> Function()? onLoadInitialStream;
  final Future<int> Function()? onGetItemCount;
  final void Function(StreamController<ListResult> listController)?
      onGetListController;
  final String Function()? onGetEmptyMessage;
  final Axis? scrollDirection;
  final bool? reverse;
  final ScrollController? controller;

  final bool? primary;
  final ScrollPhysics? physics;
  final bool? shrinkWrap;
  final EdgeInsets? padding;
  final Widget? Function(BuildContext context, List<T> list, int index)
      itemBuilder;
  final IndexedWidgetBuilder? separatorBuilder;
  final Widget Function(String message)? errorBuilder;
  final WidgetBuilder? emptyBuilder;
  final WidgetBuilder? loadingBuilder;
  final SliverGridDelegate? gridDelegate;
  final bool useFullScreenBuilder;
  final double? builderHeight;

  final PageController? pageController;
  final bool isPageView;
  final void Function(int)? onPageChanged;

  const AsyncListView(
      {super.key,
      this.isPageView = false,
      this.pageController,
      this.onPageChanged,
      required this.onLoadInitial,
      this.onLoadInitialStream,
      this.onLoadMore,
      this.onLoadLess,
      this.onGetItemCount,
      this.onGetEmptyMessage,
      this.onGetListController,
      this.gridDelegate,
      this.scrollDirection,
      this.reverse,
      this.controller,
      this.primary,
      this.physics,
      this.shrinkWrap,
      this.padding,
      required this.itemBuilder,
      this.errorBuilder,
      this.emptyBuilder,
      this.loadingBuilder,
      this.separatorBuilder,
      this.useFullScreenBuilder = false,
      this.builderHeight});

  @override
  State<AsyncListView> createState() => _AsyncListViewState<T>();
}

class _AsyncListViewState<T> extends State<AsyncListView> {
  final StreamController<ListResult<T>> listController = StreamController();
  StreamSubscription? listSub;

  String? errorMessage;
  bool loading = true;

  final List<T> list = [];

  int? totalCount;
  int? itemCount;
  int? start;
  int? end;
  int? page;
  bool hasReachedTop = false;
  bool hasReachedBottom = false;

  @override
  void initState() {
    super.initState();
    getInitalList();
    getTotalListCount();
    widget.onGetListController?.call(listController);
    listController.stream.listen((result) {
      updateListResult(result);
    });
  }

  @override
  void dispose() {
    listController.close();
    listSub?.cancel();
    super.dispose();
  }

  void increaseItemCount(ListResult<T> result) {
    if (totalCount != null) {
      totalCount = totalCount! + result.list.length;
    }
  }

  void decreaseItemCount(ListResult<T> result) {
    if (totalCount != null) {
      totalCount = totalCount! - result.list.length;
    }
  }

  void updateListResult(ListResult<T> result) {
    if (result.action == ListAction.addBottom ||
        result.action == ListAction.addTop ||
        result.action == ListAction.insert) {
      increaseItemCount(result);
    } else if (result.action == ListAction.remove) {
      decreaseItemCount(result);
    } else if (result.action == ListAction.replace) {
      if (totalCount != null) {
        totalCount = result.list.length;
      }
    }
    switch (result.action) {
      case ListAction.addBottom:
        getMoreList(result.list);
        break;
      case ListAction.addTop:
        getLessList(result.list);
        break;
      case ListAction.insert:
      case ListAction.remove:
      case ListAction.modify:
        updateListActionToList(result);
        break;
      case ListAction.replace:
        list.clear();
        setState(() {});
        list.addAll(result.list);
        setState(() {});
        break;
    }
  }

  void updateListActionToList(ListResult<T> result) {
    if (result.listValues == null) return;
    if (result.listValues!.isNotEmpty &&
        result.listValues!.length == result.list.length) {
      for (int i = 0; i < result.list.length; i++) {
        //final value = result.list[i];
        final listValue = result.listValues![i];
        if (result.action == ListAction.insert) {
          list.insert(listValue.index ?? list.length, listValue.value);
        } else if (result.action == ListAction.remove) {
          if (listValue.index != null) {
            list.removeAt(listValue.index!);
          } else {
            list.remove(listValue.value);
          }
        } else if (result.action == ListAction.modify) {
          if (listValue.index != null) {
            list[listValue.index!] = listValue.value;
          }
        }
      }
    }
  }

  List<int?> getPageInfos(int? page, int? totalCount, int? itemCount) {
    if (page == null || totalCount == null || itemCount == null) {
      return [null, null];
    }
    if (page <= 0) return [0, 0];
    int totalPages = (totalCount / itemCount).ceil();
    if (page > 0) {
      page = totalPages;
    }

    int start = ((page - 1) * itemCount);
    int end = start + itemCount - 1;
    if (end > totalCount - 1) {
      end = totalCount - 1;
    }
    return [start, end];
  }

  List<int?> getMoreInfos(
      int? end, int? page, int? totalCount, int? itemCount) {
    if (end == null || totalCount == null || itemCount == null) {
      return [null, null, null];
    }

    if (end <= 0 || end >= totalCount - 1) return [0, 0];
    int start = end + 1;
    end = start + itemCount - 1;
    if (end > totalCount - 1) {
      end = totalCount - 1;
    }
    return [start, end, page != null ? page + 1 : null];
  }

  List<int?> getLessInfos(
      int? start, int? page, int? totalCount, int? itemCount) {
    if (start == null || totalCount == null || itemCount == null) {
      return [null, null, null];
    }
    if (start <= 0 || start >= totalCount - 1) return [0, 0];

    int end = start - 1;
    start = end - itemCount + 1;
    if (start < 0) {
      start = 0;
    }
    return [start, end, page != null ? page - 1 : null];
  }

  void getTotalListCount() async {
    if (widget.onGetItemCount == null) return;
    try {
      totalCount = await widget.onGetItemCount!();
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      setState(() {});
    }
  }

  void getInitalList() async {
    try {
      final future = widget.onLoadInitial(listController);
      loading = true;
      final response = await future;
      final values = response.list;
      totalCount = response.totalCount;
      itemCount = response.itemCount;
      page = response.page;
      start = response.start;
      end = response.end;

      if (page != null && (start == null || end == null)) {
        final positions = getPageInfos(page, totalCount, itemCount);
        start = positions[0];
        end = positions[1];
      }
      hasReachedTop = start == 0;
      hasReachedBottom = itemCount != null && end == itemCount! - 1;

      loading = false;
      for (int i = 0; i < values.length; i++) {
        final value = values[i];
        list.add(value);
      }
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      setState(() {});
    }

    if (widget.onLoadInitialStream != null) {
      final Stream stream = widget.onLoadInitialStream!();
      listSub = stream.listen((result) {
        updateListResult(result);
        errorMessage = null;
      }, onDone: () {
        setState(() {});
      }, onError: (e) {
        errorMessage = e.toString();
      });
    }
  }

  void getMoreList([List<T>? newList]) async {
    if (widget.onLoadMore == null || loading) return;
    if (end != null) {
      final positions = getMoreInfos(end, page, totalCount, itemCount);
      start = positions[0];
      end = positions[1];
      page = positions[2];
    }
    hasReachedBottom = itemCount != null && end == itemCount! - 1;
    try {
      final future = newList != null
          ? Future.value(newList)
          : widget.onLoadMore!(list, start, end, page, hasReachedBottom);
      loading = true;
      setState(() {});
      final values = await future;
      loading = false;

      for (int i = 0; i < values.length; i++) {
        final value = values[i];
        list.add(value);
      }
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      setState(() {});
    }
  }

  void getLessList([List<T>? newList]) async {
    if (widget.onLoadLess == null || loading) return;

    if (end != null) {
      final positions = getLessInfos(end, page, totalCount, itemCount);
      start = positions[0];
      end = positions[1];
      page = positions[2];
    }
    hasReachedTop = start == 0;
    try {
      final future = newList != null
          ? Future.value(newList)
          : widget.onLoadLess!(list, start, end, page, hasReachedTop);
      loading = true;
      setState(() {});
      final values = await future;
      loading = false;

      for (int i = 0; i < values.length; i++) {
        final value = values[i];
        list.insert(0, value);
      }
      errorMessage = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      setState(() {});
    }
  }

  Widget? getBuilder() {
    if (errorMessage != null) {
      return widget.errorBuilder?.call(errorMessage!) ??
          ErrorOrSuccessView(message: errorMessage!, isError: true);
    }
    if (loading) {
      return widget.loadingBuilder?.call(context) ?? const LoadingView();
    }
    return null;
  }

  Widget? getListBuilder(BuildContext context, int index) {
    if (!widget.useFullScreenBuilder && index == list.length - 1) {
      final builder = getBuilder();
      if (builder == null) return Container();
      return SizedBox(
        height:
            widget.isPageView ? double.infinity : widget.builderHeight ?? 100,
        width: double.infinity,
        child: Center(child: builder),
      );
    }
    if (index == 0 &&
        widget.onLoadLess != null &&
        !hasReachedTop &&
        (totalCount == null || (totalCount != list.length))) {
      getLessList();
    }
    if (index == list.length - 1 &&
        widget.onLoadMore != null &&
        !hasReachedBottom &&
        (totalCount == null ||
            (index < totalCount! && totalCount != list.length))) {
      getMoreList();
    }
    return widget.itemBuilder(context, list, index);
  }

  int get listCount {
    if (!widget.useFullScreenBuilder && (loading || errorMessage != null)) {
      return list.length + 1;
    }
    return list.length;
  }

  @override
  Widget build(BuildContext context) {
    final builder = getBuilder();
    if (widget.useFullScreenBuilder && builder != null) {
      return builder;
    }
    if (list.isEmpty) {
      return widget.emptyBuilder?.call(context) ??
          ErrorOrSuccessView(
              message: widget.onGetEmptyMessage?.call() ?? "Empty List");
    }

    if (widget.gridDelegate != null) {
      return GridView.builder(
        scrollDirection: widget.scrollDirection ?? Axis.vertical,
        reverse: widget.reverse ?? false,
        controller: widget.controller,
        shrinkWrap: widget.shrinkWrap ?? false,
        primary: widget.primary,
        padding: widget.padding,
        physics: widget.physics,
        gridDelegate: widget.gridDelegate!,
        itemCount: listCount,
        itemBuilder: getListBuilder,
      );
    }

    if (widget.separatorBuilder != null) {
      return ListView.separated(
        scrollDirection: widget.scrollDirection ?? Axis.vertical,
        reverse: widget.reverse ?? false,
        controller: widget.controller,
        shrinkWrap: widget.shrinkWrap ?? false,
        primary: widget.primary,
        padding: widget.padding,
        physics: widget.physics,
        itemCount: listCount,
        separatorBuilder: widget.separatorBuilder!,
        itemBuilder: getListBuilder,
      );
    }
    if (widget.isPageView) {
      return PageView.builder(
        scrollDirection: widget.scrollDirection ?? Axis.vertical,
        reverse: widget.reverse ?? false,
        controller: widget.pageController,
        onPageChanged: widget.onPageChanged,
        physics: widget.physics,
        itemCount: listCount,
        itemBuilder: getListBuilder,
      );
    }

    return ListView.builder(
      scrollDirection: widget.scrollDirection ?? Axis.vertical,
      reverse: widget.reverse ?? false,
      controller: widget.controller,
      shrinkWrap: widget.shrinkWrap ?? false,
      primary: widget.primary,
      padding: widget.padding,
      physics: widget.physics,
      itemCount: listCount,
      itemBuilder: getListBuilder,
    );
  }
}
