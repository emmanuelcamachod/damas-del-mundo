#!/usr/bin/env node
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.resolve(__dirname, '..');
const html = fs.readFileSync(path.join(ROOT, 'index.html'), 'utf8');

const START_MARKER = '// === PURE ENGINE START ===';
const END_MARKER = '// === PURE ENGINE END ===';
const startIdx = html.indexOf(START_MARKER);
const endIdx = html.indexOf(END_MARKER);
assert.ok(startIdx !== -1 && endIdx !== -1 && endIdx > startIdx, 'Markers PURE ENGINE missing in index.html');

const engineCode = html.slice(startIdx, endIdx + END_MARKER.length);
const wrappedCode = `${engineCode}
;globalThis.__ENGINE__ = {
  RULES,
  getRuleConfig,
  createEmptyBoardPure,
  cloneBoardPure,
  createInitialBoardPure,
  generateLegalMovesPure,
  applyFullMovePure,
  computeHuffableTargetsPure,
  computeBoardSignaturePure,
  evaluateBoardPure,
  findBestAiDecisionPure,
  getDifficultyParamsPure
};`;

const context = vm.createContext({ Math, Array, Boolean, Number, String, Object, Error, console });
vm.runInContext(wrappedCode, context);
const E = context.__ENGINE__;
assert.ok(E && E.RULES && E.generateLegalMovesPure, 'Pure engine export failed');

function countPieces(board, col) {
  let count = 0;
  for (let r = 0; r < board.length; r++) {
    for (let c = 0; c < board[r].length; c++) {
      if (board[r][c] && board[r][c].col === col) count++;
    }
  }
  return count;
}

function runTest(name, fn) {
  fn();
  console.log(`[PASS] ${name}`);
}

// 1. Initial boards & piece counts for all 7 variants
runTest('Initial boards & piece counts for all 7 variants', () => {
  const expected = {
    spanish: { size: 8, pieces: 12 },
    international: { size: 10, pieces: 20 },
    brazilian: { size: 8, pieces: 12 },
    english: { size: 8, pieces: 12 },
    russian: { size: 8, pieces: 12 },
    italian: { size: 8, pieces: 12 },
    turkish: { size: 8, pieces: 16 },
  };
  for (const [id, spec] of Object.entries(expected)) {
    const cfg = E.getRuleConfig(id);
    assert.equal(cfg.size, spec.size, `${id} size`);
    const b = E.createInitialBoardPure(id);
    assert.equal(b.length, spec.size);
    assert.equal(countPieces(b, 'w'), spec.pieces, `${id} white count`);
    assert.equal(countPieces(b, 'b'), spec.pieces, `${id} black count`);
    const opening = E.generateLegalMovesPure(b, cfg, 'w', false);
    assert.ok(opening.moves.length > 0, `${id} opening moves exist`);
  }
});

// 2. Spanish Draughts: mandatory capture, NO backward pawn capture
runTest('Spanish Draughts: mandatory capture & pawn cannot capture backward', () => {
  const cfg = E.getRuleConfig('spanish');
  const b = E.createEmptyBoardPure(8);
  // White pawn at (3,2), Black pawn behind it at (4,3) -> white pawn CANNOT capture backward
  b[3][2] = { col: 'w', king: false };
  b[4][3] = { col: 'b', king: false };
  const genNoBack = E.generateLegalMovesPure(b, cfg, 'w', false);
  assert.equal(genNoBack.hasMandatoryCapture, false);
  assert.ok(genNoBack.moves.every(m => m.captures.length === 0));

  // Add Black pawn ahead at (2,3) with empty landing (1,4) -> mandatory forward capture
  b[2][3] = { col: 'b', king: false };
  const genFwd = E.generateLegalMovesPure(b, cfg, 'w', false);
  assert.equal(genFwd.hasMandatoryCapture, true);
  assert.equal(genFwd.moves.length, 1);
  assert.equal(genFwd.moves[0].toR, 1);
  assert.equal(genFwd.moves[0].toC, 4);
});

