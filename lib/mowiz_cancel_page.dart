import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:http/http.dart' as http;

// Base URL configuration for API calls
import 'config_service.dart';

import 'l10n/app_localizations.dart';
import 'mowiz/mowiz_scaffold.dart';
import 'styles/mowiz_buttons.dart';
import 'styles/mowiz_design_system.dart';
import 'sound_helper.dart';

class MowizCancelPage extends StatefulWidget {
  const MowizCancelPage({super.key});

  @override
  State<MowizCancelPage> createState() => _MowizCancelPageState();
}

class _MowizCancelPageState extends State<MowizCancelPage> {
  final _plateCtrl = TextEditingController();
  bool _loading = false;

  bool get _validateDisabled => _plateCtrl.text.trim().isEmpty || _loading;

  @override
  void dispose() {
    _plateCtrl.dispose();
    super.dispose();
  }

  Future<void> _validate() async {
    final l = AppLocalizations.of(context);
    final t = l.t; // i18n
    final plate = _plateCtrl.text.trim().toUpperCase();
    setState(() => _loading = true);
    try {
      // API call
      final res = await http.get(
        // Use the base URL constant here
        Uri.parse('${ConfigService.apiBaseUrl}/v1/onstreet-service/validate-ticket/$plate'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final valid = data['valid'] == true;
        final msg = data['message'] as String?;
        // SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(valid
                ? (msg?.isNotEmpty == true
                    ? msg!
                    : t('ticketValid'))
                : t('ticketNotFound')),
            backgroundColor: valid ? Colors.green : Colors.red,
          ),
        );
        if (valid) {
          SoundHelper.playSuccess();
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) Navigator.of(context).pop();
        } else {
          SoundHelper.playError();
        }
      } else {
        debugPrint('HTTP ${res.statusCode}: ${res.body}');
        // SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('networkError')),
            backgroundColor: Colors.red,
          ),
        );
        SoundHelper.playError();
      }
    } catch (e) {
      debugPrint('Error: $e');
      // SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('networkError')),
          backgroundColor: Colors.red,
        ),
      );
      SoundHelper.playError();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t; // i18n
    return MowizScaffold(
      title: t('cancelFine'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          // 🎨 Usar sistema de diseño homogéneo
          final contentWidth = MowizDesignSystem.getContentWidth(width);
          final horizontalPadding = MowizDesignSystem.getHorizontalPadding(contentWidth);
          final spacing = MowizDesignSystem.getSpacing(width);
          final bodyFontSize = MowizDesignSystem.getBodyFontSize(width);

          return MowizDesignSystem.getScrollableContent(
            availableHeight: height,
            contentHeight: 400, // Altura estimada del contenido
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MowizDesignSystem.maxContentWidth,
                  minWidth: MowizDesignSystem.minContentWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _plateCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(hintText: t('enterPlate')),
                        style: TextStyle(fontSize: bodyFontSize),
                        onChanged: (_) => setState(() {}),
                      ),
                      SizedBox(height: spacing * 1.2),
                      FilledButton(
                        onPressed: _validateDisabled
                            ? null
                            : () {
                                SoundHelper.playTap();
                                _validate();
                              },
                        style: MowizDesignSystem.getPrimaryButtonStyle(
                          width: width,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : AutoSizeText(t('validate'), maxLines: 1),
                      ),
                      SizedBox(height: spacing),
                      FilledButton(
                        onPressed: () {
                          SoundHelper.playTap();
                          Navigator.of(context).pop();
                        },
                        style: MowizDesignSystem.getSecondaryButtonStyle(
                          width: width,
                          backgroundColor: const Color(0xFFA7A7A7),
                          foregroundColor: Colors.white,
                        ),
                        child: AutoSizeText(t('cancel'), maxLines: 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
