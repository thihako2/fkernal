# Networking Deep Dive

FKernal's networking layer is designed to be **declarative, type-safe, and resilient**. It abstracts away the complexity of `Dio` or `http` clients behind simple configuration objects.

## Declarative Endpoints

Instead of writing repository methods for every API call, you define `Endpoint` objects.

```dart
final getUserEndpoint = Endpoint(
  id: 'getUser',
  path: '/users/{id}',
  method: HttpMethod.get,
  parser: (json) => User.fromJson(json),
);
```

### Properties

| Property | Description |
|----------|-------------|
| `id` | Unique identifier (required). Used to fetch resources. |
| `path` | URL path. Supports `{param}` syntax. |
| `method` | HTTP verb (`get`, `post`, `put`, `delete`, `patch`). |
| `headers` | Static headers for this specific endpoint. |
| `requiresAuth` | Whether to inject the auth token (default: `true`). |
| `parser` | Function to transform JSON `dynamic` to typed data `T`. |
| `cacheConfig` | Caching strategy for this endpoint. |
| `invalidates` | List of endpoint IDs to clear from cache on success. |

## Dynamic Parameters

### Path Parameters
Endpoints with `{param}` in their path require a `pathParams` map when fetching:

```dart
// Definition
path: '/users/{userId}/posts'

// Usage
context.fetchResource('getUserPosts', pathParams: {'userId': '123'});
```

### Query Parameters
Standard query parameters are passed via `params`:

```dart
context.fetchResource('getUsers', params: {'page': 1, 'limit': 10});
// Result: /users?page=1&limit=10
```

## Request Lifecycle

1.  **Deduplication**: If a GET request for the same ID+Params is already in flight, the new request waits for the existing one.
2.  **Cache Check**: If valid cache exists (and policy permits), return immediate data.
3.  **Authentication**: If `requiresAuth` is true, the configured `AuthConfig` injects the token.
4.  **Network Call**: The `INetworkClient` executes the request.
5.  **Parsing**: The `parser` function runs (on the main thread currently).
6.  **Storage**: Successful responses are written to cache.
7.  **Invalidation**: If the endpoint lists `invalidates` IDs, those entries are purged from cache.

## Customization

### Interceptors
You can add standard Dio interceptors without replacing the client:

```dart
FKernalConfig(
  interceptors: [
    LogInterceptor(),
    MyAuthInterceptor(),
  ],
)
```

### Replacing the Client
For GraphQL or non-REST apis, implement `INetworkClient`:

```dart
class GraphQLClientAdapter implements INetworkClient {
  final GraphQLClient _client;
  
  @override
  Future<T> request<T>(Endpoint endpoint, {Map<String, dynamic>? params, ...}) async {
    // translate Endpoint to Query/Mutation options
  }
}
```
