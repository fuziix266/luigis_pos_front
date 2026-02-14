import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/api_client.dart';

// Events
abstract class CatalogEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadCatalog extends CatalogEvent {}

// States
abstract class CatalogState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CatalogInitial extends CatalogState {}

class CatalogLoading extends CatalogState {}

class CatalogLoaded extends CatalogState {
  final List<dynamic> pizzas;
  final List<dynamic> ingredients;
  final List<dynamic> drinks;
  final List<dynamic> sides;
  final List<dynamic> sizes;
  final List<dynamic> promos;
  final Map<String, dynamic>? promoToday;

  CatalogLoaded({
    required this.pizzas,
    required this.ingredients,
    required this.drinks,
    required this.sides,
    required this.sizes,
    required this.promos,
    this.promoToday,
  });

  @override
  List<Object?> get props => [
    pizzas,
    ingredients,
    drinks,
    sides,
    sizes,
    promos,
    promoToday,
  ];
}

class CatalogError extends CatalogState {
  final String message;
  CatalogError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  final ApiClient apiClient;

  CatalogBloc(this.apiClient) : super(CatalogInitial()) {
    on<LoadCatalog>(_onLoad);
  }

  Future<void> _onLoad(LoadCatalog event, Emitter<CatalogState> emit) async {
    emit(CatalogLoading());
    try {
      final results = await Future.wait([
        apiClient.getPizzas(),
        apiClient.getIngredients(),
        apiClient.getDrinks(),
        apiClient.getSides(),
        apiClient.getSizes(),
        apiClient.getPromos(),
      ]);

      Map<String, dynamic>? promoToday;
      try {
        promoToday = await apiClient.getPromoToday();
      } catch (_) {}

      emit(
        CatalogLoaded(
          pizzas: results[0],
          ingredients: results[1],
          drinks: results[2],
          sides: results[3],
          sizes: results[4],
          promos: results[5],
          promoToday: promoToday,
        ),
      );
    } catch (e) {
      emit(CatalogError('Error cargando catálogo: ${e.toString()}'));
    }
  }
}