// 3. Spanish Draughts: Law of Quantity (2 captures beat 1) & Law of Quality (1 king beats 1 pawn)
runTest('Spanish Draughts: Law of Quantity and Law of Quality', () => {
  const cfg = E.getRuleConfig('spanish');
  const b1 = E.createEmptyBoardPure(8);
  // Pawn at (6,1) can either go 1-jump over (5,0) -> (4,-1 impossible) wait:
  // Pawn A at (5,0) jumps (4,1) -> (3,2) -> 1 capture
  // Pawn B at (6,3) jumps (5,4)->(4,5)->(3,6)->(2,7) -> 2 captures
  b1[5][0] = { col: 'w', king: false };
  b1[4][1] = { col: 'b', king: false };
  b1[6][3] = { col: 'w', king: false };
  b1[5][4] = { col: 'b', king: false };
  b1[3][6] = { col: 'b', king: false };
  const qMoves = E.generateLegalMovesPure(b1, cfg, 'w', false);
  assert.equal(qMoves.moves.length, 1);
  assert.equal(qMoves.moves[0].fromR, 6);
  assert.equal(qMoves.moves[0].fromC, 3);
  assert.equal(qMoves.moves[0].captures.length, 2);

  // Law of Quality: tie of 1 capture -> King captures Black King (quality 1) vs Pawn/King captures Black Pawn (quality 0)
  const b2 = E.createEmptyBoardPure(8);
  b2[7][0] = { col: 'w', king: true };
  b2[5][2] = { col: 'b', king: true }; // Quality 1
  b2[6][5] = { col: 'w', king: false };
  b2[5][6] = { col: 'b', king: false }; // Quality 0
  const qualMoves = E.generateLegalMovesPure(b2, cfg, 'w', false);
  assert.ok(qualMoves.moves.length >= 1);
  assert.ok(qualMoves.moves.every(m => m.capturedKingsCount === 1 && m.fromR === 7 && m.fromC === 0));
});

