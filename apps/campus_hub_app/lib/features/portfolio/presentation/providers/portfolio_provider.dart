import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/portfolio_repository.dart';
import '../../domain/portfolio_models.dart';

final userPortfolioProvider = FutureProvider.autoDispose<PortfolioModel>((ref) async {
  final repo = ref.watch(portfolioRepositoryProvider);
  return repo.getUserPortfolio();
});

final publicPortfolioProvider = FutureProvider.autoDispose.family<PortfolioModel, String>((ref, identifier) async {
  final repo = ref.watch(portfolioRepositoryProvider);
  return repo.getPublicPortfolio(identifier);
});
