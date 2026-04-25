import 'package:app_ui/app_ui.dart';
import 'package:fly/fly.dart';
import 'package:fly_bloc/fly_bloc.dart';
import 'package:makerlog/bot/cubit/bot_cubit.dart';
import 'package:makerlog/bot/repository/bot_repository.dart';
import 'package:makerlog/chat/cubit/chat_cubit.dart';
import 'package:makerlog/chat/cubit/chat_state.dart';
import 'package:makerlog/chat/repository/chat_repository.dart';
import 'package:makerlog/chat/widgets/chat_conversation.dart';
import 'package:makerlog/ollama_setup/cubit/ollama_setup_cubit.dart';
import 'package:makerlog/ollama_setup/repository/ollama_setup_repository.dart';
import 'package:makerlog/widgets/header.dart';
import 'package:makerlog/widgets/input_bar.dart';

/// Chat page — owns the chat cubit + repository for this screen and
/// lays out the vertical stack: header, conversation, options picker
/// (when the machine is waiting on the human), and the always-on
/// free-form input.
class ChatPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<OllamaSetupCubit>(
      create: (_) => OllamaSetupCubit(repository: OllamaSetupRepository()),
      child: BlocProvider<BotCubit>(
        create: (_) => BotCubit(repository: BotRepository()),
        child: _ChatCubitScope(),
      ),
    );
  }
}

class _ChatCubitScope extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatCubit>(
      create: (ctx) => ChatCubit(
        repository: ChatRepository(),
        ollamaSetupCubit: ctx.read<OllamaSetupCubit>(),
        botCubit: ctx.read<BotCubit>(),
      ),
      child: _ChatPageView(),
    );
  }
}

class _ChatPageView extends StatefulWidget {
  @override
  State<_ChatPageView> createState() => _ChatPageViewState();
}

class _ChatPageViewState extends State<_ChatPageView> {
  // A stable controller — rebuilding the widget on every frame would
  // otherwise hand the TextField a fresh empty one and swallow input.
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChatCubit>();
    return Column(
      children: [
        Header(),
        Expanded(child: ChatConversation()),
        BlocBuilder<ChatCubit, ChatState>(
          builder: (context, state) {
            if (!state.awaitingUserInput || state.options.isEmpty) {
              return SizedBox(height: 0);
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: OptionsPicker(
                options: state.options,
                shouldHandleEnter: () => _controller.text.isEmpty,
                onSelected: (option) => cubit.submit(option),
              ),
            );
          },
        ),
        BlocBuilder<ChatCubit, ChatState>(
          builder: (context, state) {
            final prompts = context.read<ChatCubit>().repository.setupPrompts();
            final hint = state.currentPromptIndex < prompts.length
                ? prompts[state.currentPromptIndex].freeFormHint
                : null;
            return InputBar(
              bloc: cubit,
              controller: _controller,
              placeholder: hint,
            );
          },
        ),
      ],
    );
  }
}