// 4. Turkish obstacle in Spanish & Flying King behavior
runTest('Spanish Draughts: Flying King & Turkish obstacle (deferred piece removal blocks re-cross)', () => {
  const cfg = E.getRuleConfig('spanish');
  const b = E.createEmptyBoardPure(8);
  // White king at (6,1), Black pawn at (5,2), landing at (4,3) -> can turn NE or SE,
  // or wait: king jumps (5,2) to (4,3), then jumps (3,4) to (2,5), CANNOT cross back over (3,4) or (5,2) in same chain
  b[6][1] = { col: 'w', king: true };
  b[5][2] = { col: 'b', king: false };
  b[3][2] = { col: 'b', king: false };
  b[1][4] = { col: 'b', king: false };
  // Path: (6,1) -> capture (5,2) -> land (4,3) -> capture (3,2) -> land (2,1)? No, (3,2) is NW of (4,3), landing at (2,1) or (1,0).
  // Put (2,3) enemy too: from (4,3) -> (3,2) -> (2,1), if (2,1) turns NE over (1,2) it lands on (0,3).
  // Verify landing on occupied/already-captured piece is blocked!
  b[4][3] = null;
  const gen = E.generateLegalMovesPure(b, cfg, 'w', false);
  // King at (6,1) captures (5,2)->(4,3)->captures (3,2)->(2,1) (or (1,0)) = 2 captures
  assert.ok(gen.moves.every(m => m.captures.length === 2));
  // Ensure Turkish obstacle blocks jumping along ray through an already captured piece:
  const bObs = E.createEmptyBoardPure(8);
  bObs[6][1] = { col: 'w', king: true };
  bObs[5][2] = { col: 'b', king: false }; // captured first, landing (3,4)
  bObs[2][5] = { col: 'b', king: false }; // captured? Wait: from (3,4) to (1,6) captures (2,5),
  // put another enemy at (2,3) and try to cross back through (3,4)->(5,2):
  // Instead test directly: White king at (5,0), Black at (4,1), Black at (2,3).
  // Jump 1: (5,0) x (4,1) -> (3,2), or lands (3,2) and wait if another Black is at (1,4)?
  // Better: White king at (7,0), Black at (6,1), empty (5,2), Black at (4,1)?? Wait: if Black at (6,1) is captured,
  // from (5,2) can White king go NW to (4,1) and then SW? No, that doesn't cross (6,1).
  // To cross (5,2)'s captured piece at (4,3):
  // Square cycle: A=(6,1) -> cap(5,2) -> B=(4,3) -> cap(3,4) -> C=(2,5) -> cap(3,6) -> D=(4,7) ... not crossing (5,2).
  // Same-diagonal return: king jumps (4,3) -> (5,2) [land (6,1)? no, backward ray along same diag] -> ray hits captured piece at (4,3) and stops!
  bObs[6][1] = null; bObs[5][2] = null; bObs[2][5] = null;
  bObs[2][1] = { col: 'w', king: true };
  bObs[3][2] = { col: 'b', king: false };
  bObs[5][4] = { col: 'b', king: false }; // Along same ray! First jump lands at (4,3), then jumps (5,4) to (6,5)
  // From (6,5), jumping BACK NW must stop at already-captured (5,4) and NOT treat it as empty or capturable again.
  const obsMoves = E.generateLegalMovesPure(bObs, cfg, 'w', false);
  assert.equal(obsMoves.moves.length, 2, 'Flying king can finish at (6,5) or (7,6)');
  assert.ok(obsMoves.moves.every(m => m.captures.length === 2));

  // Classic Turkish obstacle ray-blocking: piece captured in step 1 at (6,3) remains on board and blocks sliding past it after step 5 at (4,5)
  const bRay = E.createEmptyBoardPure(8);
  bRay[7][2] = { col: 'w', king: true };
  bRay[6][3] = { col: 'b', king: false };
  bRay[4][3] = { col: 'b', king: false };
  bRay[2][3] = { col: 'b', king: false };
  bRay[2][5] = { col: 'b', king: false };
  bRay[4][5] = { col: 'b', king: false };
  const rayMoves = E.generateLegalMovesPure(bRay, cfg, 'w', false);
  assert.ok(rayMoves.moves.some(m => m.captures.length === 5 && m.toR === 5 && m.toC === 4));
  assert.ok(
    rayMoves.moves.every(m => !((m.toR === 6 && m.toC === 3) || (m.toR === 7 && m.toC === 2))),
    'Turkish obstacle at (6,3) must prevent king from landing on (6,3) or sliding past to (7,2)'
  );
});

// 5. No mid-jump promotion in Brazilian vs Mid-jump promotion in Russian
runTest('No mid-jump promotion in Brazilian vs Mid-jump promotion in Russian', () => {
  const bBase = E.createEmptyBoardPure(8);
  // White pawn at (2,1), Black pawn at (1,2), empty (0,3), Black pawn at (1,4), empty (2,5) and (3,6)
  bBase[2][1] = { col: 'w', king: false };
  bBase[1][2] = { col: 'b', king: false };
  bBase[1][4] = { col: 'b', king: false };

  // Brazilian: pawn jumps (1,2)->(0,3) [touches promo row], continues backward (1,4)->(2,5). Does NOT stay King!
  const brCfg = E.getRuleConfig('brazilian');
  const brGen = E.generateLegalMovesPure(bBase, brCfg, 'w', false);
  assert.equal(brGen.moves.length, 1);
  assert.equal(brGen.moves[0].captures.length, 2);
  assert.equal(brGen.moves[0].toR, 2);
  assert.equal(brGen.moves[0].toC, 5);
  assert.equal(brGen.moves[0].promotesToKing, false);
  const brRes = E.applyFullMovePure(bBase, brCfg, brGen.moves[0]);
  assert.equal(brRes.nextBoard[2][5].king, false);

  // Russian: pawn jumps (1,2)->(0,3), promotes MID-JUMP to flying king, can land on (2,5) OR slide further to (3,6) / (4,7)!
  const ruCfg = E.getRuleConfig('russian');
  const ruGen = E.generateLegalMovesPure(bBase, ruCfg, 'w', false);
  assert.ok(ruGen.moves.length >= 2);
  assert.ok(ruGen.moves.every(m => m.promotesToKing === true));
  assert.ok(ruGen.moves.some(m => m.toR === 4 && m.toC === 7), 'Russian promoted flying king lands at (4,7)');
});

