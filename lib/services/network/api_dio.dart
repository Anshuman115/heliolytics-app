import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/utils/app_logger.dart';

final apiDioProvider = Provider<Dio>((ref) => AppLogger.instance.createApiDio());
