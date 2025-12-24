// FKernal Comprehensive Example
// This single file demonstrates ALL features of the FKernal framework.
//
// Features demonstrated:
// - FKernal initialization with full configuration
// - Networking with endpoints, caching, and invalidation
// - State management with FKernalBuilder
// - Local state with slices (Value, Toggle, Counter, List)
// - Theme switching
// - Error handling
// - Context extensions

import 'package:flutter/material.dart';
import 'package:fkernal/fkernal.dart';

// ============================================================================
// MODELS - Implement FKernalModel for type-safe API handling
// ============================================================================

class User implements FKernalModel {
  final int? id;
  final String name;
  final String username;
  final String email;
  final String? phone;
  final String? website;

  User(
      {this.id,
      required this.name,
      required this.username,
      required this.email,
      this.phone,
      this.website});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        name: json['name'] ?? '',
        username: json['username'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'],
        website: json['website'],
      );

  @override
  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'username': username,
        'email': email,
        if (phone != null) 'phone': phone,
        if (website != null) 'website': website,
      };

  @override
  void validate() {
    if (name.isEmpty) {
      throw const FKernalError(
          type: FKernalErrorType.validation, message: 'Name required');
    }
    if (!email.contains('@')) {
      throw const FKernalError(
          type: FKernalErrorType.validation, message: 'Valid email required');
    }
  }
}

class Post implements FKernalModel {
  final int? id;
  final int userId;
  final String title;
  final String body;

  Post(
      {this.id, required this.userId, required this.title, required this.body});

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'],
        userId: json['userId'] ?? 0,
        title: json['title'] ?? '',
        body: json['body'] ?? '',
      );

  @override
  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'userId': userId,
        'title': title,
        'body': body
      };

  @override
  void validate() {
    if (title.isEmpty) {
      throw const FKernalError(
          type: FKernalErrorType.validation, message: 'Title required');
    }
  }
}

class Todo implements FKernalModel {
  final int? id;
  final int userId;
  final String title;
  final bool completed;

  Todo(
      {this.id,
      required this.userId,
      required this.title,
      this.completed = false});

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        id: json['id'],
        userId: json['userId'] ?? 0,
        title: json['title'] ?? '',
        completed: json['completed'] ?? false,
      );

  @override
  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'userId': userId,
        'title': title,
        'completed': completed
      };

  @override
  void validate() {
    if (title.isEmpty) {
      throw const FKernalError(
          type: FKernalErrorType.validation, message: 'Title required');
    }
  }
}

// ============================================================================
// LOCAL STATE - Complex state for calculator demo
// ============================================================================

class CalculatorState {
  final String display;
  final String expression;
  final double? firstOperand;
  final String? operator;
  final bool shouldResetDisplay;
  final List<String> history;

  const CalculatorState({
    this.display = '0',
    this.expression = '',
    this.firstOperand,
    this.operator,
    this.shouldResetDisplay = false,
    this.history = const [],
  });

  CalculatorState copyWith({
    String? display,
    String? expression,
    double? firstOperand,
    String? operator,
    bool? shouldResetDisplay,
    bool clearFirstOperand = false,
    bool clearOperator = false,
    List<String>? history,
  }) {
    return CalculatorState(
      display: display ?? this.display,
      expression: expression ?? this.expression,
      firstOperand:
          clearFirstOperand ? null : (firstOperand ?? this.firstOperand),
      operator: clearOperator ? null : (operator ?? this.operator),
      shouldResetDisplay: shouldResetDisplay ?? this.shouldResetDisplay,
      history: history ?? this.history,
    );
  }
}

// ============================================================================
// ENDPOINTS - Declarative API configuration
// ============================================================================

final endpoints = <Endpoint>[
  // GET endpoints with caching
  Endpoint(
    id: 'getUsers',
    path: '/users',
    method: HttpMethod.get,
    cacheConfig: const CacheConfig(duration: Duration(minutes: 5)),
    parser: (json) => (json as List)
        .map((u) => User.fromJson(Map<String, dynamic>.from(u)))
        .toList(),
    description: 'Fetches all users',
  ),
  Endpoint(
    id: 'getUser',
    path: '/users/{id}',
    method: HttpMethod.get,
    cacheConfig: const CacheConfig(duration: Duration(minutes: 10)),
    parser: (json) => User.fromJson(Map<String, dynamic>.from(json)),
    description: 'Fetches user by ID',
  ),
  // POST with cache invalidation
  Endpoint(
    id: 'createUser',
    path: '/users',
    method: HttpMethod.post,
    invalidates: ['getUsers'],
    parser: (json) => User.fromJson(Map<String, dynamic>.from(json)),
    description: 'Creates a new user',
  ),
  // Posts
  Endpoint(
    id: 'getPosts',
    path: '/posts',
    method: HttpMethod.get,
    cacheConfig: CacheConfig.medium,
    parser: (json) => (json as List)
        .map((p) => Post.fromJson(Map<String, dynamic>.from(p)))
        .toList(),
  ),
  Endpoint(
    id: 'getUserPosts',
    path: '/users/{userId}/posts',
    method: HttpMethod.get,
    cacheConfig: CacheConfig.short,
    parser: (json) => (json as List)
        .map((p) => Post.fromJson(Map<String, dynamic>.from(p)))
        .toList(),
  ),
  // Todos
  Endpoint(
    id: 'getTodos',
    path: '/todos',
    method: HttpMethod.get,
    cacheConfig: CacheConfig.short,
    parser: (json) => (json as List)
        .map((t) => Todo.fromJson(Map<String, dynamic>.from(t)))
        .toList(),
  ),
];

