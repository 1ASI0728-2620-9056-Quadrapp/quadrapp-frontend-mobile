// US30, US31, US35
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/iam/iam.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';

/// Las partes de Más que se piden por separado: una puede faltar sin tumbar
/// las demás.
enum MoreSection { calendar, domains, team }

/// Lo que muestra Más (`/ops/more`): el calendario del campus, los dominios
/// de correo y el equipo de la institución.
class MoreOverview extends Equatable {
  const MoreOverview({
    this.events,
    this.domains,
    this.team,
    this.failures = const {},
  });

  /// De la más próxima a la más lejana; `null` si no llegó.
  final List<CalendarEvent>? events;
  final List<InstitutionDomain>? domains;
  final Team? team;
  final Map<MoreSection, Failure> failures;

  bool get isPartial => failures.isNotEmpty;

  bool get isEmpty => events == null && domains == null && team == null;

  Set<String> get missing => {for (final s in failures.keys) s.name};

  MoreOverview copyWith({
    List<CalendarEvent>? events,
    List<InstitutionDomain>? domains,
    Team? team,
  }) => MoreOverview(
    events: events ?? this.events,
    domains: domains ?? this.domains,
    team: team ?? this.team,
    failures: failures,
  );

  @override
  List<Object?> get props => [events, domains, team, failures];
}
