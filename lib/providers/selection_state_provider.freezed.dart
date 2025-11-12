// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'selection_state_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SelectionState {
  bool get isSelectionModeActive => throw _privateConstructorUsedError;
  Set<String> get selectedItemIds => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $SelectionStateCopyWith<SelectionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SelectionStateCopyWith<$Res> {
  factory $SelectionStateCopyWith(
          SelectionState value, $Res Function(SelectionState) then) =
      _$SelectionStateCopyWithImpl<$Res, SelectionState>;
  @useResult
  $Res call({bool isSelectionModeActive, Set<String> selectedItemIds});
}

/// @nodoc
class _$SelectionStateCopyWithImpl<$Res, $Val extends SelectionState>
    implements $SelectionStateCopyWith<$Res> {
  _$SelectionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isSelectionModeActive = null,
    Object? selectedItemIds = null,
  }) {
    return _then(_value.copyWith(
      isSelectionModeActive: null == isSelectionModeActive
          ? _value.isSelectionModeActive
          : isSelectionModeActive // ignore: cast_nullable_to_non_nullable
              as bool,
      selectedItemIds: null == selectedItemIds
          ? _value.selectedItemIds
          : selectedItemIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SelectionStateImplCopyWith<$Res>
    implements $SelectionStateCopyWith<$Res> {
  factory _$$SelectionStateImplCopyWith(_$SelectionStateImpl value,
          $Res Function(_$SelectionStateImpl) then) =
      __$$SelectionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool isSelectionModeActive, Set<String> selectedItemIds});
}

/// @nodoc
class __$$SelectionStateImplCopyWithImpl<$Res>
    extends _$SelectionStateCopyWithImpl<$Res, _$SelectionStateImpl>
    implements _$$SelectionStateImplCopyWith<$Res> {
  __$$SelectionStateImplCopyWithImpl(
      _$SelectionStateImpl _value, $Res Function(_$SelectionStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isSelectionModeActive = null,
    Object? selectedItemIds = null,
  }) {
    return _then(_$SelectionStateImpl(
      isSelectionModeActive: null == isSelectionModeActive
          ? _value.isSelectionModeActive
          : isSelectionModeActive // ignore: cast_nullable_to_non_nullable
              as bool,
      selectedItemIds: null == selectedItemIds
          ? _value._selectedItemIds
          : selectedItemIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
    ));
  }
}

/// @nodoc

class _$SelectionStateImpl implements _SelectionState {
  const _$SelectionStateImpl(
      {this.isSelectionModeActive = false,
      final Set<String> selectedItemIds = const <String>{}})
      : _selectedItemIds = selectedItemIds;

  @override
  @JsonKey()
  final bool isSelectionModeActive;
  final Set<String> _selectedItemIds;
  @override
  @JsonKey()
  Set<String> get selectedItemIds {
    if (_selectedItemIds is EqualUnmodifiableSetView) return _selectedItemIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_selectedItemIds);
  }

  @override
  String toString() {
    return 'SelectionState(isSelectionModeActive: $isSelectionModeActive, selectedItemIds: $selectedItemIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SelectionStateImpl &&
            (identical(other.isSelectionModeActive, isSelectionModeActive) ||
                other.isSelectionModeActive == isSelectionModeActive) &&
            const DeepCollectionEquality()
                .equals(other._selectedItemIds, _selectedItemIds));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isSelectionModeActive,
      const DeepCollectionEquality().hash(_selectedItemIds));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SelectionStateImplCopyWith<_$SelectionStateImpl> get copyWith =>
      __$$SelectionStateImplCopyWithImpl<_$SelectionStateImpl>(
          this, _$identity);
}

abstract class _SelectionState implements SelectionState {
  const factory _SelectionState(
      {final bool isSelectionModeActive,
      final Set<String> selectedItemIds}) = _$SelectionStateImpl;

  @override
  bool get isSelectionModeActive;
  @override
  Set<String> get selectedItemIds;
  @override
  @JsonKey(ignore: true)
  _$$SelectionStateImplCopyWith<_$SelectionStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
