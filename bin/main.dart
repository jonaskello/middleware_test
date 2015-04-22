import 'dart:io';
import 'dart:async';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_proxy/shelf_proxy.dart' as proxy;

class CopiedRequest extends Request {

  List<List<int>> _body;
  Request _request;

  CopiedRequest(Request request, [Uri requestedUri]) : super(
      request.method,
      requestedUri != null ? requestedUri : request.requestedUri,
      protocolVersion: request.protocolVersion,
      headers: request.headers, handlerPath: request.handlerPath,
      //url: request.url,
      encoding: request.encoding, context: request.context) {
    _request = request;
  }

  Future copyBody() async {
    _body = await _request.read().toList();
  }

  @override Stream<List<int>> read() {
    return new Stream.fromIterable(_body);
  }

}

Handler copyRequestMiddleware(Handler innerHandler) {
  return (Request req) async {
    var copiedRequest = new CopiedRequest(req);
    await copiedRequest.copyBody();
    return innerHandler(copiedRequest);
  };

}

Handler middleware(Handler innerHandler) {
  return (Request req) async {

    Request nextRequest = req;
    if (req.method == "GET" && (req.headers["accept"] == 'html' || req.headers["accept"] == '*/*')) {
      var copied = new CopiedRequest(req, req.requestedUri.replace(path: "/default.aspx")) ;
      await copied.copyBody();
      nextRequest = copied;
    }
    return innerHandler(nextRequest);
  };
}

void main() {

  Handler proxyHandler = proxy.proxyHandler("http://www.divid.se/does_not_exist");

  var rewriteToIndexHandler = new Pipeline()
  .addMiddleware(middleware)
  .addHandler(proxyHandler);

  Handler cascadeHandler = new Cascade()
  .add(proxyHandler)
  .add(rewriteToIndexHandler)
  .handler;

  Handler handler = const Pipeline()
  .addMiddleware(copyRequestMiddleware)
  .addHandler(cascadeHandler);

  io.serve(handler, InternetAddress.ANY_IP_V4, 1234).then((server) {
    print('Serving at http://${server.address.host}:${server.port}');
  });

}

