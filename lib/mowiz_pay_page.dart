import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:http/http.dart' as http;

import 'config_service.dart';
import 'l10n/app_localizations.dart';
import 'mowiz_time_page.dart';
import 'mowiz/mowiz_scaffold.dart';
import 'mowiz_page.dart';
import 'styles/mowiz_buttons.dart';
import 'styles/mowiz_design_system.dart';
import 'sound_helper.dart';

class _ZoneData {
  const _ZoneData({required this.id, required this.name, required this.color});
  final String id;
  final String name;
  final Color color;
}

class MowizPayPage extends StatefulWidget {
  final String? selectedCompany;
  
  const MowizPayPage({super.key, this.selectedCompany});

  @override
  State<MowizPayPage> createState() => _MowizPayPageState();
}

class _MowizPayPageState extends State<MowizPayPage> {
  String? _selectedZone;
  final _plateCtrl = TextEditingController();

  List<_ZoneData> _zones = [];
  bool _loadingZones = true;

  Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  Future<void> _loadZones() async {
    setState(() {
      _zones = [];
      _selectedZone = null;
      _loadingZones = true;
    });
    
    try {
      // 🎯 Determinar URL según la empresa seleccionada
      String apiUrl;
      if (widget.selectedCompany == 'MOWIZ') {
        // MOWIZ usa la rama tariff2 con zonas diferentes
        apiUrl = 'https://tariff2.onrender.com/v1/onstreet-service/zones';
      } else {
        // EYPSA usa la rama main (por defecto)
        apiUrl = '${ConfigService.apiBaseUrl}/v1/onstreet-service/zones';
      }
      
      final res = await http.get(Uri.parse(apiUrl));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        _zones = data
            .map((e) => _ZoneData(
                  id: e['id'] as String,
                  name: e['name'] as String,
                  color: _parseColor(e['color'] as String),
                ))
            .toList();
      } else {
        debugPrint('HTTP ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) setState(() => _loadingZones = false);
  }

  bool get _confirmEnabled =>
      _selectedZone != null && _plateCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final colorScheme = Theme.of(context).colorScheme;

    return MowizScaffold(
      title: 'MeyPark - ${widget.selectedCompany ?? 'EYPSA'} - ${t('selectZone')}',
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            // 🎨 Usar sistema de diseño homogéneo
            final contentWidth = MowizDesignSystem.getContentWidth(width);
            final horizontalPadding = MowizDesignSystem.getHorizontalPadding(contentWidth);
            final spacing = MowizDesignSystem.getSpacing(width);
            final titleFontSize = MowizDesignSystem.getTitleFontSize(width);
            final bodyFontSize = MowizDesignSystem.getBodyFontSize(width);
            final buttonHeight = MowizDesignSystem.getPrimaryButtonHeight(width);

            Widget zoneButton(String value, String text, Color color) {
              return FilledButton(
                onPressed: () {
                  SoundHelper.playTap();
                  print('🐛 DEBUG: Zona seleccionada - ID: "$value", Nombre: "$text"');
                  setState(() => _selectedZone = value);
                },
                style: MowizDesignSystem.getSmartWidthButtonStyle(
                  width: width,
                  backgroundColor: _selectedZone == value ? color : colorScheme.secondary,
                  foregroundColor: _selectedZone == value 
                    ? Colors.white 
                    : colorScheme.onSecondary,
                  text: text,
                  isPrimary: true,
                  isEnabled: true,
                ),
                child: AutoSizeText(
                  text,
                  maxLines: 1,
                  minFontSize: 13,
                ),
              );
            }

            // 🎨 Usar sistema de diseño homogéneo con scroll inteligente
            return MowizDesignSystem.getScrollableContent(
              availableHeight: height,
              contentHeight: 600, // Altura estimada del contenido
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MowizDesignSystem.getContentWidth(width),
                    minWidth: MowizDesignSystem.minContentWidth,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AutoSizeText(
                          t('selectZone'),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: titleFontSize,
                          ),
                        ),
                        SizedBox(height: spacing),
                        if (_loadingZones)
                          const Center(child: CircularProgressIndicator())
                        else
                          Builder(
                            builder: (context) {
                              if (MowizDesignSystem.isKiosk(width)) {
                                // Layout vertical para aparcímetro (botones apilados)
                                return Column(
                                  children: _zones
                                      .map(
                                        (z) => Padding(
                                          padding: EdgeInsets.only(bottom: spacing * 0.5),
                                          child: zoneButton(z.id, z.name, z.color),
                                        ),
                                      )
                                      .toList(),
                                );
                              } else {
                                // Layout horizontal para otras pantallas
                                final count = _zones.length.clamp(1, 3);
                                final btnWidth = (contentWidth - spacing * (count - 1)) / count;
                                return Wrap(
                                  spacing: spacing,
                                  runSpacing: spacing,
                                  alignment: WrapAlignment.center,
                                  children: _zones
                                      .map(
                                        (z) => SizedBox(
                                          width: btnWidth,
                                          child: zoneButton(z.id, z.name, z.color),
                                        ),
                                      )
                                      .toList(),
                                );
                              }
                            },
                          ),
                        SizedBox(height: spacing),
                        TextField(
                          controller: _plateCtrl,
                          enabled: _selectedZone != null,
                          decoration: InputDecoration(
                            labelText: t('plate'),
                            hintText: t('enterPlate'),
                          ),
                          style: TextStyle(fontSize: bodyFontSize),
                          onChanged: (_) => setState(() {}),
                        ),
                        SizedBox(height: spacing * 1.5),
                        FilledButton(
                          onPressed: _confirmEnabled
                              ? () {
                                  SoundHelper.playTap();
                                  print('🐛 DEBUG: Navegando a MowizTimePage con zone: "$_selectedZone"');
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => MowizTimePage(
                                        zone: _selectedZone!,
                                        plate: _plateCtrl.text.trim(),
                                        selectedCompany: widget.selectedCompany,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          style: MowizDesignSystem.getSmartWidthButtonStyle(
                            width: width,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            text: t('confirm'),
                            isPrimary: true,
                            isEnabled: _confirmEnabled,
                          ),
                          child: AutoSizeText(
                            t('confirm'),
                            maxLines: 1,
                            minFontSize: 13,
                          ),
                        ),
                        SizedBox(height: spacing),
                        FilledButton(
                          onPressed: () {
                            SoundHelper.playTap();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const MowizPage()),
                              (route) => false,
                            );
                          },
                          style: MowizDesignSystem.getSmartWidthButtonStyle(
                            width: width,
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            foregroundColor: Theme.of(context).colorScheme.onSecondary,
                            text: t('back'),
                            isPrimary: false,
                            isEnabled: true,
                          ),
                          child: AutoSizeText(
                            t('back'),
                            maxLines: 1,
                            minFontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
