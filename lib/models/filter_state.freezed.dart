// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'filter_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$FilterState {
  String get searchQuery => throw _privateConstructorUsedError;
  List<String> get selectedStores => throw _privateConstructorUsedError;
  List<String> get selectedCategories => throw _privateConstructorUsedError;
  List<String> get selectedSubcategories => throw _privateConstructorUsedError;
  SortOption get sortOption => throw _privateConstructorUsedError;

  /// Create a copy of FilterState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FilterStateCopyWith<FilterState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FilterStateCopyWith<$Res> {
  factory $FilterStateCopyWith(
          FilterState value, $Res Function(FilterState) then) =
      _$FilterStateCopyWithImpl<$Res, FilterState>;
  @useResult
  $Res call(
      {String searchQuery,
      List<String> selectedStores,
      List<String> selectedCategories,
      List<String> selectedSubcategories,
      SortOption sortOption});
}

/// @nodoc
class _$FilterStateCopyWithImpl<$Res, $Val extends FilterState>
    implements $FilterStateCopyWith<$Res> {
  _$FilterStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FilterState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? searchQuery = null,
    Object? selectedStores = null,
    Object? selectedCategories = null,
    Object? selectedSubcategories = null,
    Object? sortOption = null,
  }) {
    return _then(_value.copyWith(
      searchQuery: null == searchQuery
          ? _value.searchQuery
          : searchQuery // ignore: cast_nullable_to_non_nullable
              as String,
      selectedStores: null == selectedStores
          ? _value.selectedStores
          : selectedStores // ignore: cast_nullable_to_non_nullable
              as List<String>,
      selectedCategories: null == selectedCategories
          ? _value.selectedCategories
          : selectedCategories // ignore: cast_nullable_to_non_nullable
              as List<String>,
      selectedSubcategories: null == selectedSubcategories
          ? _value.selectedSubcategories
          : selectedSubcategories // ignore: cast_nullable_to_non_nullable
              as List<String>,
      sortOption: null == sortOption
          ? _value.sortOption
          : sortOption // ignore: cast_nullable_to_non_nullable
              as SortOption,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FilterStateImplCopyWith<$Res>
    implements $FilterStateCopyWith<$Res> {
  factory _$$FilterStateImplCopyWith(
          _$FilterStateImpl value, $Res Function(_$FilterStateImpl) then) =
      __$$FilterStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String searchQuery,
      List<String> selectedStores,
      List<String> selectedCategories,
      List<String> selectedSubcategories,
      SortOption sortOption});
}

/// @nodoc
class __$$FilterStateImplCopyWithImpl<$Res>
    extends _$FilterStateCopyWithImpl<$Res, _$FilterStateImpl>
    implements _$$FilterStateImplCopyWith<$Res> {
  __$$FilterStateImplCopyWithImpl(
      _$FilterStateImpl _value, $Res Function(_$FilterStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of FilterState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? searchQuery = null,
    Object? selectedStores = null,
    Object? selectedCategories = null,
    Object? selectedSubcategories = null,
    Object? sortOption = null,
  }) {
    return _then(_$FilterStateImpl(
      searchQuery: null == searchQuery
          ? _value.searchQuery
          : searchQuery // ignore: cast_nullable_to_non_nullable
              as String,
      selectedStores: null == selectedStores
          ? _value._selectedStores
          : selectedStores // ignore: cast_nullable_to_non_nullable
              as List<String>,
      selectedCategories: null == selectedCategories
          ? _value._selectedCategories
          : selectedCategories // ignore: cast_nullable_to_non_nullable
              as List<String>,
      selectedSubcategories: null == selectedSubcategories
          ? _value._selectedSubcategories
          : selectedSubcategories // ignore: cast_nullable_to_non_nullable
              as List<String>,
      sortOption: null == sortOption
          ? _value.sortOption
          : sortOption // ignore: cast_nullable_to_non_nullable
              as SortOption,
    ));
  }
}

/// @nodoc

class _$FilterStateImpl implements _FilterState {
  const _$FilterStateImpl(
      {this.searchQuery = '',
      final List<String> selectedStores = const [],
      final List<String> selectedCategories = const [],
      final List<String> selectedSubcategories = const [],
      this.sortOption = SortOption.alphabetical})
      : _selectedStores = selectedStores,
        _selectedCategories = selectedCategories,
        _selectedSubcategories = selectedSubcategories;

  @override
  @JsonKey()
  final String searchQuery;
  final List<String> _selectedStores;
  @override
  @JsonKey()
  List<String> get selectedStores {
    if (_selectedStores is EqualUnmodifiableListView) return _selectedStores;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_selectedStores);
  }

  final List<String> _selectedCategories;
  @override
  @JsonKey()
  List<String> get selectedCategories {
    if (_selectedCategories is EqualUnmodifiableListView)
      return _selectedCategories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_selectedCategories);
  }

  final List<String> _selectedSubcategories;
  @override
  @JsonKey()
  List<String> get selectedSubcategories {
    if (_selectedSubcategories is EqualUnmodifiableListView)
      return _selectedSubcategories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_selectedSubcategories);
  }

  @override
  @JsonKey()
  final SortOption sortOption;

  @override
  String toString() {
    return 'FilterState(searchQuery: $searchQuery, selectedStores: $selectedStores, selectedCategories: $selectedCategories, selectedSubcategories: $selectedSubcategories, sortOption: $sortOption)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FilterStateImpl &&
            (identical(other.searchQuery, searchQuery) ||
                other.searchQuery == searchQuery) &&
            const DeepCollectionEquality()
                .equals(other._selectedStores, _selectedStores) &&
            const DeepCollectionEquality()
                .equals(other._selectedCategories, _selectedCategories) &&
            const DeepCollectionEquality()
                .equals(other._selectedSubcategories, _selectedSubcategories) &&
            (identical(other.sortOption, sortOption) ||
                other.sortOption == sortOption));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      searchQuery,
      const DeepCollectionEquality().hash(_selectedStores),
      const DeepCollectionEquality().hash(_selectedCategories),
      const DeepCollectionEquality().hash(_selectedSubcategories),
      sortOption);

  /// Create a copy of FilterState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FilterStateImplCopyWith<_$FilterStateImpl> get copyWith =>
      __$$FilterStateImplCopyWithImpl<_$FilterStateImpl>(this, _$identity);
}

abstract class _FilterState implements FilterState {
  const factory _FilterState(
      {final String searchQuery,
      final List<String> selectedStores,
      final List<String> selectedCategories,
      final List<String> selectedSubcategories,
      final SortOption sortOption}) = _$FilterStateImpl;

  @override
  String get searchQuery;
  @override
  List<String> get selectedStores;
  @override
  List<String> get selectedCategories;
  @override
  List<String> get selectedSubcategories;
  @override
  SortOption get sortOption;

  /// Create a copy of FilterState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FilterStateImplCopyWith<_$FilterStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
