import 'package:core/presentation/utils/app_toast.dart';
import 'package:core/presentation/utils/keyboard_utils.dart';
import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:core/utils/app_logger.dart';
import 'package:core/utils/platform_info.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/capability/capability_identifier.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/properties/properties.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:jmap_dart_client/jmap/core/unsigned_int.dart';
import 'package:jmap_dart_client/jmap/identities/identity.dart';
import 'package:jmap_dart_client/jmap/mail/email/email_address.dart';
import 'package:model/extensions/email_address_extension.dart';
import 'package:model/extensions/identity_extension.dart';
import 'package:model/user/user_profile.dart';
import 'package:rich_text_composer/rich_text_composer.dart';
import 'package:tmail_ui_user/features/base/base_controller.dart';
import 'package:tmail_ui_user/features/composer/presentation/controller/rich_text_web_controller.dart';
import 'package:tmail_ui_user/features/identity_creator/presentation/extesions/size_extension.dart';
import 'package:tmail_ui_user/features/identity_creator/presentation/model/identity_creator_arguments.dart';
import 'package:tmail_ui_user/features/identity_creator/presentation/utils/identity_creator_constants.dart';
import 'package:tmail_ui_user/features/mailbox_creator/domain/model/verification/email_address_validator.dart';
import 'package:tmail_ui_user/features/mailbox_creator/domain/model/verification/empty_name_validator.dart';
import 'package:tmail_ui_user/features/mailbox_creator/domain/state/verify_name_view_state.dart';
import 'package:tmail_ui_user/features/mailbox_creator/domain/usecases/verify_name_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_creator/presentation/extensions/validator_failure_extension.dart';
import 'package:tmail_ui_user/features/manage_account/domain/model/create_new_identity_request.dart';
import 'package:tmail_ui_user/features/manage_account/domain/model/edit_identity_request.dart';
import 'package:tmail_ui_user/features/manage_account/domain/state/get_all_identities_state.dart';
import 'package:tmail_ui_user/features/manage_account/domain/usecases/get_all_identities_interactor.dart';
import 'package:tmail_ui_user/features/manage_account/presentation/extensions/identity_extension.dart';
import 'package:tmail_ui_user/features/manage_account/presentation/model/identity_action_type.dart';
import 'package:tmail_ui_user/features/manage_account/presentation/profiles/identities/utils/identity_utils.dart';
import 'package:tmail_ui_user/main/error/capability_validator.dart';
import 'package:tmail_ui_user/main/localizations/app_localizations.dart';
import 'package:tmail_ui_user/main/routes/route_navigation.dart';
import 'package:uuid/uuid.dart';

class IdentityCreatorController extends BaseController {

  final VerifyNameInteractor _verifyNameInteractor;
  final GetAllIdentitiesInteractor _getAllIdentitiesInteractor;
  final IdentityUtils _identityUtils;

  final _uuid = Get.find<Uuid>();
  final _appToast = Get.find<AppToast>();

  final noneEmailAddress = EmailAddress(null, 'None');
  final listEmailAddressDefault = <EmailAddress>[].obs;
  final listEmailAddressOfReplyTo = <EmailAddress>[].obs;
  final errorNameIdentity = Rxn<String>();
  final errorBccIdentity = Rxn<String>();
  final emailOfIdentity = Rxn<EmailAddress>();
  final replyToOfIdentity = Rxn<EmailAddress>();
  final bccOfIdentity = Rxn<EmailAddress>();
  final actionType = IdentityActionType.create.obs;
  final isDefaultIdentity = RxBool(false);
  final isDefaultIdentitySupported = RxBool(false);

  final RichTextController keyboardRichTextController = RichTextController();
  final RichTextWebController richTextWebController = RichTextWebController();
  final TextEditingController inputNameIdentityController = TextEditingController();
  final TextEditingController inputBccIdentityController = TextEditingController();
  final FocusNode inputNameIdentityFocusNode = FocusNode();
  final FocusNode inputBccIdentityFocusNode = FocusNode();
  final ScrollController scrollController = ScrollController();

  String? _nameIdentity;
  String? _contentHtmlEditor;
  AccountId? accountId;
  Session? session;
  UserProfile? userProfile;
  Identity? identity;
  IdentityCreatorArguments? arguments;

  final GlobalKey htmlKey = GlobalKey();
  final htmlEditorMinHeight = 160;

  void updateNameIdentity(BuildContext context, String? value) {
    _nameIdentity = value;
    errorNameIdentity.value = _getErrorInputNameString(context);
  }

