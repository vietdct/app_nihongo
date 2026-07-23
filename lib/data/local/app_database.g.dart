// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $VocabularyTableTable extends VocabularyTable
    with TableInfo<$VocabularyTableTable, VocabularyTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VocabularyTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
      'word', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _readingMeta =
      const VerificationMeta('reading');
  @override
  late final GeneratedColumn<String> reading = GeneratedColumn<String>(
      'reading', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _meaningViMeta =
      const VerificationMeta('meaningVi');
  @override
  late final GeneratedColumn<String> meaningVi = GeneratedColumn<String>(
      'meaning_vi', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _partOfSpeechMeta =
      const VerificationMeta('partOfSpeech');
  @override
  late final GeneratedColumn<String> partOfSpeech = GeneratedColumn<String>(
      'part_of_speech', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _exampleJpMeta =
      const VerificationMeta('exampleJp');
  @override
  late final GeneratedColumn<String> exampleJp = GeneratedColumn<String>(
      'example_jp', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _exampleViMeta =
      const VerificationMeta('exampleVi');
  @override
  late final GeneratedColumn<String> exampleVi = GeneratedColumn<String>(
      'example_vi', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _audioUrlMeta =
      const VerificationMeta('audioUrl');
  @override
  late final GeneratedColumn<String> audioUrl = GeneratedColumn<String>(
      'audio_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _levelIdMeta =
      const VerificationMeta('levelId');
  @override
  late final GeneratedColumn<String> levelId = GeneratedColumn<String>(
      'level_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        word,
        reading,
        meaningVi,
        partOfSpeech,
        exampleJp,
        exampleVi,
        audioUrl,
        levelId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vocabulary_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<VocabularyTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('word')) {
      context.handle(
          _wordMeta, word.isAcceptableOrUnknown(data['word']!, _wordMeta));
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('reading')) {
      context.handle(_readingMeta,
          reading.isAcceptableOrUnknown(data['reading']!, _readingMeta));
    } else if (isInserting) {
      context.missing(_readingMeta);
    }
    if (data.containsKey('meaning_vi')) {
      context.handle(_meaningViMeta,
          meaningVi.isAcceptableOrUnknown(data['meaning_vi']!, _meaningViMeta));
    } else if (isInserting) {
      context.missing(_meaningViMeta);
    }
    if (data.containsKey('part_of_speech')) {
      context.handle(
          _partOfSpeechMeta,
          partOfSpeech.isAcceptableOrUnknown(
              data['part_of_speech']!, _partOfSpeechMeta));
    }
    if (data.containsKey('example_jp')) {
      context.handle(_exampleJpMeta,
          exampleJp.isAcceptableOrUnknown(data['example_jp']!, _exampleJpMeta));
    }
    if (data.containsKey('example_vi')) {
      context.handle(_exampleViMeta,
          exampleVi.isAcceptableOrUnknown(data['example_vi']!, _exampleViMeta));
    }
    if (data.containsKey('audio_url')) {
      context.handle(_audioUrlMeta,
          audioUrl.isAcceptableOrUnknown(data['audio_url']!, _audioUrlMeta));
    }
    if (data.containsKey('level_id')) {
      context.handle(_levelIdMeta,
          levelId.isAcceptableOrUnknown(data['level_id']!, _levelIdMeta));
    } else if (isInserting) {
      context.missing(_levelIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VocabularyTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VocabularyTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      word: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}word'])!,
      reading: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reading'])!,
      meaningVi: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meaning_vi'])!,
      partOfSpeech: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}part_of_speech']),
      exampleJp: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}example_jp']),
      exampleVi: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}example_vi']),
      audioUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}audio_url']),
      levelId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}level_id'])!,
    );
  }

  @override
  $VocabularyTableTable createAlias(String alias) {
    return $VocabularyTableTable(attachedDatabase, alias);
  }
}

