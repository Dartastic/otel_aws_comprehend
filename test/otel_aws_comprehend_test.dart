// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_aws_comprehend/otel_aws_comprehend.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_aws_comprehend-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('DetectSentiment records sentiment scores', () async {
    await tracedAwsComprehend<String>(
      operation: 'DetectSentiment',
      languageCode: 'en',
      invoke: () async => const AwsComprehendCallResult(
        value: 'ok',
        result: AwsComprehendResult(
          charactersProcessed: 240,
          sentiment: 'POSITIVE',
          sentimentPositive: 0.82,
          sentimentNegative: 0.05,
          sentimentNeutral: 0.10,
          sentimentMixed: 0.03,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('comprehend DetectSentiment')!);
    expect(a['rpc.service'], 'Comprehend');
    expect(a['aws.comprehend.sentiment'], 'POSITIVE');
    expect(a['aws.comprehend.sentiment.positive'], 0.82);
    expect(a['aws.comprehend.characters_processed'], 240);
  });

  test('DetectPiiEntities records pii count', () async {
    await tracedAwsComprehend<String>(
      operation: 'DetectPiiEntities',
      invoke: () async => const AwsComprehendCallResult(
        value: 'ok',
        result:
            AwsComprehendResult(charactersProcessed: 200, piiEntityCount: 3),
      ),
    );
    final a = attrsOf(spans.findSpanByName('comprehend DetectPiiEntities')!);
    expect(a['aws.comprehend.pii_entity_count'], 3);
  });

  test('suppression skips spans', () async {
    await runWithoutAwsComprehendInstrumentationAsync(() async {
      await tracedAwsComprehend<String>(
        operation: 'DetectSentiment',
        invoke: () async => const AwsComprehendCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('comprehend '), isEmpty);
  });
}
