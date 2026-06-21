// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'folders_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$FoldersState {
  List<VideoFolder> get folders => throw _privateConstructorUsedError;
  bool get isScanning => throw _privateConstructorUsedError;
  int get scanProgress => throw _privateConstructorUsedError;
  bool get fromCache => throw _privateConstructorUsedError;
  List<String> get storageRoots => throw _privateConstructorUsedError;
  Set<String> get newPaths => throw _privateConstructorUsedError;

  /// Create a copy of FoldersState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FoldersStateCopyWith<FoldersState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FoldersStateCopyWith<$Res> {
  factory $FoldersStateCopyWith(
          FoldersState value, $Res Function(FoldersState) then) =
      _$FoldersStateCopyWithImpl<$Res, FoldersState>;
  @useResult
  $Res call(
      {List<VideoFolder> folders,
      bool isScanning,
      int scanProgress,
      bool fromCache,
      List<String> storageRoots,
      Set<String> newPaths});
}

/// @nodoc
class _$FoldersStateCopyWithImpl<$Res, $Val extends FoldersState>
    implements $FoldersStateCopyWith<$Res> {
  _$FoldersStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FoldersState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? folders = null,
    Object? isScanning = null,
    Object? scanProgress = null,
    Object? fromCache = null,
    Object? storageRoots = null,
    Object? newPaths = null,
  }) {
    return _then(_value.copyWith(
      folders: null == folders
          ? _value.folders
          : folders // ignore: cast_nullable_to_non_nullable
              as List<VideoFolder>,
      isScanning: null == isScanning
          ? _value.isScanning
          : isScanning // ignore: cast_nullable_to_non_nullable
              as bool,
      scanProgress: null == scanProgress
          ? _value.scanProgress
          : scanProgress // ignore: cast_nullable_to_non_nullable
              as int,
      fromCache: null == fromCache
          ? _value.fromCache
          : fromCache // ignore: cast_nullable_to_non_nullable
              as bool,
      storageRoots: null == storageRoots
          ? _value.storageRoots
          : storageRoots // ignore: cast_nullable_to_non_nullable
              as List<String>,
      newPaths: null == newPaths
          ? _value.newPaths
          : newPaths // ignore: cast_nullable_to_non_nullable
              as Set<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FoldersStateImplCopyWith<$Res>
    implements $FoldersStateCopyWith<$Res> {
  factory _$$FoldersStateImplCopyWith(
          _$FoldersStateImpl value, $Res Function(_$FoldersStateImpl) then) =
      __$$FoldersStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<VideoFolder> folders,
      bool isScanning,
      int scanProgress,
      bool fromCache,
      List<String> storageRoots,
      Set<String> newPaths});
}

/// @nodoc
class __$$FoldersStateImplCopyWithImpl<$Res>
    extends _$FoldersStateCopyWithImpl<$Res, _$FoldersStateImpl>
    implements _$$FoldersStateImplCopyWith<$Res> {
  __$$FoldersStateImplCopyWithImpl(
      _$FoldersStateImpl _value, $Res Function(_$FoldersStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of FoldersState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? folders = null,
    Object? isScanning = null,
    Object? scanProgress = null,
    Object? fromCache = null,
    Object? storageRoots = null,
    Object? newPaths = null,
  }) {
    return _then(_$FoldersStateImpl(
      folders: null == folders
          ? _value._folders
          : folders // ignore: cast_nullable_to_non_nullable
              as List<VideoFolder>,
      isScanning: null == isScanning
          ? _value.isScanning
          : isScanning // ignore: cast_nullable_to_non_nullable
              as bool,
      scanProgress: null == scanProgress
          ? _value.scanProgress
          : scanProgress // ignore: cast_nullable_to_non_nullable
              as int,
      fromCache: null == fromCache
          ? _value.fromCache
          : fromCache // ignore: cast_nullable_to_non_nullable
              as bool,
      storageRoots: null == storageRoots
          ? _value._storageRoots
          : storageRoots // ignore: cast_nullable_to_non_nullable
              as List<String>,
      newPaths: null == newPaths
          ? _value._newPaths
          : newPaths // ignore: cast_nullable_to_non_nullable
              as Set<String>,
    ));
  }
}

/// @nodoc

class _$FoldersStateImpl implements _FoldersState {
  const _$FoldersStateImpl(
      {final List<VideoFolder> folders = const [],
      this.isScanning = false,
      this.scanProgress = 0,
      this.fromCache = false,
      final List<String> storageRoots = const [],
      final Set<String> newPaths = const {}})
      : _folders = folders,
        _storageRoots = storageRoots,
        _newPaths = newPaths;

  final List<VideoFolder> _folders;
  @override
  @JsonKey()
  List<VideoFolder> get folders {
    if (_folders is EqualUnmodifiableListView) return _folders;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_folders);
  }

  @override
  @JsonKey()
  final bool isScanning;
  @override
  @JsonKey()
  final int scanProgress;
  @override
  @JsonKey()
  final bool fromCache;
  final List<String> _storageRoots;
  @override
  @JsonKey()
  List<String> get storageRoots {
    if (_storageRoots is EqualUnmodifiableListView) return _storageRoots;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_storageRoots);
  }

  final Set<String> _newPaths;
  @override
  @JsonKey()
  Set<String> get newPaths {
    if (_newPaths is EqualUnmodifiableSetView) return _newPaths;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_newPaths);
  }

  @override
  String toString() {
    return 'FoldersState(folders: $folders, isScanning: $isScanning, scanProgress: $scanProgress, fromCache: $fromCache, storageRoots: $storageRoots, newPaths: $newPaths)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FoldersStateImpl &&
            const DeepCollectionEquality().equals(other._folders, _folders) &&
            (identical(other.isScanning, isScanning) ||
                other.isScanning == isScanning) &&
            (identical(other.scanProgress, scanProgress) ||
                other.scanProgress == scanProgress) &&
            (identical(other.fromCache, fromCache) ||
                other.fromCache == fromCache) &&
            const DeepCollectionEquality()
                .equals(other._storageRoots, _storageRoots) &&
            const DeepCollectionEquality().equals(other._newPaths, _newPaths));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_folders),
      isScanning,
      scanProgress,
      fromCache,
      const DeepCollectionEquality().hash(_storageRoots),
      const DeepCollectionEquality().hash(_newPaths));

  /// Create a copy of FoldersState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FoldersStateImplCopyWith<_$FoldersStateImpl> get copyWith =>
      __$$FoldersStateImplCopyWithImpl<_$FoldersStateImpl>(this, _$identity);
}

abstract class _FoldersState implements FoldersState {
  const factory _FoldersState(
      {final List<VideoFolder> folders,
      final bool isScanning,
      final int scanProgress,
      final bool fromCache,
      final List<String> storageRoots,
      final Set<String> newPaths}) = _$FoldersStateImpl;

  @override
  List<VideoFolder> get folders;
  @override
  bool get isScanning;
  @override
  int get scanProgress;
  @override
  bool get fromCache;
  @override
  List<String> get storageRoots;
  @override
  Set<String> get newPaths;

  /// Create a copy of FoldersState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FoldersStateImplCopyWith<_$FoldersStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