class VocabularyTableData extends DataClass
    implements Insertable<VocabularyTableData> {
  final String id;
  final String word;
  final String reading;
  final String meaningVi;
  final String? partOfSpeech;
  final String? exampleJp;
  final String? exampleVi;
  final String? audioUrl;
  final String levelId;
  const VocabularyTableData(
      {required this.id,
      required this.word,
      required this.reading,
      required this.meaningVi,
      this.partOfSpeech,
      this.exampleJp,
      this.exampleVi,
      this.audioUrl,
      required this.levelId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['word'] = Variable<String>(word);
    map['reading'] = Variable<String>(reading);
    map['meaning_vi'] = Variable<String>(meaningVi);
    if (!nullToAbsent || partOfSpeech != null) {
      map['part_of_speech'] = Variable<String>(partOfSpeech);
    }
    if (!nullToAbsent || exampleJp != null) {
      map['example_jp'] = Variable<String>(exampleJp);
    }
    if (!nullToAbsent || exampleVi != null) {
      map['example_vi'] = Variable<String>(exampleVi);
    }
    if (!nullToAbsent || audioUrl != null) {
      map['audio_url'] = Variable<String>(audioUrl);
    }
    map['level_id'] = Variable<String>(levelId);
    return map;
  }

  VocabularyTableCompanion toCompanion(bool nullToAbsent) {
    return VocabularyTableCompanion(
      id: Value(id),
      word: Value(word),
      reading: Value(reading),
      meaningVi: Value(meaningVi),
      partOfSpeech: partOfSpeech == null && nullToAbsent
          ? const Value.absent()
          : Value(partOfSpeech),
      exampleJp: exampleJp == null && nullToAbsent
          ? const Value.absent()
          : Value(exampleJp),
      exampleVi: exampleVi == null && nullToAbsent
          ? const Value.absent()
          : Value(exampleVi),
      audioUrl: audioUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(audioUrl),
      levelId: Value(levelId),
    );
  }

  factory VocabularyTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VocabularyTableData(
      id: serializer.fromJson<String>(json['id']),
      word: serializer.fromJson<String>(json['word']),
      reading: serializer.fromJson<String>(json['reading']),
      meaningVi: serializer.fromJson<String>(json['meaningVi']),
      partOfSpeech: serializer.fromJson<String?>(json['partOfSpeech']),
      exampleJp: serializer.fromJson<String?>(json['exampleJp']),
      exampleVi: serializer.fromJson<String?>(json['exampleVi']),
      audioUrl: serializer.fromJson<String?>(json['audioUrl']),
      levelId: serializer.fromJson<String>(json['levelId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'word': serializer.toJson<String>(word),
      'reading': serializer.toJson<String>(reading),
      'meaningVi': serializer.toJson<String>(meaningVi),
      'partOfSpeech': serializer.toJson<String?>(partOfSpeech),
      'exampleJp': serializer.toJson<String?>(exampleJp),
      'exampleVi': serializer.toJson<String?>(exampleVi),
      'audioUrl': serializer.toJson<String?>(audioUrl),
      'levelId': serializer.toJson<String>(levelId),
    };
  }

  VocabularyTableData copyWith(
          {String? id,
          String? word,
          String? reading,
          String? meaningVi,
          Value<String?> partOfSpeech = const Value.absent(),
          Value<String?> exampleJp = const Value.absent(),
          Value<String?> exampleVi = const Value.absent(),
          Value<String?> audioUrl = const Value.absent(),
          String? levelId}) =>
      VocabularyTableData(
        id: id ?? this.id,
        word: word ?? this.word,
        reading: reading ?? this.reading,
        meaningVi: meaningVi ?? this.meaningVi,
        partOfSpeech:
            partOfSpeech.present ? partOfSpeech.value : this.partOfSpeech,
        exampleJp: exampleJp.present ? exampleJp.value : this.exampleJp,
        exampleVi: exampleVi.present ? exampleVi.value : this.exampleVi,
        audioUrl: audioUrl.present ? audioUrl.value : this.audioUrl,
        levelId: levelId ?? this.levelId,
      );
  VocabularyTableData copyWithCompanion(VocabularyTableCompanion data) {
    return VocabularyTableData(
      id: data.id.present ? data.id.value : this.id,
      word: data.word.present ? data.word.value : this.word,
      reading: data.reading.present ? data.reading.value : this.reading,
      meaningVi: data.meaningVi.present ? data.meaningVi.value : this.meaningVi,
      partOfSpeech: data.partOfSpeech.present
          ? data.partOfSpeech.value
          : this.partOfSpeech,
      exampleJp: data.exampleJp.present ? data.exampleJp.value : this.exampleJp,
      exampleVi: data.exampleVi.present ? data.exampleVi.value : this.exampleVi,
      audioUrl: data.audioUrl.present ? data.audioUrl.value : this.audioUrl,
      levelId: data.levelId.present ? data.levelId.value : this.levelId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyTableData(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('reading: $reading, ')
          ..write('meaningVi: $meaningVi, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('exampleJp: $exampleJp, ')
          ..write('exampleVi: $exampleVi, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('levelId: $levelId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, word, reading, meaningVi, partOfSpeech,
      exampleJp, exampleVi, audioUrl, levelId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VocabularyTableData &&
          other.id == this.id &&
          other.word == this.word &&
          other.reading == this.reading &&
          other.meaningVi == this.meaningVi &&
          other.partOfSpeech == this.partOfSpeech &&
          other.exampleJp == this.exampleJp &&
          other.exampleVi == this.exampleVi &&
          other.audioUrl == this.audioUrl &&
          other.levelId == this.levelId);
}

class VocabularyTableCompanion extends UpdateCompanion<VocabularyTableData> {
  final Value<String> id;
  final Value<String> word;
  final Value<String> reading;
  final Value<String> meaningVi;
  final Value<String?> partOfSpeech;
  final Value<String?> exampleJp;
  final Value<String?> exampleVi;
  final Value<String?> audioUrl;
  final Value<String> levelId;
  final Value<int> rowid;
  const VocabularyTableCompanion({
    this.id = const Value.absent(),
    this.word = const Value.absent(),
    this.reading = const Value.absent(),
    this.meaningVi = const Value.absent(),
    this.partOfSpeech = const Value.absent(),
    this.exampleJp = const Value.absent(),
    this.exampleVi = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.levelId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VocabularyTableCompanion.insert({
    required String id,
    required String word,
    required String reading,
    required String meaningVi,
    this.partOfSpeech = const Value.absent(),
    this.exampleJp = const Value.absent(),
    this.exampleVi = const Value.absent(),
    this.audioUrl = const Value.absent(),
    required String levelId,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        word = Value(word),
        reading = Value(reading),
        meaningVi = Value(meaningVi),
        levelId = Value(levelId);
  static Insertable<VocabularyTableData> custom({
    Expression<String>? id,
    Expression<String>? word,
    Expression<String>? reading,
    Expression<String>? meaningVi,
    Expression<String>? partOfSpeech,
    Expression<String>? exampleJp,
    Expression<String>? exampleVi,
    Expression<String>? audioUrl,
    Expression<String>? levelId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (word != null) 'word': word,
      if (reading != null) 'reading': reading,
      if (meaningVi != null) 'meaning_vi': meaningVi,
      if (partOfSpeech != null) 'part_of_speech': partOfSpeech,
      if (exampleJp != null) 'example_jp': exampleJp,
      if (exampleVi != null) 'example_vi': exampleVi,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (levelId != null) 'level_id': levelId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VocabularyTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? word,
      Value<String>? reading,
      Value<String>? meaningVi,
      Value<String?>? partOfSpeech,
      Value<String?>? exampleJp,
      Value<String?>? exampleVi,
      Value<String?>? audioUrl,
      Value<String>? levelId,
      Value<int>? rowid}) {
    return VocabularyTableCompanion(
      id: id ?? this.id,
      word: word ?? this.word,
      reading: reading ?? this.reading,
      meaningVi: meaningVi ?? this.meaningVi,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      exampleJp: exampleJp ?? this.exampleJp,
      exampleVi: exampleVi ?? this.exampleVi,
      audioUrl: audioUrl ?? this.audioUrl,
      levelId: levelId ?? this.levelId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (reading.present) {
      map['reading'] = Variable<String>(reading.value);
    }
    if (meaningVi.present) {
      map['meaning_vi'] = Variable<String>(meaningVi.value);
    }
    if (partOfSpeech.present) {
      map['part_of_speech'] = Variable<String>(partOfSpeech.value);
    }
    if (exampleJp.present) {
      map['example_jp'] = Variable<String>(exampleJp.value);
    }
    if (exampleVi.present) {
      map['example_vi'] = Variable<String>(exampleVi.value);
    }
    if (audioUrl.present) {
      map['audio_url'] = Variable<String>(audioUrl.value);
    }
    if (levelId.present) {
      map['level_id'] = Variable<String>(levelId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyTableCompanion(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('reading: $reading, ')
          ..write('meaningVi: $meaningVi, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('exampleJp: $exampleJp, ')
          ..write('exampleVi: $exampleVi, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('levelId: $levelId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KanjiTableTable extends KanjiTable
    with TableInfo<$KanjiTableTable, KanjiTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KanjiTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _characterMeta =
      const VerificationMeta('character');
  @override
  late final GeneratedColumn<String> character = GeneratedColumn<String>(
      'character', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _onyomiMeta = const VerificationMeta('onyomi');
  @override
  late final GeneratedColumn<String> onyomi = GeneratedColumn<String>(
      'onyomi', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _kunyomiMeta =
      const VerificationMeta('kunyomi');
  @override
  late final GeneratedColumn<String> kunyomi = GeneratedColumn<String>(
      'kunyomi', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _meaningViMeta =
      const VerificationMeta('meaningVi');
  @override
  late final GeneratedColumn<String> meaningVi = GeneratedColumn<String>(
      'meaning_vi', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _strokeCountMeta =
      const VerificationMeta('strokeCount');
  @override
  late final GeneratedColumn<int> strokeCount = GeneratedColumn<int>(
      'stroke_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _exampleJpMeta =
      const VerificationMeta('exampleJp');
  @override
  late final GeneratedColumn<String> exampleJp = GeneratedColumn<String>(
      'example_jp', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _exampleViMeta =
      const VerificationMeta('exampleVi');
  @override
  late final GeneratedColumn<String> exampleVi = GeneratedColumn<String>(
      'example_vi', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _levelIdMeta =
      const VerificationMeta('levelId');
  @override
  late final GeneratedColumn<String> levelId = GeneratedColumn<String>(
      'level_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        character,
        onyomi,
        kunyomi,
        meaningVi,
        strokeCount,
        exampleJp,
        exampleVi,
        levelId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kanji_table';
  @override
  VerificationContext validateIntegrity(Insertable<KanjiTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('character')) {
      context.handle(_characterMeta,
          character.isAcceptableOrUnknown(data['character']!, _characterMeta));
    } else if (isInserting) {
      context.missing(_characterMeta);
    }
    if (data.containsKey('onyomi')) {
      context.handle(_onyomiMeta,
          onyomi.isAcceptableOrUnknown(data['onyomi']!, _onyomiMeta));
    }
    if (data.containsKey('kunyomi')) {
      context.handle(_kunyomiMeta,
          kunyomi.isAcceptableOrUnknown(data['kunyomi']!, _kunyomiMeta));
    }
    if (data.containsKey('meaning_vi')) {
      context.handle(_meaningViMeta,
          meaningVi.isAcceptableOrUnknown(data['meaning_vi']!, _meaningViMeta));
    } else if (isInserting) {
      context.missing(_meaningViMeta);
    }
    if (data.containsKey('stroke_count')) {
      context.handle(
          _strokeCountMeta,
          strokeCount.isAcceptableOrUnknown(
              data['stroke_count']!, _strokeCountMeta));
    }
    if (data.containsKey('example_jp')) {
      context.handle(_exampleJpMeta,
          exampleJp.isAcceptableOrUnknown(data['example_jp']!, _exampleJpMeta));
    }
    if (data.containsKey('example_vi')) {
      context.handle(_exampleViMeta,
          exampleVi.isAcceptableOrUnknown(data['example_vi']!, _exampleViMeta));
    }
    if (data.containsKey('level_id')) {
      context.handle(_levelIdMeta,
          levelId.isAcceptableOrUnknown(data['level_id']!, _levelIdMeta));
    } else if (isInserting) {
      context.missing(_levelIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KanjiTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KanjiTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      character: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}character'])!,
      onyomi: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}onyomi']),
      kunyomi: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kunyomi']),
      meaningVi: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meaning_vi'])!,
      strokeCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stroke_count']),
      exampleJp: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}example_jp']),
      exampleVi: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}example_vi']),
      levelId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}level_id'])!,
    );
  }

  @override
  $KanjiTableTable createAlias(String alias) {
    return $KanjiTableTable(attachedDatabase, alias);
  }
}

class KanjiTableData extends DataClass implements Insertable<KanjiTableData> {
  final String id;
  final String character;
  final String? onyomi;
  final String? kunyomi;
  final String meaningVi;
  final int? strokeCount;
  final String? exampleJp;
  final String? exampleVi;
  final String levelId;
  const KanjiTableData(
      {required this.id,
      required this.character,
      this.onyomi,
      this.kunyomi,
      required this.meaningVi,
      this.strokeCount,
      this.exampleJp,
      this.exampleVi,
      required this.levelId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['character'] = Variable<String>(character);
    if (!nullToAbsent || onyomi != null) {
      map['onyomi'] = Variable<String>(onyomi);
    }
    if (!nullToAbsent || kunyomi != null) {
      map['kunyomi'] = Variable<String>(kunyomi);
    }
    map['meaning_vi'] = Variable<String>(meaningVi);
    if (!nullToAbsent || strokeCount != null) {
      map['stroke_count'] = Variable<int>(strokeCount);
    }
    if (!nullToAbsent || exampleJp != null) {
      map['example_jp'] = Variable<String>(exampleJp);
    }
    if (!nullToAbsent || exampleVi != null) {
      map['example_vi'] = Variable<String>(exampleVi);
    }
    map['level_id'] = Variable<String>(levelId);
    return map;
  }

  KanjiTableCompanion toCompanion(bool nullToAbsent) {
    return KanjiTableCompanion(
      id: Value(id),
      character: Value(character),
      onyomi:
          onyomi == null && nullToAbsent ? const Value.absent() : Value(onyomi),
      kunyomi: kunyomi == null && nullToAbsent
          ? const Value.absent()
          : Value(kunyomi),
      meaningVi: Value(meaningVi),
      strokeCount: strokeCount == null && nullToAbsent
          ? const Value.absent()
          : Value(strokeCount),
      exampleJp: exampleJp == null && nullToAbsent
          ? const Value.absent()
          : Value(exampleJp),
      exampleVi: exampleVi == null && nullToAbsent
          ? const Value.absent()
          : Value(exampleVi),
      levelId: Value(levelId),
    );
  }

  factory KanjiTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KanjiTableData(
      id: serializer.fromJson<String>(json['id']),
      character: serializer.fromJson<String>(json['character']),
      onyomi: serializer.fromJson<String?>(json['onyomi']),
      kunyomi: serializer.fromJson<String?>(json['kunyomi']),
      meaningVi: serializer.fromJson<String>(json['meaningVi']),
      strokeCount: serializer.fromJson<int?>(json['strokeCount']),
      exampleJp: serializer.fromJson<String?>(json['exampleJp']),
      exampleVi: serializer.fromJson<String?>(json['exampleVi']),
      levelId: serializer.fromJson<String>(json['levelId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'character': serializer.toJson<String>(character),
      'onyomi': serializer.toJson<String?>(onyomi),
      'kunyomi': serializer.toJson<String?>(kunyomi),
      'meaningVi': serializer.toJson<String>(meaningVi),
      'strokeCount': serializer.toJson<int?>(strokeCount),
      'exampleJp': serializer.toJson<String?>(exampleJp),
      'exampleVi': serializer.toJson<String?>(exampleVi),
      'levelId': serializer.toJson<String>(levelId),
    };
  }

  KanjiTableData copyWith(
          {String? id,
          String? character,
          Value<String?> onyomi = const Value.absent(),
          Value<String?> kunyomi = const Value.absent(),
          String? meaningVi,
          Value<int?> strokeCount = const Value.absent(),
          Value<String?> exampleJp = const Value.absent(),
          Value<String?> exampleVi = const Value.absent(),
          String? levelId}) =>
      KanjiTableData(
        id: id ?? this.id,
        character: character ?? this.character,
        onyomi: onyomi.present ? onyomi.value : this.onyomi,
        kunyomi: kunyomi.present ? kunyomi.value : this.kunyomi,
        meaningVi: meaningVi ?? this.meaningVi,
        strokeCount: strokeCount.present ? strokeCount.value : this.strokeCount,
        exampleJp: exampleJp.present ? exampleJp.value : this.exampleJp,
        exampleVi: exampleVi.present ? exampleVi.value : this.exampleVi,
        levelId: levelId ?? this.levelId,
      );
  KanjiTableData copyWithCompanion(KanjiTableCompanion data) {
    return KanjiTableData(
      id: data.id.present ? data.id.value : this.id,
      character: data.character.present ? data.character.value : this.character,
      onyomi: data.onyomi.present ? data.onyomi.value : this.onyomi,
      kunyomi: data.kunyomi.present ? data.kunyomi.value : this.kunyomi,
      meaningVi: data.meaningVi.present ? data.meaningVi.value : this.meaningVi,
      strokeCount:
          data.strokeCount.present ? data.strokeCount.value : this.strokeCount,
      exampleJp: data.exampleJp.present ? data.exampleJp.value : this.exampleJp,
      exampleVi: data.exampleVi.present ? data.exampleVi.value : this.exampleVi,
      levelId: data.levelId.present ? data.levelId.value : this.levelId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KanjiTableData(')
          ..write('id: $id, ')
          ..write('character: $character, ')
          ..write('onyomi: $onyomi, ')
          ..write('kunyomi: $kunyomi, ')
          ..write('meaningVi: $meaningVi, ')
          ..write('strokeCount: $strokeCount, ')
          ..write('exampleJp: $exampleJp, ')
          ..write('exampleVi: $exampleVi, ')
          ..write('levelId: $levelId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, character, onyomi, kunyomi, meaningVi,
      strokeCount, exampleJp, exampleVi, levelId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KanjiTableData &&
          other.id == this.id &&
          other.character == this.character &&
          other.onyomi == this.onyomi &&
          other.kunyomi == this.kunyomi &&
          other.meaningVi == this.meaningVi &&
          other.strokeCount == this.strokeCount &&
          other.exampleJp == this.exampleJp &&
          other.exampleVi == this.exampleVi &&
          other.levelId == this.levelId);
}

class KanjiTableCompanion extends UpdateCompanion<KanjiTableData> {
  final Value<String> id;
  final Value<String> character;
  final Value<String?> onyomi;
  final Value<String?> kunyomi;
  final Value<String> meaningVi;
  final Value<int?> strokeCount;
  final Value<String?> exampleJp;
  final Value<String?> exampleVi;
  final Value<String> levelId;
  final Value<int> rowid;
  const KanjiTableCompanion({
    this.id = const Value.absent(),
    this.character = const Value.absent(),
    this.onyomi = const Value.absent(),
    this.kunyomi = const Value.absent(),
    this.meaningVi = const Value.absent(),
    this.strokeCount = const Value.absent(),
    this.exampleJp = const Value.absent(),
    this.exampleVi = const Value.absent(),
    this.levelId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KanjiTableCompanion.insert({
    required String id,
    required String character,
    this.onyomi = const Value.absent(),
    this.kunyomi = const Value.absent(),
    required String meaningVi,
    this.strokeCount = const Value.absent(),
    this.exampleJp = const Value.absent(),
    this.exampleVi = const Value.absent(),
    required String levelId,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        character = Value(character),
        meaningVi = Value(meaningVi),
        levelId = Value(levelId);
  static Insertable<KanjiTableData> custom({
    Expression<String>? id,
    Expression<String>? character,
    Expression<String>? onyomi,
    Expression<String>? kunyomi,
    Expression<String>? meaningVi,
    Expression<int>? strokeCount,
    Expression<String>? exampleJp,
    Expression<String>? exampleVi,
    Expression<String>? levelId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (character != null) 'character': character,
      if (onyomi != null) 'onyomi': onyomi,
      if (kunyomi != null) 'kunyomi': kunyomi,
      if (meaningVi != null) 'meaning_vi': meaningVi,
      if (strokeCount != null) 'stroke_count': strokeCount,
      if (exampleJp != null) 'example_jp': exampleJp,
      if (exampleVi != null) 'example_vi': exampleVi,
      if (levelId != null) 'level_id': levelId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KanjiTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? character,
      Value<String?>? onyomi,
      Value<String?>? kunyomi,
      Value<String>? meaningVi,
      Value<int?>? strokeCount,
      Value<String?>? exampleJp,
      Value<String?>? exampleVi,
      Value<String>? levelId,
      Value<int>? rowid}) {
    return KanjiTableCompanion(
      id: id ?? this.id,
      character: character ?? this.character,
      onyomi: onyomi ?? this.onyomi,
      kunyomi: kunyomi ?? this.kunyomi,
      meaningVi: meaningVi ?? this.meaningVi,
      strokeCount: strokeCount ?? this.strokeCount,
      exampleJp: exampleJp ?? this.exampleJp,
      exampleVi: exampleVi ?? this.exampleVi,
      levelId: levelId ?? this.levelId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (character.present) {
      map['character'] = Variable<String>(character.value);
    }
    if (onyomi.present) {
      map['onyomi'] = Variable<String>(onyomi.value);
    }
    if (kunyomi.present) {
      map['kunyomi'] = Variable<String>(kunyomi.value);
    }
    if (meaningVi.present) {
      map['meaning_vi'] = Variable<String>(meaningVi.value);
    }
    if (strokeCount.present) {
      map['stroke_count'] = Variable<int>(strokeCount.value);
    }
    if (exampleJp.present) {
      map['example_jp'] = Variable<String>(exampleJp.value);
    }
    if (exampleVi.present) {
      map['example_vi'] = Variable<String>(exampleVi.value);
    }
    if (levelId.present) {
      map['level_id'] = Variable<String>(levelId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KanjiTableCompanion(')
          ..write('id: $id, ')
          ..write('character: $character, ')
          ..write('onyomi: $onyomi, ')
          ..write('kunyomi: $kunyomi, ')
          ..write('meaningVi: $meaningVi, ')
          ..write('strokeCount: $strokeCount, ')
          ..write('exampleJp: $exampleJp, ')
          ..write('exampleVi: $exampleVi, ')
          ..write('levelId: $levelId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LessonsTableTable extends LessonsTable
    with TableInfo<$LessonsTableTable, LessonsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _levelIdMeta =
      const VerificationMeta('levelId');
  @override
  late final GeneratedColumn<String> levelId = GeneratedColumn<String>(
      'level_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderIndexMeta =
      const VerificationMeta('orderIndex');
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
      'order_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, description, levelId, orderIndex];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lessons_table';
  @override
  VerificationContext validateIntegrity(Insertable<LessonsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('level_id')) {
      context.handle(_levelIdMeta,
          levelId.isAcceptableOrUnknown(data['level_id']!, _levelIdMeta));
    } else if (isInserting) {
      context.missing(_levelIdMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
          _orderIndexMeta,
          orderIndex.isAcceptableOrUnknown(
              data['order_index']!, _orderIndexMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LessonsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      levelId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}level_id'])!,
      orderIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_index'])!,
    );
  }

  @override
  $LessonsTableTable createAlias(String alias) {
    return $LessonsTableTable(attachedDatabase, alias);
  }
}

class LessonsTableData extends DataClass
    implements Insertable<LessonsTableData> {
  final String id;
  final String title;
  final String? description;
  final String levelId;
  final int orderIndex;
  const LessonsTableData(
      {required this.id,
      required this.title,
      this.description,
      required this.levelId,
      required this.orderIndex});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['level_id'] = Variable<String>(levelId);
    map['order_index'] = Variable<int>(orderIndex);
    return map;
  }

  LessonsTableCompanion toCompanion(bool nullToAbsent) {
    return LessonsTableCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      levelId: Value(levelId),
      orderIndex: Value(orderIndex),
    );
  }

  factory LessonsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonsTableData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      levelId: serializer.fromJson<String>(json['levelId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'levelId': serializer.toJson<String>(levelId),
      'orderIndex': serializer.toJson<int>(orderIndex),
    };
  }

  LessonsTableData copyWith(
          {String? id,
          String? title,
          Value<String?> description = const Value.absent(),
          String? levelId,
          int? orderIndex}) =>
      LessonsTableData(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description.present ? description.value : this.description,
        levelId: levelId ?? this.levelId,
        orderIndex: orderIndex ?? this.orderIndex,
      );
  LessonsTableData copyWithCompanion(LessonsTableCompanion data) {
    return LessonsTableData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      levelId: data.levelId.present ? data.levelId.value : this.levelId,
      orderIndex:
          data.orderIndex.present ? data.orderIndex.value : this.orderIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonsTableData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('levelId: $levelId, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, description, levelId, orderIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonsTableData &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.levelId == this.levelId &&
          other.orderIndex == this.orderIndex);
}

class LessonsTableCompanion extends UpdateCompanion<LessonsTableData> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> levelId;
  final Value<int> orderIndex;
  final Value<int> rowid;
  const LessonsTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.levelId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LessonsTableCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    required String levelId,
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        levelId = Value(levelId);
  static Insertable<LessonsTableData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? levelId,
    Expression<int>? orderIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (levelId != null) 'level_id': levelId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LessonsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String?>? description,
      Value<String>? levelId,
      Value<int>? orderIndex,
      Value<int>? rowid}) {
    return LessonsTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      levelId: levelId ?? this.levelId,
      orderIndex: orderIndex ?? this.orderIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (levelId.present) {
      map['level_id'] = Variable<String>(levelId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonsTableCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('levelId: $levelId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LessonItemsTableTable extends LessonItemsTable
    with TableInfo<$LessonItemsTableTable, LessonItemsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonItemsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lessonIdMeta =
      const VerificationMeta('lessonId');
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
      'lesson_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemTypeMeta =
      const VerificationMeta('itemType');
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
      'item_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
      'item_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderIndexMeta =
      const VerificationMeta('orderIndex');
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
      'order_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, lessonId, itemType, itemId, orderIndex];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lesson_items_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<LessonItemsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('lesson_id')) {
      context.handle(_lessonIdMeta,
          lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta));
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('item_type')) {
      context.handle(_itemTypeMeta,
          itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta));
    } else if (isInserting) {
      context.missing(_itemTypeMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
          _orderIndexMeta,
          orderIndex.isAcceptableOrUnknown(
              data['order_index']!, _orderIndexMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LessonItemsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonItemsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      lessonId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}lesson_id'])!,
      itemType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_type'])!,
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_id'])!,
      orderIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_index'])!,
    );
  }

  @override
  $LessonItemsTableTable createAlias(String alias) {
    return $LessonItemsTableTable(attachedDatabase, alias);
  }
}

class LessonItemsTableData extends DataClass
    implements Insertable<LessonItemsTableData> {
  final String id;
  final String lessonId;
  final String itemType;
  final String itemId;
  final int orderIndex;
  const LessonItemsTableData(
      {required this.id,
      required this.lessonId,
      required this.itemType,
      required this.itemId,
      required this.orderIndex});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['lesson_id'] = Variable<String>(lessonId);
    map['item_type'] = Variable<String>(itemType);
    map['item_id'] = Variable<String>(itemId);
    map['order_index'] = Variable<int>(orderIndex);
    return map;
  }

  LessonItemsTableCompanion toCompanion(bool nullToAbsent) {
    return LessonItemsTableCompanion(
      id: Value(id),
      lessonId: Value(lessonId),
      itemType: Value(itemType),
      itemId: Value(itemId),
      orderIndex: Value(orderIndex),
    );
  }

  factory LessonItemsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonItemsTableData(
      id: serializer.fromJson<String>(json['id']),
      lessonId: serializer.fromJson<String>(json['lessonId']),
      itemType: serializer.fromJson<String>(json['itemType']),
      itemId: serializer.fromJson<String>(json['itemId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'lessonId': serializer.toJson<String>(lessonId),
      'itemType': serializer.toJson<String>(itemType),
      'itemId': serializer.toJson<String>(itemId),
      'orderIndex': serializer.toJson<int>(orderIndex),
    };
  }

  LessonItemsTableData copyWith(
          {String? id,
          String? lessonId,
          String? itemType,
          String? itemId,
          int? orderIndex}) =>
      LessonItemsTableData(
        id: id ?? this.id,
        lessonId: lessonId ?? this.lessonId,
        itemType: itemType ?? this.itemType,
        itemId: itemId ?? this.itemId,
        orderIndex: orderIndex ?? this.orderIndex,
      );
  LessonItemsTableData copyWithCompanion(LessonItemsTableCompanion data) {
    return LessonItemsTableData(
      id: data.id.present ? data.id.value : this.id,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      orderIndex:
          data.orderIndex.present ? data.orderIndex.value : this.orderIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonItemsTableData(')
          ..write('id: $id, ')
          ..write('lessonId: $lessonId, ')
          ..write('itemType: $itemType, ')
          ..write('itemId: $itemId, ')
          ..write('orderIndex: $orderIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lessonId, itemType, itemId, orderIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonItemsTableData &&
          other.id == this.id &&
          other.lessonId == this.lessonId &&
          other.itemType == this.itemType &&
          other.itemId == this.itemId &&
          other.orderIndex == this.orderIndex);
}

class LessonItemsTableCompanion extends UpdateCompanion<LessonItemsTableData> {
  final Value<String> id;
  final Value<String> lessonId;
  final Value<String> itemType;
  final Value<String> itemId;
  final Value<int> orderIndex;
  final Value<int> rowid;
  const LessonItemsTableCompanion({
    this.id = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.itemType = const Value.absent(),
    this.itemId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LessonItemsTableCompanion.insert({
    required String id,
    required String lessonId,
    required String itemType,
    required String itemId,
    this.orderIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        lessonId = Value(lessonId),
        itemType = Value(itemType),
        itemId = Value(itemId);
  static Insertable<LessonItemsTableData> custom({
    Expression<String>? id,
    Expression<String>? lessonId,
    Expression<String>? itemType,
    Expression<String>? itemId,
    Expression<int>? orderIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lessonId != null) 'lesson_id': lessonId,
      if (itemType != null) 'item_type': itemType,
      if (itemId != null) 'item_id': itemId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LessonItemsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? lessonId,
      Value<String>? itemType,
      Value<String>? itemId,
      Value<int>? orderIndex,
      Value<int>? rowid}) {
    return LessonItemsTableCompanion(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      itemType: itemType ?? this.itemType,
      itemId: itemId ?? this.itemId,
      orderIndex: orderIndex ?? this.orderIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonItemsTableCompanion(')
          ..write('id: $id, ')
          ..write('lessonId: $lessonId, ')
          ..write('itemType: $itemType, ')
          ..write('itemId: $itemId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VocabularyTableTable vocabularyTable =
      $VocabularyTableTable(this);
  late final $KanjiTableTable kanjiTable = $KanjiTableTable(this);
  late final $LessonsTableTable lessonsTable = $LessonsTableTable(this);
  late final $LessonItemsTableTable lessonItemsTable =
      $LessonItemsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [vocabularyTable, kanjiTable, lessonsTable, lessonItemsTable];
}

typedef $$VocabularyTableTableCreateCompanionBuilder = VocabularyTableCompanion
    Function({
  required String id,
  required String word,
  required String reading,
  required String meaningVi,
  Value<String?> partOfSpeech,
  Value<String?> exampleJp,
  Value<String?> exampleVi,
  Value<String?> audioUrl,
  required String levelId,
  Value<int> rowid,
});
typedef $$VocabularyTableTableUpdateCompanionBuilder = VocabularyTableCompanion
    Function({
  Value<String> id,
  Value<String> word,
  Value<String> reading,
  Value<String> meaningVi,
  Value<String?> partOfSpeech,
  Value<String?> exampleJp,
  Value<String?> exampleVi,
  Value<String?> audioUrl,
  Value<String> levelId,
  Value<int> rowid,
});

class $$VocabularyTableTableFilterComposer
    extends Composer<_$AppDatabase, $VocabularyTableTable> {
  $$VocabularyTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get word => $composableBuilder(
      column: $table.word, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reading => $composableBuilder(
      column: $table.reading, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get meaningVi => $composableBuilder(
      column: $table.meaningVi, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get partOfSpeech => $composableBuilder(
      column: $table.partOfSpeech, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exampleJp => $composableBuilder(
      column: $table.exampleJp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exampleVi => $composableBuilder(
      column: $table.exampleVi, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get audioUrl => $composableBuilder(
      column: $table.audioUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get levelId => $composableBuilder(
      column: $table.levelId, builder: (column) => ColumnFilters(column));
}

class $$VocabularyTableTableOrderingComposer
    extends Composer<_$AppDatabase, $VocabularyTableTable> {
  $$VocabularyTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get word => $composableBuilder(
      column: $table.word, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reading => $composableBuilder(
      column: $table.reading, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meaningVi => $composableBuilder(
      column: $table.meaningVi, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get partOfSpeech => $composableBuilder(
      column: $table.partOfSpeech,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exampleJp => $composableBuilder(
      column: $table.exampleJp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exampleVi => $composableBuilder(
      column: $table.exampleVi, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get audioUrl => $composableBuilder(
      column: $table.audioUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get levelId => $composableBuilder(
      column: $table.levelId, builder: (column) => ColumnOrderings(column));
}

class $$VocabularyTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $VocabularyTableTable> {
  $$VocabularyTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<String> get reading =>
      $composableBuilder(column: $table.reading, builder: (column) => column);

  GeneratedColumn<String> get meaningVi =>
      $composableBuilder(column: $table.meaningVi, builder: (column) => column);

  GeneratedColumn<String> get partOfSpeech => $composableBuilder(
      column: $table.partOfSpeech, builder: (column) => column);

  GeneratedColumn<String> get exampleJp =>
      $composableBuilder(column: $table.exampleJp, builder: (column) => column);

  GeneratedColumn<String> get exampleVi =>
      $composableBuilder(column: $table.exampleVi, builder: (column) => column);

  GeneratedColumn<String> get audioUrl =>
      $composableBuilder(column: $table.audioUrl, builder: (column) => column);

  GeneratedColumn<String> get levelId =>
      $composableBuilder(column: $table.levelId, builder: (column) => column);
}

class $$VocabularyTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VocabularyTableTable,
    VocabularyTableData,
    $$VocabularyTableTableFilterComposer,
    $$VocabularyTableTableOrderingComposer,
    $$VocabularyTableTableAnnotationComposer,
    $$VocabularyTableTableCreateCompanionBuilder,
    $$VocabularyTableTableUpdateCompanionBuilder,
    (
      VocabularyTableData,
      BaseReferences<_$AppDatabase, $VocabularyTableTable, VocabularyTableData>
    ),
    VocabularyTableData,
    PrefetchHooks Function()> {
  $$VocabularyTableTableTableManager(
      _$AppDatabase db, $VocabularyTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VocabularyTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VocabularyTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VocabularyTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> word = const Value.absent(),
            Value<String> reading = const Value.absent(),
            Value<String> meaningVi = const Value.absent(),
            Value<String?> partOfSpeech = const Value.absent(),
            Value<String?> exampleJp = const Value.absent(),
            Value<String?> exampleVi = const Value.absent(),
            Value<String?> audioUrl = const Value.absent(),
            Value<String> levelId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VocabularyTableCompanion(
            id: id,
            word: word,
            reading: reading,
            meaningVi: meaningVi,
            partOfSpeech: partOfSpeech,
            exampleJp: exampleJp,
            exampleVi: exampleVi,
            audioUrl: audioUrl,
            levelId: levelId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String word,
            required String reading,
            required String meaningVi,
            Value<String?> partOfSpeech = const Value.absent(),
            Value<String?> exampleJp = const Value.absent(),
            Value<String?> exampleVi = const Value.absent(),
            Value<String?> audioUrl = const Value.absent(),
            required String levelId,
            Value<int> rowid = const Value.absent(),
          }) =>
              VocabularyTableCompanion.insert(
            id: id,
            word: word,
            reading: reading,
            meaningVi: meaningVi,
            partOfSpeech: partOfSpeech,
            exampleJp: exampleJp,
            exampleVi: exampleVi,
            audioUrl: audioUrl,
            levelId: levelId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VocabularyTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VocabularyTableTable,
    VocabularyTableData,
    $$VocabularyTableTableFilterComposer,
    $$VocabularyTableTableOrderingComposer,
    $$VocabularyTableTableAnnotationComposer,
    $$VocabularyTableTableCreateCompanionBuilder,
    $$VocabularyTableTableUpdateCompanionBuilder,
    (
      VocabularyTableData,
      BaseReferences<_$AppDatabase, $VocabularyTableTable, VocabularyTableData>
    ),
    VocabularyTableData,
    PrefetchHooks Function()>;
typedef $$KanjiTableTableCreateCompanionBuilder = KanjiTableCompanion Function({
  required String id,
  required String character,
  Value<String?> onyomi,
  Value<String?> kunyomi,
  required String meaningVi,
  Value<int?> strokeCount,
  Value<String?> exampleJp,
  Value<String?> exampleVi,
  required String levelId,
  Value<int> rowid,
});
typedef $$KanjiTableTableUpdateCompanionBuilder = KanjiTableCompanion Function({
  Value<String> id,
  Value<String> character,
  Value<String?> onyomi,
  Value<String?> kunyomi,
  Value<String> meaningVi,
  Value<int?> strokeCount,
  Value<String?> exampleJp,
  Value<String?> exampleVi,
  Value<String> levelId,
  Value<int> rowid,
});

class $$KanjiTableTableFilterComposer
    extends Composer<_$AppDatabase, $KanjiTableTable> {
  $$KanjiTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get character => $composableBuilder(
      column: $table.character, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get onyomi => $composableBuilder(
      column: $table.onyomi, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kunyomi => $composableBuilder(
      column: $table.kunyomi, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get meaningVi => $composableBuilder(
      column: $table.meaningVi, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get strokeCount => $composableBuilder(
      column: $table.strokeCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exampleJp => $composableBuilder(
      column: $table.exampleJp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exampleVi => $composableBuilder(
      column: $table.exampleVi, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get levelId => $composableBuilder(
      column: $table.levelId, builder: (column) => ColumnFilters(column));
}

class $$KanjiTableTableOrderingComposer
    extends Composer<_$AppDatabase, $KanjiTableTable> {
  $$KanjiTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get character => $composableBuilder(
      column: $table.character, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get onyomi => $composableBuilder(
      column: $table.onyomi, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kunyomi => $composableBuilder(
      column: $table.kunyomi, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meaningVi => $composableBuilder(
      column: $table.meaningVi, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get strokeCount => $composableBuilder(
      column: $table.strokeCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exampleJp => $composableBuilder(
      column: $table.exampleJp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exampleVi => $composableBuilder(
      column: $table.exampleVi, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get levelId => $composableBuilder(
      column: $table.levelId, builder: (column) => ColumnOrderings(column));
}

class $$KanjiTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $KanjiTableTable> {
  $$KanjiTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get character =>
      $composableBuilder(column: $table.character, builder: (column) => column);

  GeneratedColumn<String> get onyomi =>
      $composableBuilder(column: $table.onyomi, builder: (column) => column);

  GeneratedColumn<String> get kunyomi =>
      $composableBuilder(column: $table.kunyomi, builder: (column) => column);

  GeneratedColumn<String> get meaningVi =>
      $composableBuilder(column: $table.meaningVi, builder: (column) => column);

  GeneratedColumn<int> get strokeCount => $composableBuilder(
      column: $table.strokeCount, builder: (column) => column);

  GeneratedColumn<String> get exampleJp =>
      $composableBuilder(column: $table.exampleJp, builder: (column) => column);

  GeneratedColumn<String> get exampleVi =>
      $composableBuilder(column: $table.exampleVi, builder: (column) => column);

  GeneratedColumn<String> get levelId =>
      $composableBuilder(column: $table.levelId, builder: (column) => column);
}

class $$KanjiTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $KanjiTableTable,
    KanjiTableData,
    $$KanjiTableTableFilterComposer,
    $$KanjiTableTableOrderingComposer,
    $$KanjiTableTableAnnotationComposer,
    $$KanjiTableTableCreateCompanionBuilder,
    $$KanjiTableTableUpdateCompanionBuilder,
    (
      KanjiTableData,
      BaseReferences<_$AppDatabase, $KanjiTableTable, KanjiTableData>
    ),
    KanjiTableData,
    PrefetchHooks Function()> {
  $$KanjiTableTableTableManager(_$AppDatabase db, $KanjiTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KanjiTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KanjiTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KanjiTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> character = const Value.absent(),
            Value<String?> onyomi = const Value.absent(),
            Value<String?> kunyomi = const Value.absent(),
            Value<String> meaningVi = const Value.absent(),
            Value<int?> strokeCount = const Value.absent(),
            Value<String?> exampleJp = const Value.absent(),
            Value<String?> exampleVi = const Value.absent(),
            Value<String> levelId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              KanjiTableCompanion(
            id: id,
            character: character,
            onyomi: onyomi,
            kunyomi: kunyomi,
            meaningVi: meaningVi,
            strokeCount: strokeCount,
            exampleJp: exampleJp,
            exampleVi: exampleVi,
            levelId: levelId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String character,
            Value<String?> onyomi = const Value.absent(),
            Value<String?> kunyomi = const Value.absent(),
            required String meaningVi,
            Value<int?> strokeCount = const Value.absent(),
            Value<String?> exampleJp = const Value.absent(),
            Value<String?> exampleVi = const Value.absent(),
            required String levelId,
            Value<int> rowid = const Value.absent(),
          }) =>
              KanjiTableCompanion.insert(
            id: id,
            character: character,
            onyomi: onyomi,
            kunyomi: kunyomi,
            meaningVi: meaningVi,
            strokeCount: strokeCount,
            exampleJp: exampleJp,
            exampleVi: exampleVi,
            levelId: levelId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$KanjiTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $KanjiTableTable,
    KanjiTableData,
    $$KanjiTableTableFilterComposer,
    $$KanjiTableTableOrderingComposer,
    $$KanjiTableTableAnnotationComposer,
    $$KanjiTableTableCreateCompanionBuilder,
    $$KanjiTableTableUpdateCompanionBuilder,
    (
      KanjiTableData,
      BaseReferences<_$AppDatabase, $KanjiTableTable, KanjiTableData>
    ),
    KanjiTableData,
    PrefetchHooks Function()>;
typedef $$LessonsTableTableCreateCompanionBuilder = LessonsTableCompanion
    Function({
  required String id,
  required String title,
  Value<String?> description,
  required String levelId,
  Value<int> orderIndex,
  Value<int> rowid,
});
typedef $$LessonsTableTableUpdateCompanionBuilder = LessonsTableCompanion
    Function({
  Value<String> id,
  Value<String> title,
  Value<String?> description,
  Value<String> levelId,
  Value<int> orderIndex,
  Value<int> rowid,
});

class $$LessonsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LessonsTableTable> {
  $$LessonsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get levelId => $composableBuilder(
      column: $table.levelId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnFilters(column));
}

class $$LessonsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LessonsTableTable> {
  $$LessonsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get levelId => $composableBuilder(
      column: $table.levelId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnOrderings(column));
}

class $$LessonsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LessonsTableTable> {
  $$LessonsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get levelId =>
      $composableBuilder(column: $table.levelId, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => column);
}

class $$LessonsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LessonsTableTable,
    LessonsTableData,
    $$LessonsTableTableFilterComposer,
    $$LessonsTableTableOrderingComposer,
    $$LessonsTableTableAnnotationComposer,
    $$LessonsTableTableCreateCompanionBuilder,
    $$LessonsTableTableUpdateCompanionBuilder,
    (
      LessonsTableData,
      BaseReferences<_$AppDatabase, $LessonsTableTable, LessonsTableData>
    ),
    LessonsTableData,
    PrefetchHooks Function()> {
  $$LessonsTableTableTableManager(_$AppDatabase db, $LessonsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LessonsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LessonsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String> levelId = const Value.absent(),
            Value<int> orderIndex = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LessonsTableCompanion(
            id: id,
            title: title,
            description: description,
            levelId: levelId,
            orderIndex: orderIndex,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            Value<String?> description = const Value.absent(),
            required String levelId,
            Value<int> orderIndex = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LessonsTableCompanion.insert(
            id: id,
            title: title,
            description: description,
            levelId: levelId,
            orderIndex: orderIndex,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LessonsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LessonsTableTable,
    LessonsTableData,
    $$LessonsTableTableFilterComposer,
    $$LessonsTableTableOrderingComposer,
    $$LessonsTableTableAnnotationComposer,
    $$LessonsTableTableCreateCompanionBuilder,
    $$LessonsTableTableUpdateCompanionBuilder,
    (
      LessonsTableData,
      BaseReferences<_$AppDatabase, $LessonsTableTable, LessonsTableData>
    ),
    LessonsTableData,
    PrefetchHooks Function()>;
typedef $$LessonItemsTableTableCreateCompanionBuilder
    = LessonItemsTableCompanion Function({
  required String id,
  required String lessonId,
  required String itemType,
  required String itemId,
  Value<int> orderIndex,
  Value<int> rowid,
});
typedef $$LessonItemsTableTableUpdateCompanionBuilder
    = LessonItemsTableCompanion Function({
  Value<String> id,
  Value<String> lessonId,
  Value<String> itemType,
  Value<String> itemId,
  Value<int> orderIndex,
  Value<int> rowid,
});

class $$LessonItemsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LessonItemsTableTable> {
  $$LessonItemsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lessonId => $composableBuilder(
      column: $table.lessonId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemType => $composableBuilder(
      column: $table.itemType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnFilters(column));
}

class $$LessonItemsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LessonItemsTableTable> {
  $$LessonItemsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lessonId => $composableBuilder(
      column: $table.lessonId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemType => $composableBuilder(
      column: $table.itemType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnOrderings(column));
}

class $$LessonItemsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LessonItemsTableTable> {
  $$LessonItemsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => column);
}

class $$LessonItemsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LessonItemsTableTable,
    LessonItemsTableData,
    $$LessonItemsTableTableFilterComposer,
    $$LessonItemsTableTableOrderingComposer,
    $$LessonItemsTableTableAnnotationComposer,
    $$LessonItemsTableTableCreateCompanionBuilder,
    $$LessonItemsTableTableUpdateCompanionBuilder,
    (
      LessonItemsTableData,
      BaseReferences<_$AppDatabase, $LessonItemsTableTable,
          LessonItemsTableData>
    ),
    LessonItemsTableData,
    PrefetchHooks Function()> {
  $$LessonItemsTableTableTableManager(
      _$AppDatabase db, $LessonItemsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonItemsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LessonItemsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LessonItemsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> lessonId = const Value.absent(),
            Value<String> itemType = const Value.absent(),
            Value<String> itemId = const Value.absent(),
            Value<int> orderIndex = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LessonItemsTableCompanion(
            id: id,
            lessonId: lessonId,
            itemType: itemType,
            itemId: itemId,
            orderIndex: orderIndex,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String lessonId,
            required String itemType,
            required String itemId,
            Value<int> orderIndex = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LessonItemsTableCompanion.insert(
            id: id,
            lessonId: lessonId,
            itemType: itemType,
            itemId: itemId,
            orderIndex: orderIndex,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LessonItemsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LessonItemsTableTable,
    LessonItemsTableData,
    $$LessonItemsTableTableFilterComposer,
    $$LessonItemsTableTableOrderingComposer,
    $$LessonItemsTableTableAnnotationComposer,
    $$LessonItemsTableTableCreateCompanionBuilder,
    $$LessonItemsTableTableUpdateCompanionBuilder,
    (
      LessonItemsTableData,
      BaseReferences<_$AppDatabase, $LessonItemsTableTable,
          LessonItemsTableData>
    ),
    LessonItemsTableData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VocabularyTableTableTableManager get vocabularyTable =>
      $$VocabularyTableTableTableManager(_db, _db.vocabularyTable);
  $$KanjiTableTableTableManager get kanjiTable =>
      $$KanjiTableTableTableManager(_db, _db.kanjiTable);
  $$LessonsTableTableTableManager get lessonsTable =>
      $$LessonsTableTableTableManager(_db, _db.lessonsTable);
  $$LessonItemsTableTableTableManager get lessonItemsTable =>
      $$LessonItemsTableTableTableManager(_db, _db.lessonItemsTable);
}
