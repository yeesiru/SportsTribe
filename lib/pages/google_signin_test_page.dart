import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInTestPage extends StatefulWidget {
  const GoogleSignInTestPage({Key? key}) : super(key: key);

  @override
  State<GoogleSignInTestPage> createState() => _GoogleSignInTestPageState();
}
class _GoogleSignInTestPageState extends State<GoogleSignInTestPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  String _status = 'Not tested';

  Future<void> _testGoogleSignIn() async {
    try {
      setState(() {
        _status = 'Testing Google Sign-In plugin...';
      });
      await _googleSignIn.isSignedIn();

      setState(() {
        _status = 'Google Sign-In plugin is working correctly!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sign-In Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Status: $_status',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testGoogleSignIn,
              child: const Text('Test Google Sign-In Plugin'),
            ),
          ],
        ),
      ),
    );
  }
}
