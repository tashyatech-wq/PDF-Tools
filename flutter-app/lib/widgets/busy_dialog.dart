import 'package:flutter/material.dart';

/// Mutable message shown inside the dialog from [runBusy] -- update it (e.g.
/// from a `compress`/`split` progress callback) to show live progress such
/// as "Compressing page 3 of 30" instead of a static label.
class BusyMessage extends ValueNotifier<String> {
  BusyMessage(super.value);
}

/// Shows a non-dismissible "working" dialog, then runs [action].
///
/// The PDF libraries this app uses (Syncfusion's PDF engine especially) do
/// all their work synchronously on the UI isolate -- there isn't a single
/// real suspension point in their `await` chains, just async-flavoured
/// wrappers around plain CPU-bound Dart. That means a bare `setState(() =>
/// _working = true)` followed immediately by the heavy call never actually
/// gets painted: Flutter can't render the frame it just scheduled until the
/// current synchronous call stack returns, and that stack *is* the
/// compression/merge/etc. work. The result is a button that looks dead for
/// a few seconds and then suddenly shows a result.
///
/// Showing the dialog and yielding one real frame *before* calling [action]
/// guarantees the user sees "Compressing..." etc. the instant they tap,
/// even though the dialog's own spinner will stop animating once the heavy
/// work actually starts (same underlying reason) -- the dialog having
/// already appeared is what answers "did my tap register?".
Future<T> runBusy<T>(
  BuildContext context, {
  required String message,
  required Future<T> Function(BusyMessage message) action,
}) async {
  final busyMessage = BusyMessage(message);
  // showDialog's default route fades/scales in over ~150-200ms, so it would
  // visibly lag behind the button's own instant disabled/grey state change
  // even though both are triggered by the same tap. showGeneralDialog with
  // a zero transition duration puts it on screen in the very first frame
  // instead, so the two read as one single, immediate response.
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    transitionDuration: Duration.zero,
    pageBuilder: (context, _, _) => _BusyDialog(message: busyMessage),
  );

  // Let the dialog's first frame actually reach the screen before the
  // (often synchronous) heavy work below starts and blocks the UI isolate.
  await Future<void>.delayed(const Duration(milliseconds: 80));

  try {
    return await action(busyMessage);
  } finally {
    busyMessage.dispose();
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}

class _BusyDialog extends StatelessWidget {
  const _BusyDialog({required this.message});

  final BusyMessage message;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.6),
              ),
              const SizedBox(width: 18),
              Flexible(
                child: ValueListenableBuilder<String>(
                  valueListenable: message,
                  builder: (context, value, _) => Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
