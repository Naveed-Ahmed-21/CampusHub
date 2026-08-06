
import 'package:freezed_annotation/freezed_annotation.dart';
import 'api_exception.dart';

part 'api_result.freezed.dart';

@freezed
sealed class ApiResult<T> with _$ApiResult<T> {
  const factory ApiResult.success(T data) = ApiResultSuccess<T>;
  const factory ApiResult.failure(ApiException error) = ApiResultFailure<T>;
}
