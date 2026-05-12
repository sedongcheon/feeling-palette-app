import 'package:flutter/material.dart';

import '../constants/theme.dart';
import '../db/diary_dao.dart';
import '../l10n/app_localizations.dart';
import '../models/diary.dart';
import '../widgets/diary_detail_card.dart';

class DiaryDetailScreen extends StatefulWidget {
  final String entryId;
  const DiaryDetailScreen({super.key, required this.entryId});

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {
  DiaryEntry? _entry;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    DiaryDao().findById(widget.entryId).then((entry) {
      if (!mounted) return;
      setState(() {
        _entry = entry;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.commonClose,
              style: TextStyle(
                  color: palette.tabBarActive,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ),
        leadingWidth: 64,
        title: Text(
          loc.diaryDetailTitle,
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: palette.text),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _entry == null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(
                        loc.diaryDetailNotFound,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 15, color: palette.textSecondary),
                      ),
                    )
                  : DiaryDetailCard(entry: _entry!),
        ),
      ),
    );
  }
}
