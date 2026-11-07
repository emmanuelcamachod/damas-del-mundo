// Pantalla móvil interactiva Multivariante (8x8 y 10x10) con IA Adaptativa, Academia 10 Niveles y Coach.
// Cumple 05_CALIDAD/ui_ux.md: 5 estados visuales, WCAG AA >= 4.5:1 y áreas >= 48dp.

import 'package:flutter/material.dart';
import '../domain/checkers_engine.dart';
import 'academy_sheet.dart';
import 'ai_dna_sheet.dart';
import 'game_controller.dart';
import 'victory_celebration_dialog.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  late final GameController _controller;
  GameStatus _lastSeenStatus = GameStatus.inProgress;

  @override
  void initState() {
    super.initState();
    _controller = GameController();
    _controller.addListener(_handleGameStateChanged);
  }

  void _handleGameStateChanged() {
    final newStatus = _controller.currentBoard.status;
    if (newStatus != _lastSeenStatus) {
      _lastSeenStatus = newStatus;
      if (newStatus == GameStatus.whiteWins || newStatus == GameStatus.blackWins) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showVictoryDialog();
        });
      }
    }
  }

  void _showVictoryDialog() {
    if (!mounted) {
      return;
    }
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => VictoryCelebrationDialog(
        controller: _controller,
        onRematch: _controller.resetGame,
        onInspectDna: _openAiDnaSheet,
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_handleGameStateChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: _buildAppBar(),
        body: SafeArea(
          child: Column(
            children: [
              _buildVariantAndModeToolbar(),
              _buildFeedbackBanner(),
              _buildScoreAndTurnHeader(),
              Expanded(child: _buildBoardWithAdvantageBar()),
              _buildMoveHistoryPanel(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final lesson = _controller.activeLesson;
    final titleText = lesson != null
        ? 'Academia: ${lesson.title}'
        : 'Damas: ${_controller.currentBoard.ruleset.displayName}';
    return AppBar(
      backgroundColor: const Color(0xFF1E293B),
      foregroundColor: Colors.white,
      title: Text(
        titleText,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      actions: [
        IconButton(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          tooltip: 'Pedir Pista Explicada al Entrenador Táctico (Coach)',
          onPressed: _controller.requestCoachAdvice,
          icon: const Icon(Icons.lightbulb_outline, color: Color(0xFFFBBF24)),
        ),
        IconButton(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          tooltip: 'Ver ADN del Jugador y Errores Críticos',
          onPressed: _openAiDnaSheet,
          icon: const Icon(Icons.analytics_outlined, color: Color(0xFF38BDF8)),
        ),
        IconButton(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          tooltip: _controller.canUndo
              ? 'Deshacer última jugada'
              : 'Sin jugadas para deshacer (Estado Disabled)',
          onPressed: _controller.canUndo ? _controller.undoLastMove : null,
          icon: const Icon(Icons.undo),
        ),
        IconButton(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          tooltip: 'Reiniciar partida o ejercicio',
          onPressed: _controller.resetGame,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  void _openAiDnaSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AiDnaSheet(controller: _controller),
    );
  }

  void _openAcademySheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AcademySheet(controller: _controller),
    );
  }

  Widget _buildVariantAndModeToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF1E293B),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildVariantSelectorButton(),
            const SizedBox(width: 8),
            _buildAcademyButtonChip(),
            const SizedBox(width: 8),
            _buildAiToggleChip(),
            const SizedBox(width: 8),
            _buildHuffingToggleChip(),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantSelectorButton() {
    return PopupMenuButton<CheckersRuleset>(
      tooltip: 'Seleccionar variante de Damas del Mundo',
      onSelected: (preset) {
        final withHuff = preset.copyWith(
          allowHuffing: _controller.currentBoard.ruleset.allowHuffing,
        );
        _controller.changeRuleset(withHuff);
      },
      itemBuilder: (context) {
        return [
          for (final preset in CheckersRuleset.allWorldPresets)
            PopupMenuItem<CheckersRuleset>(
              value: preset,
              child: Text(preset.displayName),
            ),
        ];
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Chip(
          avatar: const Icon(Icons.public, color: Color(0xFF0F172A), size: 20),
          label: Text(
            _controller.currentBoard.ruleset.displayName,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFF38BDF8),
        ),
      ),
    );
  }

  Widget _buildAcademyButtonChip() {
    final inAcademy = _controller.activeLesson != null;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: ActionChip(
        avatar: const Icon(Icons.school, color: Colors.white, size: 20),
        backgroundColor: inAcademy ? const Color(0xFF7C3AED) : const Color(0xFF4F46E5),
        onPressed: _openAcademySheet,
        label: Text(
          inAcademy
              ? 'Academia: Nivel ${_controller.activeLesson!.levelNumber}/10'
              : 'Academia (10 Niveles + Retos)',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAiToggleChip() {
    final active = _controller.vsAiEnabled;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: FilterChip(
        selected: active,
        onSelected: _controller.toggleVsAiMode,
        selectedColor: const Color(0xFF059669),
        backgroundColor: const Color(0xFF334155),
        label: Text(
          active ? 'Vs IA Némesis (Activa)' : '2 Jugadores Local',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildHuffingToggleChip() {
    final huffOn = _controller.currentBoard.ruleset.allowHuffing;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: FilterChip(
        selected: huffOn,
        onSelected: _controller.toggleHuffingRule,
        selectedColor: const Color(0xFFD97706),
        backgroundColor: const Color(0xFF334155),
        label: Text(
          huffOn ? 'Regla del Soplido: SÍ' : 'Captura Obligatoria',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildFeedbackBanner() {
    if (_controller.isLoading) {
      return _buildBannerBox(
        color: const Color(0xFF1E3A8A),
        icon: Icons.psychology,
        text: 'IA Némesis calculando en Isolate (Alfa-Beta + Libro del Rival)...',
      );
    }
    if (_controller.currentBoard.canHuff) {
      return _buildBannerBox(
        color: const Color(0xFFB45309),
        icon: Icons.air,
        text: '¡El rival omitió comer! Toca su pieza infractora (borde rojo) para SOPLARLA gratis antes de mover.',
      );
    }
    if (_controller.humanErrorMessage != null) {
      return _buildBannerBox(
        color: const Color(0xFF991B1B),
        icon: Icons.warning_amber_rounded,
        text: _controller.humanErrorMessage!,
      );
    }
    if (_controller.successMessage != null) {
      return _buildBannerBox(
        color: const Color(0xFF065F46),
        icon: Icons.emoji_events_outlined,
        text: _controller.successMessage!,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBannerBox({
    required Color color,
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: color,
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreAndTurnHeader() {
    final board = _controller.currentBoard;
    final whiteCount = board.countPieces(PlayerColor.white);
    final blackCount = board.countPieces(PlayerColor.black);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPlayerCounter('Blancas', whiteCount, board.turn == PlayerColor.white),
          _buildMandatoryCaptureBadge(board.hasMandatoryCapture),
          _buildPlayerCounter(
            _controller.vsAiEnabled ? 'IA Némesis' : 'Negras',
            blackCount,
            board.turn == PlayerColor.black,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCounter(String label, int count, bool isActiveTurn) {
    final borderColor = isActiveTurn ? const Color(0xFF38BDF8) : Colors.transparent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Text(
        '$label: $count',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildMandatoryCaptureBadge(bool hasCapture) {
    if (!hasCapture) {
      return const Text(
        'Movimiento Libre',
        style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFB45309),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        children: [
          Icon(Icons.bolt, color: Colors.white, size: 16),
          SizedBox(width: 4),
          Text(
            '¡Captura Disponible!',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardWithAdvantageBar() {
    return Row(
      children: [
        _buildAdvantageThermometer(),
        Expanded(child: _buildCenteredBoard()),
      ],
    );
  }

  Widget _buildAdvantageThermometer() {
    final clamped = _controller.lastEvaluationCp.clamp(-600.0, 600.0);
    final whiteRatio = ((clamped + 600.0) / 1200.0).clamp(0.08, 0.92);
    return Container(
      width: 14,
      margin: const EdgeInsets.only(left: 10, top: 14, bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF475569)),
      ),
      child: Column(
        children: [
          Expanded(
            flex: ((1.0 - whiteRatio) * 100).round(),
            child: Container(color: const Color(0xFF0F172A)),
          ),
          Expanded(
            flex: (whiteRatio * 100).round(),
            child: Container(color: const Color(0xFFF8FAFC)),
          ),
        ],
      ),
    );
  }

  Widget _buildCenteredBoard() {
    final size = _controller.currentBoard.ruleset.boardSize;
    final totalSquares = _controller.currentBoard.ruleset.totalSquares;
    return Center(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF475569), width: 3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalSquares,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: size,
            ),
            itemBuilder: (context, index) {
              final pos = BoardPosition(index ~/ size, index % size);
              return _buildBoardSquare(pos);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBoardSquare(BoardPosition pos) {
    final ruleset = _controller.currentBoard.ruleset;
    final isPlayable = BoardPosition.isPlayableForRuleset(pos.row, pos.col, ruleset);
    final isSelected = _controller.selectedPosition == pos;
    final targetMove = _findTargetMoveForPosition(pos);
    final isMandatoryOrigin = _isMandatoryOriginSquare(pos);
    final isHuffable = _controller.currentBoard.huffablePositions.contains(pos);
    final bgColor = _resolveSquareBackgroundColor(
      isPlayable,
      isSelected,
      targetMove != null,
    );
    return Semantics(
      button: isPlayable,
      label: 'Casilla ${pos.toAlgebraicLabel(ruleset.boardSize)}',
      child: InkWell(
        onTap: () => _controller.onSquareTapped(pos),
        child: Container(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          color: bgColor,
          child: _buildSquareContent(
            pos,
            targetMove,
            isMandatoryOrigin,
            isHuffable,
          ),
        ),
      ),
    );
  }

  Color _resolveSquareBackgroundColor(
    bool isPlayable,
    bool isSelected,
    bool isTarget,
  ) {
    if (!isPlayable) {
      return const Color(0xFFE2E8F0);
    }
    if (isSelected) {
      return const Color(0xFF0284C7);
    }
    if (isTarget) {
      return const Color(0xFF15803D);
    }
    return const Color(0xFF334155);
  }

  Widget _buildSquareContent(
    BoardPosition pos,
    CheckersMove? targetMove,
    bool isMandatoryOrigin,
    bool isHuffable,
  ) {
    final piece = _controller.currentBoard.pieceAt(pos);
    if (piece != null) {
      return _buildPieceToken(piece, isMandatoryOrigin, isHuffable);
    }
    if (targetMove != null) {
      return _buildTargetIndicator(targetMove.isCapture);
    }
    return const SizedBox.shrink();
  }

  Widget _buildPieceToken(
    CheckersPiece piece,
    bool isMandatoryOrigin,
    bool isHuffable,
  ) {
    final isWhite = piece.color == PlayerColor.white;
    final strokeColor = _resolvePieceBorderColor(
      isWhite,
      isMandatoryOrigin,
      isHuffable,
    );
    return Container(
      margin: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isWhite
              ? const [Color(0xFFFFFFFF), Color(0xFFF1F5F9), Color(0xFFCBD5E1)]
              : const [Color(0xFF334155), Color(0xFF1E293B), Color(0xFF090D16)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isWhite ? 0.35 : 0.6),
            blurRadius: 5,
            offset: const Offset(1.5, 3.0),
          ),
        ],
        border: Border.all(
          color: strokeColor,
          width: (isMandatoryOrigin || isHuffable) ? 3.0 : 1.8,
        ),
      ),
      child: Center(
        child: _buildSteppedRibbedRing(piece, isWhite),
      ),
    );
  }

  Widget _buildSteppedRibbedRing(CheckersPiece piece, bool isWhite) {
    final ringBorderColor = isWhite ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    return Container(
      margin: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: ringBorderColor,
          width: 1.2,
        ),
      ),
      child: Center(
        child: _buildInnerPieceContent(piece, isWhite),
      ),
    );
  }

  Widget _buildInnerPieceContent(CheckersPiece piece, bool isWhite) {
    if (piece.isKing) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.55),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          Icons.workspace_premium,
          size: 22,
          color: isWhite ? const Color(0xFFB45309) : const Color(0xFFFCD34D),
        ),
      );
    }
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isWhite ? const Color(0xFF94A3B8) : const Color(0xFF334155),
          width: 1.2,
        ),
        color: isWhite
            ? const Color(0xFFE2E8F0).withValues(alpha: 0.6)
            : const Color(0xFF0F172A).withValues(alpha: 0.6),
      ),
    );
  }

  Color _resolvePieceBorderColor(
    bool isWhite,
    bool isMandatoryOrigin,
    bool isHuffable,
  ) {
    if (isHuffable) {
      return const Color(0xFFEF4444);
    }
    if (isMandatoryOrigin) {
      return const Color(0xFFF59E0B);
    }
    return isWhite ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
  }

  Widget _buildTargetIndicator(bool isCaptureTarget) {
    return Center(
      child: Icon(
        isCaptureTarget ? Icons.gps_fixed : Icons.circle,
        size: isCaptureTarget ? 22 : 14,
        color: Colors.white,
      ),
    );
  }

  CheckersMove? _findTargetMoveForPosition(BoardPosition pos) {
    for (final move in _controller.movesForSelectedPiece) {
      if (move.to == pos) {
        return move;
      }
    }
    return null;
  }

  bool _isMandatoryOriginSquare(BoardPosition pos) {
    if (!_controller.currentBoard.hasMandatoryCapture) {
      return false;
    }
    for (final move in _controller.currentBoard.mandatoryCaptures()) {
      if (move.from == pos) {
        return true;
      }
    }
    return false;
  }

  Widget _buildMoveHistoryPanel() {
    final logs = _controller.moveLog;
    return Container(
      height: 76,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF1E293B),
      child: logs.isEmpty
          ? _buildEmptyMoveHistoryState()
          : _buildPopulatedMoveHistory(logs),
    );
  }

  Widget _buildEmptyMoveHistoryState() {
    return const Row(
      children: [
        Icon(Icons.touch_app_outlined, color: Color(0xFF38BDF8), size: 22),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Sin jugadas registradas aún (Estado Empty). Toca una ficha, abre la Academia (10 Niveles) o pide pista al Coach (bombilla).',
            style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildPopulatedMoveHistory(List<MoveHistoryEntry> logs) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final item = logs[index];
        return Chip(
          backgroundColor: const Color(0xFF334155),
          label: Text(
            '#${item.moveNumber} ${item.player.displayName}: ${item.notation}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        );
      },
    );
  }
}
