import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/api_client.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String username;
  final String password;
  LoginRequested(this.username, this.password);
  @override
  List<Object?> get props => [username, password];
}

class LogoutRequested extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final Map<String, dynamic> user;
  final String token;
  AuthAuthenticated(this.user, this.token);
  @override
  List<Object?> get props => [user, token];
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiClient apiClient;

  AuthBloc(this.apiClient) : super(AuthInitial()) {
    on<LoginRequested>(_onLogin);
    on<LogoutRequested>(_onLogout);
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await apiClient.login(event.username, event.password);
      if (response['success'] == true) {
        final data = response['data'];
        final token = data['token'];
        apiClient.setToken(token);
        emit(AuthAuthenticated(data['user'], token));
      } else {
        emit(AuthError(response['error'] ?? 'Error de autenticación'));
      }
    } catch (e) {
      emit(AuthError('Error de conexión: ${e.toString()}'));
    }
  }

  void _onLogout(LogoutRequested event, Emitter<AuthState> emit) {
    apiClient.clearToken();
    emit(AuthInitial());
  }
}
