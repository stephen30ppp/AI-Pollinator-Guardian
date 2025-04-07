import 'package:ai_pollinator_guardian/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/firebase_service.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialize the Vertex AI service and create a `GenerativeModel` instance
  // Specify a model that supports your use case
  final model =
      FirebaseVertexAI.instance.generativeModel(model: 'gemini-2.0-flash');


  runApp(const PollinatorGuardianApp());
}
