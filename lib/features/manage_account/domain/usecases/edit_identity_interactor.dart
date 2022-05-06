import 'dart:core';

import 'package:core/core.dart';
import 'package:dartz/dartz.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:tmail_ui_user/features/manage_account/domain/model/edit_identity_request.dart';
import 'package:tmail_ui_user/features/manage_account/domain/repository/manage_account_repository.dart';
import 'package:tmail_ui_user/features/manage_account/domain/state/edit_identity_state.dart';

class EditIdentityInteractor {
  final ManageAccountRepository manageAccountRepository;

  EditIdentityInteractor(this.manageAccountRepository);

  Stream<Either<Failure, Success>> execute(AccountId accountId, EditIdentityRequest identityRequest) async* {
    try {
      final newIdentity = await manageAccountRepository.editIdentity(accountId, identityRequest);
      yield Right(EditIdentitySuccess(newIdentity));
    } catch (exception) {
      yield Left(EditIdentityFailure(exception));
    }
  }
}