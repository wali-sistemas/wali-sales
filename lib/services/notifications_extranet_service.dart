import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotificationsExtranet() async {
  var status = await Permission.notification.status;
  if (!status.isGranted) {
    status = await Permission.notification.request();
  }

  if (status.isGranted) {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings darwinInitializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: darwinInitializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  } else {
    //print("Permiso de notificaciones denegado.");
  }
}

Future<void> showNotification(dynamic order) async {
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
    'your_channel_id',
    'your_channel_name',
    importance: Importance.max,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    playSound: true,
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
  );

  final numberFormat = new NumberFormat.simpleCurrency();
  String docTotalTxt = numberFormat.format(order["docTotal"]);
  if (docTotalTxt.contains('.')) {
    int decimalIndex = docTotalTxt.indexOf('.');
    docTotalTxt = docTotalTxt.substring(0, decimalIndex);
  }

  await flutterLocalNotificationsPlugin.show(
    1,
    'Pedido Extranet ' + order["docNum"],
    order["docDate"] +
        ' Valor:' +
        docTotalTxt.toString() +
        '\n' +
        order["cardCode"] +
        ' ' +
        order["cardName"],
    notificationDetails,
  );
}
