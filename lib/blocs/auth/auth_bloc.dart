import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:usa_in_ua/models/auth/domain/auth_failure.dart';
import 'package:usa_in_ua/models/auth/domain/i_auth_facade.dart';
import 'package:usa_in_ua/models/auth/domain/value_objects.dart';

part 'auth_event.dart';
part 'auth_state.dart';
part 'auth_bloc.freezed.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final IAuthFacade _authFacade;

  AuthBloc(this._authFacade) : super(AuthState.initial()) {
    on<PhoneNumberChanged>(
      (event, emit) async {
        emit(
          state.copyWith(
            phoneNumber: PhoneNumber(event.phoneNumber),
            authFailureOrSuccessOption: none(),
          ),
        );
      },
    );
    on<PasswordChanged>(
      (event, emit) async {
        emit(
          state.copyWith(
            password: Password(event.password),
            authFailureOrSuccessOption: none(),
          ),
        );
      },
    );
    on<EmailChanged>(
      (event, emit) async {
        emit(
          state.copyWith(
            emailAddress: EmailAddress(event.email),
            authFailureOrSuccessOption: none(),
          ),
        );
      },
    );
    on<UserNameChanged>(
      (event, emit) async {
        emit(
          state.copyWith(
            userName: UserName(event.userName),
            authFailureOrSuccessOption: none(),
          ),
        );
      },
    );
    on<VerifyPhoneNumber>(
      (event, emit) async {
        Either<AuthFailure, Unit>? failureOrSuccess;
        Either<AuthFailure, String>? getVarificationResult;

        if (state.phoneNumber.isValid() && state.emailAddress.isValid()) {
          emit(
            state.copyWith(
              isSubmitting: true,
              authFailureOrSuccessOption: none(),
            ),
          );

          getVarificationResult = await _authFacade.verifyPhoneNumber(
            phoneNumber: state.phoneNumber,
          );

          getVarificationResult.fold(
            (l) => failureOrSuccess = left(l),
            (r) => emit(
              state.copyWith(
                verificationId: r,
              ),
            ),
          );

          emit(
            state.copyWith(
              isSubmitting: false,
              authFailureOrSuccessOption: optionOf(failureOrSuccess),
            ),
          );
        }

        emit(
          state.copyWith(
            isSubmitting: false,
            showErrorMessages: true,
            authFailureOrSuccessOption: optionOf(failureOrSuccess),
          ),
        );
      },
    );
    on<VerifyOTP>((event, emit) async {
      Either<AuthFailure, Unit> authResult;

      emit(
        state.copyWith(
          isSubmitting: true,
          authFailureOrSuccessOption: none(),
        ),
      );

      authResult = await _authFacade.confirmOTP(
        verificationCode: state.verificationId,
        otpCode: event.otpCode,
      );

      emit(
        state.copyWith(
          isSubmitting: false,
          authFailureOrSuccessOption: some(authResult),
        ),
      );
    });
    on<SignInWithPhoneNumberAndPasswordPressed>(
      (event, emit) async {
        Either<AuthFailure, Unit>? failureOrSuccess;

        if (state.phoneNumber.isValid()) {
          emit(
            state.copyWith(
              isSubmitting: true,
              authFailureOrSuccessOption: none(),
            ),
          );

          failureOrSuccess = await _authFacade.signInWithPhoneNumberAndPassword(
            phoneNumber: state.phoneNumber,
            password: state.password,
          );

          emit(
            state.copyWith(
              isSubmitting: false,
              authFailureOrSuccessOption: some(failureOrSuccess),
            ),
          );
        }

        emit(
          state.copyWith(
            isSubmitting: false,
            showErrorMessages: true,
            authFailureOrSuccessOption: optionOf(failureOrSuccess),
          ),
        );
      },
    );
    on<SignInWithGooglePressed>(
      (event, emit) async {
        emit(
          state.copyWith(
            isSubmitting: true,
            authFailureOrSuccessOption: none(),
          ),
        );
        final failureOrSuccess = await _authFacade.signInWithGoogle();
        emit(
          state.copyWith(
            isSubmitting: false,
            authFailureOrSuccessOption: some(failureOrSuccess),
          ),
        );
      },
    );
  }
}
