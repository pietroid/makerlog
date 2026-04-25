import 'dart:async';

import 'package:fly_bloc/fly_bloc.dart';
import 'package:makerlog/worklog/cubit/worklog_state.dart';
import 'package:makerlog/worklog/repository/worklog_entry.dart';
import 'package:makerlog/worklog/repository/worklog_repository.dart';

/// Owns the worklog history: loads on startup, keeps the in-memory
/// list in sync with `.makerbook/worklog.md`.
class WorklogCubit extends Cubit<WorklogState> {
  final WorklogRepository repository;

  WorklogCubit({required this.repository}) : super(const WorklogState()) {
    _init();
  }

  Future<void> _init() async {
    final entries = await repository.load();
    emit(state.copyWith(entries: entries));
  }

  /// Adds a new entry, writes it to disk, and updates the state.
  Future<void> submit(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final entry = WorklogEntry(
      timestamp: DateTime.now(),
      text: trimmed,
    );

    await repository.append(entry);
    emit(state.copyWith(entries: [...state.entries, entry]));
  }
}
