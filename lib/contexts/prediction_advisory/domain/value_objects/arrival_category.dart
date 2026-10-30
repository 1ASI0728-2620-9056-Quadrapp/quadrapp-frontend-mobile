/// Categoría de disponibilidad esperada al llegar (US15). En la UI se muestra
/// traducida ("Alta", "Limitada", "Baja"), nunca el código.
///
/// Es un tipo distinto de `ConfidenceLevel` aunque compartan `HIGH` y `LOW`.
enum ArrivalCategory { high, limited, low }
