import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heliolytics/core/utils/talker_log.dart';
import 'package:talker/talker.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';

const _hiddenHeaders = {'X-Heliolytics-Token', 'Authorization', 'Cookie'};

Dio createApiDio(Talker talker) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      validateStatus: (code) => code != null && code < 500,
    ),
  );
  if (!kReleaseMode) {
    dio.interceptors.add(
      TalkerDioLogger(
        talker: talker,
        settings: const TalkerDioLoggerSettings(
          printRequestHeaders: true,
          printResponseHeaders: false,
          printResponseMessage: true,
          printErrorHeaders: true,
          hiddenHeaders: _hiddenHeaders,
        ),
      ),
    );
  }
  return dio;
}

final apiDioProvider = Provider<Dio>((ref) {
  return createApiDio(ref.watch(talkerProvider));
});
