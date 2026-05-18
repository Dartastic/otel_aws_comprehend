// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_aws_comprehend_suppression.dart';

const _tracerName = 'dartastic_otel_libs_aws_comprehend';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class AwsComprehendResult {
  const AwsComprehendResult({
    this.charactersProcessed,
    this.languageCode,
    this.sentiment,
    this.sentimentMixed,
    this.sentimentNegative,
    this.sentimentNeutral,
    this.sentimentPositive,
    this.entityCount,
    this.keyPhraseCount,
    this.piiEntityCount,
  });

  /// Comprehend bills per Unit (100 chars). Track the underlying char
  /// count so the cost calculator is just chars / 100.
  final int? charactersProcessed;
  final String? languageCode;

  /// `Sentiment` field — `POSITIVE`, `NEGATIVE`, `NEUTRAL`, `MIXED`.
  final String? sentiment;
  final double? sentimentMixed;
  final double? sentimentNegative;
  final double? sentimentNeutral;
  final double? sentimentPositive;
  final int? entityCount;
  final int? keyPhraseCount;
  final int? piiEntityCount;
}

class AwsComprehendCallResult<T> {
  const AwsComprehendCallResult({required this.value, this.result});
  final T value;
  final AwsComprehendResult? result;
}

/// Wraps an AWS Comprehend operation in a CLIENT span. [operation] is
/// the API method name (e.g. `DetectSentiment`, `DetectEntities`,
/// `DetectKeyPhrases`, `DetectPiiEntities`, `BatchDetectSentiment`,
/// `DetectDominantLanguage`).
Future<T> tracedAwsComprehend<T>({
  required String operation,
  required Future<AwsComprehendCallResult<T>> Function() invoke,
  String? languageCode,
  String? region,
}) async {
  if (awsComprehendInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'aws-api',
    'rpc.service': 'Comprehend',
    'rpc.method': operation,
  };
  if (languageCode != null) {
    m['aws.comprehend.request.language_code'] = languageCode;
  }
  if (region != null) m['cloud.region'] = region;

  final span = _tracer().startSpan(
    'comprehend $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.charactersProcessed != null) {
        extras.add(OTel.attributeInt(
          'aws.comprehend.characters_processed',
          r.result!.charactersProcessed!,
        ));
      }
      if (r.result!.languageCode != null) {
        extras.add(OTel.attributeString(
          'aws.comprehend.response.language_code',
          r.result!.languageCode!,
        ));
      }
      if (r.result!.sentiment != null) {
        extras.add(OTel.attributeString(
          'aws.comprehend.sentiment',
          r.result!.sentiment!,
        ));
      }
      if (r.result!.sentimentPositive != null) {
        extras.add(OTel.attributeDouble(
          'aws.comprehend.sentiment.positive',
          r.result!.sentimentPositive!,
        ));
      }
      if (r.result!.sentimentNegative != null) {
        extras.add(OTel.attributeDouble(
          'aws.comprehend.sentiment.negative',
          r.result!.sentimentNegative!,
        ));
      }
      if (r.result!.sentimentNeutral != null) {
        extras.add(OTel.attributeDouble(
          'aws.comprehend.sentiment.neutral',
          r.result!.sentimentNeutral!,
        ));
      }
      if (r.result!.sentimentMixed != null) {
        extras.add(OTel.attributeDouble(
          'aws.comprehend.sentiment.mixed',
          r.result!.sentimentMixed!,
        ));
      }
      if (r.result!.entityCount != null) {
        extras.add(OTel.attributeInt(
          'aws.comprehend.entity_count',
          r.result!.entityCount!,
        ));
      }
      if (r.result!.keyPhraseCount != null) {
        extras.add(OTel.attributeInt(
          'aws.comprehend.key_phrase_count',
          r.result!.keyPhraseCount!,
        ));
      }
      if (r.result!.piiEntityCount != null) {
        extras.add(OTel.attributeInt(
          'aws.comprehend.pii_entity_count',
          r.result!.piiEntityCount!,
        ));
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
