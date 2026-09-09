import 'package:english_ai_app/screens/admin_dashboard_screen.dart';
import 'package:english_ai_app/services/firestore_progress_service.dart';
import 'package:english_ai_app/theme/app_colors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('avatarInitials', () {
    test('usa las iniciales del nickname con dos palabras', () {
      expect(avatarInitials('Juan Pérez', 'juan@test.com'), 'JP');
    });

    test('usa las dos primeras letras si el nickname es una sola palabra', () {
      expect(avatarInitials('María', 'maria@test.com'), 'MA');
    });

    test('cae al email si no hay nickname', () {
      expect(avatarInitials(null, 'luis@test.com'), 'LU');
    });

    test('cae al email si el nickname está vacío o en blanco', () {
      expect(avatarInitials('   ', 'ana@test.com'), 'AN');
    });

    test('maneja nombres de una sola letra', () {
      expect(avatarInitials('A', 'a@test.com'), 'A');
    });

    test('devuelve ? si no hay ningún dato usable', () {
      expect(avatarInitials(null, ''), '?');
    });
  });

  group('avatarColorFor', () {
    test('es determinístico para el mismo uid', () {
      expect(avatarColorFor('uid-123'), avatarColorFor('uid-123'));
    });

    test('devuelve colores de la paleta de la app', () {
      const palette = [
        AppColors.primary,
        AppColors.secondary,
        AppColors.success,
        AppColors.info,
        AppColors.purpleMagic,
        AppColors.orangeSun,
        AppColors.tealOcean,
        AppColors.pinkFun,
      ];
      for (final uid in ['a', 'bb', 'ccc', 'user-1', 'user-2', 'xyz']) {
        expect(palette, contains(avatarColorFor(uid)));
      }
    });

    test('varía entre usuarios distintos', () {
      final colors = {
        for (var i = 0; i < 20; i++) avatarColorFor('user-$i'),
      };
      // Con 20 usuarios y 8 colores, debe haber más de un color distinto.
      expect(colors.length, greaterThan(1));
    });
  });

  group('formatDayKey', () {
    test('formatea con ceros a la izquierda', () {
      expect(formatDayKey(DateTime(2026, 7, 3)), '2026-07-03');
      expect(formatDayKey(DateTime(2026, 12, 25)), '2026-12-25');
    });
  });

  group('aggregateSessionsByDay', () {
    final now = DateTime(2026, 7, 23, 15, 30); // un jueves a media tarde

    test('devuelve 7 días terminando hoy, de más antiguo a más reciente', () {
      final result = aggregateSessionsByDay(const [], now: now);
      expect(result.length, 7);
      expect(result.last.date, DateTime(2026, 7, 23));
      expect(result.first.date, DateTime(2026, 7, 17));
    });

    test('rellena con 0 los días sin datos', () {
      final result = aggregateSessionsByDay(const [], now: now);
      expect(result.every((d) => d.count == 0), isTrue);
    });

    test('suma las sesiones de varios usuarios por día', () {
      final result = aggregateSessionsByDay(
        [
          {'2026-07-23': 2, '2026-07-21': 1},
          {'2026-07-23': 3, '2026-07-20': 5},
        ],
        now: now,
      );
      expect(result.last.count, 5); // hoy: 2 + 3
      expect(result[4].count, 1); // 2026-07-21
      expect(result[3].count, 5); // 2026-07-20
    });

    test('ignora días fuera de la ventana y valores no numéricos', () {
      final result = aggregateSessionsByDay(
        [
          {'2020-01-01': 99, '2026-07-23': 'no-es-numero', '2026-07-22': 4},
        ],
        now: now,
      );
      expect(result.last.count, 0); // hoy: valor inválido ignorado
      expect(result[5].count, 4); // ayer
      expect(
        result.fold<int>(0, (sum, d) => sum + d.count),
        4, // el día de 2020 no se cuela en la suma
      );
    });

    test('tolera usuarios sin mapa sessionsByDay (null)', () {
      final result = aggregateSessionsByDay(
        [null, {'2026-07-23': 1}],
        now: now,
      );
      expect(result.last.count, 1);
    });
  });

  group('countNewUsersThisWeek', () {
    final now = DateTime(2026, 7, 23, 12);

    test('cuenta solo registros de los últimos 7 días', () {
      final count = countNewUsersThisWeek(
        [
          now.subtract(const Duration(days: 1)),
          now.subtract(const Duration(days: 6)),
          now.subtract(const Duration(days: 8)), // fuera de la ventana
          null,
        ],
        now: now,
      );
      expect(count, 2);
    });

    test('devuelve 0 si no hay fechas válidas', () {
      expect(countNewUsersThisWeek([null, null], now: now), 0);
      expect(countNewUsersThisWeek(const [], now: now), 0);
    });
  });
}
