import 'package:flutter/material.dart';
import 'package:map_project/widgets/password_field.dart';
import 'package:map_project/widgets/text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text('Pictures'),

                const SizedBox(height: 20),
                const Text(
                  'Come join us!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B6E99),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),
                CustomTextField(
                  controller: _usernameController,
                  label: 'Username',
                  hint: 'Enter your username',
                ),

                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: 'Gmail',
                  hint: 'Enter your gmail',
                ),

                const SizedBox(height: 16),
                PasswordField(controller: _passwordController),

                const SizedBox(height: 16),
                PasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                ),

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : (){},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Register', style: TextStyle(fontSize: 16)),
                ),
                
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
