import 'package:basic_bible/src/features/prayer/application/prayer_list_view_model.dart';
import 'package:basic_bible/src/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A personal list of people, events and requests to remember in prayer.
/// Names can be added at the bottom and removed by swiping or with the X.
class PrayerListScreen extends ConsumerStatefulWidget {
  const PrayerListScreen({super.key});

  @override
  ConsumerState<PrayerListScreen> createState() => _PrayerListScreenState();
}

class _PrayerListScreenState extends ConsumerState<PrayerListScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    await ref.read(prayerListProvider.notifier).add(text);
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _remove(PrayerItem item) {
    final notifier = ref.read(prayerListProvider.notifier);
    notifier.remove(item.id);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Text('Removed from your prayer list'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => notifier.restore(item),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(prayerListProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Prayer List'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: items.isEmpty
                  ? const _EmptyPrayerList()
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Dismissible(
                          key: ValueKey(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: colors.errorContainer,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: Icon(
                              Icons.delete_outline,
                              color: colors.onErrorContainer,
                            ),
                          ),
                          onDismissed: (_) => _remove(item),
                          child: ListTile(
                            leading: const Icon(Icons.favorite_border),
                            title: Text(item.text),
                            trailing: IconButton(
                              tooltip: 'Remove',
                              icon: const Icon(Icons.close),
                              onPressed: () => _remove(item),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Material(
              color: colors.surfaceContainer,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _add(),
                        decoration: const InputDecoration(
                          hintText: 'Add a name, event or request',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton.filled(
                      tooltip: 'Add to prayer list',
                      icon: const Icon(Icons.add),
                      onPressed: _add,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPrayerList extends StatelessWidget {
  const _EmptyPrayerList();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 48, color: colors.outline),
            const SizedBox(height: 16),
            Text(
              'Your prayer list is empty',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Add the names of people, events or requests you want to '
              'remember in prayer. Swipe a name left, or tap the X, to remove '
              'it.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
