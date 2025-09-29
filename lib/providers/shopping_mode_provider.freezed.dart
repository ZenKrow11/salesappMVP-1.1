// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shopping_mode_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ShoppingModeState {
  Map<String, int> get productQuantities => throw _privateConstructorUsedError;
  Set<String> get checkedProductIds => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ShoppingModeStateCopyWith<ShoppingModeState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShoppingModeStateCopyWith<$Res> {
  factory $ShoppingModeStateCopyWith(
          ShoppingModeState value, $Res Function(ShoppingModeState) then) =
      _$ShoppingModeStateCopyWithImpl<$Res, ShoppingModeState>;
  @useResult
  $Res call(
      {Map<String, int> productQuantities, Set<String> checkedProductIds});
}

/// @nodoc
class _$ShoppingModeStateCopyWithImpl<$Res, $Val extends ShoppingModeState>
    implements $ShoppingModeStateCopyWith<$Res> {
  _$ShoppingModeStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productQuantities = null,
    Object? checkedProductIds = null,
  }) {
    return _then(_value.copyWith(
      productQuantities: null == productQuantities
          ? _value.productQuantities
          : productQuantities // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      checkedProductIds: null == checkedProductIds
          ? _value.checkedProductIds
          : checkedProductIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ShoppingModeStateImplCopyWith<$Res>
    implements $ShoppingModeStateCopyWith<$Res> {
  factory _$$ShoppingModeStateImplCopyWith(_$ShoppingModeStateImpl value,
          $Res Function(_$ShoppingModeStateImpl) then) =
      __$$ShoppingModeStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Map<String, int> productQuantities, Set<String> checkedProductIds});
}

/// @nodoc
class __$$ShoppingModeStateImplCopyWithImpl<$Res>
    extends _$ShoppingModeStateCopyWithImpl<$Res, _$ShoppingModeStateImpl>
    implements _$$ShoppingModeStateImplCopyWith<$Res> {
  __$$ShoppingModeStateImplCopyWithImpl(_$ShoppingModeStateImpl _value,
      $Res Function(_$ShoppingModeStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productQuantities = null,
    Object? checkedProductIds = null,
  }) {
    return _then(_$ShoppingModeStateImpl(
      productQuantities: null == productQuantities
          ? _value._productQuantities
          : productQuantities // ignore: cast_nullable_to_non_nullable
              as Map<String, int>,
      checkedProductIds: null == checkedProductIds
          ? _value._checkedProductIds
          : checkedProductIds // ignore: cast_nullable_to_non_nullable
              as Set<String>,
    ));
  }
}

/// @nodoc

class _$ShoppingModeStateImpl implements _ShoppingModeState {
  const _$ShoppingModeStateImpl(
      {final Map<String, int> productQuantities = const {},
      final Set<String> checkedProductIds = const {}})
      : _productQuantities = productQuantities,
        _checkedProductIds = checkedProductIds;

  final Map<String, int> _productQuantities;
  @override
  @JsonKey()
  Map<String, int> get productQuantities {
    if (_productQuantities is EqualUnmodifiableMapView)
      return _productQuantities;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_productQuantities);
  }

  final Set<String> _checkedProductIds;
  @override
  @JsonKey()
  Set<String> get checkedProductIds {
    if (_checkedProductIds is EqualUnmodifiableSetView)
      return _checkedProductIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_checkedProductIds);
  }

  @override
  String toString() {
    return 'ShoppingModeState(productQuantities: $productQuantities, checkedProductIds: $checkedProductIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShoppingModeStateImpl &&
            const DeepCollectionEquality()
                .equals(other._productQuantities, _productQuantities) &&
            const DeepCollectionEquality()
                .equals(other._checkedProductIds, _checkedProductIds));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_productQuantities),
      const DeepCollectionEquality().hash(_checkedProductIds));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ShoppingModeStateImplCopyWith<_$ShoppingModeStateImpl> get copyWith =>
      __$$ShoppingModeStateImplCopyWithImpl<_$ShoppingModeStateImpl>(
          this, _$identity);
}

abstract class _ShoppingModeState implements ShoppingModeState {
  const factory _ShoppingModeState(
      {final Map<String, int> productQuantities,
      final Set<String> checkedProductIds}) = _$ShoppingModeStateImpl;

  @override
  Map<String, int> get productQuantities;
  @override
  Set<String> get checkedProductIds;
  @override
  @JsonKey(ignore: true)
  _$$ShoppingModeStateImplCopyWith<_$ShoppingModeStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