// ============================================================================
// MAIN - App entry point with FKernal initialization
// ============================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FKernal with full configuration
  await FKernal.init(
    config: const FKernalConfig(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      environment: Environment.development,
      features: FeatureFlags(
        enableCache: true,
        enableOffline: false,
        enableAutoRetry: true,
        maxRetryAttempts: 3,
        enableLogging: true,
      ),
      defaultCacheConfig: CacheConfig(duration: Duration(minutes: 5)),
      connectTimeout: 30000,
      receiveTimeout: 30000,
      theme: ThemeConfig(
        primaryColor: Color(0xFF6366F1),
        secondaryColor: Color(0xFF8B5CF6),
        useMaterial3: true,
        defaultThemeMode: ThemeMode.system,
        borderRadius: 12.0,
        defaultPadding: 16.0,
      ),
      // UNIVERSAL STATE MANAGEMENT CONFIGURATION
      // FKernal uses Riverpod by default, but you can switch engines:
      // stateManagement: StateManagementType.riverpod, // default
      // stateManagement: StateManagementType.bloc,
      // stateManagement: StateManagementType.getx,
    ),
    endpoints: endpoints,
  );

  runApp(const FKernalDemoApp());
}

class FKernalDemoApp extends StatelessWidget {
  const FKernalDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FKernalApp(
      child: Builder(
        builder: (context) {
          final themeManager = context.themeManager;
          return ListenableBuilder(
            listenable: themeManager,
            builder: (context, _) => MaterialApp(
              title: 'FKernal Complete Demo',
              debugShowCheckedModeBanner: false,
              theme: themeManager.lightTheme,
              darkTheme: themeManager.darkTheme,
              themeMode: themeManager.themeMode,
              home: const HomeScreen(),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// HOME SCREEN - Navigation hub with theme toggle
// ============================================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FKernal Demo'),
        actions: [
          ListenableBuilder(
              listenable: context.themeManager,
              builder: (context, _) {
                return IconButton(
                  icon: Icon(context.themeManager.themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode),
                  onPressed: () => context.themeManager.toggleTheme(),
                  tooltip: 'Toggle Theme',
                );
              }),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primaryContainer,
                  colorScheme.secondaryContainer
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.bolt, size: 48, color: colorScheme.primary),
                const SizedBox(height: 16),
                Text('FKernal Complete Demo',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'This example demonstrates ALL features: networking, state management, local slices, theming, and error handling.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Feature demos
          Text('API Features',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _DemoCard(
            icon: Icons.people,
            title: 'Users',
            subtitle: 'FKernalBuilder, mutations, cache invalidation',
            color: colorScheme.primary,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const UsersScreen())),
          ),
          const SizedBox(height: 8),
          _DemoCard(
            icon: Icons.article,
            title: 'Posts',
            subtitle: 'Nested builders, path parameters',
            color: colorScheme.secondary,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PostsScreen())),
          ),
          const SizedBox(height: 8),
          _DemoCard(
            icon: Icons.check_circle,
            title: 'Todos',
            subtitle: 'Resource filtering and computed state',
            color: colorScheme.tertiary,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TodosScreen())),
          ),
          const SizedBox(height: 24),

          // Local State demos
          Text('Local State',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _DemoCard(
            icon: Icons.calculate,
            title: 'Calculator',
            subtitle: 'Complex local state with FKernalLocalBuilder',
            color: Colors.orange,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CalculatorScreen())),
          ),
          const SizedBox(height: 8),
          _DemoCard(
            icon: Icons.toggle_on,
            title: 'Slices Demo',
            subtitle: 'Value, Toggle, Counter, List slices',
            color: Colors.teal,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SlicesDemoScreen())),
          ),
        ],
      ),
    );
  }
}

