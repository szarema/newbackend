import 'dart:io';
import 'package:backend/middlewares/auth_middleware.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:postgres/postgres.dart';
import 'handlers/handlers.dart';

late final Connection db;

Future<void> init() async {
  db = await Connection.open(
    // Endpoint(
    //   host: 'localhost',
    //   port: 5432,
    //   database: 'pet_tracker',
    //   username: 'postgres',
    //   password: '296184gti',
    // ),

  //  Endpoint(
  //    host: 'metro.proxy.rlwy.net',
  //    port: 37194,
  //    database: 'railway',
  //    username: 'postgres',
  //    password: 'AwxBYujuwLYerRyyuDUgJOEUSrUMJiZj',
  //  ),
  //     settings: const ConnectionSettings(sslMode: SslMode.require),
  //
  // );


      Endpoint(
           host: 'centerbeam.proxy.rlwy.net',
           port: 12647,
           database: 'railway',
           username: 'postgres',
           password: 'VNAuXnkRGabzkWCjKoARxqZHFGEqSSFO',
         ),
            settings: const ConnectionSettings(sslMode: SslMode.require),

        );

  final router = Router();

  router.mount('/auth', authHandler(db).call);
  router.mount(
    '/pets',
    Pipeline()
        .addMiddleware(checkAuth())
        .addMiddleware(authGuard())
        .addHandler(petsHandler(db).call),
  );
  router.mount(
    '/health_notes',
    Pipeline()
        .addMiddleware(checkAuth())
        .addMiddleware(authGuard())
        .addHandler(healthNotesHandler(db).call),
  );
  router.mount(
    '/medical_records',
    Pipeline()
        .addMiddleware(checkAuth())
        .addMiddleware(authGuard())
        .addHandler(medicalRecordsHandler(db).call),
  );
  router.mount(
    '/notes',
    Pipeline()
        .addMiddleware(checkAuth())
        .addMiddleware(authGuard())
        .addHandler(notesHandler(db).call),
  );

  // router.mount(
  //   '/assistant',
  //   Pipeline()
  //       .addMiddleware(checkAuth())
  //       .addMiddleware(authGuard())
  //       .addHandler(assistantMessagesHandler(db).call),
  // );

  // router.mount(
  //   '/assistant',
  //   assistantMessagesHandler(db).call,
  // );

  router.mount('/assistant', assistantMessagesHandler(db).call);

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(router.call);

  final server = await serve(handler, InternetAddress.anyIPv4, 8080);
  print('API запущено по адресу http://${server.address.host}:${server.port}');
}
