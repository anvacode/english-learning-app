# Refactor: Compactar verticalmente tarjetas de lecciones

## Resumen
Hacer las tarjetas de lecciones mas delgadas verticalmente cambiando padding, espaciado y aspect ratio.

## Archivos a modificar

### 1. `lib/widgets/lesson_card.dart`

**Cambio A - Padding (linea 70):**
```dart
// ANTES:
padding: EdgeInsets.all(Responsive.scale(context, 10, 14, 16)),

// DESPUES:
padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
```

**Cambio B - Espaciado titulo/subtitulo (linea 142):**
```dart
// ANTES:
SizedBox(height: Responsive.scale(context, 4, 5, 6)),

// DESPUES:
const SizedBox(height: 2),
```

---

### 2. `lib/widgets/lesson_grid_card.dart`

**Cambio A - Padding (linea 78):**
```dart
// ANTES:
padding: EdgeInsets.all(isMobile ? 6 : Responsive.scale(context, 6, 8, 10)),

// DESPUES:
padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
```

**Cambio B - Espaciado en layout movil (linea 108):**
```dart
// ANTES:
SizedBox(height: 2),

// DESPUES:
SizedBox(height: 1),
```

**Cambio C - Espaciado en layout movil (linea 119):**
```dart
// ANTES:
SizedBox(height: 1),

// DESPUES:
const SizedBox(height: 0),
```

**Cambio D - Espaciado en layout desktop (linea 173):**
```dart
// ANTES:
SizedBox(height: 1),

// DESPUES:
const SizedBox(height: 0),
```

---

### 3. `lib/widgets/level_section.dart`

**Cambio - AspectRatio del grid (linea 301):**
```dart
// ANTES:
childAspectRatio: Responsive.scale(context, 2.5, 3.0, 3.5),

// DESPUES:
childAspectRatio: Responsive.scale(context, 2.5, 2.8, 3.0),
```
> Un aspect ratio mayor = celda mas alta y estrecha. Reducirlo hace la tarjeta mas delgada verticalmente.

---

## Verificacion
- `flutter analyze` para verificar que no hay errores de compilacion
- Revisar visualmente que las tarjetas se ven mas compactas