class _DemoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DemoCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// ============================================================================
// USERS SCREEN - FKernalBuilder with mutations
// ============================================================================

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.refreshResource<List<User>>('getUsers'),
          ),
        ],
      ),
      body: FKernalBuilder<List<User>>(
        resource: 'getUsers',
        builder: (context, users) {
          if (users.isEmpty) {
            return const AutoEmptyWidget(
                title: 'No Users', icon: Icons.people_outline);
          }
          return RefreshIndicator(
            onRefresh: () => context.refreshResource<List<User>>('getUsers'),
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(child: Text(user.name[0])),
                    title: Text(user.name),
                    subtitle: Text(user.email),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showUserDetail(context, user),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createUser(context),
        icon: const Icon(Icons.add),
        label: const Text('Add User'),
      ),
    );
  }

  void _showUserDetail(BuildContext context, User user) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
            Text('@${user.username}',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Text('Email: ${user.email}'),
            if (user.phone != null) Text('Phone: ${user.phone}'),
            if (user.website != null) Text('Website: ${user.website}'),
            const SizedBox(height: 16),
            // Nested FKernalBuilder for user posts
            Text('Posts:', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(
              height: 120,
              child: FKernalBuilder<List<Post>>(
                resource: 'getUserPosts',
                pathParams: {'userId': user.id.toString()},
                builder: (context, posts) => ListView(
                  scrollDirection: Axis.horizontal,
                  children: posts
                      .take(5)
                      .map((p) => Card(
                          child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(p.title, maxLines: 2))))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createUser(BuildContext context) async {
    try {
      await context.performAction<User>('createUser',
          payload: User(
              name: 'New User', email: 'new@example.com', username: 'newuser'));
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('User created!')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

// ============================================================================
// POSTS SCREEN - Nested builders
// ============================================================================

class PostsScreen extends StatelessWidget {
  const PostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Posts')),
      body: FKernalBuilder<List<Post>>(
        resource: 'getPosts',
        builder: (context, posts) => RefreshIndicator(
          onRefresh: () => context.refreshResource<List<Post>>('getPosts'),
          child: ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(post.body,
                          maxLines: 3, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// TODOS SCREEN - Resource filtering
// ============================================================================

class TodosScreen extends StatelessWidget {
  const TodosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todos')),
      body: FKernalBuilder<List<Todo>>(
        resource: 'getTodos',
        builder: (context, todos) {
          final completed = todos.where((t) => t.completed).toList();
          final pending = todos.where((t) => !t.completed).toList();

          return RefreshIndicator(
            onRefresh: () => context.refreshResource<List<Todo>>('getTodos'),
            child: ListView(
              children: [
                _buildSection(context, 'Pending', pending, false),
                _buildSection(context, 'Completed', completed, true),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<Todo> todos, bool isCompleted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            Chip(label: Text('${todos.length}')),
          ]),
        ),
        ...todos.take(10).map((todo) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: Icon(
                    isCompleted ? Icons.check_circle : Icons.circle_outlined,
                    color: isCompleted ? Colors.green : null),
                title: Text(todo.title,
                    style: TextStyle(
                        decoration:
                            isCompleted ? TextDecoration.lineThrough : null)),
              ),
            )),
      ],
    );
  }
}

// ============================================================================
// CALCULATOR SCREEN - FKernalLocalBuilder with complex state
// ============================================================================

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FKernalLocalBuilder<CalculatorState>(
      slice: 'calculator',
      create: () => LocalSlice<CalculatorState>(
          initialState: const CalculatorState(), enableHistory: true),
      builder: (context, state, update) {
        void onDigit(String d) => update((s) => s.copyWith(
            display:
                s.shouldResetDisplay || s.display == '0' ? d : s.display + d,
            shouldResetDisplay: false));
        void onOperator(String op) => update((s) => s.copyWith(
            firstOperand: double.tryParse(s.display),
            operator: op,
            expression: '${s.display} $op',
            shouldResetDisplay: true));
        void onClear() => update((s) => s.copyWith(
            display: '0',
            expression: '',
            clearFirstOperand: true,
            clearOperator: true));
        void onEquals() {
          if (state.firstOperand == null || state.operator == null) return;
          final second = double.tryParse(state.display) ?? 0;
          double result = 0;
          switch (state.operator) {
            case '+':
              result = state.firstOperand! + second;
              break;
            case '-':
              result = state.firstOperand! - second;
              break;
            case '×':
              result = state.firstOperand! * second;
              break;
            case '÷':
              result = second != 0 ? state.firstOperand! / second : 0;
              break;
          }
          final r = result == result.toInt()
              ? result.toInt().toString()
              : result.toStringAsFixed(4);
          update((s) => s.copyWith(
              display: r,
              expression: '',
              clearFirstOperand: true,
              clearOperator: true,
              shouldResetDisplay: true));
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Calculator (Local State)')),
          body: Column(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  alignment: Alignment.bottomRight,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (state.expression.isNotEmpty)
                        Text(state.expression,
                            style: const TextStyle(
                                fontSize: 20, color: Colors.grey)),
                      Text(state.display,
                          style: const TextStyle(
                              fontSize: 48, fontWeight: FontWeight.w300)),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: GridView.count(
                  crossAxisCount: 4,
                  padding: const EdgeInsets.all(8),
                  children: [
                    _CalcBtn('C', onTap: onClear, isFunc: true),
                    _CalcBtn('±', onTap: () {}, isFunc: true),
                    _CalcBtn('%', onTap: () {}, isFunc: true),
                    _CalcBtn('÷', onTap: () => onOperator('÷'), isOp: true),
                    _CalcBtn('7', onTap: () => onDigit('7')),
                    _CalcBtn('8', onTap: () => onDigit('8')),
                    _CalcBtn('9', onTap: () => onDigit('9')),
                    _CalcBtn('×', onTap: () => onOperator('×'), isOp: true),
                    _CalcBtn('4', onTap: () => onDigit('4')),
                    _CalcBtn('5', onTap: () => onDigit('5')),
                    _CalcBtn('6', onTap: () => onDigit('6')),
                    _CalcBtn('-', onTap: () => onOperator('-'), isOp: true),
                    _CalcBtn('1', onTap: () => onDigit('1')),
                    _CalcBtn('2', onTap: () => onDigit('2')),
                    _CalcBtn('3', onTap: () => onDigit('3')),
                    _CalcBtn('+', onTap: () => onOperator('+'), isOp: true),
                    _CalcBtn('0', onTap: () => onDigit('0')),
                    _CalcBtn('.', onTap: () {}),
                    _CalcBtn('⌫', onTap: () {}),
                    _CalcBtn('=', onTap: onEquals, isEquals: true),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CalcBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isOp;
  final bool isFunc;
  final bool isEquals;

  const _CalcBtn(this.label,
      {required this.onTap,
      this.isOp = false,
      this.isFunc = false,
      this.isEquals = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Color bg = colorScheme.surface;
    Color fg = colorScheme.onSurface;
    if (isEquals) {
      bg = colorScheme.primary;
      fg = colorScheme.onPrimary;
    } else if (isOp) {
      bg = colorScheme.primaryContainer;
      fg = colorScheme.onPrimaryContainer;
    } else if (isFunc) {
      bg = colorScheme.surfaceContainerHighest;
    }

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
              child: Text(label, style: TextStyle(fontSize: 24, color: fg))),
        ),
      ),
    );
  }
}

// ============================================================================
// SLICES DEMO SCREEN - All slice types
// ============================================================================

class SlicesDemoScreen extends StatelessWidget {
  const SlicesDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Local State Slices')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Toggle Slice
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ToggleSlice',
                      style: Theme.of(context).textTheme.titleMedium),
                  FKernalToggleBuilder(
                    slice: 'darkMode',
                    create: () => ToggleSlice(false),
                    builder: (context, value, toggle) => SwitchListTile(
                      title: const Text('Dark Mode'),
                      value: value,
                      onChanged: (_) => toggle.toggle(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Counter Slice
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CounterSlice',
                      style: Theme.of(context).textTheme.titleMedium),
                  FKernalCounterBuilder(
                    slice: 'counter',
                    create: () => CounterSlice(initial: 0, min: 0, max: 100),
                    builder: (context, value, counter) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                            onPressed: counter.decrement,
                            icon: const Icon(Icons.remove)),
                        Text('$value',
                            style: Theme.of(context).textTheme.headlineMedium),
                        IconButton(
                            onPressed: counter.increment,
                            icon: const Icon(Icons.add)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Value Slice
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ValueSlice<String>',
                      style: Theme.of(context).textTheme.titleMedium),
                  FKernalValueBuilder<String>(
                    slice: 'message',
                    create: () => ValueSlice<String>('Hello FKernal!'),
                    builder: (context, value, setValue) => Column(
                      children: [
                        Text(value,
                            style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            ElevatedButton(
                                onPressed: () => setValue('Hello!'),
                                child: const Text('Hello')),
                            ElevatedButton(
                                onPressed: () => setValue('FKernal rocks!'),
                                child: const Text('Rocks')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // List Slice
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ListSlice<String>',
                      style: Theme.of(context).textTheme.titleMedium),
                  FKernalListBuilder<String>(
                    slice: 'items',
                    create: () => ListSlice<String>(['Item 1', 'Item 2']),
                    builder: (context, items, slice) => Column(
                      children: [
                        ...items.map((item) => ListTile(
                              title: Text(item),
                              trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => slice.remove(item)),
                            )),
                        ElevatedButton(
                          onPressed: () =>
                              slice.add('Item ${items.length + 1}'),
                          child: const Text('Add Item'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
