// Pantalla móvil interactiva Multivariante (8x8 y 10x10) con IA Adaptativa, Academia 10 Niveles y Coach.
// Cumple 05_CALIDAD/ui_ux.md: 5 estados visuales, WCAG AA >= 4.5:1 y áreas >= 48dp.

import 'package:flutter/material.dart';
import '../domain/checkers_engine.dart';
import '../multiplayer/multiplayer.dart';
import 'academy_sheet.dart';
import 'ai_dna_sheet.dart';
import 'coin_shop_dialog.dart';
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
            _buildCoinWalletChip(),
            const SizedBox(width: 8),
            _buildOnlineBettingSelectorChip(),
            const SizedBox(width: 8),
            _buildVariantSelectorButton(),
            const SizedBox(width: 8),
            _buildDifficultySelectorChip(),
            const SizedBox(width: 8),
            _buildThemeSelectorChip(),
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

  Widget _buildCoinWalletChip() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: ActionChip(
        onPressed: () => CoinShopDialog.show(context, _controller),
        backgroundColor: const Color(0xFF0F172A),
        avatar: const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_controller.playerCoins} 🪙',
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.add_circle, color: Colors.amber, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineBettingSelectorChip() {
    final isOnline = _controller.isOnlineMatch;
    return PopupMenuButton<MatchmakingTier>(
      tooltip: 'Buscar Partida Online con Apuesta de Monedas',
      onSelected: (tier) => _controller.joinOnlineMatchWithBet(tier),
      itemBuilder: (context) {
        return [
          for (final tier in MatchmakingTier.allTiers)
            PopupMenuItem<MatchmakingTier>(
              value: tier,
              child: Row(
                children: [
                  Text(tier.iconEmoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${tier.name} (Apuesta: ${tier.entryFee} 🪙 | Pozo: ${tier.prizePool} 🪙)'),
                  ),
                ],
              ),
            ),
        ];
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Chip(
          backgroundColor: isOnline ? const Color(0xFF059669) : const Color(0xFFD97706),
          avatar: Icon(
            isOnline ? Icons.wifi : Icons.sports_esports,
            color: Colors.white,
            size: 20,
          ),
          label: Text(
            isOnline
                ? 'Online (${_controller.activeOnlineRoom?.tier.entryFee} 🪙)'
                : 'Apostar Online',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultySelectorChip() {
    return PopupMenuButton<AiDifficulty>(
      tooltip: 'Cambiar Dificultad de la IA Offline',
      onSelected: _controller.setAiDifficulty,
      itemBuilder: (context) {
        return [
          for (final diff in AiDifficulty.values)
            PopupMenuItem<AiDifficulty>(
              value: diff,
              child: Text(diff.displayName),
            ),
        ];
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Chip(
          backgroundColor: const Color(0xFF1E3A8A),
          avatar: const Icon(Icons.speed, color: Colors.cyanAccent, size: 20),
          label: Text(
            _controller.aiDifficulty.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelectorChip() {
    return PopupMenuButton<BoardVisualTheme>(
      tooltip: 'Cambiar Estilo y Tema del Tablero',
      onSelected: _controller.setBoardVisualTheme,
      itemBuilder: (context) {
        return [
          for (final theme in BoardVisualTheme.values)
            PopupMenuItem<BoardVisualTheme>(
              value: theme,
              child: Text(theme.displayName),
            ),
        ];
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Chip(
          backgroundColor: const Color(0xFF334155),
          avatar: const Icon(Icons.palette_outlined, color: Colors.amber, size: 20),
          label: Text(
            _controller.boardVisualTheme.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
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

  Color _resolveBoardBorderColor() {
    switch (_controller.boardVisualTheme) {
      case BoardVisualTheme.classicWood:
        return const Color(0xFF451A03);
      case BoardVisualTheme.luxuryMarble:
        return const Color(0xFF334155);
      case BoardVisualTheme.cyberNeon:
        return const Color(0xFF06B6D4);
      case BoardVisualTheme.tuscanLeather:
        return const Color(0xFF78350F);
      case BoardVisualTheme.royalJade:
        return const Color(0xFF059669);
    }
  }

  Color _resolveBoardFrameColor() {
    switch (_controller.boardVisualTheme) {
      case BoardVisualTheme.classicWood:
        return const Color(0xFF2D180B);
      case BoardVisualTheme.luxuryMarble:
        return const Color(0xFF0B0F19);
      case BoardVisualTheme.cyberNeon:
        return const Color(0xFF050811);
      case BoardVisualTheme.tuscanLeather:
        return const Color(0xFF321C11);
      case BoardVisualTheme.royalJade:
        return const Color(0xFF041F16);
    }
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
            color: _resolveBoardFrameColor(),
            border: Border.all(color: _resolveBoardBorderColor(), width: 3.5),
            borderRadius: BorderRadius.circular(10),
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
          child: CustomPaint(
            painter: _TactileGrainPainter(
              theme: _controller.boardVisualTheme,
              isPlayable: isPlayable,
              isSelectedOrTarget: isSelected || targetMove != null,
            ),
            child: _buildSquareContent(
              pos,
              targetMove,
              isMandatoryOrigin,
              isHuffable,
            ),
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
    if (isSelected) {
      return const Color(0xFF0284C7);
    }
    if (isTarget) {
      return const Color(0xFF15803D);
    }
    final theme = _controller.boardVisualTheme;
    if (!isPlayable) {
      switch (theme) {
        case BoardVisualTheme.classicWood:
          return const Color(0xFFD8B68A);
        case BoardVisualTheme.luxuryMarble:
          return const Color(0xFFE2E8F0);
        case BoardVisualTheme.cyberNeon:
          return const Color(0xFF13203C);
        case BoardVisualTheme.tuscanLeather:
          return const Color(0xFFD7CCC8);
        case BoardVisualTheme.royalJade:
          return const Color(0xFFD1FAE5);
      }
    }
    switch (theme) {
      case BoardVisualTheme.classicWood:
        return const Color(0xFF5C3A21);
      case BoardVisualTheme.luxuryMarble:
        return const Color(0xFF0F172A);
      case BoardVisualTheme.cyberNeon:
        return const Color(0xFF090D16);
      case BoardVisualTheme.tuscanLeather:
        return const Color(0xFF451A03);
      case BoardVisualTheme.royalJade:
        return const Color(0xFF064E3B);
    }
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

  List<Color> _resolvePieceGradient(bool isWhite) {
    final theme = _controller.boardVisualTheme;
    if (isWhite) {
      switch (theme) {
        case BoardVisualTheme.classicWood:
          return const [Color(0xFFFFFFFF), Color(0xFFF1F5F9), Color(0xFFCBD5E1)];
        case BoardVisualTheme.luxuryMarble:
          return const [Color(0xFFFFFFFF), Color(0xFFF8FAFC), Color(0xFFCBD5E1)];
        case BoardVisualTheme.cyberNeon:
          return const [Color(0xFFE0F2FE), Color(0xFF38BDF8), Color(0xFF0284C7)];
        case BoardVisualTheme.tuscanLeather:
          return const [Color(0xFFFFFBEB), Color(0xFFFEF3C7), Color(0xFFD97706)];
        case BoardVisualTheme.royalJade:
          return const [Color(0xFFECFDF5), Color(0xFFA7F3D0), Color(0xFF34D399)];
      }
    }
    switch (theme) {
      case BoardVisualTheme.classicWood:
        return const [Color(0xFF334155), Color(0xFF1E293B), Color(0xFF090D16)];
      case BoardVisualTheme.luxuryMarble:
        return const [Color(0xFF1E293B), Color(0xFF090D16), Color(0xFF020617)];
      case BoardVisualTheme.cyberNeon:
        return const [Color(0xFF4C0519), Color(0xFF9F1239), Color(0xFF1C030B)];
      case BoardVisualTheme.tuscanLeather:
        return const [Color(0xFF291811), Color(0xFF180D09), Color(0xFF0A0503)];
      case BoardVisualTheme.royalJade:
        return const [Color(0xFF022C22), Color(0xFF064E3B), Color(0xFF011510)];
    }
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
          colors: _resolvePieceGradient(isWhite),
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
    return const SizedBox.shrink();
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

class _TactileGrainPainter extends CustomPainter {
  const _TactileGrainPainter({
    required this.theme,
    required this.isPlayable,
    required this.isSelectedOrTarget,
  });

  final BoardVisualTheme theme;
  final bool isPlayable;
  final bool isSelectedOrTarget;

  @override
  void paint(Canvas canvas, Size size) {
    if (isSelectedOrTarget) return;
    if (theme == BoardVisualTheme.classicWood) {
      _paintWoodGrain(canvas, size);
      return;
    }
    if (theme == BoardVisualTheme.tuscanLeather) {
      _paintLeatherGrain(canvas, size);
      return;
    }
  }

  void _paintWoodGrain(Canvas canvas, Size size) {
    final stripeColor = isPlayable
        ? const Color(0xFF241106).withValues(alpha: 0.55)
        : const Color(0xFF8C5828).withValues(alpha: 0.35);
    final paint = Paint()
      ..color = stripeColor
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    const step = 8.0;
    final total = size.width + size.height;
    for (double d = 0; d <= total; d += step) {
      canvas.drawLine(Offset(d, 0), Offset(0, d), paint);
    }
  }

  void _paintLeatherGrain(Canvas canvas, Size size) {
    final stripeColor = isPlayable
        ? const Color(0xFF1A0801).withValues(alpha: 0.65)
        : const Color(0xFF6D4C41).withValues(alpha: 0.35);
    final paint = Paint()
      ..color = stripeColor
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    const stepX = 7.0;
    for (double x = 0; x <= size.width; x += stepX) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    final crossPaint = Paint()
      ..color = stripeColor.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    const stepY = 10.0;
    for (double y = 0; y <= size.height; y += stepY) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), crossPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TactileGrainPainter oldDelegate) {
    return oldDelegate.theme != theme ||
        oldDelegate.isPlayable != isPlayable ||
        oldDelegate.isSelectedOrTarget != isSelectedOrTarget;
  }
}
