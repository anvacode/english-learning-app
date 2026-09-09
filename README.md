# 🎓 English AI Learning App

Una aplicación educativa interactiva para que niños aprendan inglés de forma divertida mediante lecciones, juegos y ejercicios de pronunciación.

[![Flutter Version](https://img.shields.io/badge/Flutter-3.10+-blue.svg)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Cloud%20Firestore-orange.svg)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Test Status](https://img.shields.io/badge/Tests-18%20passing-brightgreen)]()

## 🎯 Público Objetivo

- **Edad**: Niños de 5 a 10 años (especialmente 5-8 años)
- **Idioma**: Hispanohablantes aprendiendo inglés
- **Enfoque**: Aprendizaje lúdico y gamificado

## 📱 Plataformas Soportadas

- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 11+)
- ✅ **Web** (Chrome, Firefox, Safari, Edge)

---

## ✨ Características Principales

### 🤖 Tecnología de Voz IA

| Feature | Descripción |
|---------|-------------|
| **Práctica de Pronunciación** | Speech-to-text para evaluar cómo el niño pronuncia palabras en inglés |
| **Feedback en Tiempo Real** | Algoritmo de similitud de Levenshtein para evaluar precisión |
| **Text-to-Speech** | Audio de palabras y frases en inglés con velocidad configurable |
| **Evaluación de Frases** | Análisis de oraciones completas con tolerancia intelligent |

### 🎯 Sistema de Aprendizaje Adaptativo

| Feature | Descripción |
|---------|-------------|
| **Test Diagnóstico Visual** | 10 preguntas con emojis diseñadas para niños de 5-8 años |
| **3 Niveles de Dificultad** | Principiante, Intermedio, Avanzado |
| **Seguimiento de Progreso** | Lecciones no iniciadas, en progreso, dominadas |
| **Maestría por Lección** | Requiere 80% de precisión y todos los items completados |

### 🎮 Gamificación Completa

| Feature | Descripción |
|---------|-------------|
| **Sistema de Estrellas** | Gana estrellas por completar lecciones y ejercicios |
| **Tienda Integral** | Avatares, efectos visuales, power-ups |
| **Logros/Badges** | Insignias por completar lecciones y alcanzar metas |
| **Rachas Diarias** | Bonificaciones por práctica consistente |
| **Power-ups** | Efectos temporales (ej: doble estrellas por 3 días) |

### 📚 Tipos de Ejercicios

- **Opción Múltiple** - Selecciona la respuesta correcta
- **Emparejamiento (Matching)** - Relaciona imágenes con palabras
- **Deletreo (Spelling)** - Escribe la palabra correcta
- **Práctica Auditiva (Listening)** - Identifica lo que escuchas
- **Speed Match** - Emparejamiento cronometrado
- **Memory Game** - Juego de memoria con imágenes
- **Práctica de Pronunciación** - Evalúa tu voz

### 🔐 Autenticación y Datos

| Feature | Descripción |
|---------|-------------|
| **Email/Contraseña** | Registro e inicio de sesión tradicional |
| **Google Sign-In** | Inicio rápido con cuenta de Google |
| **Sesión de Invitado** | Prueba la app sin registro |
| **Sincronización en la Nube** | Firebase Firestore para datos remotos |
| **Modo Offline First** | Funciona sin conexión, sincroniza automáticamente |

### 🎨 Interfaz Adaptativa

| Feature | Descripción |
|---------|-------------|
| **Diseño Responsive** | Breakpoints: 600px (móvil), 900px (tablet), 1200px (desktop) |
| **Modo Oscuro/Claro** | Soporte para temas del sistema |
| **Animaciones** | Transiciones suaves, confeti, efectos visuales |
| **Accesible para Niños** | Botones grandes, emojis claros, feedback visual |

---

## 🏠 Estructura de Lecciones

### Categorías Disponibles
- 🌈 Colores
- 🐕 Animales
- 🍎 Frutas
- 👨‍👩‍👧‍👦 Familia
- 🔢 Números
- 👃 Partes del cuerpo
- 👕 Ropa
- 🍔 Comidas
- 🏃 Acciones
- 📚 Materias escolares

### Niveles
| Nivel | Descripción |
|-------|-------------|
| **Principiante** | Vocabulario básico, palabras simples |
| **Intermedio** | Oraciones completas, gramática básica |
| **Avanzado** | Reading, escritura, expresiones complejas |

---

## 🚀 Cómo Empezar

### Requisitos Previos

- [Flutter](https://flutter.dev/docs/get-started/install) (versión 3.10+)
- [Dart](https://dart.dev/get-dart) (versión 3.0+)
- [Android Studio](https://developer.android.com/studio) o [VS Code](https://code.visualstudio.com/)
- Cuenta en [Firebase](https://firebase.google.com/)

### Instalación

```bash
# 1. Clona el repositorio
git clone https://github.com/anvacode/english-ai-learning-app.git
cd english-ai-learning-app

# 2. Instala las dependencias
flutter pub get

# 3. Configura Firebase
# - Crea un proyecto en Firebase Console
# - Agrega apps Android, iOS y Web
# - Descarga google-services.json y GoogleService-Info.plist
# - Colócalos en las carpetas correspondientes
# - Habilita Authentication (Email/Password y Google)
# - Configura Firestore Database

# 4. Ejecuta la app
flutter run                    # Android
flutter run -d chrome          # Web
flutter run -d ios             # iOS (solo Mac)
```

---

## 📁 Estructura del Proyecto

```
lib/
├── main.dart                          # Punto de entrada
├── firebase_options.dart              # Configuración Firebase
│
├── data/                              # Datos y contenido
│   ├── lessons_data.dart              # Lecciones hardcodeadas
│   └── diagnostic_questions_data.dart # Preguntas test diagnóstico
│
├── logic/                             # Lógica de negocio
│   ├── auth_provider.dart             # Autenticación
│   ├── lesson_controller.dart         # Control de lecciones
│   ├── star_service.dart              # Gestión de estrellas
│   ├── badge_service.dart             # Sistema de logros
│   ├── user_profile_service.dart      # Perfil de usuario
│   └── activity_result_service.dart   # Resultados de actividades
│
├── models/                            # Modelos de datos
│   ├── lesson.dart                    # Lección
│   ├── lesson_item.dart               # Item de lección
│   ├── lesson_exercise.dart           # Tipo de ejercicio
│   ├── user_profile.dart               # Perfil de usuario
│   ├── badge.dart                     # Logro
│   └── activity_result.dart           # Resultado de actividad
│
├── screens/                           # Pantallas
│   ├── auth/                          # Autenticación
│   ├── diagnostic/                    # Test diagnóstico
│   ├── profile/                       # Perfil de usuario
│   ├── practice/                      # Ejercicios prácticos
│   ├── settings_screen.dart           # Configuración
│   ├── lesson_history_screen.dart     # Historial
│   ├── help_screen.dart               # Ayuda
│   └── home_screen.dart               # Pantalla principal
│
├── services/                          # Servicios externos
│   ├── firebase_service.dart          # Firebase
│   ├── audio_service.dart             # Audio y TTS
│   ├── speech_recognition_service.dart# Speech-to-text
│   ├── sync_service.dart              # Sincronización
│   ├── sync_queue_service.dart        # Cola de sync
│   ├── shop_service.dart              # Tienda
│   └── theme_service.dart            # Temas
│
├── widgets/                           # Widgets reutilizables
│   ├── avatar_widget.dart             # Avatar de usuario
│   ├── star_counter.dart              # Contador de estrellas
│   ├── practice_card.dart             # Card de práctica
│   └── lesson_image.dart              # Imagen de lección
│
└── theme/                             # Temas y estilos
    ├── app_colors.dart                # Colores
    └── app_icons.dart                  # Iconos
```

---

## 🛠️ Tecnologías Utilizadas

| Categoría | Paquetes |
|-----------|----------|
| **Framework** | Flutter, Dart |
| **Backend** | Firebase (Auth, Firestore) |
| **State Management** | Provider |
| **Almacenamiento** | SharedPreferences, SQLite (sqflite) |
| **Audio** | flutter_tts, audioplayers |
| **Voz** | speech_to_text, permission_handler |
| **Autenticación** | google_sign_in, firebase_auth |
| **Red** | connectivity_plus |
| **Utils** | uuid, json_annotation |

---

## 🧪 Testing

```bash
# Ejecutar todos los tests
flutter test

# Ejecutar análisis estático
flutter analyze

# Estado actual: 18 tests passing, 0 errores
```

---

## 🤝 Contribuir

1. Haz fork del repositorio
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commitea tus cambios (`git commit -m 'Agrega nueva funcionalidad'`)
4. Haz push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

### Normas de Código
- Ejecutar `flutter analyze` antes de commit
- Agregar tests para nuevas funcionalidades
- Usar snake_case para variables y PascalCase para clases
- Mantener null safety

---

## 📄 Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

---

## 👥 Autores

- **anvacode** - *Desarrollo inicial* - [GitHub](https://github.com/anvacode)

---

## 🙏 Agradecimientos

- Iconos por [Flutter Material Icons](https://fonts.google.com/icons)
- Comunidad de Flutter por el soporte
- Todos los contribuidores

---

<p align="center">
  <b>¡Aprende inglés de forma divertida! 🌟</b><br>
  <sub>Hecho con ❤️ para niños de 5-10 años</sub>
</p>
