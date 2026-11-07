// Hoja modal interactiva de la Academia de 10 Niveles y Generador Infinito de Retos.
// Cumple RF-006, RN-008 y RNF-004 (anidación <= 2, contraste WCAG AA y áreas >= 48dp).

import 'package:flutter/material.dart';
import '../academy/academy_engine.dart';
import 'game_controller.dart';

class AcademySheet extends StatelessWidget {
  final GameController controller;

  const AcademySheet({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final levels = AcademyCurriculum.allLevels;
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 10),
          _buildInfiniteGeneratorCard(context),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: levels.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _buildLevelCard(context, levels[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Academia (10 Niveles) · Superados: ${controller.completedLessonIds.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildInfiniteGeneratorCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF38BDF8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFFBBF24), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Laboratorio Infinito (Resueltos: ${controller.infinitePuzzlesSolved})',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: ElevatedButton(
              onPressed: () {
                controller.startNextInfinitePuzzle();
                Navigator.of(context).pop();
              },
              child: const Text('Nuevo Reto'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(BuildContext context, AcademyLevel level) {
    final lesson = level.lessons.first;
    final isDone = controller.completedLessonIds.contains(lesson.id);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone ? const Color(0xFF10B981) : const Color(0xFF475569),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLevelTitleRow(level, isDone),
          const SizedBox(height: 6),
          Text(
            level.summary,
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            'Técnicas: ${level.featuredTechniques.join(" · ")}',
            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: ElevatedButton.icon(
              onPressed: () {
                controller.startAcademyLesson(lesson);
                Navigator.of(context).pop();
              },
              icon: Icon(isDone ? Icons.check_circle : Icons.play_arrow),
              label: Text('Practicar: ${lesson.title}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelTitleRow(AcademyLevel level, bool isDone) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            level.rankTitle,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
        if (isDone)
          const Icon(Icons.verified, color: Color(0xFF10B981), size: 20),
      ],
    );
  }
}
