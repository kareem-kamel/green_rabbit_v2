abstract class AppFailure implements Exception {
  final String message;
  const AppFailure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends AppFailure {
  const ServerFailure(super.message);
}

class CacheFailure extends AppFailure {
  const CacheFailure(super.message);
}

class NoInternetFailure extends AppFailure {
  const NoInternetFailure([super.message = "No internet connection. Please try again."]);
}
