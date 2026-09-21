sealed class Failure {
  final String message;
  final Object? cause;

  const Failure(this.message, [this.cause]);

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.cause]);
}

class SshFailure extends Failure {
  const SshFailure(super.message, [super.cause]);
}

class CgiTriggerFailure extends Failure {
  const CgiTriggerFailure(super.message, [super.cause]);
}

class PortVerificationFailure extends Failure {
  const PortVerificationFailure(super.message, [super.cause]);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message, [super.cause]);
}

class ParsingFailure extends Failure {
  const ParsingFailure(super.message, [super.cause]);
}