  void updateContentHtmlEditor(String? text) => _contentHtmlEditor = text;

  String? get contentHtmlEditor {
    if (_contentHtmlEditor != null) {
      return _contentHtmlEditor;
    } else {
      return arguments?.identity?.signatureAsString;
    }
  }

  IdentityCreatorController(
      this._verifyNameInteractor,
      this._getAllIdentitiesInteractor,
      this._identityUtils
  );

  @override
  void onInit() {
    super.onInit();
    log('IdentityCreatorController::onInit():arguments: ${Get.arguments}');
    arguments = Get.arguments;
  }

  @override
  void onReady() {
    super.onReady();
    log('IdentityCreatorController::onReady():');
    if (arguments != null) {
      accountId = arguments!.accountId;
      session = arguments!.session;
      userProfile = arguments!.userProfile;
      identity = arguments!.identity;
      actionType.value = arguments!.actionType;
      _checkDefaultIdentityIsSupported();
      _setUpValueFromIdentity();
      _getAllIdentities();
    }
  }

  @override
  void onClose() {
    log('IdentityCreatorController::onClose():');
    keyboardRichTextController.dispose();
    inputNameIdentityFocusNode.dispose();
    inputBccIdentityFocusNode.dispose();
    inputNameIdentityController.dispose();
    inputBccIdentityController.dispose();
    scrollController.dispose();
    richTextWebController.onClose();
    super.onClose();
  }

  @override
  void handleSuccessViewState(Success success) {
    super.handleSuccessViewState(success);
    if (success is GetAllIdentitiesSuccess) {
      _getALlIdentitiesSuccess(success);
    }
  }

  @override
  void handleFailureViewState(Failure failure) {
    super.handleFailureViewState(failure);
    if (failure is GetAllIdentitiesFailure) {
      _getALlIdentitiesFailure(failure);
    }
  }

  void _checkDefaultIdentityIsSupported() {
    if (session != null && accountId != null) {
      isDefaultIdentitySupported.value = [CapabilityIdentifier.jamesSortOrder].isSupported(session!, accountId!);
    }
  }

  void _setUpValueFromIdentity() {
    _nameIdentity = identity?.name ?? '';
    inputNameIdentityController.text = identity?.name ?? '';

    if (identity?.signatureAsString.isNotEmpty == true) {
      updateContentHtmlEditor(arguments?.identity?.signatureAsString ?? '');
      if (PlatformInfo.isWeb) {
        richTextWebController.editorController.setText(arguments?.identity?.signatureAsString ?? '');
      }
    }
  }

  void _getAllIdentities() {
    if (accountId != null && session != null) {
      final propertiesRequired = isDefaultIdentitySupported.isTrue
        ? Properties({'email', 'sortOrder'})
        : Properties({'email'});

      consumeState(_getAllIdentitiesInteractor.execute(session!, accountId!, properties: propertiesRequired));
    }
  }

  void _getALlIdentitiesSuccess(GetAllIdentitiesSuccess success) {
    if (success.identities?.isNotEmpty == true) {
      listEmailAddressDefault.value = success.identities!
          .map((identity) => identity.toEmailAddressNoName())
          .toSet()
          .toList();
      listEmailAddressOfReplyTo.add(noneEmailAddress);
      listEmailAddressOfReplyTo.addAll(listEmailAddressDefault);
      _setUpAllFieldEmailAddress();

      if (isDefaultIdentitySupported.isTrue) {
        _setUpDefaultIdentity(success.identities);
      }
    } else {
      _setDefaultEmailAddressList();
    }
  }

  void _getALlIdentitiesFailure(GetAllIdentitiesFailure failure) {
    _setDefaultEmailAddressList();
  }

  void _setDefaultEmailAddressList() {
    listEmailAddressOfReplyTo.add(noneEmailAddress);

    if (userProfile != null && userProfile?.email.isNotEmpty == true) {
      final userEmailAddress = EmailAddress(null, userProfile!.email);
      listEmailAddressDefault.add(userEmailAddress);
      listEmailAddressOfReplyTo.addAll(listEmailAddressDefault);
    }

    _setUpAllFieldEmailAddress();
  }