// 6. Italian: Pawn CANNOT capture King, King is 1-step
runTest('Italian Draughts: pawn cannot capture king & non-flying king', () => {
  const itCfg = E.getRuleConfig('italian');
  const b = E.createEmptyBoardPure(8);
  b[4][3] = { col: 'w', king: false };
  b[3][4] = { col: 'b', king: true }; // King! Pawn cannot jump it
  const gen = E.generateLegalMovesPure(b, itCfg, 'w', false);
  assert.equal(gen.hasMandatoryCapture, false);
  assert.ok(gen.moves.every(m => m.captures.length === 0));

  // Verify King moves only 1 step
  const bKing = E.createEmptyBoardPure(8);
  bKing[4][3] = { col: 'w', king: true };
  const genK = E.generateLegalMovesPure(bKing, itCfg, 'w', false);
  assert.equal(genK.moves.length, 4);
  assert.ok(genK.moves.every(m => Math.abs(m.toR - 4) === 1 && Math.abs(m.toC - 3) === 1));
});

// 7. Turkish: Orthogonal capture, immediate removal, no 180-deg immediate reversal
runTest('Turkish Draughts: orthogonal movement, immediate removal, no 180 reversal', () => {
  const trCfg = E.getRuleConfig('turkish');
  const b = E.createEmptyBoardPure(8);
  b[5][3] = { col: 'w', king: false };
  b[4][3] = { col: 'b', king: false };
  b[2][3] = { col: 'b', king: false };
  b[3][4] = { col: 'b', king: false };
  const gen = E.generateLegalMovesPure(b, trCfg, 'w', false);
  // Pawn jumps forward (4,3)->(3,3), then forward (2,3)->(1,3) OR sideways (3,4)->(3,5) [both length 2]
  assert.equal(gen.hasMandatoryCapture, true);
  assert.ok(gen.moves.some(m => m.toR === 1 && m.toC === 3 && m.captures.length === 2));
  assert.ok(gen.moves.some(m => m.toR === 3 && m.toC === 5 && m.captures.length === 2));

  // Test 180 reversal blocked for king in same chain:
  // King at (4,2) jumps right over (4,3) to (4,4). Enemy at (4,3) removed immediately, another enemy at (4,1).
  // Wait: even if (4,3) was removed immediately, king MUST NOT turn 180 degrees left immediately after jumping right!
  const bRev = E.createEmptyBoardPure(8);
  bRev[4][2] = { col: 'w', king: true };
  bRev[4][3] = { col: 'b', king: false };
  bRev[4][1] = { col: 'b', king: false };
  const genRev = E.generateLegalMovesPure(bRev, trCfg, 'w', false);
  // Must NOT bounce back left over (4,1) on the next step after jumping right to (4,4..7)
  assert.ok(genRev.moves.every(m => m.captures.length === 1));
});

