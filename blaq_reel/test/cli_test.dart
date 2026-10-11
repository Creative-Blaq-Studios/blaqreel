import 'dart:io';

import 'package:blaq_reel/cli/init.dart';
import 'package:blaq_reel/cli/project.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory app;

  setUp(() {
    app = Directory.systemTemp.createTempSync('blaq_reel_app');
    File('${app.path}/pubspec.yaml').writeAsStringSync('''
name: tiny
dependencies:
  flutter_riverpod: any
flutter:
  fonts:
    - family: Inter
    - family: Gabarito
''');
    Directory('${app.path}/lib/features/home').createSync(recursive: true);
    File('${app.path}/lib/theme.dart').writeAsStringSync('''
const ink = Color(0xFF111111);
const ink2 = Color(0xFF111111);
const accent = Color(0xFFFF6B00);
const paper = Color(0xFFF5F5F5);
''');
    File(
      '${app.path}/lib/features/home/home_screen.dart',
    ).writeAsStringSync('class HomeScreen extends StatelessWidget {}');
  });

  tearDown(() => app.deleteSync(recursive: true));

  test('Given an app, when surveyed, then its brand and screens are found', () {
    final s = AppSurvey.of(Project(app));
    expect(s.name, 'tiny');
    expect(s.state, 'riverpod');
    expect(s.fonts, ['Inter', 'Gabarito']);
    expect(s.ink, '#111111');
    expect(s.accent, '#FF6B00');
    expect(s.paper, '#F5F5F5');
    expect(s.screens.single.$1, 'HomeScreen');
    expect(s.screens.single.$2, 'package:tiny/features/home/home_screen.dart');
  });

  test('Given init, when run twice, then the second run keeps the files', () {
    final project = Project(app);
    final first = initReels(project);
    expect(first, contains('app_reels/reel.yaml'));
    expect(first, contains('app_reels/host.dart'));
    expect(project.initialized, isTrue);
    expect(
      File('${app.path}/app_reels/host.dart').readAsStringSync(),
      contains('ProviderScope'),
    );
    expect(
      File('${app.path}/app_reels/cuts/first.dart').readAsStringSync(),
      contains('HomeScreen'),
    );
    expect(initReels(project), isEmpty);
    expect(initReels(project, force: true), isNotEmpty);
  });

  test('Given reel.yaml, then the project reads where output goes', () {
    final project = Project(app);
    initReels(project);
    expect(project.out, '${app.path}/app_reels/out');
    expect(project.format, 'vertical');
  });
}
