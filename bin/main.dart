/*
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_static/shelf_static.dart';

Handler middleware(Handler innerHandler) {
  return (Request req) {
    var x = req.requestedUri;
    if (req.method == "GET" && req.headers["xxx"] == 'yyy') {
      // ...
    } else {
      return innerHandler(req);
    }
  };
}

main() {

  var staticHandler = createStaticHandler('/Users/JonKel', defaultDocument: 'index.html');

  var handler = const Pipeline()
  .addMiddleware(middleware)
//  .addHandler((request) => new Response.ok("success"));
  .addHandler(staticHandler);

  serve(handler, 'localhost', 1234);

//serve(middleware(handler), 'localhost', 1234);

//  serve(middleware((request) {
//    if(request.method == "GET") {
//      // ...
//    }
//    return new Response.ok("success");
//  }), 'localhost', 1234);
}

*/


import 'dart:io';
import 'dart:async';
//import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_proxy/shelf_proxy.dart' as proxy;

import 'history_api_fallback_middleware.dart';

Future main() async {

  //var authMiddleware = await auth_helper.createAuthMiddleware();

  Handler authenticatedApiHandler = const Pipeline()
  .addMiddleware(createMiddleware(requestHandler: (Request request) {
    // This middleware continues the pipeline if the request is for the API, otherwise it returns 404
    if (request.url.path.startsWith('api/')) {
      return null;
    }
    else {
//        print("Not an API call ${request.url.path}");
      return new Response.notFound("Not an API call");
    }
  }))
//  .addMiddleware(authMiddleware)
  .addHandler(_apiHandler);

//  Handler authenticatedFileHandler = const Pipeline()
//  .addMiddleware(createMiddleware(requestHandler: (Request request) {
//    // This middleware continues the pipeline if the request is for the API, otherwise it returns 404
//    if (request.url.path.startsWith('file')) {
//      return null;
//    }
//    else {
////        print("Not an API call ${request.url.path}");
//      return new Response.notFound("Not an file call");
//    }
//  }))
//  .addMiddleware(authMiddleware)
//  .addHandler(_fileHandler);


  Handler staticOrProxyHandler;
  staticOrProxyHandler = proxy.proxyHandler("http://localhost:63000/promaster/web/");

  var rewriteToIndexHandler = new Pipeline()
  .addMiddleware(new HistoryApiFallbackMiddleware().middleware)
  .addHandler(staticOrProxyHandler);


  // We need to enable anonymous access to the static script client, but authenticated access to API
  // so therefore we cascade the handlers so authentication will not be required for access to static client
  // Cascade calls the handlers in sequence, stopping at the first with acceptable reponse.
  // First we try authenticated API handler, if it does not return a good response, then use anonymous static handler.
  Handler cascadeHandler = new Cascade()
  .add(authenticatedApiHandler)
//    .add(authenticatedFileHandler)
  .add(staticOrProxyHandler)
  .add(rewriteToIndexHandler)
  .handler;

  Handler handler = const Pipeline()
//      .addMiddleware(logRequests())
//  .addMiddleware(exceptionResponse())
  .addHandler(cascadeHandler);

  io.serve(handler, InternetAddress.ANY_IP_V4, 1234).then((server) {
    print('Serving at http://${server.address.host}:${server.port}');
  });

}

Future<Response> _apiHandler(Request request) async {
//    var fileResponse = await _fileHandler(request);
//    if (fileResponse != null && fileResponse.statusCode == 200)
//      return fileResponse;
//  var response = _shelfRequestHandler.HandleShelfRequest(request);
//  return response;
  return new Response.notFound("Not API");
}

//Future<Response> _fileHandler(Request request) async {
//  if (!request.url.path.startsWith('file'))
//    return new Response.notFound("Not a file request");
//
//  if (!request.requestedUri.queryParameters.containsKey("id"))
//    return new Response.notFound("Must specify file id");
//
//  var id = request.requestedUri.queryParameters["id"];
//  var result = await _sqlQueryExecutor.execute("SELECT type, data FROM file WHERE id = @id", {
//    "id" : id
//  });
//
//  var file = result.singleAsList(false);
//  if (file == null)
//    return new Response.notFound("File with id " + id + " not found");
//  String contentType;
//  if (file[0] == "pdf")
//    contentType = "application/pdf";
//  else if (file[0] == "jpg")
//    contentType = "image/jpg";
//  else
//    return new Response.internalServerError();
//  var base64Encoded = CryptoUtils.base64StringToBytes(file[1]);
//  var stream = new Stream.fromIterable(new List<List<int>>()
//    ..add(base64Encoded));
//  return new Response.ok(stream, headers: {
//    'Content-Type' : contentType
//  });
//}

