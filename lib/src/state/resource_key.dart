/// A type-safe key for accessing resource state.
///
/// ```dart
/// const usersKey = ResourceKey<List<User>>('getUsers');
///
/// final state = context.useResource(usersKey); // inferred as ResourceState<List<User>>
/// ```
class ResourceKey<T> {
  final String id;
  const ResourceKey(this.id);

  @override
  String toString() => 'ResourceKey<$T>($id)';

  @override
  bool operator ==(Object other) => other is ResourceKey && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
