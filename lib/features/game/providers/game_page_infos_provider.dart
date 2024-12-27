import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_action.dart';
import '../models/game_page_infos.dart';

class GamePageInfosNotifier extends StateNotifier<GamePageInfos?> {
  GamePageInfosNotifier(super.state);

  void updateGamePageInfos(GamePageInfos infos) {
    state = infos;
  }

  void updateTotalPages(int totalPages) {
    if (state?.totalPages == totalPages) return;
    state = state?.copyWith(totalPages: totalPages);
  }

  void updateCurrentPage(int currentPage) {
    if (state?.currentPage == currentPage) return;

    state = state?.copyWith(currentPage: currentPage);
  }

  void updateFirst(int firstRecordId, int firstRecordIdRoundId,
      {int? totalPages}) {
    if (state?.firstRecordId == firstRecordId &&
        state?.firstRecordIdRoundId == firstRecordIdRoundId &&
        state?.totalPages == totalPages) {
      return;
    }

    state = state?.copyWith(
      firstRecordId: firstRecordId,
      firstRecordIdRoundId: firstRecordIdRoundId,
      totalPages: totalPages,
    );
  }

  void updateLast(int lastRecordId, int lastRecordIdRoundId,
      {int? totalPages}) {
    if (state?.lastRecordId == lastRecordId &&
        state?.lastRecordIdRoundId == lastRecordIdRoundId &&
        state?.totalPages == totalPages) {
      return;
    }
    state = state?.copyWith(
      lastRecordId: lastRecordId,
      lastRecordIdRoundId: lastRecordIdRoundId,
      totalPages: totalPages,
    );
  }

  @override
  void dispose() {
    state = null;
    super.dispose();
  }
}

final gamePageInfosProvider =
    StateNotifierProvider<GamePageInfosNotifier, GamePageInfos?>(
  (ref) {
    return GamePageInfosNotifier(null);
  },
);