  void _setUpAllFieldEmailAddress() {
    listEmailAddressOfReplyTo.value = listEmailAddressOfReplyTo.toSet().toList();
    listEmailAddressDefault.value = listEmailAddressDefault.toSet().toList();

    if (actionType.value == IdentityActionType.edit && identity != null) {
      if (identity?.replyTo?.isNotEmpty == true) {
        try {
          replyToOfIdentity.value = listEmailAddressOfReplyTo
              .firstWhere((emailAddress) => emailAddress ==  identity?.replyTo!.first);
        } catch(e) {
          replyToOfIdentity.value = noneEmailAddress;
        }
      } else {
        replyToOfIdentity.value = noneEmailAddress;
      }

      if (identity?.bcc?.isNotEmpty == true) {
        bccOfIdentity.value = identity?.bcc!.first;
        inputBccIdentityController.text = identity?.bcc!.first.emailAddress ?? '';
      } else {
        bccOfIdentity.value = null;
      }

      if (identity?.email?.isNotEmpty == true) {
        try {
          emailOfIdentity.value = listEmailAddressDefault
              .firstWhere((emailAddress) => emailAddress.email ==  identity?.email);
        } catch(e) {
          emailOfIdentity.value = null;
        }
      } else {
        emailOfIdentity.value = listEmailAddressDefault.isNotEmpty
            ? listEmailAddressDefault.first
            : null;
      }
    } else {
      replyToOfIdentity.value = null;
      bccOfIdentity.value = null;
      emailOfIdentity.value = listEmailAddressDefault.isNotEmpty
          ? listEmailAddressDefault.first
          : null;
    }
  }

  void _setUpDefaultIdentity(List<Identity>? identities) {
    final listDefaultIdentityIds = _identityUtils
        .getSmallestOrderedIdentity(identities)
        ?.map((identity) => identity.id!);
    
    if (haveDefaultIdentities(identities, listDefaultIdentityIds) && 
      listDefaultIdentityIds?.contains(identity?.id) == true
    ) {
      isDefaultIdentity.value = true;
    } else {
      isDefaultIdentity.value = false;
    }
  }

  bool haveDefaultIdentities(
    Iterable<Identity>? allIdentities, 
    Iterable<IdentityId>? defaultIdentityIds
  ) {
    return defaultIdentityIds?.length != allIdentities?.length;
  }

  void updateEmailOfIdentity(EmailAddress? newEmailAddress) {
    emailOfIdentity.value = newEmailAddress;
  }

  void updaterReplyToOfIdentity(EmailAddress? newEmailAddress) {
    replyToOfIdentity.value = newEmailAddress;
  }

  void updateBccOfIdentity(EmailAddress? newEmailAddress) {
    bccOfIdentity.value = newEmailAddress;
  }

  Future<String?> _getSignatureHtmlText() async {
    if (PlatformInfo.isWeb) {
      return richTextWebController.editorController.getText();
    } else {
      return keyboardRichTextController.htmlEditorApi?.getText();
    }
  }

  void createNewIdentity(BuildContext context) async {
    clearFocusEditor(context);

    final error = _getErrorInputNameString(context);
    if (error?.isNotEmpty == true) {
      errorNameIdentity.value = error;
      inputNameIdentityFocusNode.requestFocus();
      return;
    }

    final errorBcc = _getErrorInputAddressString(context);
    if (errorBcc?.isNotEmpty == true) {
      errorBccIdentity.value = errorBcc;
      inputBccIdentityFocusNode.requestFocus();
      return;
    }

    final signatureHtmlText = PlatformInfo.isWeb
        ? contentHtmlEditor
        : await _getSignatureHtmlText();
    final bccAddress = bccOfIdentity.value != null && bccOfIdentity.value != noneEmailAddress
        ? {bccOfIdentity.value!}
        : <EmailAddress>{};
    final replyToAddress = replyToOfIdentity.value != null && replyToOfIdentity.value != noneEmailAddress
        ? {replyToOfIdentity.value!}
        : <EmailAddress>{};

    final sortOrder = isDefaultIdentitySupported.isTrue
      ? UnsignedInt(isDefaultIdentity.value ? 0 : 100)
      : null;
    
    final newIdentity = Identity(
      name: _nameIdentity,
      email: emailOfIdentity.value?.email,
      replyTo: replyToAddress,
      bcc: bccAddress,
      htmlSignature: Signature(signatureHtmlText ?? ''),
      sortOrder: sortOrder);

    final generateCreateId = Id(_uuid.v1());

    if (actionType.value == IdentityActionType.create) {
      final identityRequest = CreateNewIdentityRequest(
        generateCreateId, 
        newIdentity,
        isDefaultIdentity: isDefaultIdentity.value);
      popBack(result: identityRequest);
    } else {
      final identityRequest = EditIdentityRequest(
        identityId: identity!.id!,
        identityRequest: newIdentity.toIdentityRequest(),
        isDefaultIdentity: isDefaultIdentity.value);
      popBack(result: identityRequest);
    }
  }

