import 'package:block_puzzle/models/cell.dart';
import 'package:block_puzzle/models/quest.dart';
import 'package:block_puzzle/services/quest_validation.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> stageJson({Object? goal, Object? board, Object? seed}) => {
  'id': 's1',
  'board':
      board ??
      [
        '........',
        '........',
        '........',
        '........',
        '........',
        '........',
        '3r33.r33',
        '333.3333',
      ],
  'goal': goal ?? {'type': 'score', 'target': 100},
  'seed': ?seed,
};

void main() {
  group('QuestStage.fromJson', () {
    test('parses a valid stage with gems and seed', () {
      final stage = QuestStage.fromJson(
        stageJson(
          goal: {
            'type': 'gems',
            'counts': {'red': 2},
          },
          seed: 7,
        ),
      );
      expect(stage.id, 's1');
      expect(stage.seed, 7);
      expect(stage.hard, isFalse);
      expect((stage.goal as GemsGoal).counts, {GemColor.red: 2});
      expect(stage.board.at(6, 1)!.gem, GemColor.red);
    });

    test('rejects bad boards', () {
      expect(
        () => QuestStage.fromJson(stageJson(board: ['........'])),
        throwsFormatException,
      );
      expect(
        () => QuestStage.fromJson(stageJson(board: List.filled(8, 'XXXXXXXX'))),
        throwsFormatException,
      );
      expect(
        () => QuestStage.fromJson(stageJson(board: List.filled(8, '.......'))),
        throwsFormatException,
      );
    });

    test('rejects bad goals and seeds', () {
      expect(
        () => QuestStage.fromJson(stageJson(goal: {'type': 'coins'})),
        throwsFormatException,
      );
      expect(
        () => QuestStage.fromJson(
          stageJson(goal: {'type': 'score', 'target': 0}),
        ),
        throwsFormatException,
      );
      expect(
        () => QuestStage.fromJson(
          stageJson(
            goal: {
              'type': 'gems',
              'counts': {'teal': 1},
            },
          ),
        ),
        throwsFormatException,
      );
      expect(
        () => QuestStage.fromJson(stageJson(seed: 'abc')),
        throwsFormatException,
      );
    });
  });

  group('manifest', () {
    test('rejects wrong schema and duplicate ids', () {
      expect(
        () => QuestManifest.fromJson(const {'schema': 2, 'packs': []}),
        throwsFormatException,
      );
      final ref = {
        'id': 'a',
        'title': 'A',
        'release_date': '2026-07-01',
        'file': 'packs/a.json',
        'checksum': 'x',
      };
      expect(
        () => QuestManifest.fromJson({
          'schema': 1,
          'packs': [ref, Map.of(ref)],
        }),
        throwsFormatException,
      );
    });

    test('rejects malformed release dates', () {
      expect(
        () => QuestPackRef.fromJson(const {
          'id': 'a',
          'title': 'A',
          'release_date': 'July 1',
          'file': 'f',
          'checksum': 'c',
        }),
        throwsFormatException,
      );
    });

    test('release gating compares against UTC now', () {
      final ref = QuestPackRef.fromJson(const {
        'id': 'a',
        'title': 'A',
        'release_date': '2026-07-15',
        'file': 'f',
        'checksum': 'c',
      });
      expect(ref.releasedBy(DateTime.utc(2026, 7, 14)), isFalse);
      expect(ref.releasedBy(DateTime.utc(2026, 7, 15)), isTrue);
      expect(ref.releasedBy(DateTime.utc(2026, 8, 1)), isTrue);
    });
  });

  group('playability validation', () {
    test('flags pre-completed lines', () {
      final pack = QuestPack.fromJson({
        'schema': 1,
        'id': 'p',
        'title': 'P',
        'stages': [
          stageJson(
            board: [
              '11111111', // full row 0
              '........',
              '........',
              '........',
              '........',
              '........',
              '........',
              '........',
            ],
            // Gem goal is satisfiable regardless of the board now (gems
            // come from the tray), so no gem-impossibility problem.
            goal: {
              'type': 'gems',
              'counts': {'blue': 5},
            },
          ),
        ],
      });
      final problems = validatePack(pack);
      expect(problems.single, contains('pre-completed'));
    });
  });

  group('opening tray', () {
    test('parses a valid 3-piece tray', () {
      final stage = QuestStage.fromJson(
        stageJson()..['tray'] = ['single', 'line2h', 'square2'],
      );
      expect(stage.tray, ['single', 'line2h', 'square2']);
    });

    test('rejects wrong sizes and unknown ids', () {
      expect(
        () => QuestStage.fromJson(stageJson()..['tray'] = ['single']),
        throwsFormatException,
      );
      expect(
        () => QuestStage.fromJson(
          stageJson()..['tray'] = ['single', 'line2h', 'megapiece'],
        ),
        throwsFormatException,
      );
    });

    test('validator demands a full opening cascade', () {
      QuestPack packWith(List<String> board, List<String> tray) =>
          QuestPack.fromJson({
            'schema': 1,
            'id': 'p',
            'title': 'P',
            'stages': [stageJson(board: board)..['tray'] = tray],
          });

      // Empty board: nothing can break on move one.
      expect(
        validatePack(
          packWith(List.filled(8, '........'), ['single', 'line2h', 'square2']),
        ).single,
        contains('opening cascade'),
      );

      // Only ONE break available: two pieces would place without
      // clearing — the strengthened contract rejects this too.
      expect(
        validatePack(
          packWith(
            [
              '........',
              '........',
              '........',
              '........',
              '........',
              '........',
              '........',
              '1111111.',
            ],
            ['single', 'line2h', 'square2'],
          ),
        ).single,
        contains('opening cascade'),
      );

      // Three designed gaps: every piece breaks — valid.
      expect(
        validatePack(
          packWith(
            [
              '........',
              '........',
              '........',
              '........',
              '........',
              '11...111',
              '000..000',
              '3333.333',
            ],
            ['line3h', 'line2h', 'single'],
          ),
        ),
        isEmpty,
      );
    });
  });

  group('goalDescription', () {
    test('describes score and gem goals', () {
      expect(goalDescription(const ScoreGoal(700)), contains('700'));
      expect(
        goalDescription(const GemsGoal({GemColor.red: 2})),
        contains('gems'),
      );
    });
  });
}
