// US30, US31, US35
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/more/more_overview.dart';
import 'package:quadrapp_mobile/contexts/iam/iam.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/time/app_time_formatter.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// Cubit de Más (`/ops/more`): la administración de la universidad.
///
/// Pide en paralelo el calendario (desde hoy hasta [calendarDays] días),
/// los dominios y el equipo. Estados (`ViewState<MoreOverview>`):
/// - `ViewLoading` (con `previous` al recargar);
/// - `ViewError`: no llegó nada o el servidor negó el acceso (403);
/// - `ViewPartial`: faltó alguna parte (su tarjeta lo dice);
/// - `ViewData`: llegó todo.
///
/// Registrar, cancelar, agregar, retirar e invitar devuelven la falla (o
/// `null`) para que la ventana la diga, y al salir bien actualizan la
/// pantalla sin volver a pedir todo.
class MoreCubit extends Cubit<ViewState<MoreOverview>> {
  MoreCubit({
    required this._getCampusCalendar,
    required this._createCalendarEvent,
    required this._cancelCalendarEvent,
    required this._getInstitutionDomains,
    required this._addInstitutionDomain,
    required this._removeInstitutionDomain,
    required this._getTeam,
    required this._inviteTeamMember,
    required this._clock,
  }) : super(const ViewInitial());

  final GetCampusCalendar _getCampusCalendar;
  final CreateCalendarEvent _createCalendarEvent;
  final CancelCalendarEvent _cancelCalendarEvent;
  final GetInstitutionDomains _getInstitutionDomains;
  final AddInstitutionDomain _addInstitutionDomain;
  final RemoveInstitutionDomain _removeInstitutionDomain;
  final GetTeam _getTeam;
  final InviteTeamMember _inviteTeamMember;
  final Clock _clock;

  /// Cuántos días del calendario se muestran desde hoy.
  static const int calendarDays = 90;

  int _request = 0;

  MoreOverview? get _current => switch (state) {
    ViewData(:final data) => data,
    ViewPartial(:final data) => data,
    ViewLoading(:final previous) => previous,
    ViewError(:final previous) => previous,
    _ => null,
  };

  /// Desde la medianoche de hoy en Lima: lo que ya pasó hoy sigue a la vista.
  CalendarWindow get _window {
    const offset = AppTimeFormatter.limaOffset;
    final local = _clock.now().add(offset);
    final today = DateTime.utc(
      local.year,
      local.month,
      local.day,
    ).subtract(offset);
    return (from: today, to: today.add(const Duration(days: calendarDays)));
  }

  Future<void> load() => _fetch(previous: _current);

  Future<void> refresh() => _fetch(previous: _current);

  Future<void> _fetch({MoreOverview? previous}) async {
    final request = ++_request;
    emit(ViewLoading(previous: previous));
    final results = await Future.wait<Result<Object>>([
      _getCampusCalendar(_window),
      _getInstitutionDomains(const NoParams()),
      _getTeam(const NoParams()),
    ]);
    if (isClosed || request != _request) return;
    final failures = <MoreSection, Failure>{};
    Object? take(Result<Object> result, MoreSection section) {
      switch (result) {
        case Success(:final value):
          return value;
        case Err(:final failure):
          failures[section] = failure;
          return null;
      }
    }

    final overview = MoreOverview(
      events: take(results[0], MoreSection.calendar) as List<CalendarEvent>?,
      domains:
          take(results[1], MoreSection.domains) as List<InstitutionDomain>?,
      team: take(results[2], MoreSection.team) as Team?,
      failures: failures,
    );
    // El 403 vale para todo: no se muestra nada a medias.
    final forbidden = failures.values.whereType<ForbiddenFailure>().firstOrNull;
    if (forbidden != null) {
      emit(ViewError(forbidden, previous: previous));
    } else if (overview.isEmpty) {
      emit(ViewError(failures.values.first, previous: previous));
    } else if (overview.isPartial) {
      emit(ViewPartial(overview, missing: overview.missing));
    } else {
      emit(ViewData(overview));
    }
  }

  void _update(MoreOverview Function(MoreOverview current) change) {
    final current = _current;
    if (current == null || isClosed) return;
    final next = change(current);
    emit(
      next.isPartial
          ? ViewPartial(next, missing: next.missing)
          : ViewData(next),
    );
  }

  /// Registra una entrada del calendario (US35 esc. 1 y 2).
  Future<Failure?> createEvent(NewCalendarEvent event) async {
    final result = await _createCalendarEvent(event);
    switch (result) {
      case Err(:final failure):
        return failure;
      case Success(:final value):
        _update((current) {
          final window = _window;
          final inWindow =
              value.startsAt.isBefore(window.to) &&
              value.endsAt.isAfter(window.from);
          if (!inWindow) return current;
          final events = [...?current.events, value]
            ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
          return current.copyWith(events: events);
        });
        return null;
    }
  }

  /// Cancela una entrada (US35 esc. 3).
  Future<Failure?> cancelEvent(CalendarEventId id) async {
    final result = await _cancelCalendarEvent(id);
    switch (result) {
      case Err(:final failure):
        return failure;
      case Success():
        _update(
          (current) => current.copyWith(
            events: [
              for (final e in current.events ?? const <CalendarEvent>[])
                if (e.id != id) e,
            ],
          ),
        );
        return null;
    }
  }

  /// Agrega un dominio (US30 esc. 1 y 3).
  Future<Failure?> addDomain(String raw) async {
    final result = await _addInstitutionDomain(raw);
    switch (result) {
      case Err(:final failure):
        return failure;
      case Success(:final value):
        _update(
          (current) => current.copyWith(domains: [...?current.domains, value]),
        );
        return null;
    }
  }

  /// Retira un dominio (US30 esc. 2).
  Future<Failure?> removeDomain(InstitutionDomainId id) async {
    final result = await _removeInstitutionDomain(id);
    switch (result) {
      case Err(:final failure):
        return failure;
      case Success():
        _update(
          (current) => current.copyWith(
            domains: [
              for (final d in current.domains ?? const <InstitutionDomain>[])
                if (d.id != id) d,
            ],
          ),
        );
        return null;
    }
  }

  /// Invita a una persona (US31 esc. 1). Una invitación inválida no llega al
  /// servidor.
  Future<Failure?> invite({
    required String email,
    required UserRole role,
  }) async {
    final invitation = NewInvitation.create(email: email, role: role);
    final result = switch (invitation) {
      Err(:final failure) => Err<InvitationReceipt>(failure),
      Success(:final value) => await _inviteTeamMember(value),
    };
    switch (result) {
      case Err(:final failure):
        return failure;
      case Success(:final value):
        _update((current) {
          final team = current.team;
          if (team == null) return current;
          return current.copyWith(
            team: Team(
              serverTime: team.serverTime,
              members: [
                for (final m in team.members)
                  if (m.email != value.member.email) m,
                value.member,
              ],
            ),
          );
        });
        return null;
    }
  }
}
