import 'package:flutter/material.dart';

import '../services/api_services.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController nameController = TextEditingController();

  final TextEditingController emailController = TextEditingController();

  bool isLoading = false;

  void updateProfile() async {
    setState(() {
      isLoading = true;
    });

    final response = await ApiService.updateProfile(
      nameController.text.trim(),
      emailController.text.trim(),
    );

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(response['message'])));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),

            const SizedBox(height: 30),

            CustomTextField(controller: nameController, label: 'Name'),

            const SizedBox(height: 20),

            CustomTextField(controller: emailController, label: 'Email'),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,

              child: CustomButton(
                text: 'Update Profile',
                icon: Icons.person,
                isLoading: isLoading,
                onPressed: updateProfile,
              ),
            ),

            const SizedBox(height: 30),

            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return SwitchListTile(
                  title: const Text('Dark Mode'),
                  secondary: const Icon(Icons.dark_mode),
                  value: themeProvider.isDarkMode,

                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
