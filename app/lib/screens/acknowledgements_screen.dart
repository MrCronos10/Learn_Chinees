import 'package:flutter/material.dart';
import 'package:study_engine/study_engine.dart';

/// Credits every third-party source used in the Course Content.
class AcknowledgementsScreen extends StatelessWidget {
  const AcknowledgementsScreen({super.key, required this.engine});

  final StudyEngine engine;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acknowledgements')),
      body: FutureBuilder(
        future: engine.acknowledgements(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load Acknowledgements: ${snapshot.error}'),
            );
          }
          final acknowledgements = snapshot.data;
          if (acknowledgements == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (acknowledgements.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No third-party sources are used in the current Lessons.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            children: [
              for (final a in acknowledgements)
                ListTile(
                  title: Text(a.name),
                  subtitle: SelectableText(
                    'By ${a.author}\nLicense: ${a.license}\n${a.url}',
                  ),
                  isThreeLine: true,
                ),
            ],
          );
        },
      ),
    );
  }
}
