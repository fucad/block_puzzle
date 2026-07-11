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
    test('flags pre-completed lines and impossible gem goals', () {
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
            goal: {
              'type': 'gems',
              'counts': {'blue': 1}, // no blue gems on board
            },
          ),
        ],
      });
      final problems = validatePack(pack);
      expect(problems, hasLength(2));
      expect(problems.first, contains('pre-completed'));
      expect(problems.last, contains('blue'));
    });
  });
}
