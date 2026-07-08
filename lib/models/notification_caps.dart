/// Parsed notification service capabilities from endpoint 0x001e caps reply.
class NotificationCaps {
  final int version;
  final bool supportsPictures;
  final bool supportsNotificationKey;

  const NotificationCaps({
    this.version = 4,
    this.supportsPictures = false,
    this.supportsNotificationKey = false,
  });

  static const v4 = NotificationCaps();
}
