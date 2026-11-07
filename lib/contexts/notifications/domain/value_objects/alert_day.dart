/// Día de la semana de una suscripción (US33). El número es el del contrato:
/// 1 = lunes ... 7 = domingo.
enum AlertDay {
  monday(1),
  tuesday(2),
  wednesday(3),
  thursday(4),
  friday(5),
  saturday(6),
  sunday(7);

  const AlertDay(this.isoNumber);

  final int isoNumber;

  /// El día con ese número, o `null` si no está entre 1 y 7.
  static AlertDay? fromIsoNumber(int number) {
    for (final day in values) {
      if (day.isoNumber == number) return day;
    }
    return null;
  }
}
