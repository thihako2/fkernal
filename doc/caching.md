# Caching Strategy Deep Dive

FKernal implements a sophisticated caching layer designed to make applications feel instant while ensuring data consistency.

## Overview

1.  **Storage**: By default, FKernal uses **Hive** for high-performance binary storage.
2.  **Logic**: It implements the **Stale-While-Revalidate** pattern where applicable.
3.  **Control**: Caching is controlled per-endpoint via `CacheConfig`.

## Cache Configuration (`CacheConfig`)

Every `Endpoint` has a `cacheConfig` property.

```dart
Endpoint(
  id: 'getProfile',
  cacheConfig: CacheConfig(
    duration: Duration(minutes: 15), // TTL
    strategy: CacheStrategy.staleWhileRevalidate,
  ),
  ...
)
```

### Cache Strategies

| Strategy | Description |
|:---|:---|
| `CacheStrategy.performance` (Default) | Returns cached data immediately if valid. If expired, fetches network. |
| `CacheStrategy.staleWhileRevalidate` | Returns cached data immediately (even if expired) then fetches network in background to update. Only fetches if expired. |
| `CacheStrategy.freshness` | Always fetches from network. Updates cache on success. |

### Presets

| Preset | Duration | Use Case |
|:---|:---|:---|
| `CacheConfig.none` | 0 | Real-time data, search results |
| `CacheConfig.short` | 1 min | Stock tickers, live feeds |
| `CacheConfig.medium` | 5 min | User feeds, comments |
| `CacheConfig.long` | 1 hour | User profiles, product details |
| `CacheConfig.persistent` | 24 hours | Config, categories, static content |

## Cache Invalidation

Keeping cache consistent is crucial. FKernal provides robust invalidation mechanisms.

### 1. Automatic Invalidation (Recommended)

Define relationships between endpoints. When a mutation (POST/PUT/DELETE) succeeds, it automatically clears related read (GET) caches.

```dart
Endpoint(
  id: 'createPost',
  method: HttpMethod.post,
  invalidates: ['getFeed', 'getUserPosts'], // Clears these keys
)
```

### 2. Manual Invalidation

You can manually invalidate cache using `StorageManager`.

```dart
// Invalidate a specific resource
context.storageManager.invalidate('getFeed');

// Invalidate with specific arguments (params)
// Note: This is harder as cache keys depend on params
```

### 3. Wildcard Invalidation

For cleaning up groups of resources:

```dart
// Clears anything starting with 'user_'
context.storageManager.invalidatePattern('user_*'); 
```

## Storage Providers

FKernal uses two storage interfaces:

1.  **`IStorageProvider`**: For standard cache (Hive default).
2.  **`ISecureStorageProvider`**: For sensitive data like tokens (FlutterSecureStorage recommended).

You can override these in `FKernalConfig` to use SharedPreferences, SQLite, or any other storage engine.
