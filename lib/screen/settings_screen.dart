import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _apiKeyPreferenceKey = 'google_books_api_key';

  final TextEditingController _apiKeyController = TextEditingController();
  bool _hasSavedApiKey = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }

    setState(() {
      _apiKeyController.text = prefs.getString(_apiKeyPreferenceKey) ?? '';
      _hasSavedApiKey = _apiKeyController.text.isNotEmpty;
    });
  }

  Future<void> _saveApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final trimmedValue = _apiKeyController.text.trim();
    await prefs.setString(_apiKeyPreferenceKey, trimmedValue);

    if (!mounted) {
      return;
    }

    setState(() {
      _hasSavedApiKey = trimmedValue.isNotEmpty;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(trimmedValue.isEmpty ? 'API key cleared.' : 'API key saved.'),
        duration: const Duration(seconds: 4),
        showCloseIcon: true,
        closeIconColor: Colors.deepOrange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text('Google Books API'),
            tiles: [
              CustomSettingsTile(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(40.0, 4.0, 18.0, 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'To find book information easily using ISBN number, you need a Google Books API key.\n\nYou can obtain your own free API key from the Google Cloud Console.',
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _apiKeyController,
                        decoration: InputDecoration(
                          labelText: 'API Key',
                          hintText: 'Paste your Google Books API key',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.save_alt_rounded),
                            onPressed: _saveApiKey,
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _saveApiKey(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _hasSavedApiKey
                            ? 'A saved API key is currently configured.'
                            : 'No API key is currently configured.',
                        style: TextStyle(
                          color: _hasSavedApiKey ? Colors.green.shade700 : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}