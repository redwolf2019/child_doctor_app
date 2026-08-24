import 'package:flutter/material.dart';

import 'app.dart';
import 'audio/local_audio.dart';
import 'exam/exam_coordinator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final audio = LocalAudio();
  final coordinator = ExamCoordinator(audio: audio);
  runApp(AppShell(coordinator: coordinator, audio: audio));
}
