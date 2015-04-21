library promaster_app.shelf_server.history_api_fallback_middleware;

import 'dart:async';
import 'package:shelf/shelf.dart';

typedef Uri RewriteRule(Uri parsedUrl, Match match);

class Rewrite {
  final String from;
  final RewriteRule to;

  Rewrite(this.from, this.to);
}

class HistoryApiFallbackOptions {
  final String index;
  final List<Rewrite> rewrites;

  HistoryApiFallbackOptions({this.index: "/index.html", this.rewrites: const []});
}

class HistoryApiFallbackMiddleware {

  final HistoryApiFallbackOptions _options;

  HistoryApiFallbackMiddleware([HistoryApiFallbackOptions options = null])
  : _options = options != null ? options : new HistoryApiFallbackOptions();

  Middleware get middleware => _createHandler;

  Handler _createHandler(Handler innerHandler) {
    return (Request request) => _handle(request, innerHandler);
  }

  Future<Response> _handle(Request req, Handler innerHandler) async {

//    List<List<int>> body = await req.read().toList();
//    Request newReq = new Request(req.method, req.requestedUri,
//    protocolVersion: req.protocolVersion, headers: req.headers, handlerPath: req.handlerPath, url: req.url,
//    body: body, encoding:req.encoding, context: req.context);

    var headers = req.headers;
    if (req.method != 'GET') {
      logger("Not rewriting ${req.method} ${req.url} because the method is not GET.");
      return innerHandler(req);
    }
    else if (req.headers == null || req.headers["accept"].length == 0) {
      logger("Not rewriting ${req.method} ${req.url} because the client did not send an HTTP accept header.");
      return innerHandler(req);
    } else if (headers["accept"].indexOf('application/json') == 0) {
      logger("Not rewriting ${req.method} ${req.url} because the client prefers JSON.");
      return innerHandler(req);
    }
    else if (!acceptsHtml(headers["accept"])) {
      logger("Not rewriting ${req.method} ${req.url} because the client does not accept HTML.");
      return innerHandler(req);
    }

//      var parsedUrl = url.parse(req.url);
    var parsedUrl = req.requestedUri;
    var rewriteTarget;
    //_options.rewrites = _options.rewrites != null ? _options.rewrites : [];
    for (var i = 0; i < _options.rewrites.length; i++) {
      var rewrite = _options.rewrites[i];
      var match = parsedUrl.path.matchAsPrefix(rewrite.from);
      if (match != null) {
        rewriteTarget = evaluateRewriteRule(parsedUrl, match, rewrite.to);
        logger("Rewriting, ${req.method} ${req.url} to $rewriteTarget");
//          req.url = rewriteTarget;
        var newRequest = new Request("GET", rewriteTarget);
        return innerHandler(newRequest);
      }
    }

    if (parsedUrl.path.indexOf('.') != -1) {
      logger("Not rewriting ${req.method} ${req.url} because the path includes a dot (.) character.");
      return innerHandler(req);
    }

    rewriteTarget = _options.index; // != null ? _options.index : "/index.html";
    logger("Rewriting, ${req.method} ${req.url} to $rewriteTarget");
//      req.url = rewriteTarget;
//    var rewriteTarget2 = Uri.parse(rewriteTarget);
    var rewriteTarget2 = req.requestedUri.replace(path: rewriteTarget);
    var newRequest = new Request("GET", rewriteTarget2);
    return innerHandler(newRequest);

  }

//  dynamic _noRewriteReturn(Request request, Handler innerHandler) {
//    return new Response.notFound();
////    return innerHandler(request);
//  }

  Uri evaluateRewriteRule(Uri parsedUrl, Match match, RewriteRule rule) {
//  if (rule == String) {
//    return rule;
//  } else if (rule !== 'function') {
//    throw new Error('Rewrite rule can only be of type string of function.');
//  }

    return rule(parsedUrl, match);
  }

  bool acceptsHtml(header) {
    return header.indexOf('text/html') != -1 || header.indexOf('*/*') != -1;
  }

  void logger(String msg) {
    print(msg);
  }

}
