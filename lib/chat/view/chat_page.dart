import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:fly/fly.dart';
import 'package:fly_bloc/fly_bloc.dart';
import 'package:makerlog/bot/cubit/bot_cubit.dart';
import 'package:makerlog/bot/cubit/bot_state.dart';
import 'package:makerlog/bot/repository/bot_repository.dart';
import 'package:makerlog/chat/cubit/chat_cubit.dart';
import 'package:makerlog/chat/cubit/chat_state.dart';
import 'package:makerlog/chat/repository/chat_repository.dart';
import 'package:makerlog/chat/widgets/chat_conversation.dart';
import 'package:makerlog/ollama_setup/cubit/ollama_setup_cubit.dart';
import 'package:makerlog/ollama_setup/cubit/ollama_setup_state.dart';
import 'package:makerlog/ollama_setup/repository/ollama_setup_repository.dart';
import 'package:makerlog/widgets/header.dart';
import 'package:makerlog/widgets/input_bar.dart';

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
      create: (ctx) => ChatCubit(repository: ChatRepository()),
      child: _ChatPageView(),
    );
  }
}

class _ChatPageView extends StatefulWidget {
  @override
  State<_ChatPageView> createState() => _ChatPageViewState();
}

class _ChatPageViewState extends State<_ChatPageView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  OllamaSetupStatus? _lastSetupStatus;
  BotStatus? _lastBotStatus;

  @override
  Widget build(BuildContext context) {
    final chatCubit = context.read<ChatCubit>();
    final botCubit = context.read<BotCubit>();

    return Column(
      children: [
        Header(),
        Expanded(child: ChatConversation(controller: _scrollController)),
        BlocListener<OllamaSetupCubit, OllamaSetupState>(
          listenWhen: (previous, current) =>
              previous.status != current.status ||
              current.status == OllamaSetupStatus.installing,
          listener: (ctx, setupState) {
            if (setupState.status != _lastSetupStatus) {
              chatCubit.appendSystemMessage(setupState.message);
              _lastSetupStatus = setupState.status;
            } else if (setupState.status == OllamaSetupStatus.installing) {
              chatCubit.replaceTailSystemMessage(setupState.message);
            }

            if (setupState.isReady) {
              unawaited(botCubit.ensureReady());
            } else if (setupState.isTerminalFailure) {
              chatCubit.advanceAfterSetup();
            }
          },
          child: BlocListener<BotCubit, BotState>(
            listenWhen: (previous, current) =>
                previous.status != current.status ||
                current.status == BotStatus.installing ||
                current.status == BotStatus.answering,
            listener: (ctx, botState) {
              if (botState.status != _lastBotStatus) {
                chatCubit.appendSystemMessage(botState.message);
                _lastBotStatus = botState.status;
              } else if (botState.status == BotStatus.installing) {
                chatCubit.replaceTailSystemMessage(botState.message);
              }

              if (botState.isReady || botState.isTerminalFailure) {
                chatCubit.advanceAfterSetup();
              } else if (botState.status == BotStatus.answering) {
                chatCubit.replaceTailSystemMessage(botState.message);
              } else if (botState.status == BotStatus.answered ||
                  botState.status == BotStatus.error) {
                chatCubit.replaceTailSystemMessage(botState.message);
                chatCubit.advanceAfterBotAnswer();
              }
            },
            child: BlocBuilder<ChatCubit, ChatState>(
              builder: (context, state) {
                if (!state.awaitingUserInput || state.options.isEmpty) {
                  return SizedBox(height: 0);
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: OptionsPicker(
                    options: state.options,
                    shouldHandleEnter: () => _controller.text.isEmpty,
                    onSelected: (option) => chatCubit.submit(option),
                  ),
                );
              },
            ),
          ),
        ),
        BlocBuilder<ChatCubit, ChatState>(
          builder: (context, state) {
            final prompts =
                context.read<ChatCubit>().repository.setupPrompts();
            final hint = state.currentPromptIndex < prompts.length
                ? prompts[state.currentPromptIndex].freeFormHint
                : null;
            return InputBar(
              bloc: chatCubit,
              controller: _controller,
              placeholder: hint,
            );
          },
        ),
      ],
    );
  }
}