// 8. Huffing mode + AI Decision (Alpha-Beta tactical strength + Negative Space)
runTest('Huffing mode & Alpha-Beta tactical search', () => {
  const cfg = E.getRuleConfig('spanish');
  const b = E.createEmptyBoardPure(8);
  b[5][2] = { col: 'w', king: false };
  b[4][3] = { col: 'b', king: false }; // White has capture to (3,4)
  b[6][5] = { col: 'w', king: false };

  const legalWithHuff = E.generateLegalMovesPure(b, cfg, 'w', true);
  assert.equal(legalWithHuff.hasMandatoryCapture, true);
  assert.ok(legalWithHuff.moves.some(m => m.captures.length === 0), 'Simple moves allowed when huffing active');

  const quietChoice = legalWithHuff.moves.find(m => m.fromR === 6 && m.fromC === 5);
  assert.ok(quietChoice);
  const huffTargets = E.computeHuffableTargetsPure(legalWithHuff.mandatoryCaptureFroms, quietChoice);
  assert.equal(huffTargets.length, 1);
  assert.equal(huffTargets[0].r, 5);
  assert.equal(huffTargets[0].c, 2);

  // AI depth scaling & tactical capture selection
  assert.equal(E.getDifficultyParamsPure('easy', cfg).depth, 1);
  assert.equal(E.getDifficultyParamsPure('medium', cfg).depth, 2);
  assert.equal(E.getDifficultyParamsPure('hard', cfg).depth, 4);
  assert.equal(E.getDifficultyParamsPure('master', cfg).depth, 5);
  assert.equal(E.getDifficultyParamsPure('master', E.getRuleConfig('international')).depth, 4);

  const bAi = E.createEmptyBoardPure(8);
  bAi[2][3] = { col: 'b', king: false };
  bAi[3][4] = { col: 'w', king: false };
  bAi[5][4] = { col: 'w', king: false };
  const dec = E.findBestAiDecisionPure(bAi, cfg, 'b', 'hard', true, [], () => 0.1);
  assert.ok(dec.move);
  assert.equal(dec.move.captures.length, 2, 'AI picks 2-capture combo even if huffing allows quiet moves');
});

// 9. Quiet clock & signature checks + Negative Space invariant throws
runTest('Quiet half-move clock, repetition signature & assertDomain negative space', () => {
  const cfg = E.getRuleConfig('spanish');
  const b = E.createEmptyBoardPure(8);
  b[4][3] = { col: 'w', king: true };
  b[0][5] = { col: 'b', king: true };
  const kingMoves = E.generateLegalMovesPure(b, cfg, 'w', false);
  const quietKingMove = kingMoves.moves.find(m => m.captures.length === 0);
  assert.ok(quietKingMove);
  const res = E.applyFullMovePure(b, cfg, quietKingMove);
  assert.equal(res.resetsQuietClock, false, 'Quiet king move does not reset 40-move clock');

  const sig1 = E.computeBoardSignaturePure(b, cfg, 'w');
  const sig2 = E.computeBoardSignaturePure(res.nextBoard, cfg, 'b');
  assert.notEqual(sig1, sig2);

  assert.throws(() => E.getRuleConfig('alien_checkers'), /DomainInvariantError/);
  assert.throws(() => E.createEmptyBoardPure(12), /DomainInvariantError/);
});

// 10. Structural checks: <= 2 control-flow nesting inside PURE ENGINE & Academy integrity intact
runTest('PURE ENGINE nesting depth <= 2 & Academy Mode preservation', () => {
  const cleanLines = engineCode.split('\n');
  let maxDepth = 0;
  let currentFnDepth = 0;
  let braceDepth = 0;
  let controlStack = [];

  for (const raw of cleanLines) {
    const line = raw.trim();
    if (!line || line.startsWith('//')) continue;
    const opensControl = /^(if|else if|else|for|while)\b/.test(line) && line.includes('{');
    const opensBrace = (line.match(/\{/g) || []).length;
    const closesBrace = (line.match(/\}/g) || []).length;

    if (opensControl) {
      currentFnDepth++;
      if (currentFnDepth > maxDepth) maxDepth = currentFnDepth;
      controlStack.push(braceDepth + opensBrace);
    }
    braceDepth += opensBrace - closesBrace;
    while (controlStack.length > 0 && braceDepth < controlStack[controlStack.length - 1]) {
      controlStack.pop();
      currentFnDepth--;
    }
  }
  assert.ok(maxDepth <= 2, `Expected max control nesting <= 2 inside PURE ENGINE, got ${maxDepth}`);

  assert.ok(html.includes('function demonstrateAcademyLesson()'), 'demonstrateAcademyLesson intact');
  assert.ok(html.includes('function getAcademySingleStepMoves('), 'getAcademySingleStepMoves intact');
  assert.ok(html.includes('function handleAcademyCellClick('), 'handleAcademyCellClick intact');
  assert.ok(html.includes("id=\"academyTutorialHand\"") || html.includes("academyTutorialHand"), 'academyTutorialHand intact');
});

console.log('\nALL JS ENGINE & ACADEMY INVARIANT TESTS PASSED!');
