import 'package:app_ui/app_ui.dart';
import 'package:fly/fly.dart';
import 'package:fly_bloc/fly_bloc.dart';
import 'package:makerlog/worklog/cubit/worklog_cubit.dart';
import 'package:makerlog/worklog/cubit/worklog_state.dart';
import 'package:makerlog/worklog/repository/worklog_entry.dart';
import 'package:makerlog/worklog/repository/worklog_repository.dart';
import 'package:makerlog/widgets/header.dart';

class WorklogPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorklogCubit>(
      create: (_) => WorklogCubit(repository: WorklogRepository()),
      child: _WorklogPageView(),
    );
  }
}

class _WorklogPageView extends StatefulWidget {
  @override
  State<_WorklogPageView> createState() => _WorklogPageViewState();
}

class _WorklogPageViewState extends State<_WorklogPageView> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WorklogCubit>();

    return Column(
      children: [
        Header(),
        Expanded(
          child: BlocBuilder<WorklogCubit, WorklogState>(
            builder: (context, state) {
              if (state.entries.isEmpty) {
                return Center(
                  child: Text(
                    'No entries yet. Start typing below!',
                    style: TextStyle(
                      color: Color.brightBlack,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }

              return ListView(
                children: state.entries.map((entry) {
                  return _WorklogEntryRow(entry: entry);
                }).toList(),
              );
            },
          ),
        ),
        Container(
          color: Color.black,
          height: 1,
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Row(
            children: [
              Text(
                '❯ ',
                style: const TextStyle(
                  color: Color.brightCyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  placeholder: 'what are you working on?',
                  onSubmit: (text) {
                    cubit.submit(text);
                    _controller.clear();
                  },
                  style: const TextStyle(color: Color.brightWhite),
                  placeholderStyle: const TextStyle(
                    color: Color.brightBlack,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WorklogEntryRow extends StatelessWidget {
  final WorklogEntry entry;

  _WorklogEntryRow({required this.entry});

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '[${_formatTime(entry.timestamp)}] ',
            style: TextStyle(color: Color.brightBlack),
          ),
          Expanded(
            child: Text(
              entry.text,
              style: TextStyle(color: Color.brightWhite),
            ),
          ),
        ],
      ),
    );
  }
}
