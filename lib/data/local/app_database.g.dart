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
  static const VerificationMeta _partOfSpeechMeta =
      const VerificationMeta('partOfSpeech');
  @override
  late final GeneratedColumn<String> partOfSpeech = GeneratedColumn<String>(
      'part_of_speech', aliasedName, true,
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
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, word, reading, partOfSpeech, audioUrl, levelId, category];
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
    if (data.containsKey('part_of_speech')) {
      context.handle(
          _partOfSpeechMeta,
          partOfSpeech.isAcceptableOrUnknown(
              data['part_of_speech']!, _partOfSpeechMeta));
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
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
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
      partOfSpeech: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}part_of_speech']),
      audioUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}audio_url']),
      levelId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}level_id'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category']),
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
  final String? partOfSpeech;
  final String? audioUrl;
  final String levelId;

  /// Chủ đề để duyệt/lọc (VD: "Mua sắm", "Gia đình") — 1 từ đúng 1 category,
  /// có thể null cho từ chưa được gán (xem migration `vocabulary_category`).
  final String? category;
  const VocabularyTableData(
      {required this.id,
      required this.word,
      required this.reading,
      this.partOfSpeech,
      this.audioUrl,
      required this.levelId,
      this.category});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['word'] = Variable<String>(word);
    map['reading'] = Variable<String>(reading);
    if (!nullToAbsent || partOfSpeech != null) {
      map['part_of_speech'] = Variable<String>(partOfSpeech);
    }
    if (!nullToAbsent || audioUrl != null) {
      map['audio_url'] = Variable<String>(audioUrl);
    }
    map['level_id'] = Variable<String>(levelId);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    return map;
  }

  VocabularyTableCompanion toCompanion(bool nullToAbsent) {
    return VocabularyTableCompanion(
      id: Value(id),
      word: Value(word),
      reading: Value(reading),
      partOfSpeech: partOfSpeech == null && nullToAbsent
          ? const Value.absent()
          : Value(partOfSpeech),
      audioUrl: audioUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(audioUrl),
      levelId: Value(levelId),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
    );
  }

  factory VocabularyTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VocabularyTableData(
      id: serializer.fromJson<String>(json['id']),
      word: serializer.fromJson<String>(json['word']),
      reading: serializer.fromJson<String>(json['reading']),
      partOfSpeech: serializer.fromJson<String?>(json['partOfSpeech']),
      audioUrl: serializer.fromJson<String?>(json['audioUrl']),
      levelId: serializer.fromJson<String>(json['levelId']),
      category: serializer.fromJson<String?>(json['category']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'word': serializer.toJson<String>(word),
      'reading': serializer.toJson<String>(reading),
      'partOfSpeech': serializer.toJson<String?>(partOfSpeech),
      'audioUrl': serializer.toJson<String?>(audioUrl),
      'levelId': serializer.toJson<String>(levelId),
      'category': serializer.toJson<String?>(category),
    };
  }

  VocabularyTableData copyWith(
          {String? id,
          String? word,
          String? reading,
          Value<String?> partOfSpeech = const Value.absent(),
          Value<String?> audioUrl = const Value.absent(),
          String? levelId,
          Value<String?> category = const Value.absent()}) =>
      VocabularyTableData(
        id: id ?? this.id,
        word: word ?? this.word,
        reading: reading ?? this.reading,
        partOfSpeech:
            partOfSpeech.present ? partOfSpeech.value : this.partOfSpeech,
        audioUrl: audioUrl.present ? audioUrl.value : this.audioUrl,
        levelId: levelId ?? this.levelId,
        category: category.present ? category.value : this.category,
      );
  VocabularyTableData copyWithCompanion(VocabularyTableCompanion data) {
    return VocabularyTableData(
      id: data.id.present ? data.id.value : this.id,
      word: data.word.present ? data.word.value : this.word,
      reading: data.reading.present ? data.reading.value : this.reading,
      partOfSpeech: data.partOfSpeech.present
          ? data.partOfSpeech.value
          : this.partOfSpeech,
      audioUrl: data.audioUrl.present ? data.audioUrl.value : this.audioUrl,
      levelId: data.levelId.present ? data.levelId.value : this.levelId,
      category: data.category.present ? data.category.value : this.category,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyTableData(')
          ..write('id: $id, ')
          ..write('word: $word, ')
          ..write('reading: $reading, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('levelId: $levelId, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, word, reading, partOfSpeech, audioUrl, levelId, category);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VocabularyTableData &&
          other.id == this.id &&
          other.word == this.word &&
          other.reading == this.reading &&
          other.partOfSpeech == this.partOfSpeech &&
          other.audioUrl == this.audioUrl &&
          other.levelId == this.levelId &&
          other.category == this.category);
}

class VocabularyTableCompanion extends UpdateCompanion<VocabularyTableData> {
  final Value<String> id;
  final Value<String> word;
  final Value<String> reading;
  final Value<String?> partOfSpeech;
  final Value<String?> audioUrl;
  final Value<String> levelId;
  final Value<String?> category;
  final Value<int> rowid;
  const VocabularyTableCompanion({
    this.id = const Value.absent(),
    this.word = const Value.absent(),
    this.reading = const Value.absent(),
    this.partOfSpeech = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.levelId = const Value.absent(),
    this.category = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VocabularyTableCompanion.insert({
    required String id,
    required String word,
    required String reading,
    this.partOfSpeech = const Value.absent(),
    this.audioUrl = const Value.absent(),
    required String levelId,
    this.category = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        word = Value(word),
        reading = Value(reading),
        levelId = Value(levelId);
  static Insertable<VocabularyTableData> custom({
    Expression<String>? id,
    Expression<String>? word,
    Expression<String>? reading,
    Expression<String>? partOfSpeech,
    Expression<String>? audioUrl,
    Expression<String>? levelId,
    Expression<String>? category,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (word != null) 'word': word,
      if (reading != null) 'reading': reading,
      if (partOfSpeech != null) 'part_of_speech': partOfSpeech,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (levelId != null) 'level_id': levelId,
      if (category != null) 'category': category,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VocabularyTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? word,
      Value<String>? reading,
      Value<String?>? partOfSpeech,
      Value<String?>? audioUrl,
      Value<String>? levelId,
      Value<String?>? category,
      Value<int>? rowid}) {
    return VocabularyTableCompanion(
      id: id ?? this.id,
      word: word ?? this.word,
      reading: reading ?? this.reading,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      audioUrl: audioUrl ?? this.audioUrl,
      levelId: levelId ?? this.levelId,
      category: category ?? this.category,
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
    if (partOfSpeech.present) {
      map['part_of_speech'] = Variable<String>(partOfSpeech.value);
    }
    if (audioUrl.present) {
      map['audio_url'] = Variable<String>(audioUrl.value);
    }
    if (levelId.present) {
      map['level_id'] = Variable<String>(levelId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
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
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('levelId: $levelId, ')
          ..write('category: $category, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VocabularyMeaningsTableTable extends VocabularyMeaningsTable
    with TableInfo<$VocabularyMeaningsTableTable, VocabularyMeaningsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VocabularyMeaningsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vocabularyIdMeta =
      const VerificationMeta('vocabularyId');
  @override
  late final GeneratedColumn<String> vocabularyId = GeneratedColumn<String>(
      'vocabulary_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderIndexMeta =
      const VerificationMeta('orderIndex');
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
      'order_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _meaningViMeta =
      const VerificationMeta('meaningVi');
  @override
  late final GeneratedColumn<String> meaningVi = GeneratedColumn<String>(
      'meaning_vi', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
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
  @override
  List<GeneratedColumn> get $columns =>
      [id, vocabularyId, orderIndex, meaningVi, exampleJp, exampleVi];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vocabulary_meanings_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<VocabularyMeaningsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vocabulary_id')) {
      context.handle(
          _vocabularyIdMeta,
          vocabularyId.isAcceptableOrUnknown(
              data['vocabulary_id']!, _vocabularyIdMeta));
    } else if (isInserting) {
      context.missing(_vocabularyIdMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
          _orderIndexMeta,
          orderIndex.isAcceptableOrUnknown(
              data['order_index']!, _orderIndexMeta));
    }
    if (data.containsKey('meaning_vi')) {
      context.handle(_meaningViMeta,
          meaningVi.isAcceptableOrUnknown(data['meaning_vi']!, _meaningViMeta));
    } else if (isInserting) {
      context.missing(_meaningViMeta);
    }
    if (data.containsKey('example_jp')) {
      context.handle(_exampleJpMeta,
          exampleJp.isAcceptableOrUnknown(data['example_jp']!, _exampleJpMeta));
    }
    if (data.containsKey('example_vi')) {
      context.handle(_exampleViMeta,
          exampleVi.isAcceptableOrUnknown(data['example_vi']!, _exampleViMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VocabularyMeaningsTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VocabularyMeaningsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      vocabularyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vocabulary_id'])!,
      orderIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_index'])!,
      meaningVi: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}meaning_vi'])!,
      exampleJp: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}example_jp']),
      exampleVi: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}example_vi']),
    );
  }

  @override
  $VocabularyMeaningsTableTable createAlias(String alias) {
    return $VocabularyMeaningsTableTable(attachedDatabase, alias);
  }
}

class VocabularyMeaningsTableData extends DataClass
    implements Insertable<VocabularyMeaningsTableData> {
  final String id;
  final String vocabularyId;
  final int orderIndex;
  final String meaningVi;
  final String? exampleJp;
  final String? exampleVi;
  const VocabularyMeaningsTableData(
      {required this.id,
      required this.vocabularyId,
      required this.orderIndex,
      required this.meaningVi,
      this.exampleJp,
      this.exampleVi});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vocabulary_id'] = Variable<String>(vocabularyId);
    map['order_index'] = Variable<int>(orderIndex);
    map['meaning_vi'] = Variable<String>(meaningVi);
    if (!nullToAbsent || exampleJp != null) {
      map['example_jp'] = Variable<String>(exampleJp);
    }
    if (!nullToAbsent || exampleVi != null) {
      map['example_vi'] = Variable<String>(exampleVi);
    }
    return map;
  }

  VocabularyMeaningsTableCompanion toCompanion(bool nullToAbsent) {
    return VocabularyMeaningsTableCompanion(
      id: Value(id),
      vocabularyId: Value(vocabularyId),
      orderIndex: Value(orderIndex),
      meaningVi: Value(meaningVi),
      exampleJp: exampleJp == null && nullToAbsent
          ? const Value.absent()
          : Value(exampleJp),
      exampleVi: exampleVi == null && nullToAbsent
          ? const Value.absent()
          : Value(exampleVi),
    );
  }

  factory VocabularyMeaningsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VocabularyMeaningsTableData(
      id: serializer.fromJson<String>(json['id']),
      vocabularyId: serializer.fromJson<String>(json['vocabularyId']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      meaningVi: serializer.fromJson<String>(json['meaningVi']),
      exampleJp: serializer.fromJson<String?>(json['exampleJp']),
      exampleVi: serializer.fromJson<String?>(json['exampleVi']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vocabularyId': serializer.toJson<String>(vocabularyId),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'meaningVi': serializer.toJson<String>(meaningVi),
      'exampleJp': serializer.toJson<String?>(exampleJp),
      'exampleVi': serializer.toJson<String?>(exampleVi),
    };
  }

  VocabularyMeaningsTableData copyWith(
          {String? id,
          String? vocabularyId,
          int? orderIndex,
          String? meaningVi,
          Value<String?> exampleJp = const Value.absent(),
          Value<String?> exampleVi = const Value.absent()}) =>
      VocabularyMeaningsTableData(
        id: id ?? this.id,
        vocabularyId: vocabularyId ?? this.vocabularyId,
        orderIndex: orderIndex ?? this.orderIndex,
        meaningVi: meaningVi ?? this.meaningVi,
        exampleJp: exampleJp.present ? exampleJp.value : this.exampleJp,
        exampleVi: exampleVi.present ? exampleVi.value : this.exampleVi,
      );
  VocabularyMeaningsTableData copyWithCompanion(
      VocabularyMeaningsTableCompanion data) {
    return VocabularyMeaningsTableData(
      id: data.id.present ? data.id.value : this.id,
      vocabularyId: data.vocabularyId.present
          ? data.vocabularyId.value
          : this.vocabularyId,
      orderIndex:
          data.orderIndex.present ? data.orderIndex.value : this.orderIndex,
      meaningVi: data.meaningVi.present ? data.meaningVi.value : this.meaningVi,
      exampleJp: data.exampleJp.present ? data.exampleJp.value : this.exampleJp,
      exampleVi: data.exampleVi.present ? data.exampleVi.value : this.exampleVi,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyMeaningsTableData(')
          ..write('id: $id, ')
          ..write('vocabularyId: $vocabularyId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('meaningVi: $meaningVi, ')
          ..write('exampleJp: $exampleJp, ')
          ..write('exampleVi: $exampleVi')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, vocabularyId, orderIndex, meaningVi, exampleJp, exampleVi);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VocabularyMeaningsTableData &&
          other.id == this.id &&
          other.vocabularyId == this.vocabularyId &&
          other.orderIndex == this.orderIndex &&
          other.meaningVi == this.meaningVi &&
          other.exampleJp == this.exampleJp &&
          other.exampleVi == this.exampleVi);
}

class VocabularyMeaningsTableCompanion
    extends UpdateCompanion<VocabularyMeaningsTableData> {
  final Value<String> id;
  final Value<String> vocabularyId;
  final Value<int> orderIndex;
  final Value<String> meaningVi;
  final Value<String?> exampleJp;
  final Value<String?> exampleVi;
  final Value<int> rowid;
  const VocabularyMeaningsTableCompanion({
    this.id = const Value.absent(),
    this.vocabularyId = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.meaningVi = const Value.absent(),
    this.exampleJp = const Value.absent(),
    this.exampleVi = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VocabularyMeaningsTableCompanion.insert({
    required String id,
    required String vocabularyId,
    this.orderIndex = const Value.absent(),
    required String meaningVi,
    this.exampleJp = const Value.absent(),
    this.exampleVi = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        vocabularyId = Value(vocabularyId),
        meaningVi = Value(meaningVi);
  static Insertable<VocabularyMeaningsTableData> custom({
    Expression<String>? id,
    Expression<String>? vocabularyId,
    Expression<int>? orderIndex,
    Expression<String>? meaningVi,
    Expression<String>? exampleJp,
    Expression<String>? exampleVi,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vocabularyId != null) 'vocabulary_id': vocabularyId,
      if (orderIndex != null) 'order_index': orderIndex,
      if (meaningVi != null) 'meaning_vi': meaningVi,
      if (exampleJp != null) 'example_jp': exampleJp,
      if (exampleVi != null) 'example_vi': exampleVi,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VocabularyMeaningsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? vocabularyId,
      Value<int>? orderIndex,
      Value<String>? meaningVi,
      Value<String?>? exampleJp,
      Value<String?>? exampleVi,
      Value<int>? rowid}) {
    return VocabularyMeaningsTableCompanion(
      id: id ?? this.id,
      vocabularyId: vocabularyId ?? this.vocabularyId,
      orderIndex: orderIndex ?? this.orderIndex,
      meaningVi: meaningVi ?? this.meaningVi,
      exampleJp: exampleJp ?? this.exampleJp,
      exampleVi: exampleVi ?? this.exampleVi,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vocabularyId.present) {
      map['vocabulary_id'] = Variable<String>(vocabularyId.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (meaningVi.present) {
      map['meaning_vi'] = Variable<String>(meaningVi.value);
    }
    if (exampleJp.present) {
      map['example_jp'] = Variable<String>(exampleJp.value);
    }
    if (exampleVi.present) {
      map['example_vi'] = Variable<String>(exampleVi.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VocabularyMeaningsTableCompanion(')
          ..write('id: $id, ')
          ..write('vocabularyId: $vocabularyId, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('meaningVi: $meaningVi, ')
          ..write('exampleJp: $exampleJp, ')
          ..write('exampleVi: $exampleVi, ')
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
      'meaning_vi', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
  static const VerificationMeta _hanVietMeta =
      const VerificationMeta('hanViet');
  @override
  late final GeneratedColumn<String> hanViet = GeneratedColumn<String>(
      'han_viet', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _mnemonicMeta =
      const VerificationMeta('mnemonic');
  @override
  late final GeneratedColumn<String> mnemonic = GeneratedColumn<String>(
      'mnemonic', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _strokeDataMeta =
      const VerificationMeta('strokeData');
  @override
  late final GeneratedColumn<String> strokeData = GeneratedColumn<String>(
      'stroke_data', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _levelIdMeta =
      const VerificationMeta('levelId');
  @override
  late final GeneratedColumn<String> levelId = GeneratedColumn<String>(
      'level_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _componentsMeta =
      const VerificationMeta('components');
  @override
  late final GeneratedColumn<String> components = GeneratedColumn<String>(
      'components', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
        hanViet,
        mnemonic,
        strokeData,
        levelId,
        components
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
    if (data.containsKey('han_viet')) {
      context.handle(_hanVietMeta,
          hanViet.isAcceptableOrUnknown(data['han_viet']!, _hanVietMeta));
    }
    if (data.containsKey('mnemonic')) {
      context.handle(_mnemonicMeta,
          mnemonic.isAcceptableOrUnknown(data['mnemonic']!, _mnemonicMeta));
    }
    if (data.containsKey('stroke_data')) {
      context.handle(
          _strokeDataMeta,
          strokeData.isAcceptableOrUnknown(
              data['stroke_data']!, _strokeDataMeta));
    }
    if (data.containsKey('level_id')) {
      context.handle(_levelIdMeta,
          levelId.isAcceptableOrUnknown(data['level_id']!, _levelIdMeta));
    } else if (isInserting) {
      context.missing(_levelIdMeta);
    }
    if (data.containsKey('components')) {
      context.handle(
          _componentsMeta,
          components.isAcceptableOrUnknown(
              data['components']!, _componentsMeta));
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
          .read(DriftSqlType.string, data['${effectivePrefix}meaning_vi']),
      strokeCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stroke_count']),
      exampleJp: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}example_jp']),
      exampleVi: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}example_vi']),
      hanViet: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}han_viet']),
      mnemonic: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mnemonic']),
      strokeData: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}stroke_data']),
      levelId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}level_id'])!,
      components: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}components']),
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
  final String? meaningVi;
  final int? strokeCount;
  final String? exampleJp;
  final String? exampleVi;
  final String? hanViet;
  final String? mnemonic;
  final String? strokeData;
  final String levelId;

  /// Các bộ ghép trực tiếp nên chữ này (JSON của List&lt;String&gt;) — xem
  /// migration `20260727020000_kanji_components.sql` để biết nguồn dữ liệu.
  final String? components;
  const KanjiTableData(
      {required this.id,
      required this.character,
      this.onyomi,
      this.kunyomi,
      this.meaningVi,
      this.strokeCount,
      this.exampleJp,
      this.exampleVi,
      this.hanViet,
      this.mnemonic,
      this.strokeData,
      required this.levelId,
      this.components});
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
    if (!nullToAbsent || meaningVi != null) {
      map['meaning_vi'] = Variable<String>(meaningVi);
    }
    if (!nullToAbsent || strokeCount != null) {
      map['stroke_count'] = Variable<int>(strokeCount);
    }
    if (!nullToAbsent || exampleJp != null) {
      map['example_jp'] = Variable<String>(exampleJp);
    }
    if (!nullToAbsent || exampleVi != null) {
      map['example_vi'] = Variable<String>(exampleVi);
    }
    if (!nullToAbsent || hanViet != null) {
      map['han_viet'] = Variable<String>(hanViet);
    }
    if (!nullToAbsent || mnemonic != null) {
      map['mnemonic'] = Variable<String>(mnemonic);
    }
    if (!nullToAbsent || strokeData != null) {
      map['stroke_data'] = Variable<String>(strokeData);
    }
    map['level_id'] = Variable<String>(levelId);
    if (!nullToAbsent || components != null) {
      map['components'] = Variable<String>(components);
    }
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
      meaningVi: meaningVi == null && nullToAbsent
          ? const Value.absent()
          : Value(meaningVi),
      strokeCount: strokeCount == null && nullToAbsent
          ? const Value.absent()
          : Value(strokeCount),
      exampleJp: exampleJp == null && nullToAbsent
          ? const Value.absent()
          : Value(exampleJp),
      exampleVi: exampleVi == null && nullToAbsent
          ? const Value.absent()
          : Value(exampleVi),
      hanViet: hanViet == null && nullToAbsent
          ? const Value.absent()
          : Value(hanViet),
      mnemonic: mnemonic == null && nullToAbsent
          ? const Value.absent()
          : Value(mnemonic),
      strokeData: strokeData == null && nullToAbsent
          ? const Value.absent()
          : Value(strokeData),
      levelId: Value(levelId),
      components: components == null && nullToAbsent
          ? const Value.absent()
          : Value(components),
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
      meaningVi: serializer.fromJson<String?>(json['meaningVi']),
      strokeCount: serializer.fromJson<int?>(json['strokeCount']),
      exampleJp: serializer.fromJson<String?>(json['exampleJp']),
      exampleVi: serializer.fromJson<String?>(json['exampleVi']),
      hanViet: serializer.fromJson<String?>(json['hanViet']),
      mnemonic: serializer.fromJson<String?>(json['mnemonic']),
      strokeData: serializer.fromJson<String?>(json['strokeData']),
      levelId: serializer.fromJson<String>(json['levelId']),
      components: serializer.fromJson<String?>(json['components']),
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
      'meaningVi': serializer.toJson<String?>(meaningVi),
      'strokeCount': serializer.toJson<int?>(strokeCount),
      'exampleJp': serializer.toJson<String?>(exampleJp),
      'exampleVi': serializer.toJson<String?>(exampleVi),
      'hanViet': serializer.toJson<String?>(hanViet),
      'mnemonic': serializer.toJson<String?>(mnemonic),
      'strokeData': serializer.toJson<String?>(strokeData),
      'levelId': serializer.toJson<String>(levelId),
      'components': serializer.toJson<String?>(components),
    };
  }

  KanjiTableData copyWith(
          {String? id,
          String? character,
          Value<String?> onyomi = const Value.absent(),
          Value<String?> kunyomi = const Value.absent(),
          Value<String?> meaningVi = const Value.absent(),
          Value<int?> strokeCount = const Value.absent(),
          Value<String?> exampleJp = const Value.absent(),
          Value<String?> exampleVi = const Value.absent(),
          Value<String?> hanViet = const Value.absent(),
          Value<String?> mnemonic = const Value.absent(),
          Value<String?> strokeData = const Value.absent(),
          String? levelId,
          Value<String?> components = const Value.absent()}) =>
      KanjiTableData(
        id: id ?? this.id,
        character: character ?? this.character,
        onyomi: onyomi.present ? onyomi.value : this.onyomi,
        kunyomi: kunyomi.present ? kunyomi.value : this.kunyomi,
        meaningVi: meaningVi.present ? meaningVi.value : this.meaningVi,
        strokeCount: strokeCount.present ? strokeCount.value : this.strokeCount,
        exampleJp: exampleJp.present ? exampleJp.value : this.exampleJp,
        exampleVi: exampleVi.present ? exampleVi.value : this.exampleVi,
        hanViet: hanViet.present ? hanViet.value : this.hanViet,
        mnemonic: mnemonic.present ? mnemonic.value : this.mnemonic,
        strokeData: strokeData.present ? strokeData.value : this.strokeData,
        levelId: levelId ?? this.levelId,
        components: components.present ? components.value : this.components,
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
      hanViet: data.hanViet.present ? data.hanViet.value : this.hanViet,
      mnemonic: data.mnemonic.present ? data.mnemonic.value : this.mnemonic,
      strokeData:
          data.strokeData.present ? data.strokeData.value : this.strokeData,
      levelId: data.levelId.present ? data.levelId.value : this.levelId,
      components:
          data.components.present ? data.components.value : this.components,
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
          ..write('hanViet: $hanViet, ')
          ..write('mnemonic: $mnemonic, ')
          ..write('strokeData: $strokeData, ')
          ..write('levelId: $levelId, ')
          ..write('components: $components')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      character,
      onyomi,
      kunyomi,
      meaningVi,
      strokeCount,
      exampleJp,
      exampleVi,
      hanViet,
      mnemonic,
      strokeData,
      levelId,
      components);
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
          other.hanViet == this.hanViet &&
          other.mnemonic == this.mnemonic &&
          other.strokeData == this.strokeData &&
          other.levelId == this.levelId &&
          other.components == this.components);
}

class KanjiTableCompanion extends UpdateCompanion<KanjiTableData> {
  final Value<String> id;
  final Value<String> character;
  final Value<String?> onyomi;
  final Value<String?> kunyomi;
  final Value<String?> meaningVi;
  final Value<int?> strokeCount;
  final Value<String?> exampleJp;
  final Value<String?> exampleVi;
  final Value<String?> hanViet;
  final Value<String?> mnemonic;
  final Value<String?> strokeData;
  final Value<String> levelId;
  final Value<String?> components;
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
    this.hanViet = const Value.absent(),
    this.mnemonic = const Value.absent(),
    this.strokeData = const Value.absent(),
    this.levelId = const Value.absent(),
    this.components = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KanjiTableCompanion.insert({
    required String id,
    required String character,
    this.onyomi = const Value.absent(),
    this.kunyomi = const Value.absent(),
    this.meaningVi = const Value.absent(),
    this.strokeCount = const Value.absent(),
    this.exampleJp = const Value.absent(),
    this.exampleVi = const Value.absent(),
    this.hanViet = const Value.absent(),
    this.mnemonic = const Value.absent(),
    this.strokeData = const Value.absent(),
    required String levelId,
    this.components = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        character = Value(character),
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
    Expression<String>? hanViet,
    Expression<String>? mnemonic,
    Expression<String>? strokeData,
    Expression<String>? levelId,
    Expression<String>? components,
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
      if (hanViet != null) 'han_viet': hanViet,
      if (mnemonic != null) 'mnemonic': mnemonic,
      if (strokeData != null) 'stroke_data': strokeData,
      if (levelId != null) 'level_id': levelId,
      if (components != null) 'components': components,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KanjiTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? character,
      Value<String?>? onyomi,
      Value<String?>? kunyomi,
      Value<String?>? meaningVi,
      Value<int?>? strokeCount,
      Value<String?>? exampleJp,
      Value<String?>? exampleVi,
      Value<String?>? hanViet,
      Value<String?>? mnemonic,
      Value<String?>? strokeData,
      Value<String>? levelId,
      Value<String?>? components,
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
      hanViet: hanViet ?? this.hanViet,
      mnemonic: mnemonic ?? this.mnemonic,
      strokeData: strokeData ?? this.strokeData,
      levelId: levelId ?? this.levelId,
      components: components ?? this.components,
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
    if (hanViet.present) {
      map['han_viet'] = Variable<String>(hanViet.value);
    }
    if (mnemonic.present) {
      map['mnemonic'] = Variable<String>(mnemonic.value);
    }
    if (strokeData.present) {
      map['stroke_data'] = Variable<String>(strokeData.value);
    }
    if (levelId.present) {
      map['level_id'] = Variable<String>(levelId.value);
    }
    if (components.present) {
      map['components'] = Variable<String>(components.value);
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
          ..write('hanViet: $hanViet, ')
          ..write('mnemonic: $mnemonic, ')
          ..write('strokeData: $strokeData, ')
          ..write('levelId: $levelId, ')
          ..write('components: $components, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GrammarPointsTableTable extends GrammarPointsTable
    with TableInfo<$GrammarPointsTableTable, GrammarPointsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GrammarPointsTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _explanationMeta =
      const VerificationMeta('explanation');
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
      'explanation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
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
  static const VerificationMeta _commonMistakeMeta =
      const VerificationMeta('commonMistake');
  @override
  late final GeneratedColumn<String> commonMistake = GeneratedColumn<String>(
      'common_mistake', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _memoryTipMeta =
      const VerificationMeta('memoryTip');
  @override
  late final GeneratedColumn<String> memoryTip = GeneratedColumn<String>(
      'memory_tip', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _comparisonNoteMeta =
      const VerificationMeta('comparisonNote');
  @override
  late final GeneratedColumn<String> comparisonNote = GeneratedColumn<String>(
      'comparison_note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _levelIdMeta =
      const VerificationMeta('levelId');
  @override
  late final GeneratedColumn<String> levelId = GeneratedColumn<String>(
      'level_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _practiceTokensMeta =
      const VerificationMeta('practiceTokens');
  @override
  late final GeneratedColumn<String> practiceTokens = GeneratedColumn<String>(
      'practice_tokens', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _practiceBlankIndexMeta =
      const VerificationMeta('practiceBlankIndex');
  @override
  late final GeneratedColumn<int> practiceBlankIndex = GeneratedColumn<int>(
      'practice_blank_index', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        explanation,
        exampleJp,
        exampleVi,
        commonMistake,
        memoryTip,
        comparisonNote,
        levelId,
        practiceTokens,
        practiceBlankIndex
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grammar_points_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<GrammarPointsTableData> instance,
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
    if (data.containsKey('explanation')) {
      context.handle(
          _explanationMeta,
          explanation.isAcceptableOrUnknown(
              data['explanation']!, _explanationMeta));
    } else if (isInserting) {
      context.missing(_explanationMeta);
    }
    if (data.containsKey('example_jp')) {
      context.handle(_exampleJpMeta,
          exampleJp.isAcceptableOrUnknown(data['example_jp']!, _exampleJpMeta));
    }
    if (data.containsKey('example_vi')) {
      context.handle(_exampleViMeta,
          exampleVi.isAcceptableOrUnknown(data['example_vi']!, _exampleViMeta));
    }
    if (data.containsKey('common_mistake')) {
      context.handle(
          _commonMistakeMeta,
          commonMistake.isAcceptableOrUnknown(
              data['common_mistake']!, _commonMistakeMeta));
    }
    if (data.containsKey('memory_tip')) {
      context.handle(_memoryTipMeta,
          memoryTip.isAcceptableOrUnknown(data['memory_tip']!, _memoryTipMeta));
    }
    if (data.containsKey('comparison_note')) {
      context.handle(
          _comparisonNoteMeta,
          comparisonNote.isAcceptableOrUnknown(
              data['comparison_note']!, _comparisonNoteMeta));
    }
    if (data.containsKey('level_id')) {
      context.handle(_levelIdMeta,
          levelId.isAcceptableOrUnknown(data['level_id']!, _levelIdMeta));
    } else if (isInserting) {
      context.missing(_levelIdMeta);
    }
    if (data.containsKey('practice_tokens')) {
      context.handle(
          _practiceTokensMeta,
          practiceTokens.isAcceptableOrUnknown(
              data['practice_tokens']!, _practiceTokensMeta));
    }
    if (data.containsKey('practice_blank_index')) {
      context.handle(
          _practiceBlankIndexMeta,
          practiceBlankIndex.isAcceptableOrUnknown(
              data['practice_blank_index']!, _practiceBlankIndexMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GrammarPointsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GrammarPointsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      explanation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}explanation'])!,
      exampleJp: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}example_jp']),
      exampleVi: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}example_vi']),
      commonMistake: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}common_mistake']),
      memoryTip: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}memory_tip']),
      comparisonNote: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}comparison_note']),
      levelId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}level_id'])!,
      practiceTokens: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}practice_tokens']),
      practiceBlankIndex: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}practice_blank_index']),
    );
  }

  @override
  $GrammarPointsTableTable createAlias(String alias) {
    return $GrammarPointsTableTable(attachedDatabase, alias);
  }
}

class GrammarPointsTableData extends DataClass
    implements Insertable<GrammarPointsTableData> {
  final String id;
  final String title;
  final String explanation;
  final String? exampleJp;
  final String? exampleVi;
  final String? commonMistake;
  final String? memoryTip;
  final String? comparisonNote;
  final String levelId;

  /// Từ/cụm tách sẵn từ example_jp, đúng thứ tự (JSON của List&lt;String&gt;) —
  /// dùng cho Practice mở rộng, xem migration
  /// `20260727040000_grammar_practice_tokens.sql`.
  final String? practiceTokens;
  final int? practiceBlankIndex;
  const GrammarPointsTableData(
      {required this.id,
      required this.title,
      required this.explanation,
      this.exampleJp,
      this.exampleVi,
      this.commonMistake,
      this.memoryTip,
      this.comparisonNote,
      required this.levelId,
      this.practiceTokens,
      this.practiceBlankIndex});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['explanation'] = Variable<String>(explanation);
    if (!nullToAbsent || exampleJp != null) {
      map['example_jp'] = Variable<String>(exampleJp);
    }
    if (!nullToAbsent || exampleVi != null) {
      map['example_vi'] = Variable<String>(exampleVi);
    }
    if (!nullToAbsent || commonMistake != null) {
      map['common_mistake'] = Variable<String>(commonMistake);
    }
    if (!nullToAbsent || memoryTip != null) {
      map['memory_tip'] = Variable<String>(memoryTip);
    }
    if (!nullToAbsent || comparisonNote != null) {
      map['comparison_note'] = Variable<String>(comparisonNote);
    }
    map['level_id'] = Variable<String>(levelId);
    if (!nullToAbsent || practiceTokens != null) {
      map['practice_tokens'] = Variable<String>(practiceTokens);
    }
    if (!nullToAbsent || practiceBlankIndex != null) {
      map['practice_blank_index'] = Variable<int>(practiceBlankIndex);
    }
    return map;
  }

  GrammarPointsTableCompanion toCompanion(bool nullToAbsent) {
    return GrammarPointsTableCompanion(
      id: Value(id),
      title: Value(title),
      explanation: Value(explanation),
      exampleJp: exampleJp == null && nullToAbsent
          ? const Value.absent()
          : Value(exampleJp),
      exampleVi: exampleVi == null && nullToAbsent
          ? const Value.absent()
          : Value(exampleVi),
      commonMistake: commonMistake == null && nullToAbsent
          ? const Value.absent()
          : Value(commonMistake),
      memoryTip: memoryTip == null && nullToAbsent
          ? const Value.absent()
          : Value(memoryTip),
      comparisonNote: comparisonNote == null && nullToAbsent
          ? const Value.absent()
          : Value(comparisonNote),
      levelId: Value(levelId),
      practiceTokens: practiceTokens == null && nullToAbsent
          ? const Value.absent()
          : Value(practiceTokens),
      practiceBlankIndex: practiceBlankIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(practiceBlankIndex),
    );
  }

  factory GrammarPointsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GrammarPointsTableData(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      explanation: serializer.fromJson<String>(json['explanation']),
      exampleJp: serializer.fromJson<String?>(json['exampleJp']),
      exampleVi: serializer.fromJson<String?>(json['exampleVi']),
      commonMistake: serializer.fromJson<String?>(json['commonMistake']),
      memoryTip: serializer.fromJson<String?>(json['memoryTip']),
      comparisonNote: serializer.fromJson<String?>(json['comparisonNote']),
      levelId: serializer.fromJson<String>(json['levelId']),
      practiceTokens: serializer.fromJson<String?>(json['practiceTokens']),
      practiceBlankIndex: serializer.fromJson<int?>(json['practiceBlankIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'explanation': serializer.toJson<String>(explanation),
      'exampleJp': serializer.toJson<String?>(exampleJp),
      'exampleVi': serializer.toJson<String?>(exampleVi),
      'commonMistake': serializer.toJson<String?>(commonMistake),
      'memoryTip': serializer.toJson<String?>(memoryTip),
      'comparisonNote': serializer.toJson<String?>(comparisonNote),
      'levelId': serializer.toJson<String>(levelId),
      'practiceTokens': serializer.toJson<String?>(practiceTokens),
      'practiceBlankIndex': serializer.toJson<int?>(practiceBlankIndex),
    };
  }

  GrammarPointsTableData copyWith(
          {String? id,
          String? title,
          String? explanation,
          Value<String?> exampleJp = const Value.absent(),
          Value<String?> exampleVi = const Value.absent(),
          Value<String?> commonMistake = const Value.absent(),
          Value<String?> memoryTip = const Value.absent(),
          Value<String?> comparisonNote = const Value.absent(),
          String? levelId,
          Value<String?> practiceTokens = const Value.absent(),
          Value<int?> practiceBlankIndex = const Value.absent()}) =>
      GrammarPointsTableData(
        id: id ?? this.id,
        title: title ?? this.title,
        explanation: explanation ?? this.explanation,
        exampleJp: exampleJp.present ? exampleJp.value : this.exampleJp,
        exampleVi: exampleVi.present ? exampleVi.value : this.exampleVi,
        commonMistake:
            commonMistake.present ? commonMistake.value : this.commonMistake,
        memoryTip: memoryTip.present ? memoryTip.value : this.memoryTip,
        comparisonNote:
            comparisonNote.present ? comparisonNote.value : this.comparisonNote,
        levelId: levelId ?? this.levelId,
        practiceTokens:
            practiceTokens.present ? practiceTokens.value : this.practiceTokens,
        practiceBlankIndex: practiceBlankIndex.present
            ? practiceBlankIndex.value
            : this.practiceBlankIndex,
      );
  GrammarPointsTableData copyWithCompanion(GrammarPointsTableCompanion data) {
    return GrammarPointsTableData(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      explanation:
          data.explanation.present ? data.explanation.value : this.explanation,
      exampleJp: data.exampleJp.present ? data.exampleJp.value : this.exampleJp,
      exampleVi: data.exampleVi.present ? data.exampleVi.value : this.exampleVi,
      commonMistake: data.commonMistake.present
          ? data.commonMistake.value
          : this.commonMistake,
      memoryTip: data.memoryTip.present ? data.memoryTip.value : this.memoryTip,
      comparisonNote: data.comparisonNote.present
          ? data.comparisonNote.value
          : this.comparisonNote,
      levelId: data.levelId.present ? data.levelId.value : this.levelId,
      practiceTokens: data.practiceTokens.present
          ? data.practiceTokens.value
          : this.practiceTokens,
      practiceBlankIndex: data.practiceBlankIndex.present
          ? data.practiceBlankIndex.value
          : this.practiceBlankIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GrammarPointsTableData(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('explanation: $explanation, ')
          ..write('exampleJp: $exampleJp, ')
          ..write('exampleVi: $exampleVi, ')
          ..write('commonMistake: $commonMistake, ')
          ..write('memoryTip: $memoryTip, ')
          ..write('comparisonNote: $comparisonNote, ')
          ..write('levelId: $levelId, ')
          ..write('practiceTokens: $practiceTokens, ')
          ..write('practiceBlankIndex: $practiceBlankIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      explanation,
      exampleJp,
      exampleVi,
      commonMistake,
      memoryTip,
      comparisonNote,
      levelId,
      practiceTokens,
      practiceBlankIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GrammarPointsTableData &&
          other.id == this.id &&
          other.title == this.title &&
          other.explanation == this.explanation &&
          other.exampleJp == this.exampleJp &&
          other.exampleVi == this.exampleVi &&
          other.commonMistake == this.commonMistake &&
          other.memoryTip == this.memoryTip &&
          other.comparisonNote == this.comparisonNote &&
          other.levelId == this.levelId &&
          other.practiceTokens == this.practiceTokens &&
          other.practiceBlankIndex == this.practiceBlankIndex);
}

class GrammarPointsTableCompanion
    extends UpdateCompanion<GrammarPointsTableData> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> explanation;
  final Value<String?> exampleJp;
  final Value<String?> exampleVi;
  final Value<String?> commonMistake;
  final Value<String?> memoryTip;
  final Value<String?> comparisonNote;
  final Value<String> levelId;
  final Value<String?> practiceTokens;
  final Value<int?> practiceBlankIndex;
  final Value<int> rowid;
  const GrammarPointsTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.explanation = const Value.absent(),
    this.exampleJp = const Value.absent(),
    this.exampleVi = const Value.absent(),
    this.commonMistake = const Value.absent(),
    this.memoryTip = const Value.absent(),
    this.comparisonNote = const Value.absent(),
    this.levelId = const Value.absent(),
    this.practiceTokens = const Value.absent(),
    this.practiceBlankIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GrammarPointsTableCompanion.insert({
    required String id,
    required String title,
    required String explanation,
    this.exampleJp = const Value.absent(),
    this.exampleVi = const Value.absent(),
    this.commonMistake = const Value.absent(),
    this.memoryTip = const Value.absent(),
    this.comparisonNote = const Value.absent(),
    required String levelId,
    this.practiceTokens = const Value.absent(),
    this.practiceBlankIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        explanation = Value(explanation),
        levelId = Value(levelId);
  static Insertable<GrammarPointsTableData> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? explanation,
    Expression<String>? exampleJp,
    Expression<String>? exampleVi,
    Expression<String>? commonMistake,
    Expression<String>? memoryTip,
    Expression<String>? comparisonNote,
    Expression<String>? levelId,
    Expression<String>? practiceTokens,
    Expression<int>? practiceBlankIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (explanation != null) 'explanation': explanation,
      if (exampleJp != null) 'example_jp': exampleJp,
      if (exampleVi != null) 'example_vi': exampleVi,
      if (commonMistake != null) 'common_mistake': commonMistake,
      if (memoryTip != null) 'memory_tip': memoryTip,
      if (comparisonNote != null) 'comparison_note': comparisonNote,
      if (levelId != null) 'level_id': levelId,
      if (practiceTokens != null) 'practice_tokens': practiceTokens,
      if (practiceBlankIndex != null)
        'practice_blank_index': practiceBlankIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GrammarPointsTableCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? explanation,
      Value<String?>? exampleJp,
      Value<String?>? exampleVi,
      Value<String?>? commonMistake,
      Value<String?>? memoryTip,
      Value<String?>? comparisonNote,
      Value<String>? levelId,
      Value<String?>? practiceTokens,
      Value<int?>? practiceBlankIndex,
      Value<int>? rowid}) {
    return GrammarPointsTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      explanation: explanation ?? this.explanation,
      exampleJp: exampleJp ?? this.exampleJp,
      exampleVi: exampleVi ?? this.exampleVi,
      commonMistake: commonMistake ?? this.commonMistake,
      memoryTip: memoryTip ?? this.memoryTip,
      comparisonNote: comparisonNote ?? this.comparisonNote,
      levelId: levelId ?? this.levelId,
      practiceTokens: practiceTokens ?? this.practiceTokens,
      practiceBlankIndex: practiceBlankIndex ?? this.practiceBlankIndex,
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
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
    }
    if (exampleJp.present) {
      map['example_jp'] = Variable<String>(exampleJp.value);
    }
    if (exampleVi.present) {
      map['example_vi'] = Variable<String>(exampleVi.value);
    }
    if (commonMistake.present) {
      map['common_mistake'] = Variable<String>(commonMistake.value);
    }
    if (memoryTip.present) {
      map['memory_tip'] = Variable<String>(memoryTip.value);
    }
    if (comparisonNote.present) {
      map['comparison_note'] = Variable<String>(comparisonNote.value);
    }
    if (levelId.present) {
      map['level_id'] = Variable<String>(levelId.value);
    }
    if (practiceTokens.present) {
      map['practice_tokens'] = Variable<String>(practiceTokens.value);
    }
    if (practiceBlankIndex.present) {
      map['practice_blank_index'] = Variable<int>(practiceBlankIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GrammarPointsTableCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('explanation: $explanation, ')
          ..write('exampleJp: $exampleJp, ')
          ..write('exampleVi: $exampleVi, ')
          ..write('commonMistake: $commonMistake, ')
          ..write('memoryTip: $memoryTip, ')
          ..write('comparisonNote: $comparisonNote, ')
          ..write('levelId: $levelId, ')
          ..write('practiceTokens: $practiceTokens, ')
          ..write('practiceBlankIndex: $practiceBlankIndex, ')
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
  late final $VocabularyMeaningsTableTable vocabularyMeaningsTable =
      $VocabularyMeaningsTableTable(this);
  late final $KanjiTableTable kanjiTable = $KanjiTableTable(this);
  late final $GrammarPointsTableTable grammarPointsTable =
      $GrammarPointsTableTable(this);
  late final $LessonsTableTable lessonsTable = $LessonsTableTable(this);
  late final $LessonItemsTableTable lessonItemsTable =
      $LessonItemsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        vocabularyTable,
        vocabularyMeaningsTable,
        kanjiTable,
        grammarPointsTable,
        lessonsTable,
        lessonItemsTable
      ];
}

typedef $$VocabularyTableTableCreateCompanionBuilder = VocabularyTableCompanion
    Function({
  required String id,
  required String word,
  required String reading,
  Value<String?> partOfSpeech,
  Value<String?> audioUrl,
  required String levelId,
  Value<String?> category,
  Value<int> rowid,
});
typedef $$VocabularyTableTableUpdateCompanionBuilder = VocabularyTableCompanion
    Function({
  Value<String> id,
  Value<String> word,
  Value<String> reading,
  Value<String?> partOfSpeech,
  Value<String?> audioUrl,
  Value<String> levelId,
  Value<String?> category,
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

  ColumnFilters<String> get partOfSpeech => $composableBuilder(
      column: $table.partOfSpeech, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get audioUrl => $composableBuilder(
      column: $table.audioUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get levelId => $composableBuilder(
      column: $table.levelId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));
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

  ColumnOrderings<String> get partOfSpeech => $composableBuilder(
      column: $table.partOfSpeech,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get audioUrl => $composableBuilder(
      column: $table.audioUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get levelId => $composableBuilder(
      column: $table.levelId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<String> get partOfSpeech => $composableBuilder(
      column: $table.partOfSpeech, builder: (column) => column);

  GeneratedColumn<String> get audioUrl =>
      $composableBuilder(column: $table.audioUrl, builder: (column) => column);

  GeneratedColumn<String> get levelId =>
      $composableBuilder(column: $table.levelId, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);
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
            Value<String?> partOfSpeech = const Value.absent(),
            Value<String?> audioUrl = const Value.absent(),
            Value<String> levelId = const Value.absent(),
            Value<String?> category = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VocabularyTableCompanion(
            id: id,
            word: word,
            reading: reading,
            partOfSpeech: partOfSpeech,
            audioUrl: audioUrl,
            levelId: levelId,
            category: category,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String word,
            required String reading,
            Value<String?> partOfSpeech = const Value.absent(),
            Value<String?> audioUrl = const Value.absent(),
            required String levelId,
            Value<String?> category = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VocabularyTableCompanion.insert(
            id: id,
            word: word,
            reading: reading,
            partOfSpeech: partOfSpeech,
            audioUrl: audioUrl,
            levelId: levelId,
            category: category,
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
typedef $$VocabularyMeaningsTableTableCreateCompanionBuilder
    = VocabularyMeaningsTableCompanion Function({
  required String id,
  required String vocabularyId,
  Value<int> orderIndex,
  required String meaningVi,
  Value<String?> exampleJp,
  Value<String?> exampleVi,
  Value<int> rowid,
});
typedef $$VocabularyMeaningsTableTableUpdateCompanionBuilder
    = VocabularyMeaningsTableCompanion Function({
  Value<String> id,
  Value<String> vocabularyId,
  Value<int> orderIndex,
  Value<String> meaningVi,
  Value<String?> exampleJp,
  Value<String?> exampleVi,
  Value<int> rowid,
});

class $$VocabularyMeaningsTableTableFilterComposer
    extends Composer<_$AppDatabase, $VocabularyMeaningsTableTable> {
  $$VocabularyMeaningsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get vocabularyId => $composableBuilder(
      column: $table.vocabularyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get meaningVi => $composableBuilder(
      column: $table.meaningVi, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exampleJp => $composableBuilder(
      column: $table.exampleJp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exampleVi => $composableBuilder(
      column: $table.exampleVi, builder: (column) => ColumnFilters(column));
}

class $$VocabularyMeaningsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $VocabularyMeaningsTableTable> {
  $$VocabularyMeaningsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get vocabularyId => $composableBuilder(
      column: $table.vocabularyId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meaningVi => $composableBuilder(
      column: $table.meaningVi, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exampleJp => $composableBuilder(
      column: $table.exampleJp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exampleVi => $composableBuilder(
      column: $table.exampleVi, builder: (column) => ColumnOrderings(column));
}

class $$VocabularyMeaningsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $VocabularyMeaningsTableTable> {
  $$VocabularyMeaningsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get vocabularyId => $composableBuilder(
      column: $table.vocabularyId, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => column);

  GeneratedColumn<String> get meaningVi =>
      $composableBuilder(column: $table.meaningVi, builder: (column) => column);

  GeneratedColumn<String> get exampleJp =>
      $composableBuilder(column: $table.exampleJp, builder: (column) => column);

  GeneratedColumn<String> get exampleVi =>
      $composableBuilder(column: $table.exampleVi, builder: (column) => column);
}

class $$VocabularyMeaningsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VocabularyMeaningsTableTable,
    VocabularyMeaningsTableData,
    $$VocabularyMeaningsTableTableFilterComposer,
    $$VocabularyMeaningsTableTableOrderingComposer,
    $$VocabularyMeaningsTableTableAnnotationComposer,
    $$VocabularyMeaningsTableTableCreateCompanionBuilder,
    $$VocabularyMeaningsTableTableUpdateCompanionBuilder,
    (
      VocabularyMeaningsTableData,
      BaseReferences<_$AppDatabase, $VocabularyMeaningsTableTable,
          VocabularyMeaningsTableData>
    ),
    VocabularyMeaningsTableData,
    PrefetchHooks Function()> {
  $$VocabularyMeaningsTableTableTableManager(
      _$AppDatabase db, $VocabularyMeaningsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VocabularyMeaningsTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$VocabularyMeaningsTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VocabularyMeaningsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> vocabularyId = const Value.absent(),
            Value<int> orderIndex = const Value.absent(),
            Value<String> meaningVi = const Value.absent(),
            Value<String?> exampleJp = const Value.absent(),
            Value<String?> exampleVi = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VocabularyMeaningsTableCompanion(
            id: id,
            vocabularyId: vocabularyId,
            orderIndex: orderIndex,
            meaningVi: meaningVi,
            exampleJp: exampleJp,
            exampleVi: exampleVi,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String vocabularyId,
            Value<int> orderIndex = const Value.absent(),
            required String meaningVi,
            Value<String?> exampleJp = const Value.absent(),
            Value<String?> exampleVi = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VocabularyMeaningsTableCompanion.insert(
            id: id,
            vocabularyId: vocabularyId,
            orderIndex: orderIndex,
            meaningVi: meaningVi,
            exampleJp: exampleJp,
            exampleVi: exampleVi,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VocabularyMeaningsTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $VocabularyMeaningsTableTable,
        VocabularyMeaningsTableData,
        $$VocabularyMeaningsTableTableFilterComposer,
        $$VocabularyMeaningsTableTableOrderingComposer,
        $$VocabularyMeaningsTableTableAnnotationComposer,
        $$VocabularyMeaningsTableTableCreateCompanionBuilder,
        $$VocabularyMeaningsTableTableUpdateCompanionBuilder,
        (
          VocabularyMeaningsTableData,
          BaseReferences<_$AppDatabase, $VocabularyMeaningsTableTable,
              VocabularyMeaningsTableData>
        ),
        VocabularyMeaningsTableData,
        PrefetchHooks Function()>;
typedef $$KanjiTableTableCreateCompanionBuilder = KanjiTableCompanion Function({
  required String id,
  required String character,
  Value<String?> onyomi,
  Value<String?> kunyomi,
  Value<String?> meaningVi,
  Value<int?> strokeCount,
  Value<String?> exampleJp,
  Value<String?> exampleVi,
  Value<String?> hanViet,
  Value<String?> mnemonic,
  Value<String?> strokeData,
  required String levelId,
  Value<String?> components,
  Value<int> rowid,
});
typedef $$KanjiTableTableUpdateCompanionBuilder = KanjiTableCompanion Function({
  Value<String> id,
  Value<String> character,
  Value<String?> onyomi,
  Value<String?> kunyomi,
  Value<String?> meaningVi,
  Value<int?> strokeCount,
  Value<String?> exampleJp,
  Value<String?> exampleVi,
  Value<String?> hanViet,
  Value<String?> mnemonic,
  Value<String?> strokeData,
  Value<String> levelId,
  Value<String?> components,
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

  ColumnFilters<String> get hanViet => $composableBuilder(
      column: $table.hanViet, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mnemonic => $composableBuilder(
      column: $table.mnemonic, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get strokeData => $composableBuilder(
      column: $table.strokeData, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get levelId => $composableBuilder(
      column: $table.levelId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get components => $composableBuilder(
      column: $table.components, builder: (column) => ColumnFilters(column));
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

  ColumnOrderings<String> get hanViet => $composableBuilder(
      column: $table.hanViet, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mnemonic => $composableBuilder(
      column: $table.mnemonic, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get strokeData => $composableBuilder(
      column: $table.strokeData, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get levelId => $composableBuilder(
      column: $table.levelId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get components => $composableBuilder(
      column: $table.components, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<String> get hanViet =>
      $composableBuilder(column: $table.hanViet, builder: (column) => column);

  GeneratedColumn<String> get mnemonic =>
      $composableBuilder(column: $table.mnemonic, builder: (column) => column);

  GeneratedColumn<String> get strokeData => $composableBuilder(
      column: $table.strokeData, builder: (column) => column);

  GeneratedColumn<String> get levelId =>
      $composableBuilder(column: $table.levelId, builder: (column) => column);

  GeneratedColumn<String> get components => $composableBuilder(
      column: $table.components, builder: (column) => column);
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
            Value<String?> meaningVi = const Value.absent(),
            Value<int?> strokeCount = const Value.absent(),
            Value<String?> exampleJp = const Value.absent(),
            Value<String?> exampleVi = const Value.absent(),
            Value<String?> hanViet = const Value.absent(),
            Value<String?> mnemonic = const Value.absent(),
            Value<String?> strokeData = const Value.absent(),
            Value<String> levelId = const Value.absent(),
            Value<String?> components = const Value.absent(),
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
            hanViet: hanViet,
            mnemonic: mnemonic,
            strokeData: strokeData,
            levelId: levelId,
            components: components,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String character,
            Value<String?> onyomi = const Value.absent(),
            Value<String?> kunyomi = const Value.absent(),
            Value<String?> meaningVi = const Value.absent(),
            Value<int?> strokeCount = const Value.absent(),
            Value<String?> exampleJp = const Value.absent(),
            Value<String?> exampleVi = const Value.absent(),
            Value<String?> hanViet = const Value.absent(),
            Value<String?> mnemonic = const Value.absent(),
            Value<String?> strokeData = const Value.absent(),
            required String levelId,
            Value<String?> components = const Value.absent(),
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
            hanViet: hanViet,
            mnemonic: mnemonic,
            strokeData: strokeData,
            levelId: levelId,
            components: components,
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
typedef $$GrammarPointsTableTableCreateCompanionBuilder
    = GrammarPointsTableCompanion Function({
  required String id,
  required String title,
  required String explanation,
  Value<String?> exampleJp,
  Value<String?> exampleVi,
  Value<String?> commonMistake,
  Value<String?> memoryTip,
  Value<String?> comparisonNote,
  required String levelId,
  Value<String?> practiceTokens,
  Value<int?> practiceBlankIndex,
  Value<int> rowid,
});
typedef $$GrammarPointsTableTableUpdateCompanionBuilder
    = GrammarPointsTableCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> explanation,
  Value<String?> exampleJp,
  Value<String?> exampleVi,
  Value<String?> commonMistake,
  Value<String?> memoryTip,
  Value<String?> comparisonNote,
  Value<String> levelId,
  Value<String?> practiceTokens,
  Value<int?> practiceBlankIndex,
  Value<int> rowid,
});

class $$GrammarPointsTableTableFilterComposer
    extends Composer<_$AppDatabase, $GrammarPointsTableTable> {
  $$GrammarPointsTableTableFilterComposer({
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

  ColumnFilters<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exampleJp => $composableBuilder(
      column: $table.exampleJp, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exampleVi => $composableBuilder(
      column: $table.exampleVi, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get commonMistake => $composableBuilder(
      column: $table.commonMistake, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memoryTip => $composableBuilder(
      column: $table.memoryTip, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get comparisonNote => $composableBuilder(
      column: $table.comparisonNote,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get levelId => $composableBuilder(
      column: $table.levelId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get practiceTokens => $composableBuilder(
      column: $table.practiceTokens,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get practiceBlankIndex => $composableBuilder(
      column: $table.practiceBlankIndex,
      builder: (column) => ColumnFilters(column));
}

class $$GrammarPointsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GrammarPointsTableTable> {
  $$GrammarPointsTableTableOrderingComposer({
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

  ColumnOrderings<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exampleJp => $composableBuilder(
      column: $table.exampleJp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exampleVi => $composableBuilder(
      column: $table.exampleVi, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get commonMistake => $composableBuilder(
      column: $table.commonMistake,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memoryTip => $composableBuilder(
      column: $table.memoryTip, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get comparisonNote => $composableBuilder(
      column: $table.comparisonNote,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get levelId => $composableBuilder(
      column: $table.levelId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get practiceTokens => $composableBuilder(
      column: $table.practiceTokens,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get practiceBlankIndex => $composableBuilder(
      column: $table.practiceBlankIndex,
      builder: (column) => ColumnOrderings(column));
}

class $$GrammarPointsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GrammarPointsTableTable> {
  $$GrammarPointsTableTableAnnotationComposer({
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

  GeneratedColumn<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => column);

  GeneratedColumn<String> get exampleJp =>
      $composableBuilder(column: $table.exampleJp, builder: (column) => column);

  GeneratedColumn<String> get exampleVi =>
      $composableBuilder(column: $table.exampleVi, builder: (column) => column);

  GeneratedColumn<String> get commonMistake => $composableBuilder(
      column: $table.commonMistake, builder: (column) => column);

  GeneratedColumn<String> get memoryTip =>
      $composableBuilder(column: $table.memoryTip, builder: (column) => column);

  GeneratedColumn<String> get comparisonNote => $composableBuilder(
      column: $table.comparisonNote, builder: (column) => column);

  GeneratedColumn<String> get levelId =>
      $composableBuilder(column: $table.levelId, builder: (column) => column);

  GeneratedColumn<String> get practiceTokens => $composableBuilder(
      column: $table.practiceTokens, builder: (column) => column);

  GeneratedColumn<int> get practiceBlankIndex => $composableBuilder(
      column: $table.practiceBlankIndex, builder: (column) => column);
}

class $$GrammarPointsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GrammarPointsTableTable,
    GrammarPointsTableData,
    $$GrammarPointsTableTableFilterComposer,
    $$GrammarPointsTableTableOrderingComposer,
    $$GrammarPointsTableTableAnnotationComposer,
    $$GrammarPointsTableTableCreateCompanionBuilder,
    $$GrammarPointsTableTableUpdateCompanionBuilder,
    (
      GrammarPointsTableData,
      BaseReferences<_$AppDatabase, $GrammarPointsTableTable,
          GrammarPointsTableData>
    ),
    GrammarPointsTableData,
    PrefetchHooks Function()> {
  $$GrammarPointsTableTableTableManager(
      _$AppDatabase db, $GrammarPointsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GrammarPointsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GrammarPointsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GrammarPointsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> explanation = const Value.absent(),
            Value<String?> exampleJp = const Value.absent(),
            Value<String?> exampleVi = const Value.absent(),
            Value<String?> commonMistake = const Value.absent(),
            Value<String?> memoryTip = const Value.absent(),
            Value<String?> comparisonNote = const Value.absent(),
            Value<String> levelId = const Value.absent(),
            Value<String?> practiceTokens = const Value.absent(),
            Value<int?> practiceBlankIndex = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GrammarPointsTableCompanion(
            id: id,
            title: title,
            explanation: explanation,
            exampleJp: exampleJp,
            exampleVi: exampleVi,
            commonMistake: commonMistake,
            memoryTip: memoryTip,
            comparisonNote: comparisonNote,
            levelId: levelId,
            practiceTokens: practiceTokens,
            practiceBlankIndex: practiceBlankIndex,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            required String explanation,
            Value<String?> exampleJp = const Value.absent(),
            Value<String?> exampleVi = const Value.absent(),
            Value<String?> commonMistake = const Value.absent(),
            Value<String?> memoryTip = const Value.absent(),
            Value<String?> comparisonNote = const Value.absent(),
            required String levelId,
            Value<String?> practiceTokens = const Value.absent(),
            Value<int?> practiceBlankIndex = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GrammarPointsTableCompanion.insert(
            id: id,
            title: title,
            explanation: explanation,
            exampleJp: exampleJp,
            exampleVi: exampleVi,
            commonMistake: commonMistake,
            memoryTip: memoryTip,
            comparisonNote: comparisonNote,
            levelId: levelId,
            practiceTokens: practiceTokens,
            practiceBlankIndex: practiceBlankIndex,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GrammarPointsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GrammarPointsTableTable,
    GrammarPointsTableData,
    $$GrammarPointsTableTableFilterComposer,
    $$GrammarPointsTableTableOrderingComposer,
    $$GrammarPointsTableTableAnnotationComposer,
    $$GrammarPointsTableTableCreateCompanionBuilder,
    $$GrammarPointsTableTableUpdateCompanionBuilder,
    (
      GrammarPointsTableData,
      BaseReferences<_$AppDatabase, $GrammarPointsTableTable,
          GrammarPointsTableData>
    ),
    GrammarPointsTableData,
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
  $$VocabularyMeaningsTableTableTableManager get vocabularyMeaningsTable =>
      $$VocabularyMeaningsTableTableTableManager(
          _db, _db.vocabularyMeaningsTable);
  $$KanjiTableTableTableManager get kanjiTable =>
      $$KanjiTableTableTableManager(_db, _db.kanjiTable);
  $$GrammarPointsTableTableTableManager get grammarPointsTable =>
      $$GrammarPointsTableTableTableManager(_db, _db.grammarPointsTable);
  $$LessonsTableTableTableManager get lessonsTable =>
      $$LessonsTableTableTableManager(_db, _db.lessonsTable);
  $$LessonItemsTableTableTableManager get lessonItemsTable =>
      $$LessonItemsTableTableTableManager(_db, _db.lessonItemsTable);
}
