import 'api_error.dart';

/// Outcome of a call that can fail in an expected way. Repositories return
/// `Result` instead of throwing so view models must handle both branches.
sealed class Result<T> {
  const Result();

  /// Transforms the success value, keeping errors as they are.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Ok<T>(:final value) => Ok<R>(transform(value)),
        Err<T>(:final error) => Err<R>(error),
      };

  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };

  ApiError? get errorOrNull => switch (this) {
        Ok<T>() => null,
        Err<T>(:final error) => error,
      };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.error);
  final ApiError error;
}
