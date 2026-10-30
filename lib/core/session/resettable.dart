/// Algo que guarda datos de un usuario y debe limpiarse al cerrar sesión
/// (dispositivo compartido, US02 esc. 3).
// ignore: one_member_abstracts
abstract interface class Resettable {
  Future<void> reset();
}

/// Registro de todo lo que se limpia al cerrar sesión. Se llena en `app/di`;
/// una prueba falla si un almacén nuevo no está registrado.
class ResettableRegistry {
  final List<Resettable> _items = [];

  List<Resettable> get items => List.unmodifiable(_items);

  void register(Resettable resettable) {
    if (!_items.contains(resettable)) _items.add(resettable);
  }

  /// Limpia todo. Un fallo en uno no impide limpiar el resto.
  Future<void> resetAll() async {
    for (final item in _items) {
      try {
        await item.reset();
      } on Object {
        // Se sigue con el resto: es preferible limpiar de más que de menos.
      }
    }
  }
}
