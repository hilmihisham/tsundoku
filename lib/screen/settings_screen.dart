import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsundoku/util/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // logger
  final logger = Logger();
  
  static const String _apiKeyPreferenceKey = 'google_books_api_key';
  static const String _weeklyNotificationPreferenceKey = 'notification_prefs_weekly';

  final TextEditingController _apiKeyController = TextEditingController();

  final NotificationService _notificationService = NotificationService();

  bool _hasSavedApiKey = false;
  bool _isWeeklyNotificationEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _loadWeeklyNotification();
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

  Future<void> _loadWeeklyNotification() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }

    setState(() {
      logger.i('Weekly notification preference: ${prefs.getBool(_weeklyNotificationPreferenceKey)}');
      _isWeeklyNotificationEnabled = prefs.getBool(_weeklyNotificationPreferenceKey) ?? false;
    });
  }

  /// Saves all settings to SharedPreferences. Returns true if successful, false otherwise.
  Future<bool> _saveAllSettingsToSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_apiKeyPreferenceKey, _apiKeyController.text.trim());
      
      // weekly notification setting will only be properly saved when user exiting this screen
      await prefs.setBool(_weeklyNotificationPreferenceKey, _isWeeklyNotificationEnabled);
      await _updateWeeklyNotificationService(_isWeeklyNotificationEnabled);

      return true;
    } 
    catch (e) {
      logger.e('Error saving settings to SharedPreferences: $e');
      return false;
    }
  }

  Future<void> _updateWeeklyNotificationService(bool isEnabled) async {
    if (isEnabled) {

      logger.i('Enabling weekly notification');

      // Schedule the weekly notification for 9:00 AM every Saturday
      DateTime now = DateTime.now();
      int daysUntilNextSaturday = (DateTime.saturday - now.weekday + 7) % 7;
      DateTime nextSaturday0905am = DateTime(now.year, now.month, now.day, 9, 5).add(Duration(days: daysUntilNextSaturday == 0 ? 7 : daysUntilNextSaturday));

      // for 
      int daysUntilNextFriday = (DateTime.friday - now.weekday + 7) % 7;
      DateTime nextFridayTestTime = DateTime(now.year, now.month, now.day, 2, 20).add(Duration(days: daysUntilNextFriday == 0 ? 7 : daysUntilNextFriday));

      await _notificationService.showScheduledNotification(
        id: 1,
        title: 'Weekly tsundoku Update',
        body: 'Check your current book count in tsundoku. Get some reading done this weekend!',
        scheduledDateTime: nextFridayTestTime,
      );
    } 
    else {
      // Cancel the scheduled notification
      logger.i('Cancelling weekly notification');
      await _notificationService.cancelNotifications(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // preventing screen from popping automatically
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        logger.i('didPop: $didPop');

        // If the system already handled the pop, do nothing
        if (didPop) return;

        // Save everything when navigating back
        bool isSaveSuccessful = await _saveAllSettingsToSharedPreferences();

        if (isSaveSuccessful && context.mounted) {
          // Manually pop the screen if the condition is met
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
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
            SettingsSection(
              title: Text('Weekly Notification'),
              tiles: [
                SettingsTile.switchTile(
                  leading: Icon(Icons.notifications_active_sharp),
                  title: Text('Enable Weekly Notification'),
                  description: Text('Receive a weekly notification showing your current book count.'),
                  initialValue: _isWeeklyNotificationEnabled,
                  onToggle: (bool value) {
                    logger.i('_isWeeklyNotificationEnabled: $value');
                    setState(() {
                      _isWeeklyNotificationEnabled = value;
                    });
                  },
                ),
              ]
            ),
            SettingsSection(
              title: const Text('About'),
              tiles: [
                SettingsTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('App version'),
                  value: const Text('0.8.0'),
                ),
              ]
            ),
          ],
        ),
      ),
    );
  }
}