/// Phone or app notification event from Android.
class BandAlertEvent {
  final String type;
  final String? packageId;
  final int? notificationId;
  final String? title;
  final String? body;
  final String? callerName;
  final String? callerNumber;

  const BandAlertEvent({
    required this.type,
    this.packageId,
    this.notificationId,
    this.title,
    this.body,
    this.callerName,
    this.callerNumber,
  });

  factory BandAlertEvent.fromMap(Map<dynamic, dynamic> map) => BandAlertEvent(
        type: map['type'] as String? ?? '',
        packageId: map['package'] as String?,
        notificationId: (map['id'] as num?)?.toInt(),
        title: map['title'] as String?,
        body: map['body'] as String?,
        callerName: map['callerName'] as String?,
        callerNumber: map['callerNumber'] as String?,
      );

  bool get isCallRing => type == 'call_ring';
  bool get isCallEnd => type == 'call_end';
  bool get isAppNotification => type == 'app_notification';
}
