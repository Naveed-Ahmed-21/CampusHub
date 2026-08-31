import 'api_exception.dart';

sealed class ApiResult<T> {
  const ApiResult();

  const factory ApiResult.success(T data) = ApiResultSuccess<T>;
  const factory ApiResult.failure(ApiException error) = ApiResultFailure<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(ApiException error) failure,
  }) {
    if (this is ApiResultSuccess<T>) {
      return success((this as ApiResultSuccess<T>).data);
    } else if (this is ApiResultFailure<T>) {
      return failure((this as ApiResultFailure<T>).error);
    }
    throw StateError('Unknown ApiResult subtype: $this');
  }

  bool get isSuccess => this is ApiResultSuccess<T>;
  bool get isFailure => this is ApiResultFailure<T>;

  T? get dataOrNull => this is ApiResultSuccess<T> ? (this as ApiResultSuccess<T>).data : null;
  ApiException? get errorOrNull => this is ApiResultFailure<T> ? (this as ApiResultFailure<T>).error : null;
}

class ApiResultSuccess<T> extends ApiResult<T> {
  final T data;
  const ApiResultSuccess(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiResultSuccess<T> && runtimeType == other.runtimeType && data == other.data;

  @override
  int get hashCode => data.hashCode;
}

class ApiResultFailure<T> extends ApiResult<T> {
  final ApiException error;
  const ApiResultFailure(this.error);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiResultFailure<T> && runtimeType == other.runtimeType && error == other.error;

  @override
  int get hashCode => error.hashCode;
}
