abstract class Failure {
  final String message;
  final int? statusCode;

  const Failure(this.message, [this.statusCode]);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, [super.statusCode]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection available', super.statusCode]);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, [super.statusCode]);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, [super.statusCode]);
}
