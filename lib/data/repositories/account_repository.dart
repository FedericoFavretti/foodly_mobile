import 'dart:convert';



import '../../core/constants/api_constants.dart';

import '../../core/errors/api_exception.dart';

import '../../core/network/api_client.dart';

import '../../domain/session/session_manager.dart';



/// Operaciones de cuenta: activación, recuperación y cambio de contraseña (CU-CL01).

class AccountRepository {

  AccountRepository({ApiClient? api}) : _api = api ?? ApiClient();



  final ApiClient _api;



  static const recoveryEmailSentMessage =

      'Si el correo ingresado está asociado a una cuenta, recibirás un enlace de recuperación.';



  static const passwordResetSuccessMessage =

      'Contraseña restablecida. Ya podés iniciar sesión.';



  static const accountActivatedMessage =

      'Tu cuenta fue activada correctamente. Ya podés iniciar sesión.';



  static const passwordChangeCodeSentMessage =

      'Se ha enviado un código de 6 dígitos a tu correo.';



  static const passwordChangeCodeVerifiedMessage =

      'Código verificado. Ingresá tu nueva contraseña.';



  static const passwordChangeSuccessMessage =

      'Contraseña actualizada correctamente.';



  static const emailChangeStartedMessage =

      'Te enviamos un enlace de confirmación a tu correo actual. '

      'El cambio se aplicará cuando lo confirmes.';



  static const emailChangeSuccessMessage =

      'Tu correo fue actualizado. Iniciá sesión con tu nuevo correo.';



  Future<void> solicitarRecuperacion(String email) async {

    try {

      final response = await _api.post(

        ApiConstants.recuperarContraCorreoEndpoint,

        {'correo': email.trim()},

        requiresAuth: false,

      );



      if (response.statusCode == 200) return;



      throw ApiException(

        statusCode: response.statusCode,

        userMessage: _mapErrorMessage(response.body) ??

            'No pudimos enviar el enlace de recuperación. Intentalo más tarde.',

        debugInfo: response.body,

      );

    } on ApiException {

      rethrow;

    } on NetworkException {

      rethrow;

    } catch (error) {

      throw ApiException(

        statusCode: 0,

        userMessage: 'Ocurrió un error inesperado. Intentalo más tarde.',

        debugInfo: error.toString(),

      );

    }

  }



  Future<void> restablecerContra({

    required String token,

    required String nuevaPasswd,

    required String confirmacionPasswd,

  }) async {

    try {

      final response = await _api.post(

        ApiConstants.recuperarContraEndpoint,

        {

          'token': token.trim(),

          'nuevaPasswd': nuevaPasswd,

          'confirmacionPasswd': confirmacionPasswd,

        },

        requiresAuth: false,

      );



      if (response.statusCode == 200 || response.statusCode == 204) return;



      throw ApiException(

        statusCode: response.statusCode,

        userMessage: _mapErrorMessage(response.body) ??

            'No pudimos restablecer tu contraseña. Intentalo más tarde.',

        debugInfo: response.body,

      );

    } on ApiException {

      rethrow;

    } on NetworkException {

      rethrow;

    } catch (error) {

      throw ApiException(

        statusCode: 0,

        userMessage: 'Ocurrió un error inesperado. Intentalo más tarde.',

        debugInfo: error.toString(),

      );

    }

  }



  Future<void> reenviarActivacion(String email) async {

    try {

      final response = await _api.post(

        ApiConstants.reenviarActivacionEndpoint,

        {'correo': email.trim()},

        requiresAuth: false,

      );



      if (response.statusCode == 200) return;



      throw ApiException(

        statusCode: response.statusCode,

        userMessage: _mapErrorMessage(response.body) ??

            'No pudimos reenviar el correo. Intentalo más tarde.',

        debugInfo: response.body,

      );

    } on ApiException {

      rethrow;

    } on NetworkException {

      rethrow;

    } catch (error) {

      throw ApiException(

        statusCode: 0,

        userMessage: 'Ocurrió un error inesperado. Intentalo más tarde.',

        debugInfo: error.toString(),

      );

    }

  }



  Future<void> activarCuenta(String email) async {

    try {

      final response = await _api.postEmpty(

        ApiConstants.activarCuentaEndpoint,

        queryParameters: {'email': email.trim()},

        requiresAuth: false,

      );



      if (response.statusCode == 200) return;



      throw ApiException(

        statusCode: response.statusCode,

        userMessage: _mapErrorMessage(response.body) ??

            'No pudimos activar tu cuenta. Intentalo más tarde.',

        debugInfo: response.body,

      );

    } on ApiException {

      rethrow;

    } on NetworkException {

      rethrow;

    } catch (error) {

      throw ApiException(

        statusCode: 0,

        userMessage: 'Ocurrió un error inesperado. Intentalo más tarde.',

        debugInfo: error.toString(),

      );

    }

  }