  void onCheckboxChanged() {
    isDefaultIdentity.value = !isDefaultIdentity.value;
  }

  String? _getErrorInputNameString(BuildContext context) {
    return _verifyNameInteractor.execute(
        _nameIdentity,
        [EmptyNameValidator()]
    ).fold(
      (failure) {
          if (failure is VerifyNameFailure) {
            return failure.getMessageIdentity(context);
          } else {
            return null;
          }
        },
      (success) => null
    );
  }

  String? _getErrorInputAddressString(BuildContext context, {String? value}) {
    final emailAddress = value ?? inputBccIdentityController.text;
    if (emailAddress.trim().isEmpty) {
      return null;
    }
    return _verifyNameInteractor.execute(
        emailAddress,
        [EmailAddressValidator()]
    ).fold(
        (failure) {
          if (failure is VerifyNameFailure) {
            return failure.getMessageIdentity(context);
          } else {
            return null;
          }
        },
        (success) => null
    );
  }

  void validateInputBccAddress(BuildContext context, String? value) {
    final errorBcc = _getErrorInputAddressString(context, value: value);
    if (errorBccIdentity.value?.isNotEmpty == true
        && (errorBcc == null || errorBcc.isEmpty)) {
      errorBccIdentity.value = null;
    }
  }

  List<EmailAddress> getSuggestionEmailAddress(String? pattern) {
    if (pattern == null || pattern.isEmpty) {
      return List.empty();
    }
   return listEmailAddressOfReplyTo
       .where((emailAddress) => emailAddress.email?.contains(pattern) == true)
       .toList();
  }

  void clearFocusEditor(BuildContext context) {
    if (PlatformInfo.isMobile) {
      keyboardRichTextController.htmlEditorApi?.unfocus();
      KeyboardUtils.hideSystemKeyboardMobile();
    }
    KeyboardUtils.hideKeyboard(context);
  }

  void closeView(BuildContext context) {
    clearFocusEditor(context);
    popBack();
  }

  void initRichTextForMobile(BuildContext context, HtmlEditorApi editorApi) {
    keyboardRichTextController.onCreateHTMLEditor(
      editorApi,
      onEnterKeyDown: _onEnterKeyDownOnMobile,
      onFocus: _onFocusHTMLEditorOnMobile,
      context: context
    );
  }

  void _onFocusHTMLEditorOnMobile() async {
    inputBccIdentityFocusNode.unfocus();
    inputNameIdentityFocusNode.unfocus();
    if (htmlKey.currentContext != null) {
      await Scrollable.ensureVisible(htmlKey.currentContext!);
    }
    await Future.delayed(const Duration(milliseconds: 500), () {
      final offset = scrollController.position.pixels +
        defaultKeyboardToolbarHeight +
        htmlEditorMinHeight;
      scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 1),
        curve: Curves.linear,
      );
    });
  }

  void _onEnterKeyDownOnMobile() {
    if (scrollController.position.pixels < scrollController.position.maxScrollExtent) {
      scrollController.animateTo(
        scrollController.position.pixels + 20,
        duration: const Duration(milliseconds: 1),
        curve: Curves.linear,
      );
    }
  }

  void pickImage(BuildContext context) async {
    final filePickerResult = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true
    );

    if (context.mounted) {
      final platformFile = filePickerResult?.files.single;
      if (platformFile != null) {
        _insertInlineImage(context, platformFile);
      } else {
        _appToast.showToastErrorMessage(
          context,
          AppLocalizations.of(context).cannotSelectThisImage
        );
      }
    } else {
      logError("IdentityCreatorController::pickImage: context is unmounted");
    }
  }

  bool _isExceedMaxSizeInlineImage(int fileSize) =>
    fileSize > IdentityCreatorConstants.maxSizeIdentityInlineImage.kiloByteToBytes;

  void _insertInlineImage(BuildContext context, PlatformFile platformFile) {
    if (_isExceedMaxSizeInlineImage(platformFile.size)) {
      _appToast.showToastErrorMessage(
        context,
        AppLocalizations.of(context).pleaseChooseAnImageSizeCorrectly(
          IdentityCreatorConstants.maxSizeIdentityInlineImage
        )
      );
    } else {
      richTextWebController.insertImageAsBase64(platformFile: platformFile);
    }
  }
}