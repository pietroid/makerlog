import 'dart:async';

import 'package:fly_bloc/fly_bloc.dart';
import 'package:makerlog/worklog/cubit/worklog_state.dart';
import 'package:makerlog/worklog/repository/worklog_repository.dart';

/// Owns the worklog history: loads on startup and keeps the in-memory
/// list in sync with `.makerlog/worklog.md`.
class WorklogCubit extends Cubit<WorklogState> {
  final WorklogRepository repository;

  WorklogCubit({required this.repository}) : super(const WorklogState()) {
    _init();
  }

  Future<void> _init() async {
    final entries = await repository.load();
    emit(state.copyWith(entries: entries));
  }

  /// Adds a new entry, writes it to disk, reloads the file, and updates state.
  Future<void> submit(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final entries = await repository.append(trimmed);
    emit(state.copyWith(entries: entries));
  }
}
