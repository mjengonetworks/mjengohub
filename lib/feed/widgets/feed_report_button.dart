import 'package:flutter/material.dart';

import '../services/feed_report_service.dart';

class FeedReportButton extends StatefulWidget {
  final int postId;
  final bool authenticated;
  final VoidCallback onRequireAuth;
  final FeedReportService? service;
  const FeedReportButton({
    super.key,
    required this.postId,
    required this.authenticated,
    required this.onRequireAuth,
    this.service,
  });

  @override
  State<FeedReportButton> createState() => _FeedReportButtonState();
}

class _FeedReportButtonState extends State<FeedReportButton> {
  bool _open = false;

  Future<void> _report() async {
    if (_open) return;
    if (!widget.authenticated) {
      widget.onRequireAuth();
      return;
    }
    setState(() => _open = true);
    final result = await showDialog<FeedReportResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ReportDialog(
        postId: widget.postId,
        service: widget.service ?? FeedReportService(),
        onRequireAuth: widget.onRequireAuth,
      ),
    );
    if (!mounted) return;
    setState(() => _open = false);
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.alreadyReported
                ? 'You have already reported this content.'
                : 'Report sent to the moderation team.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Report content',
    visualDensity: VisualDensity.compact,
    onPressed: _open || widget.postId <= 0 ? null : _report,
    icon: const Icon(Icons.flag_outlined, size: 19),
  );
}

class _ReportDialog extends StatefulWidget {
  final int postId;
  final FeedReportService service;
  final VoidCallback onRequireAuth;
  const _ReportDialog({
    required this.postId,
    required this.service,
    required this.onRequireAuth,
  });

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _form = GlobalKey<FormState>();
  final _explanation = TextEditingController();
  String? _reason;
  String? _error;
  bool _busy = false;
  bool _signIn = false;

  @override
  void dispose() {
    _explanation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.service.report(
        widget.postId,
        reason: _reason!,
        explanation: _explanation.text,
      );
      if (mounted) Navigator.of(context).pop(result);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is FeedReportException
              ? error.message
              : 'Could not send your report. Please try again.';
          _signIn = error is FeedReportException && error.requiresSignIn;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: const Text('Report content'),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your report is private and will be reviewed by the moderation team.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Reason'),
                isExpanded: true,
                items: feedReportReasons.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _reason = value),
                validator: (value) => value == null ? 'Choose a reason.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _explanation,
                enabled: !_busy,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Explanation (optional)',
                  helperText: 'Up to 400 characters',
                ),
                validator: (value) => (value ?? '').trim().runes.length > 400
                    ? 'Use at most 400 characters.'
                    : null,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (_signIn)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onRequireAuth();
            },
            child: const Text('Sign in again'),
          )
        else
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(_busy ? 'Sending…' : 'Send report'),
          ),
      ],
    ),
  );
}
