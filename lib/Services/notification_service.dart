import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Service Account Credentials (JSON content you provided)
  // SECURITY WARNING: In a real production app, NEVER embed this in the client code.
  // This should be on a secure backend server. We are doing this strictly for
  // academic/demo purposes as requested.
  static const Map<String, dynamic> _serviceAccount = {
    "type": "service_account",
    "project_id": "do-an-food", 
    "private_key_id": "7b30f4abe173f3fc01b7b6fc521019b0ab90306a",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDlyNopQ9rZPG9O\n1m34RSjzA3ZvlV9O5sUdd88YMi+l9j9ouvVX+SCPSUrkarG+4mErGqOEqjTfP8/6\nm5DopF3dDyGBl0Nd86fL6hqAuxVKwhafBRNYPY2Nj3pAIOnH8bX7Im1x+1M8/zKA\nW4CFnS9JwGK7HQKBOo+w2Y8ClPwMZ/SkbEaLFf9/vtSTeYaQ9J3/j1Z91u0djZ6A\nMNLpjbiZzYBFpzEYvHj17YELc0QFUDlM5a6RrAUznGj/dv1vvChQe6NkSN+t+BNB\nDqpafSKLv82W8xjPF/yYnciCSNVblhhvScp4ZNHe38KuQ6nMfjzcTqzMzYqj9X89\nv2M0Z2WHAgMBAAECggEAAZQtELzP+DFRHB3bSsCkEtuc8EygYcgbx+dJmb+bO53s\nSbqTW+ph4LZkgBrOJ5ttSqo7i2O/wwP74AT+NBKIzpFhZlIEKE2hKN79FaD+vMA6\n4NqYmm4yTzOShd+SIyudk/PdIizxuB2heOe3Gixj5Y1q58aSmrcstArl7cTKDdkq\nnMIEFGrDY+29/liuzId3wwZ4VcNnsygjknfv2ukkxdR6JvBb9Zr6HVJIO4JE5BJb\n9TwMyP4WdJwDV9Rc8qLV5lIte9k3Y9VioedJ0wt1K51dZM4yTEeLpCtv+Kxg/L6N\noskNNgG4YYxKgvMKmGytcblshKZftRXIRmm+U6iTMQKBgQD6CsN6n8wxHDsNKVGe\nPOpxsa3vLRl5C5Rjd4iF1pncnU2jLeGfYg/JluGF+wkxdtlAxNkmJZ5Ywh7qg8Uh\n4UlhzTqa5OqiumC6p89YgDpvrYFXOl2qQgOudjMBJ/RXHgOQtCfAYhyK66mNpUXd\nRpk8ykbEasTW9SFOR9Qk1iIx3wKBgQDrQoUJ8Trd4WH6zGR0oay0M1ROiSvIj2gU\nEA9JSAaqpADLIcgAXEhzaC9h0ShU+saL3+WpcFbkMkkd/doDuJMtZGjoLXAguzwv\nbzBKrHwp8rUTtfCrlH3+gNi5LWKhpxOAUKFJ/s/D3xC30xpIbdQE9WmWm7deNhd5\nDR4F49PRWQKBgQCQphNp5/G/Y16CAao2yXSzKx+9IrD+xoUkea0gCALgjpuwT8Wb\nZ6ZMb52t3Yj29ZM/FeGtYMvW+w3ZiztKm0LRcmF54/4c/4cf1B5uS1gC7TPK23f+\nG8x3a+ebvppqn3Fej+oDMH7kmupuh/L/zGyvrzD7RezzkcGfwIvod3w2rwKBgQCn\n+VnWLHgUfl0f3hoHsHwIOfIDFSu+yq3MTV8supGP+wNaBiewIjPUutnB5L4AVwG2\nU0m+fih8TG8qS9sC9yGWsm+4/uBlbmpdj+0SFC+fH90sUqahS6feNI8JQJ+AvjNN\nVcSjeZ1MxBNCvSax+kD8vWEDmPEHAmYmFziNigruGQKBgALUsaCGPtXGnlUYc2SY\nTzzHBOKOZ8sDPmsjAX29VRuLFHL4HZhSddawP9hkC1wmTgxVZ6ftQrPMjE0SqSzf\nzVu2Rd7KwkhlzO9nakmbsXcsyIxuA5TX5V1s+2ILztgkNb83WBg5Pcyh088HnrB4\nARxOgufwLHZ85TUk+anMCRfI\n-----END PRIVATE KEY-----\n",
    "client_email": "firebase-adminsdk-fbsvc@do-an-food.iam.gserviceaccount.com",
    "client_id": "115315806342026267806",
  };

  Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
      // Still continue to init local notifications just in case
    }

    // 2. Setup Android Channel (Vital for Android 8+)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description: 'This channel is used for important notifications.', // description
      importance: Importance.max,
      playSound: true,
    );

    // 3. Create the Channel on the device
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. Initialize Local Notifications
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    // const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(); // Open if iOS needed

    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle when user taps on the local notification
        print("User tapped on local notification: ${details.payload}");
      },
    );

    // 5. Foreground Message Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // If notification is available and we are on Android
      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              // other properties...
            ),
          ),
        );
      }
    });

    // 6. Save Token
    await _saveDeviceToken();
    
    // 7. Background Message Handler (Optional for tapping logic)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
       print('A new onMessageOpenedApp event was published!');
       // Navigator.pushNamed(context, '/message', arguments: message);
    });
  }

  Future<void> updateUserToken() async {
    await _saveDeviceToken();
  }

  Future<void> _saveDeviceToken() async {
    String? token = await _firebaseMessaging.getToken();
    String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (token != null && uid != null) {
      print("FCM Token: $token");
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
      });
    }
  }

  // --- ADMIN SIDE: Send Notification (HTTP v1 API) ---
  
  Future<String> _getAccessToken() async {
    final accountCredentials = ServiceAccountCredentials.fromJson(_serviceAccount);
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final client = await clientViaServiceAccount(accountCredentials, scopes);
    return client.credentials.accessToken.data;
  }

  Future<void> sendPushNotification({
    required String recipientToken,
    required String title,
    required String body,
  }) async {
    try {
      final String accessToken = await _getAccessToken();
      final String projectId = _serviceAccount['project_id'];
      final String endpoint = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final response = await http.post(
        Uri.parse(endpoint),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(
          <String, dynamic>{
            'message': <String, dynamic>{
              'token': recipientToken,
              'notification': <String, dynamic>{
                'title': title,
                'body': body,
              },
              'data': <String, dynamic>{
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                'status': 'done'
              }
            }
          },
        ),
      );

      if (response.statusCode == 200) {
        print('FCM Notification sent successfully!');
      } else {
        print('Failed to send FCM: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error sending FCM notification: $e');
    }
  }

  Future<String?> getUserToken(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.get('fcmToken');
      }
    } catch (e) {
      print("Error fetching user token: $e");
    }
    return null;
  }
}
