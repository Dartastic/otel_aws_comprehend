// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_aws_comprehend/otel_aws_comprehend.dart';

/// Traces Aws Comprehend calls with OpenTelemetry.
///
/// `otel_aws_comprehend` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Aws Comprehend call in
/// [tracedAwsComprehend]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'aws-comprehend-example');

  // Wraps an AWS Comprehend operation in a CLIENT span.
  final awsComprehendId = await tracedAwsComprehend<String>(
    operation: 'create',
    languageCode: 'en',
    region: 'us-east-1',
    invoke: () async {
      // Make the Aws Comprehend call here, then report what it returned.
      const id = 'aws_comprehend_8f3a2c';
      return const AwsComprehendCallResult(
          value: id,
          result: AwsComprehendResult(
              charactersProcessed: 1,
              languageCode: 'en',
              sentiment: 'POSITIVE',
              sentimentMixed: 0.5,
              sentimentNegative: 0.5,
              sentimentNeutral: 0.5,
              sentimentPositive: 0.5,
              entityCount: 3,
              keyPhraseCount: 3,
              piiEntityCount: 3));
    },
  );
  OTelLog.info('tracedAwsComprehend create returned $awsComprehendId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutAwsComprehendInstrumentationAsync.
  await runWithoutAwsComprehendInstrumentationAsync(
    () => tracedAwsComprehend<String>(
      operation: 'create',
      languageCode: 'en',
      region: 'us-east-1',
      invoke: () async {
        const id = 'aws_comprehend_8f3a2c';
        return const AwsComprehendCallResult(
            value: id,
            result: AwsComprehendResult(
                charactersProcessed: 1,
                languageCode: 'en',
                sentiment: 'POSITIVE',
                sentimentMixed: 0.5,
                sentimentNegative: 0.5,
                sentimentNeutral: 0.5,
                sentimentPositive: 0.5,
                entityCount: 3,
                keyPhraseCount: 3,
                piiEntityCount: 3));
      },
    ),
  );

  await OTel.shutdown();
}
