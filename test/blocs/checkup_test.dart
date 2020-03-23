import 'package:covidnearme/src/blocs/checkup/checkup.dart';
import 'package:covidnearme/src/blocs/preferences/preferences.dart';
import 'package:covidnearme/src/data/repositories/checkups.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'CheckupBloc only responds to StartCheckup, UpdateCheckup, and '
      'CompleteCheckup', () async {
    final bloc = CheckupBloc();
    bloc.add(NotCheckupEvent());
    bloc.close();

    await expectLater(
      bloc,
      emitsInOrder(
        [
          const CheckupStateNotCreated(),
          emitsDone,
        ],
      ),
    );
  });

  test(
      'CheckupBloc does not update if CompleteCheckup is recieved in a state '
      'other than CheckupStateInProgress', () async {
    final bloc = CheckupBloc();
    bloc.add(CompleteCheckup());
    bloc.close();

    await expectLater(
      bloc,
      emitsInOrder(
        [
          const CheckupStateNotCreated(),
          emitsDone,
        ],
      ),
    );
  });

  test(
      'CheckupBloc does not update if UpdateCheckup is recieved in a state '
      'other than CheckupStateInProgress', () async {
    final bloc = CheckupBloc();
    bloc.add(UpdateCheckup());
    bloc.close();

    await expectLater(
      bloc,
      emitsInOrder(
        [
          const CheckupStateNotCreated(),
          emitsDone,
        ],
      ),
    );
  });

  test(
      'CheckupBloc starts checkup process when it receives a StartCheckup event',
      () async {
    final bloc = CheckupBloc(
      checkupsRepository: FakeCheckupsRepository(),
      preferencesState: FakePreferencesState(),
    );
    bloc.add(StartCheckup());
    bloc.close();

    await expectLater(
      bloc,
      emitsInOrder(
        [
          const CheckupStateNotCreated(),
          const CheckupStateCreating(),
          isA<CheckupStateInProgress>()
            ..having((s) => s.checkup, 'checkup', isNotNull),
          emitsDone,
        ],
      ),
    );
  });

  test(
      'CheckupBloc can update (no-op) checkup when it receives a StartCheckup, '
      'UpdateCheckup events', () async {
    final bloc = CheckupBloc(
      checkupsRepository: FakeCheckupsRepository(),
      preferencesState: FakePreferencesState(),
    );
    bloc.add(StartCheckup());
    bloc.add(UpdateCheckup());
    bloc.close();

    await expectLater(
      bloc,
      emitsInOrder(
        [
          const CheckupStateNotCreated(),
          const CheckupStateCreating(),
          isA<CheckupStateInProgress>()
            ..having((s) => s.checkup, 'checkup', isNotNull),
          isA<CheckupStateInProgress>()
            ..having((s) => s.checkup, 'checkup', isNotNull),
          emitsDone,
        ],
      ),
    );
  });

  test(
      'CheckupBloc can complete checkup after receiving StartCheckup, '
      'CompleteCheckup events', () async {
    final bloc = CheckupBloc(
      checkupsRepository: FakeCheckupsRepository(),
      preferencesState: FakePreferencesState(),
    );
    bloc.add(StartCheckup());
    bloc.add(CompleteCheckup());
    bloc.close();

    await expectLater(
      bloc,
      emitsInOrder(
        [
          const CheckupStateNotCreated(),
          const CheckupStateCreating(),
          isA<CheckupStateInProgress>()
            ..having((s) => s.checkup, 'checkup', isNotNull),
          const CheckupStateCompleting(),
          isA<CheckupStateCompleted>()
            ..having((s) => s.assessment, 'assessment', isNotNull),
          emitsDone,
        ],
      ),
    );
  });
}

class NotCheckupEvent extends CheckupEvent {}

class FakeCheckupsRepository implements CheckupsRepository {
  FakeCheckupsRepository({
    this.assessment,
    this.checkup,
  });

  final Assessment assessment;
  final Checkup checkup;

  @override
  Future<Assessment> completeCheckup(String id) async {
    return assessment ?? Assessment();
  }

  @override
  Future<Checkup> createCheckup(Checkup checkup) async {
    return checkup ?? Checkup();
  }

  @override
  Future<Checkup> updateCheckup(Checkup updatedCheckup) async {
    return checkup ?? Checkup();
  }
}

class FakePreferencesState implements PreferencesState {
  @override
  Preferences get preferences => Preferences(userId: '1');
}
