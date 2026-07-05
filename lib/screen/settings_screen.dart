import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tsundoku/util/constants.dart';
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

      // for testing purposes
      // int daysUntilNextSomeday = (DateTime.saturday - now.weekday + 7) % 7;
      // DateTime nextTestTime = DateTime(now.year, now.month, now.day, 1, 41).add(Duration(days: daysUntilNextSomeday == 0 ? 7 : daysUntilNextSomeday));

      await _notificationService.showScheduledNotification(
        id: 1,
        title: 'Weekly reminder',
        body: 'Let\'s get some reading done this weekend. Check your current book count in tsundoku.',
        scheduledDateTime: nextSaturday0905am,
      );

      // for express testing (next xx seconds)
      // await _notificationService.showNextSecondsNotification(
      //   id: 999,
      //   title: 'tsundoku TestNotif',
      //   body: 'Check check rock rock\'s!',
      //   secondsFromNow: 10,
      // );
    } 
    else {
      // Cancel the scheduled notification
      logger.i('Cancelling weekly notification');
      await _notificationService.cancelNotifications(1);
    }
  }

  Future<bool> requestNotificationPermission(BuildContext context) async {
    // check current status
    PermissionStatus notificationPermissionStatus = await Permission.notification.status;

    if (notificationPermissionStatus.isGranted) {
      // permission is already granted
      return true;
    } 
    else if (notificationPermissionStatus.isDenied) {
      logger.i('Notification permission status: isDenied. Requesting permission.');

      // request permission if it hasn't been enabled yet
      notificationPermissionStatus = await Permission.notification.request();
    } 
    else if (notificationPermissionStatus.isPermanentlyDenied) {
      logger.i('notification permission status: isPermanentlyDenied');
      
      // show popup notice if they already hard-denied permission (don't show again selected)
      if (context.mounted) {
        _showNotificationPermissionPermanentlyDeniedDialog(context);
      }
    }

    // get current status after all the shenanigans above
    if (notificationPermissionStatus.isGranted) {
      return true;
    } else {
      return false;
    }
  }

  void _showNotificationPermissionPermanentlyDeniedDialog(BuildContext context) {

    RichText contentText = RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 15.0,
          color: Colors.black87,
        ),
        children: [
          TextSpan(text: 'tsundoku need permission to send notification.\n\n'),
          TextSpan(text: 'Since this was permanently disabled, please '),
          TextSpan(
            text: 'allow permission for notification',
            style: const TextStyle(fontWeight: FontWeight.bold)
          ),
          TextSpan(text: ' manually in your app setting.'),
        ]
      ),
    );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Notification permission required'),
          content: contentText,
          // content: const Text('tsundoku need permission to send notification. Since this was permanently disabled, please allow permission for notification manually in your app setting.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await openAppSettings();
              },
            ),
          ],
        );
      },
    );
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
                              ? 'API key is currently configured.'
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
                  onToggle: (bool value) async {
                    logger.i('_isWeeklyNotificationEnabled: $value');

                    // trigger for notification permission if true
                    bool permissionStatus = false;
                    if (value == true) {
                      permissionStatus = await requestNotificationPermission(context); 
                    }

                    setState(() {
                      if (value == true && permissionStatus == true) {
                        _isWeeklyNotificationEnabled = true;
                      }
                      else {
                        _isWeeklyNotificationEnabled = false;
                      }
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
                  value: Text(Constants.appVersion.versionNumber),
                ),
              ]
            ),
          ],
        ),
      ),
    );
  }
}