import 'dart:async';

import 'package:echox/src/handler/callback.dart';
import 'package:echox/src/plugins/starttls/starttls.dart';
import 'package:echox/src/stanza/features.dart';
import 'package:echox/src/stream/base.dart';
import 'package:echox/src/stream/matcher/xpath.dart';
import 'package:echox/src/whixp.dart';

class Whixp extends WhixpBase {
  Whixp(
    String jabberID, {
    super.host,
    super.port,
    this.language = 'en',
    super.useTLS = false,
  }) : super(jabberID: jabberID) {
    setup();
  }

  void setup() {
    reset();

    /// Set [streamHeader] of declared transport for initial send.
    transport.streamHeader =
        "<stream:stream to='${boundJID.host}' xmlns:stream='$streamNamespace' xmlns='$defaultNamespace' xml:lang='$language' version='1.0'>";

    transport
      ..registerStanza(StreamFeatures())
      ..registerHandler(
        FutureCallbackHandler(
          'Stream Features',
          (stanza) => _handleStreamFeatures(stanza),
          matcher: XPathMatcher('<features xmlns="$streamNamespace"/>'),
        ),
      );

    registerPlugin('starttls', FeatureStartTLS(base: this));
  }

  void reset() {
    streamFeatureHandlers.clear();
  }

  /// Default language to use in stanza communication.
  final String language;

  Future<bool?> _handleStreamFeatures(StanzaBase features) async {
    for (final feature in streamFeatureHandlers.entries) {
      final name = feature.key;

      if ((features['features'] as Map<String, XMLBase>).containsKey(name) &&
          (features['features'] as Map<String, XMLBase>)['name'] != null) {
        final handler = streamFeatureHandlers['name']!.value1;
        final restart = streamFeatureHandlers['name']!.value2;

        final result = await handler(features);
        if (result != null && restart) {
          return true;
        }
      }
    }

    return null;
  }

  void connect() {
    transport.connect();
  }
}