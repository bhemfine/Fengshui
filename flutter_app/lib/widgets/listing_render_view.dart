import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:inkstone_engine/inkstone_engine.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../data/listing_fetch.dart';

/// Result of rendering a listing page in a WebView on the phone.
class RenderResult {
  const RenderResult({required this.text, required this.html, required this.url, required this.blocked});
  final String text;
  final String html;
  final String url;
  final bool blocked;
}

/// Loads a listing page in a small, visible WebView (so a "verify you are
/// human" check, if shown, can be tapped by the user), waits for the listing
/// facts to appear, then hands back the page text. Cookies, cache and local
/// storage are cleared afterwards. Nothing is stored or logged.
class ListingRenderView extends StatefulWidget {
  const ListingRenderView({super.key, required this.site, required this.url, required this.onDone});
  final ListingSite site;
  final String url;
  final ValueChanged<RenderResult> onDone;

  @override
  State<ListingRenderView> createState() => _ListingRenderViewState();
}

class _ListingRenderViewState extends State<ListingRenderView> {
  late final WebViewController _c;
  Timer? _poll;
  final _started = DateTime.now();
  bool _done = false;
  bool _challenge = false;
  String _url = '';

  static const _timeout = Duration(seconds: 40);

  @override
  void initState() {
    super.initState();
    _url = widget.url;
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(ListingFetcher.browserUserAgent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onUrlChange: (c) => _url = c.url ?? _url,
          onNavigationRequest: (r) =>
              r.url.startsWith('http') ? NavigationDecision.navigate : NavigationDecision.prevent,
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
    _poll = Timer.periodic(const Duration(milliseconds: 1500), (_) => _check());
  }

  bool _ready(String t) => switch (widget.site) {
    ListingSite.hdbPortal => t.contains('Storey range') || t.contains('Remaining lease'),
    ListingSite.propertyGuru =>
      t.contains('Listing ID') || t.contains('Property details') || t.contains('Project details'),
    ListingSite.ninetyNine => t.contains('Built year') || t.contains('Floor Level') || t.contains('Property type'),
  };

  static String _str(Object? r) {
    if (r is String) {
      if (r.length >= 2 && r.startsWith('"')) {
        try {
          return jsonDecode(r) as String;
        } catch (_) {}
      }
      return r;
    }
    return '$r';
  }

  Future<void> _check() async {
    if (_done) return;
    String text = '';
    try {
      text = _str(await _c.runJavaScriptReturningResult('document.body ? document.body.innerText : ""'));
    } catch (_) {}
    final challenge =
        text.contains('Verify you are human') ||
        text.contains('Just a moment') ||
        text.contains('checking your browser') ||
        text.contains('Performing security verification');
    if (challenge != _challenge && mounted) setState(() => _challenge = challenge);
    final timedOut = DateTime.now().difference(_started) > _timeout;
    if (!_ready(text) && !timedOut) return;
    _done = true;
    _poll?.cancel();
    String html = '';
    try {
      html = _str(await _c.runJavaScriptReturningResult('document.documentElement.outerHTML'));
    } catch (_) {}
    await _wipe();
    widget.onDone(RenderResult(text: text, html: html, url: _url, blocked: !_ready(text)));
  }

  Future<void> _wipe() async {
    try {
      await _c.clearCache();
      await _c.clearLocalStorage();
      await WebViewCookieManager().clearCookies();
    } catch (_) {}
  }

  @override
  void dispose() {
    _poll?.cancel();
    if (!_done) _wipe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_challenge)
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text('The site is checking this phone. If a box appears below, tap it to continue.'),
        ),
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(height: 260, child: WebViewWidget(controller: _c)),
      ),
    ],
  );
}
