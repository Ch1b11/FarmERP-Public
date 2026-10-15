import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/employee.dart';
import '../../../finance/domain/entities/finance_account.dart';
import '../../../finance/domain/usecases/get_finance_accounts_usecase.dart';
import '../../domain/entities/work_period.dart';
import '../../domain/usecases/add_bonus_usecase.dart';
import '../../domain/usecases/add_withdrawal_usecase.dart';
import '../../domain/usecases/complete_and_settle_period_usecase.dart';
import '../../domain/usecases/deactivate_employee_usecase.dart';
import '../../domain/usecases/delete_employee_usecase.dart';
import '../../domain/usecases/discard_offline_work_period_usecase.dart';
import '../../domain/usecases/get_active_work_period_usecase.dart';
import '../../domain/usecases/get_employee_by_id_usecase.dart';
import '../../domain/usecases/get_work_period_history_usecase.dart';
import '../../domain/usecases/start_work_period_usecase.dart';
import 'employee_profile_event.dart';
import 'employee_profile_state.dart';

class EmployeeProfileBloc
    extends Bloc<EmployeeProfileEvent, EmployeeProfileState> {
  final GetEmployeeByIdUseCase getEmployeeByIdUseCase;
  final GetActiveWorkPeriodUseCase getActiveWorkPeriodUseCase;
  final GetWorkPeriodHistoryUseCase getWorkPeriodHistoryUseCase;
  final GetFinanceAccountsUseCase getFinanceAccountsUseCase;
  final StartWorkPeriodUseCase startWorkPeriodUseCase;
  final AddWithdrawalUseCase addWithdrawalUseCase;
  final AddBonusUseCase addBonusUseCase;
  final CompleteAndSettlePeriodUseCase completeAndSettlePeriodUseCase;
  final DeleteEmployeeUseCase deleteEmployeeUseCase;
  final DeactivateEmployeeUseCase deactivateEmployeeUseCase;
  final DiscardOfflineWorkPeriodUseCase? discardOfflineWorkPeriodUseCase;

  StreamSubscription<List<WorkPeriod>>? _historySubscription;
  StreamSubscription<WorkPeriod?>? _activePeriodSubscription;

  EmployeeProfileBloc({
    required this.getEmployeeByIdUseCase,
    required this.getActiveWorkPeriodUseCase,
    required this.getWorkPeriodHistoryUseCase,
    required this.getFinanceAccountsUseCase,
    required this.startWorkPeriodUseCase,
    required this.addWithdrawalUseCase,
    required this.addBonusUseCase,
    required this.completeAndSettlePeriodUseCase,
    required this.deleteEmployeeUseCase,
    required this.deactivateEmployeeUseCase,
    this.discardOfflineWorkPeriodUseCase,
  }) : super(EmployeeProfileInitial()) {
    on<ProfileLoadRequested>(_onProfileLoadRequested);
    on<ProfileDeleteRequested>(_onProfileDeleteRequested);
    on<ProfileDeactivateRequested>(_onProfileDeactivateRequested);
    on<StartWorkPeriodSubmitted>(_onStartWorkPeriodSubmitted);
    on<WithdrawalSubmitted>(_onWithdrawalSubmitted);
    on<BonusSubmitted>(_onBonusSubmitted);
    on<PeriodCompletionSubmitted>(_onPeriodCompletionSubmitted);
    on<DiscardWorkPeriodRequested>(_onDiscardWorkPeriodRequested);
    on<WorkHistoryUpdated>(_onWorkHistoryUpdated);
    on<ActivePeriodUpdated>(_onActivePeriodUpdated);
  }

  Future<void> _onProfileLoadRequested(
    ProfileLoadRequested event,
    Emitter<EmployeeProfileState> emit,
  ) async {
    _historySubscription?.cancel();
    _historySubscription = getWorkPeriodHistoryUseCase
        .watch(event.employeeId)
        .listen((updatedHistory) {
          add(WorkHistoryUpdated(updatedHistory));
        });

    _activePeriodSubscription?.cancel();
    _activePeriodSubscription = getActiveWorkPeriodUseCase
        .watch(event.employeeId)
        .listen((updatedActivePeriod) {
          add(ActivePeriodUpdated(updatedActivePeriod));
        });

    final cachedEmployeeRes = await getEmployeeByIdUseCase.getCached(
      event.employeeId,
    );
    final cachedPeriodRes = await getActiveWorkPeriodUseCase.getCached(
      event.employeeId,
    );
    final cachedHistoryRes = await getWorkPeriodHistoryUseCase.getCached(
      event.employeeId,
    );
    final cachedFinanceRes = await getFinanceAccountsUseCase.getCached();

    final cachedEmployee = cachedEmployeeRes.fold((_) => null, (e) => e);
    final cachedPeriod = cachedPeriodRes.fold((_) => null, (p) => p);
    final cachedHistory = cachedHistoryRes.fold(
      (_) => <WorkPeriod>[],
      (h) => h,
    );
    final cachedFinance = cachedFinanceRes.fold(
      (_) => <FinanceAccount>[],
      (a) => a,
    );

    if (cachedEmployee != null) {
      emit(
        EmployeeProfileLoaded(
          employee: cachedEmployee,
          activePeriod: cachedPeriod,
          workHistory: cachedHistory,
          financeAccounts: cachedFinance,
        ),
      );
    } else {
      if (state is! EmployeeProfileLoaded) {
        emit(EmployeeProfileLoading());
      }
    }

    Employee? effectiveEmployee = cachedEmployee;
    if (effectiveEmployee == null) {
      try {
        final employeeResult = await getEmployeeByIdUseCase(event.employeeId);
        effectiveEmployee = await employeeResult.fold(
          (failure) async {
            if (state is! EmployeeProfileLoaded) {
              emit(EmployeeProfileError(failure.message));
            }
            return null;
          },
          (employee) async {

            if (state is! EmployeeProfileLoaded) {
              emit(
                EmployeeProfileLoaded(
                  employee: employee,
                  activePeriod: cachedPeriod,
                  workHistory: cachedHistory,
                  financeAccounts: cachedFinance,
                ),
              );
            }
            return employee;
          },
        );
        if (effectiveEmployee == null) return;
      } catch (e) {
        if (state is! EmployeeProfileLoaded) {
          emit(EmployeeProfileError(e.toString()));
        }
        return;
      }
    }

    try {
      final periodFuture = getActiveWorkPeriodUseCase(event.employeeId);
      final historyFuture = getWorkPeriodHistoryUseCase(event.employeeId);

      final financeFuture = cachedFinance.isEmpty
          ? getFinanceAccountsUseCase()
          : Future.value(Right<Failure, List<FinanceAccount>>(cachedFinance));

      final results = await Future.wait([
        periodFuture,
        historyFuture,
        financeFuture,
      ]);

      if (state is EmployeeProfileLoaded) {
        final currentLoaded = state as EmployeeProfileLoaded;
        final periodResult = results[0] as Either<Failure, WorkPeriod?>;
        final historyResult = results[1] as Either<Failure, List<WorkPeriod>>;
        final financeResult = results[2] as Either<Failure, List<FinanceAccount>>;

        final activePeriod = periodResult.fold(
          (_) => currentLoaded.activePeriod,
          (p) => p,
        );
        final workHistory = historyResult.fold(
          (_) => currentLoaded.workHistory,
          (h) => h,
        );
        final financeAccounts = financeResult.fold(
          (_) => currentLoaded.financeAccounts,
          (a) => a,
        );

        emit(
          currentLoaded.copyWith(
            activePeriod: activePeriod,
            workHistory: workHistory,
            financeAccounts: financeAccounts,
          ),
        );
      }
    } catch (_) {

    }
  }

  Future<void> _onProfileDeleteRequested(
    ProfileDeleteRequested event,
    Emitter<EmployeeProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EmployeeProfileLoaded) return;

    emit(currentState.copyWith(isSubmitting: true));

    final result = await deleteEmployeeUseCase(currentState.employee.id);
    result.fold(
      (failure) => emit(
        currentState.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(
        currentState.copyWith(
          isSubmitting: false,
          isDeleted: true,
          successMessage: 'employeeDeleted',
        ),
      ),
    );
  }

  Future<void> _onProfileDeactivateRequested(
    ProfileDeactivateRequested event,
    Emitter<EmployeeProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EmployeeProfileLoaded) return;

    emit(currentState.copyWith(isSubmitting: true));

    final result = await deactivateEmployeeUseCase(currentState.employee.id);
    result.fold(
      (failure) => emit(
        currentState.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(
        currentState.copyWith(
          isSubmitting: false,
          isDeleted: true,
          successMessage: 'employeeDeactivated',
        ),
      ),
    );
  }

  Future<void> _onStartWorkPeriodSubmitted(
    StartWorkPeriodSubmitted event,
    Emitter<EmployeeProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EmployeeProfileLoaded) return;

    emit(
      currentState.copyWith(
        isSubmitting: true,
        errorMessage: null,
        successMessage: null,
      ),
    );

    final result = await startWorkPeriodUseCase(
      employeeId: currentState.employee.id,
      arrivalDate: event.arrivalDate,
      arrivalTimeType: event.arrivalTimeType,
    );

    result.fold(
      (failure) {
        emit(
          currentState.copyWith(
            isSubmitting: false,
            errorMessage: failure.message,
          ),
        );
      },
      (newPeriod) {
        emit(
          currentState.copyWith(
            isSubmitting: false,
            activePeriod: newPeriod,
            successMessage: 'startWorkPeriodSuccess',
          ),
        );
      },
    );
  }

  Future<void> _onWithdrawalSubmitted(
    WithdrawalSubmitted event,
    Emitter<EmployeeProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EmployeeProfileLoaded) return;

    emit(
      currentState.copyWith(
        isSubmitting: true,
        errorMessage: null,
        successMessage: null,
      ),
    );

    final result = await addWithdrawalUseCase(
      periodId: event.periodId,
      amount: event.amount,
      date: event.date,
      notes: event.notes,
    );

    result.fold(
      (failure) {
        emit(
          currentState.copyWith(
            isSubmitting: false,
            errorMessage: failure.message,
          ),
        );
      },
      (updatedPeriod) {
        emit(
          currentState.copyWith(
            isSubmitting: false,
            activePeriod: updatedPeriod,
            successMessage: 'withdrawalAddedSuccess',
          ),
        );
      },
    );
  }

  Future<void> _onBonusSubmitted(
    BonusSubmitted event,
    Emitter<EmployeeProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EmployeeProfileLoaded) return;

    emit(
      currentState.copyWith(
        isSubmitting: true,
        errorMessage: null,
        successMessage: null,
      ),
    );

    final result = await addBonusUseCase(
      periodId: event.periodId,
      amount: event.amount,
      date: event.date,
      notes: event.notes,
    );

    result.fold(
      (failure) {
        emit(
          currentState.copyWith(
            isSubmitting: false,
            errorMessage: failure.message,
          ),
        );
      },
      (updatedPeriod) {
        emit(
          currentState.copyWith(
            isSubmitting: false,
            activePeriod: updatedPeriod,
            successMessage: 'bonusAddedSuccess',
          ),
        );
      },
    );
  }

  Future<void> _onPeriodCompletionSubmitted(
    PeriodCompletionSubmitted event,
    Emitter<EmployeeProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EmployeeProfileLoaded) return;

    emit(
      currentState.copyWith(
        isSubmitting: true,
        errorMessage: null,
        successMessage: null,
      ),
    );

    final result = await completeAndSettlePeriodUseCase(
      periodId: event.periodId,
      departureDate: event.departureDate,
      accountId: event.accountId,
    );

    result.fold(
      (failure) {
        emit(
          currentState.copyWith(
            isSubmitting: false,
            errorMessage: failure.message,
          ),
        );
      },
      (period) {
        final updatedHistory = [
          period,
          ...currentState.workHistory.where((w) => w.id != period.id),
        ];
        emit(
          currentState.copyWith(
            isSubmitting: false,
            clearActivePeriod: true,
            workHistory: updatedHistory,
            successMessage: 'periodCompletedSuccess',
          ),
        );
      },
    );
  }

  Future<void> _onDiscardWorkPeriodRequested(
    DiscardWorkPeriodRequested event,
    Emitter<EmployeeProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! EmployeeProfileLoaded) return;

    if (discardOfflineWorkPeriodUseCase != null) {
      await discardOfflineWorkPeriodUseCase!(event.periodId);
    }

    final isActive = currentState.activePeriod?.id == event.periodId;
    final updatedHistory = currentState.workHistory
        .where((w) => w.id != event.periodId)
        .toList();

    emit(
      currentState.copyWith(
        clearActivePeriod: isActive,
        workHistory: updatedHistory,
        successMessage: 'offlineRecordDiscarded',
      ),
    );
  }

  void _onWorkHistoryUpdated(
    WorkHistoryUpdated event,
    Emitter<EmployeeProfileState> emit,
  ) {
    final currentState = state;
    if (currentState is EmployeeProfileLoaded) {
      final history = event.history.cast<WorkPeriod>();
      emit(currentState.copyWith(workHistory: history));
    }
  }

  void _onActivePeriodUpdated(
    ActivePeriodUpdated event,
    Emitter<EmployeeProfileState> emit,
  ) {
    final currentState = state;
    if (currentState is EmployeeProfileLoaded) {
      final active = event.activePeriod as WorkPeriod?;
      if (active == null) {
        emit(currentState.copyWith(clearActivePeriod: true));
      } else {
        emit(currentState.copyWith(activePeriod: active));
      }
    }
  }

  @override
  Future<void> close() {
    _historySubscription?.cancel();
    _activePeriodSubscription?.cancel();
    return super.close();
  }
}
