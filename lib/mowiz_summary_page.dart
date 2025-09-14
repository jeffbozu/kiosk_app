import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'config_service.dart';
import 'dart:convert';

import 'l10n/app_localizations.dart';
import 'mowiz_page.dart';
import 'mowiz_time_page.dart';
import 'mowiz_success_page.dart';
import 'mowiz/mowiz_scaffold.dart';
import 'styles/mowiz_buttons.dart';
import 'styles/mowiz_design_system.dart';
import 'sound_helper.dart';

/// Helper function to format price with correct decimal separator based on locale
String formatPrice(double price, String locale) {
  if (locale.startsWith('es') || locale.startsWith('ca')) {
    // Use comma as decimal separator for Spanish and Catalan
    return '${price.toStringAsFixed(2).replaceAll('.', ',')} €';
  } else {
    // Use dot as decimal separator for English and others
    return '${price.toStringAsFixed(2)} €';
  }
}

class MowizSummaryPage extends StatefulWidget {
  final String plate;
  final String zone;
  final DateTime start;
  final int minutes;
  final double price;
  final double? discount;
  final String? selectedCompany;
  const MowizSummaryPage({
    super.key,
    required this.plate,
    required this.zone,
    required this.start,
    required this.minutes,
    required this.price,
    this.discount,
    this.selectedCompany,
  });

  @override
  State<MowizSummaryPage> createState() => _MowizSummaryPageState();
}

class _MowizSummaryPageState extends State<MowizSummaryPage> {
  String? _method;

  Future<void> _pay() async {
    if (_method == null) return;
    final plate = widget.plate.toUpperCase();
    try {
      final res = await http.post(
        Uri.parse('${ConfigService.apiBaseUrl}/v1/onstreet-service/pay-ticket'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'plate': plate}),
      );
      if (res.statusCode != 200) {
        debugPrint('HTTP ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MowizSuccessPage(
          plate: widget.plate,
          zone: widget.zone,
          start: widget.start,
          minutes: widget.minutes,
          price: widget.price,
          method: _method!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = l.t;
    final finish = widget.start.add(Duration(minutes: widget.minutes));
    final localeCode = l.locale.languageCode == 'es'
        ? 'es_ES'
        : l.locale.languageCode == 'ca'
            ? 'ca_ES'
            : 'en_GB';
    final timeFormat = DateFormat('EEE, d MMM yyyy - HH:mm', localeCode);

    Widget paymentButton(String value, IconData icon, String text, double width) {
      final selected = _method == value;
      final scheme = Theme.of(context).colorScheme;
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () async {
            SoundHelper.playTap();
            setState(() => _method = value);
            await _pay();
          },
          icon: Icon(icon, size: MowizDesignSystem.getBodyFontSize(width) + 10),
          label: AutoSizeText(text, maxLines: 1),
          style: MowizDesignSystem.getPrimaryButtonStyle(
            width: width,
            backgroundColor: selected ? scheme.primary : scheme.secondary,
            foregroundColor: selected ? scheme.onPrimary : scheme.onSecondary,
          ),
        ),
      );
    }

    return MowizScaffold(
      title: t('summaryPay'),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;

          // 🎨 Usar sistema de diseño homogéneo
          final contentWidth = MowizDesignSystem.getContentWidth(width);
          final horizontalPadding = MowizDesignSystem.getHorizontalPadding(contentWidth);
          final spacing = MowizDesignSystem.getSpacing(width);
          final titleFontSize = MowizDesignSystem.getTitleFontSize(width);
          final bodyFontSize = MowizDesignSystem.getBodyFontSize(width);

          Widget resumenCard = Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MowizDesignSystem.borderRadiusXL),
            ),
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(MowizDesignSystem.paddingL),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AutoSizeText(
                    t('totalTime'),
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: MowizDesignSystem.spacingS),
                  AutoSizeText(
                    '${widget.minutes ~/ 60}h ${widget.minutes % 60}m',
                    maxLines: 1,
                    style: TextStyle(fontSize: titleFontSize + 8),
                  ),
                  SizedBox(height: MowizDesignSystem.spacingM),
                  AutoSizeText(
                    "${t('startTime')}: ${timeFormat.format(widget.start)}",
                    maxLines: 1,
                    style: TextStyle(fontSize: bodyFontSize),
                  ),
                  SizedBox(height: MowizDesignSystem.spacingS),
                  AutoSizeText(
                    "${t('endTime')}: ${timeFormat.format(finish)}",
                    maxLines: 1,
                    style: TextStyle(fontSize: bodyFontSize),
                  ),
                  SizedBox(height: MowizDesignSystem.spacingM),
                  AutoSizeText(
                    "${t('totalPrice')}: ${formatPrice(widget.price, Intl.getCurrentLocale())}",
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: bodyFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );

          Widget contenido = ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MowizDesignSystem.maxContentWidth,
              minWidth: MowizDesignSystem.minContentWidth,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  resumenCard,
                  SizedBox(height: spacing * 1.2),
                  paymentButton('card', Icons.credit_card, t('card'), width),
                  SizedBox(height: spacing),
                  paymentButton('qr', Icons.qr_code_2, t('qrPay'), width),
                  SizedBox(height: spacing),
                  paymentButton('mobile', Icons.phone_iphone, t('mobilePay'), width),
                  SizedBox(height: spacing * 1.3),
                  FilledButton(
                    onPressed: () {
                      SoundHelper.playTap();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => MowizTimePage(
                            zone: widget.zone,
                            plate: widget.plate,
                            selectedCompany: widget.selectedCompany,
                          ),
                        ),
                        (route) => false,
                      );
                    },
                    style: MowizDesignSystem.getSecondaryButtonStyle(
                      width: width,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.onSecondary,
                    ),
                    child: AutoSizeText(t('back'), maxLines: 1),
                  ),
                ],
              ),
            ),
          );

          // 🎨 Usar scroll inteligente del sistema de diseño
          return MowizDesignSystem.getScrollableContent(
            availableHeight: height,
            contentHeight: 600, // Altura estimada del contenido
            child: Center(child: contenido),
          );
        },
      ),
    );
  }
}