  Future<void> iniciarCambioPasswd(String passwdActual) async {

    final idUsuario = await SessionManager.getClienteId();

    if (idUsuario == null) {

      throw const ApiException(

        statusCode: 401,

        userMessage: 'Tu sesión expiró. Volvé a iniciar sesión.',

      );

    }



    try {

      final response = await _api.post(

        ApiConstants.cambiarPasswdIniciarEndpoint,

        {

          'idUsuario': idUsuario,

          'passwdActual': passwdActual,

        },

        requiresAuth: true,

      );



      if (response.statusCode == 200) return;



      throw ApiException(

        statusCode: response.statusCode,

        userMessage: _mapErrorMessage(response.body) ??

            'No pudimos iniciar el cambio de contraseña. Intentalo más tarde.',

        debugInfo: response.body,

      );

    } on SessionExpiredException {

      rethrow;

    } on ApiException {

      rethrow;

    } on NetworkException {

      rethrow;

    } catch (error) {

      throw ApiException(

        statusCode: 0,

        userMessage: 'Ocurrió un error inesperado. Intentalo más tarde.',

        debugInfo: error.toString(),

      );

    }

  }



  Future<void> verificarCodigoCambioPasswd(String codigo) async {

    final idUsuario = await SessionManager.getClienteId();

    if (idUsuario == null) {

      throw const ApiException(

        statusCode: 401,

        userMessage: 'Tu sesión expiró. Volvé a iniciar sesión.',

      );

    }



    try {

      final response = await _api.post(

        ApiConstants.cambiarPasswdVerificarEndpoint,

        {

          'idUsuario': idUsuario,

          'codigo': codigo.trim(),

        },

        requiresAuth: true,

      );



      if (response.statusCode == 200) return;



      throw ApiException(

        statusCode: response.statusCode,

        userMessage: _mapErrorMessage(response.body) ??

            'El código ingresado no es válido.',

        debugInfo: response.body,

      );

    } on SessionExpiredException {

      rethrow;

    } on ApiException {

      rethrow;

    } on NetworkException {

      rethrow;

    } catch (error) {

      throw ApiException(

        statusCode: 0,

        userMessage: 'Ocurrió un error inesperado. Intentalo más tarde.',

        debugInfo: error.toString(),

      );

    }

  }



  Future<void> confirmarCambioPasswd({

    required String passwdNueva,

    required String passwdConfirmacion,

  }) async {

    final idUsuario = await SessionManager.getClienteId();

    if (idUsuario == null) {

      throw const ApiException(

        statusCode: 401,

        userMessage: 'Tu sesión expiró. Volvé a iniciar sesión.',

      );

    }



    try {

      final response = await _api.post(

        ApiConstants.cambiarPasswdConfirmarEndpoint,

        {

          'idUsuario': idUsuario,

          'passwdNueva': passwdNueva,

          'passwdConfirmacion': passwdConfirmacion,

        },

        requiresAuth: true,

      );



      if (response.statusCode == 200) return;



      throw ApiException(

        statusCode: response.statusCode,

        userMessage: _mapErrorMessage(response.body) ??

            'No pudimos actualizar tu contraseña. Intentalo más tarde.',

        debugInfo: response.body,

      );

    } on SessionExpiredException {

      rethrow;

    } on ApiException {

      rethrow;

    } on NetworkException {

      rethrow;

    } catch (error) {

      throw ApiException(

        statusCode: 0,

        userMessage: 'Ocurrió un error inesperado. Intentalo más tarde.',

        debugInfo: error.toString(),

      );

    }

  }



  Future<void> iniciarCambioCorreo(String nuevoCorreo) async {

    try {

      final response = await _api.post(

        ApiConstants.cambiarCorreoIniciarEndpoint,

        {'nuevoCorreo': nuevoCorreo.trim()},

        requiresAuth: true,

      );



      if (response.statusCode == 200 || response.statusCode == 204) return;



      throw ApiException(

        statusCode: response.statusCode,

        userMessage: _mapErrorMessage(response.body) ??

            'No pudimos iniciar el cambio de correo. Intentalo más tarde.',

        debugInfo: response.body,

      );

    } on SessionExpiredException {

      rethrow;

    } on ApiException {

      rethrow;

    } on NetworkException {

      rethrow;

    } catch (error) {

      throw ApiException(

        statusCode: 0,

        userMessage: 'Ocurrió un error inesperado. Intentalo más tarde.',

        debugInfo: error.toString(),

      );

    }

  }



  Future<void> confirmarCambioCorreo(String token) async {

    try {

      final response = await _api.post(

        ApiConstants.cambiarCorreoConfirmarEndpoint,

        {'token': token.trim()},

        requiresAuth: false,

      );



      if (response.statusCode == 200 || response.statusCode == 204) return;



      throw ApiException(

        statusCode: response.statusCode,

        userMessage: _mapErrorMessage(response.body) ??

            'No pudimos confirmar el cambio de correo. Intentalo más tarde.',

        debugInfo: response.body,

      );

    } on ApiException {

      rethrow;

    } on NetworkException {

      rethrow;

    } catch (error) {

      throw ApiException(

        statusCode: 0,

        userMessage: 'Ocurrió un error inesperado. Intentalo más tarde.',

        debugInfo: error.toString(),

      );

    }

  }



  String? _mapErrorMessage(String body) {

    if (body.isEmpty) return null;

    try {

      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {

        final message =

            decoded['mensaje'] ?? decoded['message'] ?? decoded['error'];

        if (message is String && message.isNotEmpty) return message;

      }

    } catch (_) {}



    if (body.length < 300 && !body.contains('<html')) return body;

    return null;

  }

}


