import 'package:flutter/material.dart';

import '../theme/app_colors_extension.dart';
import '../utils/responsive.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/responsive_container.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentIndex: -1,
      child: ResponsiveContainer(
        maxWidth: 700,
        child: ListView(
          padding: EdgeInsets.all(Responsive.scale(context, 16, 20, 24)),
          children: [
            SizedBox(height: Responsive.scale(context, 12, 16, 20)),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(Responsive.scale(context, 12, 14, 16)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withAlpha(30),
                        Theme.of(context).colorScheme.primary.withAlpha(10),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.help_outline_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: Responsive.scale(context, 28, 32, 36),
                  ),
                ),
                SizedBox(width: Responsive.scale(context, 12, 16, 20)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ayuda y Soporte',
                        style: TextStyle(
                          fontSize: Responsive.scale(context, 22, 26, 30),
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Encuentra respuestas a tus preguntas',
                        style: TextStyle(
                          fontSize: Responsive.scale(context, 13, 14, 15),
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.scale(context, 20, 24, 28)),
            Text(
              'Preguntas frecuentes',
              style: TextStyle(
                fontSize: Responsive.scale(context, 16, 17, 18),
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: Responsive.scale(context, 12, 14, 16)),
            _buildFaqSection(
              context,
              '¿Cómo funciona la app?',
              'English Learning es una aplicación para niños de 5-8 años que les ayuda a aprender inglés de forma divertida mediante lecciones interactivas, juegos y prácticas de pronunciación.',
              Icons.play_circle_outline,
            ),
            _buildFaqSection(
              context,
              '¿Cómo gano estrellas?',
              'Puedes ganar estrellas al completar lecciones, responder correctamente preguntas y lograr buenos resultados en los ejercicios de práctica.',
              Icons.star_outline_rounded,
            ),
            _buildFaqSection(
              context,
              '¿Qué son los badges?',
              'Los badges son logros que obtienes al completar lecciones. Cada badge tiene un icono único que se muestra en tu perfil cuando lo desbloqueas.',
              Icons.emoji_events_outlined,
            ),
            _buildFaqSection(
              context,
              '¿Cómo funciona la práctica de pronunciación?',
              'La práctica de pronunciación usa el micrófono de tu dispositivo para escucharte y evaluar si pronuncias las palabras correctamente en inglés.',
              Icons.mic_none_rounded,
            ),
            _buildFaqSection(
              context,
              '¿Puedo cambiar el idioma de la app?',
              'Por ahora la app está disponible en español como idioma de interfaz, pero las lecciones son en inglés.',
              Icons.language_rounded,
            ),
            SizedBox(height: Responsive.scale(context, 24, 28, 32)),
            Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
            SizedBox(height: Responsive.scale(context, 20, 24, 28)),
            Text(
              '¿Necesitas más ayuda?',
              style: TextStyle(
                fontSize: Responsive.scale(context, 17, 18, 20),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: Responsive.scale(context, 12, 14, 16)),
            Container(
              padding: EdgeInsets.all(Responsive.scale(context, 18, 20, 24)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer.withAlpha(80),
                    Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(50),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant.withAlpha(100),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(Responsive.scale(context, 8, 10, 12)),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.email_outlined,
                          color: Theme.of(context).colorScheme.primary,
                          size: Responsive.scale(context, 20, 22, 24),
                        ),
                      ),
                      SizedBox(width: Responsive.scale(context, 10, 12, 14)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email de soporte',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: Responsive.scale(context, 14, 15, 16),
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'english.learning.app.4559e@gmail.com',
                              style: TextStyle(
                                fontSize: Responsive.scale(context, 13, 14, 15),
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.scale(context, 16, 18, 20)),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(Responsive.scale(context, 8, 10, 12)),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: Responsive.scale(context, 20, 22, 24),
                        ),
                      ),
                      SizedBox(width: Responsive.scale(context, 10, 12, 14)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Versión',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: Responsive.scale(context, 14, 15, 16),
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '2.0.0',
                              style: TextStyle(
                                fontSize: Responsive.scale(context, 13, 14, 15),
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.scale(context, 20, 24, 28)),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqSection(
    BuildContext context,
    String question,
    String answer,
    IconData icon,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: Responsive.scale(context, 10, 12, 14)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withAlpha(120),
        ),
        boxShadow: [
          BoxShadow(
            color: context.appColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          tilePadding: EdgeInsets.all(Responsive.scale(context, 14, 16, 18)),
          childrenPadding: EdgeInsets.fromLTRB(
            Responsive.scale(context, 14, 16, 18),
            0,
            Responsive.scale(context, 14, 16, 18),
            Responsive.scale(context, 14, 16, 18),
          ),
          leading: Container(
            padding: EdgeInsets.all(Responsive.scale(context, 6, 8, 10)),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: Responsive.scale(context, 18, 20, 22),
            ),
          ),
          title: Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: Responsive.scale(context, 14, 15, 16),
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          children: [
            Text(
              answer,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
                fontSize: Responsive.scale(context, 13, 14, 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
