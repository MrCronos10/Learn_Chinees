import 'package:flutter/material.dart';
import 'package:study_engine/study_engine.dart';

import 'acknowledgements_screen.dart';

/// The Learner's settings, saved in Learner Progress.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.engine});

  final StudyEngine engine;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<bool> _showPinyin = widget.engine.showPinyin();

  Future<void> _setShowPinyin(bool show) async {
    await widget.engine.setShowPinyin(show);
    if (!mounted) return;
    setState(() {
      _showPinyin = widget.engine.showPinyin();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          FutureBuilder(
            future: _showPinyin,
            builder: (context, snapshot) => SwitchListTile(
              title: const Text('Show pinyin'),
              subtitle: const Text(
                'Turn off to practise reading characters on their own.',
              ),
              value: snapshot.data ?? true,
              onChanged: snapshot.hasData ? _setShowPinyin : null,
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Acknowledgements'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AcknowledgementsScreen(engine: widget.engine),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
