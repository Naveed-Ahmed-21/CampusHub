export interface VerifiedBookChapter {
  id: string;
  chapter_number: number;
  title: string;
  summary: string;
  estimated_minutes: number;
  content: string;
}

export interface VerifiedDocumentBook {
  id: string;
  title: string;
  tagline: string;
  category: string;
  author: string;
  canonical_url: string;
  source: string;
  estimated_minutes: number;
  cover_icon: string;
  accent_color: string;
  total_chapters: number;
  chapters: VerifiedBookChapter[];
}

export const VERIFIED_DOCUMENTATION_BOOKS: VerifiedDocumentBook[] = [
  {
    id: 'book-cpp',
    title: 'Modern C++ & STL Masterclass',
    tagline: 'Zero-overhead abstractions, pointer mechanics, RAII, and competitive DSA in C++20.',
    category: 'Systems & Performance',
    author: 'cppreference.com & LearnCpp',
    canonical_url: 'https://en.cppreference.com/w/cpp',
    source: 'ISO C++ Committee Standards',
    estimated_minutes: 65,
    cover_icon: 'code',
    accent_color: '#00599C',
    total_chapters: 5,
    chapters: [
      {
        id: 'cpp-ch1',
        chapter_number: 1,
        title: 'Modern C++ Standards & Memory Architecture',
        summary: 'Deep dive into stack vs heap memory, value categories (lvalue, prvalue, xvalue), and C++20 core.',
        estimated_minutes: 12,
        content: `### Chapter 1: Modern C++ Standards & Memory Architecture

#### 1. The C++ Compilation & Memory Model
C++ gives you direct deterministic control over computer hardware. Unlike runtime-managed environments (Java, Python, Dart), C++ compiles directly down to native CPU machine code instructions with **zero runtime overhead**.

\`\`\`
+-----------------------------------------------+
| Higher Memory (OS Kernel Space)               |
+-----------------------------------------------+
| Stack Segment (Local variables, frames)   |   | (Grows downwards)
|                                           v   |
|               (Free Memory Area)              |
|                                           ^   |
| Heap Segment (Dynamic memory via new/malloc)  | (Grows upwards)
+-----------------------------------------------+
| BSS Segment (Uninitialized global/static vars)|
+-----------------------------------------------+
| Data Segment (Initialized global/static vars) |
+-----------------------------------------------+
| Text Segment (Binary executable machine code) |
+-----------------------------------------------+
\`\`\`

#### 2. Stack vs Heap Memory
- **Stack Allocation**:
  - Blazing fast pointer bump allocation.
  - Automatically cleaned up when execution leaves the enclosing lexical scope \`{}\`.
  - Finite size (usually 1MB to 8MB). Exceeding this triggers a **Stack Overflow**.
- **Heap Allocation**:
  - Dynamically allocated at runtime using \`new\` or \`malloc\`.
  - Manually allocated; requires strict deallocation via \`delete\` or modern RAII wrappers to avoid **Memory Leaks**.

#### 3. Value Categories in Modern C++
Modern C++ classifies expressions into three primary value categories:
1. **lvalue (Locator Value)**: Has an identifiable identity and memory address. You can take its address with \`&\`. Example: Named variables \`int x = 10;\`.
2. **prvalue (Pure Rvalue)**: A temporary value without an identity used for computation. Example: \`42\`, \`x + 5\`.
3. **xvalue (eXpiring Value)**: An object with identity whose resources can be safely stolen or moved. Produced via \`std::move(x)\`.

\`\`\`cpp
int a = 10;          // 'a' is an lvalue
int& ref = a;        // lvalue reference
int&& rref = 20;     // rvalue reference bound to temporary prvalue
int&& moved = std::move(a); // casts 'a' to an xvalue
\`\`\``,
      },
      {
        id: 'cpp-ch2',
        chapter_number: 2,
        title: 'Pointers, References & The Golden Rule of RAII',
        summary: 'Pointers, reference semantics, and how Resource Acquisition Is Initialization eliminates leaks.',
        estimated_minutes: 14,
        content: `### Chapter 2: Pointers, References & The Golden Rule of RAII

#### 1. Pointers vs References
In C++, references and pointers are related but serve distinct engineering roles:

| Feature | Reference (\`T&\`) | Pointer (\`T*\`) |
| :--- | :--- | :--- |
| **Rebindability** | Cannot be reseated to another variable | Can change address anytime |
| **Nullability** | Cannot be null (guaranteed valid) | Can be \`nullptr\` |
| **Arithmetic** | No arithmetic permitted | Pointer arithmetic (\`ptr++\`, \`ptr + i\`) |
| **Indirection** | Automatic (acts as alias) | Requires explicit dereferencing (\`*ptr\`) |

\`\`\`cpp
int score = 95;
int* pScore = &score; // pScore points to memory address of score
*pScore = 100;        // Changes score to 100 via dereference

int& rScore = score;  // rScore is an alias for score
rScore = 98;          // Changes score to 98 directly
\`\`\`

#### 2. RAII (Resource Acquisition Is Initialization)
**RAII is the single most fundamental architectural paradigm in modern C++.**

> **Rule**: Tie the lifecycle of every system resource (heap memory, database connection, file descriptor, mutex lock) to the lifetime of a local stack object.

When the object is constructed, it acquires the resource. When the object exits its scope, its **destructor is deterministically called by the compiler**, releasing the resource—even if an exception is thrown!

\`\`\`cpp
class FileHandler {
private:
    FILE* fileHandle;
public:
    FileHandler(const char* path) {
        fileHandle = fopen(path, "r");
    }
    ~FileHandler() {
        if (fileHandle) {
            fclose(fileHandle); // Guaranteed release!
        }
    }
};
\`\`\``,
      },
      {
        id: 'cpp-ch3',
        chapter_number: 3,
        title: 'Modern Smart Pointers: Unique, Shared & Weak',
        summary: 'Stop writing manual delete! Master std::unique_ptr, std::shared_ptr, and std::weak_ptr.',
        estimated_minutes: 13,
        content: `### Chapter 3: Modern Smart Pointers (C++11 to C++20)

In modern C++, **raw \`new\` and \`delete\` are considered anti-patterns** in application code. The standard library provides smart pointer templates in \`<memory>\`.

#### 1. \`std::unique_ptr<T>\` (Zero-Overhead Exclusive Ownership)
- Represents sole, unshared ownership of a heap resource.
- **Cannot be copied**, only moved (\`std::move\`).
- Has **zero runtime overhead** compared to a raw pointer.

\`\`\`cpp
#include <memory>

class Student {
public:
    std::string name;
    Student(std::string n) : name(n) {}
};

void processStudent() {
    // Factory method std::make_unique guarantees exception safety
    auto s1 = std::make_unique<Student>("Naveed");
    
    // std::unique_ptr<Student> s2 = s1; // COMPILE ERROR: Cannot copy
    std::unique_ptr<Student> s2 = std::move(s1); // Transferred ownership!
    // s1 is now nullptr; s2 owns the Student.
} // Destructor runs automatically here; Student is freed!
\`\`\`

#### 2. \`std::shared_ptr<T>\` (Reference-Counted Shared Ownership)
- Multiple \`shared_ptr\` instances can own the same underlying heap object.
- Manages an atomic reference counter in a separate heap control block.
- The object is deleted only when the last \`shared_ptr\` goes out of scope (count reaches 0).

#### 3. \`std::weak_ptr<T>\` (Breaking Circular References)
- Non-owning observer of a \`shared_ptr\`. Does not increment the reference count.
- Solves the classic **Circular Reference Leak** where Node A points to Node B, and Node B points to Node A, causing the reference count never to hit zero.`,
      },
      {
        id: 'cpp-ch4',
        chapter_number: 4,
        title: 'The Standard Template Library (STL) Deep Dive',
        summary: 'Internals of std::vector, std::unordered_map, std::priority_queue, and algorithm efficiency.',
        estimated_minutes: 14,
        content: `### Chapter 4: The Standard Template Library (STL) Deep Dive

The STL is divided into four components: **Containers**, **Iterators**, **Algorithms**, and **Functors/Lambdas**.

#### 1. Sequence Containers
- **\`std::vector<T>\`**: Contiguous dynamic array.
  - Amortized \`O(1)\` push_back.
  - When capacity is exceeded, it allocates a new buffer of double size and moves existing elements.
  - Use \`vec.reserve(N)\` upfront when size is predictable to eliminate reallocation overhead.
- **\`std::deque<T>\`**: Double-ended queue implemented as fixed-size chunk arrays. \`O(1)\` insertion at both ends without full reallocation.

#### 2. Associative vs Unordered Containers
| Container | Underlying Data Structure | Search / Insert Complexity | Ordering |
| :--- | :--- | :--- | :--- |
| **\`std::map\`** | Self-balancing Red-Black Tree | \`O(log N)\` guaranteed | Sorted by key |
| **\`std::set\`** | Self-balancing Red-Black Tree | \`O(log N)\` guaranteed | Sorted values |
| **\`std::unordered_map\`** | Hash Table (Buckets + Chaining) | \`O(1)\` average, \`O(N)\` worst | Unordered |

#### 3. STL Algorithms
Always prefer standard algorithms over hand-written loops for readability and SIMD compiler optimizations:
\`\`\`cpp
#include <algorithm>
#include <vector>

std::vector<int> nums = {4, 1, 8, 3, 9, 2};
std::sort(nums.begin(), nums.end()); // O(N log N) Introsort

// Binary search via std::lower_bound in O(log N)
auto it = std::lower_bound(nums.begin(), nums.end(), 8);
bool exists = (it != nums.end() && *it == 8);
\`\`\``,
      },
      {
        id: 'cpp-ch5',
        chapter_number: 5,
        title: 'Competitive Programming & Placement OA Tactics',
        summary: 'Fast I/O, bit manipulation, custom comparators, and acing technical screening rounds.',
        estimated_minutes: 12,
        content: `### Chapter 5: Competitive Programming & Placement OA Tactics

#### 1. Fast I/O Optimization
By default, C++ \`cin\` and \`cout\` synchronize their buffers with standard C \`stdio\` (\`scanf\` and \`printf\`), which introduces significant latency on inputs with over 100,000 lines.

\`\`\`cpp
int main() {
    // Untie C++ streams from C stdio
    std::ios_base::sync_with_stdio(false);
    std::cin.tie(NULL);
    
    // Always prefer '\\n' over std::endl because endl forces a flush!
    // std::cout << val << '\\n';
    return 0;
}
\`\`\`

#### 2. Max Heap vs Min Heap with \`std::priority_queue\`
\`\`\`cpp
// Default: Max Heap (largest element on top)
std::priority_queue<int> maxHeap;

// Min Heap (smallest element on top - crucial for Dijkstra and Top K elements)
std::priority_queue<int, std::vector<int>, std::greater<int>> minHeap;
\`\`\`

#### 3. Common Online Assessment Traps
- **Integer Overflow**: Always check constraints. If numbers can reach \`10^9\` and you sum them, use \`long long\` to prevent 32-bit wrap-around!
- **Zero-Indexed Edge Cases**: Always verify array bounds (\`nums.empty()\`, single element inputs).
- **Custom Sort Lambda**:
\`\`\`cpp
std::sort(pairs.begin(), pairs.end(), [](const auto& a, const auto& b) {
    if (a.first != b.first) return a.first < b.first;
    return a.second > b.second;
});
\`\`\``,
      },
    ],
  },
  {
    id: 'book-python',
    title: 'Python 3 Internals & Production Architecture',
    tagline: 'CPython execution model, GIL mechanics, asyncio concurrency, and clean typing.',
    category: 'AI & Backend',
    author: 'Python Software Foundation & PEP 8',
    canonical_url: 'https://docs.python.org/3/',
    source: 'Official Python Language Documentation',
    estimated_minutes: 55,
    cover_icon: 'terminal',
    accent_color: '#3776AB',
    total_chapters: 4,
    chapters: [
      {
        id: 'py-ch1',
        chapter_number: 1,
        title: 'CPython Execution Model & Memory Management',
        summary: 'How source code translates to bytecode, frame objects, reference counting, and garbage collection.',
        estimated_minutes: 14,
        content: `### Chapter 1: CPython Execution Model & Memory Management

#### 1. How Python Runs Code
Python is an interpreted, bytecode-compiled language. When you execute \`python app.py\`:
1. **Parser**: Translates Python source syntax into an Abstract Syntax Tree (AST).
2. **Compiler**: Compiles the AST into Python **Bytecode** (\`.pyc\` files or in-memory code objects).
3. **PVM (Python Virtual Machine)**: An evaluation loop that executes the bytecode instructions on top of virtual CPU stack frames.

#### 2. Memory Management: Reference Counting
Every Python object in CPython is a C struct starting with \`PyObject\`, containing:
- \`ob_refcnt\`: The reference count of pointers referring to this object.
- \`ob_type\`: A pointer to the object's type descriptor.

Whenever an object is referenced, its count increases. When the reference goes out of scope or is deleted with \`del\`, the count decrements. When it reaches **zero**, CPython frees the memory immediately.

#### 3. The Generational Garbage Collector
Reference counting cannot detect **cyclic references** (e.g. Object A points to Object B, and Object B points to Object A).
To handle this, CPython runs a cyclic garbage collector organized into 3 generations (Gen 0, Gen 1, Gen 2). Newer objects are collected frequently in Gen 0; objects that survive multiple sweeps get promoted to Gen 1 and Gen 2.`,
      },
      {
        id: 'py-ch2',
        chapter_number: 2,
        title: 'The Global Interpreter Lock (GIL) & High-Performance Concurrency',
        summary: 'Understanding the GIL, I/O-bound threading, CPU-bound multiprocessing, and asyncio.',
        estimated_minutes: 15,
        content: `### Chapter 2: The Global Interpreter Lock (GIL) & Concurrency

#### 1. What is the GIL?
The **GIL** is a mutual exclusion lock used by CPython to prevent multiple native OS threads from executing Python bytecode at the exact same instant.

#### 2. Why Does CPython Have It?
- Protects CPython's reference-counting memory manager from multi-threaded race conditions without requiring thousands of fine-grained locks.
- Makes integration with native C extensions (like C standard libraries) straightforward.

#### 3. Concurrency Strategy Guide
- **I/O-Bound Tasks** (Fetching HTTP APIs, database queries, file reading):
  - **Use \`asyncio\` or \`threading\`**.
  - During socket or file operations, CPython automatically releases the GIL, allowing threads to run in parallel while waiting for network responses.
- **CPU-Bound Tasks** (Machine Learning, image resizing, numerical simulation):
  - **Use \`multiprocessing\`** or libraries like **NumPy** / **PyTorch**.
  - Spawns distinct OS processes with separate PVMs and individual address spaces, bypassing the GIL completely.`,
      },
      {
        id: 'py-ch3',
        chapter_number: 3,
        title: 'Advanced Iterators, Generators & Context Managers',
        summary: 'Lazy evaluation with yield, memory conservation, and the Python context manager protocol.',
        estimated_minutes: 13,
        content: `### Chapter 3: Advanced Iterators, Generators & Context Managers

#### 1. Generators & Lazy Evaluation
Loading large datasets into a list consumes massive RAM. A generator produces values **one at a time on demand** using the \`yield\` keyword, keeping memory usage constant at \`O(1)\`.

\`\`\`python
def read_large_logs(file_path):
    with open(file_path, 'r') as f:
        for line in f:
            if 'ERROR' in line:
                yield line.strip()

# Streams through 10GB file using only a few kilobytes of RAM
for error_line in read_large_logs('production.log'):
    send_alert(error_line)
\`\`\`

#### 2. The Context Manager Protocol (\`with\` statement)
Any class implementing \`__enter__\` and \`__exit__\` can be used with \`with\`. It guarantees cleanup even when exceptions occur.

\`\`\`python
class DatabaseTransaction:
    def __init__(self, db):
        self.db = db
    def __enter__(self):
        self.db.begin()
        return self.db
    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type:
            self.db.rollback()
        else:
            self.db.commit()
\`\`\``,
      },
      {
        id: 'py-ch4',
        chapter_number: 4,
        title: 'Modern Type Hints, Pydantic & FastAPI Microservices',
        summary: 'Static typing in dynamic Python, input validation schemas, and building production REST APIs.',
        estimated_minutes: 13,
        content: `### Chapter 4: Modern Type Hints, Pydantic & FastAPI Microservices

#### 1. Type Annotations & PEP 484
Python remains dynamically typed, but static analyzers (like \`mypy\` or IDEs) use type hints to catch bugs before code runs:

\`\`\`python
from typing import Optional, List
from pydantic import BaseModel, Field

class UserProfile(BaseModel):
    id: str
    username: str = Field(min_length=3, max_length=50)
    email: str
    skills: List[str] = []
    is_active: bool = True
\`\`\`

#### 2. FastAPI Architecture
FastAPI utilizes Python's \`async def\` and Pydantic schemas to provide asynchronous request handling with automatic OpenAPI Swagger documentation.`,
      },
    ],
  },
  {
    id: 'book-flutter',
    title: 'Flutter 3 & Dart Reactive Architecture',
    tagline: 'The Three Trees, sound null safety, Riverpod 2.0, and high-performance UI rendering.',
    category: 'Mobile Engineering',
    author: 'Flutter Dev Team & Riverpod',
    canonical_url: 'https://docs.flutter.dev',
    source: 'Official Flutter Documentation',
    estimated_minutes: 60,
    cover_icon: 'phone_android',
    accent_color: '#02569B',
    total_chapters: 4,
    chapters: [
      {
        id: 'fl-ch1',
        chapter_number: 1,
        title: 'Dart 3 Concurrency: Event Loop & Isolates',
        summary: 'Microtasks, event queues, futures, streams, and offloading heavy compute to background isolates.',
        estimated_minutes: 14,
        content: `### Chapter 1: Dart 3 Concurrency: Event Loop & Isolates

#### 1. Single-Threaded Event Loop
Dart code runs in an isolate that has an independent heap and a single thread of execution. The isolate executes code through an **Event Loop** with two queues:
1. **Microtask Queue**: Internal high-priority tasks. Executes completely before any event from the Event Queue is picked up.
2. **Event Queue**: External events like I/O, gesture taps, timers, and drawing frames.

\`\`\`
Event Loop Iteration:
[ Check Microtask Queue ] ---> (Tasks present?) ---> [ Execute Next Microtask ]
          |
         (Empty)
          |
[ Check Event Queue ] ---------> (Events present?) -> [ Execute Next Event ]
\`\`\`

#### 2. Background Isolates
Because Dart is single-threaded, running expensive operations (like parsing 50MB of JSON or image filtering) on the main thread will block UI frame rendering and cause noticeable **jank**.
Use \`Isolate.run()\` or Flutter's \`compute()\` helper to execute heavy work on another CPU thread.`,
      },
      {
        id: 'fl-ch2',
        chapter_number: 2,
        title: 'The Three Trees: Widget, Element & RenderObject',
        summary: 'How Flutter achieves 60/120 FPS by decoupling configuration from layout and painting.',
        estimated_minutes: 15,
        content: `### Chapter 2: The Three Trees Architecture

Flutter does NOT use platform native UI widgets (like Android XML views or iOS UIViews). Instead, Flutter controls every pixel directly on the canvas.

#### 1. The Three Trees
1. **Widget Tree**: Lightweight, immutable blueprints of UI configuration. Instantiated frequently at minimal cost.
2. **Element Tree**: The persistent glue between widgets and render objects. Holds the lifecycle and state of \`StatefulWidget\`.
3. **RenderObject Tree**: The heavy tree responsible for sizing, constraints, hit testing, and painting pixels to the Skia / Impeller canvas.

#### 2. Rebuild Optimization
When \`setState()\` or a Riverpod provider notifies a change, Flutter only updates the changed Widget and reconciles the Element. If the widget's \`runtimeType\` and \`key\` are unchanged, the underlying RenderObject is reused, preventing expensive layout recalculations.`,
      },
      {
        id: 'fl-ch3',
        chapter_number: 3,
        title: 'Enterprise State Management with Riverpod 2.0',
        summary: 'AsyncNotifier, ref.watch vs ref.read, autoDispose, and eliminating BuildContext coupling.',
        estimated_minutes: 16,
        content: `### Chapter 3: Enterprise State Management with Riverpod 2.0

Riverpod is a compile-time safe, reactive caching framework created to solve the fundamental shortcomings of inherited widgets and the older Provider package.

#### 1. Core Principles
- **No BuildContext Required**: Read and update state from repositories, background timers, or controllers without passing context.
- **Compile-Time Safe**: Missing providers trigger compile errors rather than runtime crashes.
- **Automatic Caching & Invalidation**: Use \`ref.invalidate(provider)\` to automatically refetch stale data.

#### 2. \`AsyncNotifier\` Pattern
\`\`\`dart
class CareerRoadmapNotifier extends AsyncNotifier<RoadmapModel> {
  @override
  Future<RoadmapModel> build() async {
    // Triggers automatically on provider initialization
    return ref.watch(careerRepositoryProvider).getActiveRoadmap();
  }

  Future<void> completeTask(String taskId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(careerRepositoryProvider).markTaskComplete(taskId);
    });
  }
}
\`\`\``,
      },
      {
        id: 'fl-ch4',
        chapter_number: 4,
        title: 'Offline Sync, Queued Interceptors & Secure Storage',
        summary: 'Dio interceptor token refresh locks, secure credential persistence, and cache-first offline strategies.',
        estimated_minutes: 15,
        content: `### Chapter 4: Offline Sync, Queued Interceptors & Secure Storage

#### 1. Token Refresh with QueuedInterceptor
When a mobile app fires multiple parallel requests and receives a \`401 Unauthorized\`, all outgoing calls must pause until the refresh token request succeeds:

\`\`\`dart
class AuthInterceptor extends QueuedInterceptor {
  final Dio dio;
  final SecureStorageService storage;
  AuthInterceptor(this.dio, this.storage);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken != null) {
        final newTokens = await refreshTokens(refreshToken);
        await storage.saveAccessToken(newTokens.accessToken);
        
        // Retry the original failed request with updated token
        err.requestOptions.headers['Authorization'] = 'Bearer \${newTokens.accessToken}';
        final cloned = await dio.fetch(err.requestOptions);
        return handler.resolve(cloned);
      }
    }
    super.onError(err, handler);
  }
}
\`\`\``,
      },
    ],
  },
  {
    id: 'book-backend',
    title: 'High-Throughput Backend & Distributed Systems',
    tagline: 'Libuv event loop, PostgreSQL B-Trees, Redis caching, and robust API security.',
    category: 'Cloud & Infrastructure',
    author: 'Node.js OpenJS & PostgreSQL Global Dev',
    canonical_url: 'https://nodejs.org/en/docs',
    source: 'Verified Systems Engineering Documentation',
    estimated_minutes: 60,
    cover_icon: 'dns',
    accent_color: '#336791',
    total_chapters: 4,
    chapters: [
      {
        id: 'be-ch1',
        chapter_number: 1,
        title: 'Node.js Libuv Internals & Non-Blocking I/O',
        summary: 'Event loop phases (timers, poll, check), the libuv threadpool, and microtask priority.',
        estimated_minutes: 15,
        content: `### Chapter 1: Node.js Libuv Internals & Non-Blocking I/O

Node.js executes JavaScript on the single-threaded V8 engine, backed by **libuv** for asynchronous cross-platform I/O.

#### 1. Event Loop Phases
Each iteration of the libuv event loop advances through specific phases:
1. **Timers Phase**: Executes callbacks scheduled by \`setTimeout()\` and \`setInterval()\`.
2. **Pending Callbacks Phase**: Executes I/O callbacks deferred from previous cycles.
3. **Idle / Prepare Phase**: Internal libuv housekeeping.
4. **Poll Phase**: Retrieves new I/O events (network connections, file descriptors) and blocks until events arrive or timers expire.
5. **Check Phase**: Executes callbacks registered with \`setImmediate()\`.
6. **Close Callbacks Phase**: Executes socket close handles (e.g. \`socket.on('close', ...)\`).

#### 2. \`process.nextTick()\` vs \`Promise.then()\`
Between every phase transition, Node drains the **Microtask Queue**. \`process.nextTick\` runs with higher priority than resolved Promises.`,
      },
      {
        id: 'be-ch2',
        chapter_number: 2,
        title: 'PostgreSQL Internals: B-Trees, VACUUM & MVCC',
        summary: 'Multi-Version Concurrency Control, Write-Ahead Logging (WAL), index structures, and query optimization.',
        estimated_minutes: 15,
        content: `### Chapter 2: PostgreSQL Internals: B-Trees, VACUUM & MVCC

#### 1. Multi-Version Concurrency Control (MVCC)
PostgreSQL handles concurrent transactions without locking readers against writers:
- When a row is updated, PostgreSQL does not overwrite the disk page in place.
- Instead, it marks the existing row version (\`xmin\`, \`xmax\`) as expired and writes a brand-new row tuple.
- Readers continue reading the consistent snapshot matching their transaction start time without blocking.

#### 2. B-Tree Indexes & Query Optimization
- A **B-Tree Index** maintains a balanced tree where leaf nodes contain pointers (Tuple IDs) to disk pages.
- Reduces full sequential table scans (\`O(N)\`) to binary traversals (\`O(log N)\`).
- Always run \`EXPLAIN ANALYZE\` to check whether the planner uses an **Index Scan**, **Bitmap Index Scan**, or a slow **Seq Scan**.`,
      },
      {
        id: 'be-ch3',
        chapter_number: 3,
        title: 'Distributed Caching with Redis & Rate Limiting',
        summary: 'Cache-Aside patterns, TTL strategies, Redis memory eviction, and Token Bucket rate limiting.',
        estimated_minutes: 15,
        content: `### Chapter 3: Distributed Caching with Redis & Rate Limiting

#### 1. Cache-Aside Pattern
1. App receives read request.
2. Checks Redis: \`GET user:101\`.
3. If **Cache Hit**: return immediately (sub-millisecond latency).
4. If **Cache Miss**: query PostgreSQL, populate Redis with TTL (\`SETEX user:101 3600 payload\`), and return response.

#### 2. Rate Limiting Algorithms
- **Sliding Window Counter**: Tracks request timestamps in a sorted set (\`ZADD\` and \`ZREMRANGEBYSCORE\`) to prevent boundary-burst attacks.`,
      },
      {
        id: 'be-ch4',
        chapter_number: 4,
        title: 'Authentication Security: JWTs & OWASP Hardening',
        summary: 'Refresh token rotation, replay attack prevention, CSRF mitigations, and SQL injection protection.',
        estimated_minutes: 15,
        content: `### Chapter 4: Authentication Security: JWTs & OWASP Hardening

#### 1. Refresh Token Family Rotation
- Store access tokens in memory / secure client storage with a short lifetime (15 minutes).
- Refresh tokens are single-use. When the client refreshes, the server issues a new Access Token AND a new Refresh Token while invalidating the previous one.
- If an attacker intercepts and attempts to reuse an old refresh token, the server detects token family compromise and revokes ALL active sessions for that user.`,
      },
    ],
  },
  {
    id: 'book-dsa',
    title: 'Placement DSA & Algorithmic Patterns',
    tagline: 'Two pointers, sliding window, graph traversals, and dynamic programming mastery.',
    category: 'Core Computer Science',
    author: 'NeetCode & OpenDSA',
    canonical_url: 'https://neetcode.io/practice',
    source: 'Verified Technical Interview Standards',
    estimated_minutes: 50,
    cover_icon: 'account_tree',
    accent_color: '#E11D48',
    total_chapters: 4,
    chapters: [
      {
        id: 'dsa-ch1',
        chapter_number: 1,
        title: 'Time & Space Complexity: Big-O Masterclass',
        summary: 'Asymptotic notation, amortized analysis, recursion tree depth, and auxiliary space.',
        estimated_minutes: 12,
        content: `### Chapter 1: Time & Space Complexity: Big-O Masterclass

#### 1. Understanding Big-O
Big-O describes the **upper bound** of an algorithm's execution time or memory footprint as input size \`N\` grows to infinity.

\`\`\`
O(1) < O(log N) < O(N) < O(N log N) < O(N^2) < O(2^N) < O(N!)
\`\`\`

#### 2. Analyzing Loops & Recursion
- Single pass through array: \`O(N)\`.
- Binary search dividing search space in half: \`O(log N)\`.
- Nested dependent loops: \`O(N^2)\`.
- Merge Sort divide-and-conquer: \`O(N log N)\`.
- Recursive tree depth dictates the auxiliary call stack space complexity.`,
      },
      {
        id: 'dsa-ch2',
        chapter_number: 2,
        title: 'Two Pointers & Sliding Window Patterns',
        summary: 'Solving subarray problems, palindromes, and target sums in linear O(N) time.',
        estimated_minutes: 13,
        content: `### Chapter 2: Two Pointers & Sliding Window Patterns

#### 1. Two Pointers (Opposite Direction)
Ideal for sorted arrays. Initialize one pointer at the start (\`left = 0\`) and one at the end (\`right = n - 1\`). Adjust pointers inward based on comparison with target.

#### 2. Sliding Window (Variable Size)
Maintain a valid window \`[left, right]\`. Expand \`right\` to add elements. When a condition is violated (e.g. duplicate character in string), shrink \`left\` until valid again. Runs in \`O(N)\` total since each element is processed at most twice.`,
      },
      {
        id: 'dsa-ch3',
        chapter_number: 3,
        title: 'Trees & Graph Traversals (BFS, DFS & Dijkstra)',
        summary: 'Binary search tree properties, topological sort, and shortest path algorithms.',
        estimated_minutes: 13,
        content: `### Chapter 3: Trees & Graph Traversals

#### 1. Tree Traversals
- **BFS (Breadth-First Search)**: Uses a **Queue**. Traverses level by level. Ideal for shortest distance in unweighted graphs.
- **DFS (Depth-First Search)**: Uses recursion or a **Stack**. Preorder (Root-Left-Right), Inorder (Left-Root-Right, sorted in BST), Postorder (Left-Right-Root).

#### 2. Dijkstra Algorithm
Calculates shortest path from a source node in a weighted graph with non-negative edge weights using a min-heap priority queue in \`O((V + E) log V)\`.`,
      },
      {
        id: 'dsa-ch4',
        chapter_number: 4,
        title: 'Dynamic Programming Patterns & Memoization',
        summary: 'Overlapping subproblems, optimal substructure, and converting recursion to 1D/2D tabulation.',
        estimated_minutes: 12,
        content: `### Chapter 4: Dynamic Programming Patterns

#### 1. When to Use DP
1. **Optimal Substructure**: The optimal solution to the problem can be constructed from optimal solutions to its subproblems.
2. **Overlapping Subproblems**: The same subproblems are solved repeatedly in a naive recursive solution.

#### 2. Top-Down vs Bottom-Up
- **Top-Down (Memoization)**: Write standard recursion, then cache results in an array/map.
- **Bottom-Up (Tabulation)**: Build a base table and iteratively compute higher values, often reducing space from \`O(N)\` to \`O(1)\`.`,
      },
    ],
  },
  {
    id: 'book-sysdesign',
    title: 'System Design Primer & Cloud Scalability',
    tagline: 'Horizontal scaling, load balancing, sharding, message queues, and CAP theorem.',
    category: 'System Architecture',
    author: 'System Design Primer (Donne Martin)',
    canonical_url: 'https://github.com/donnemartin/system-design-primer',
    source: 'High Scalability Architecture Library',
    estimated_minutes: 55,
    cover_icon: 'cloud_sync',
    accent_color: '#7C3AED',
    total_chapters: 4,
    chapters: [
      {
        id: 'sd-ch1',
        chapter_number: 1,
        title: 'Scalability Fundamentals: Vertical vs Horizontal',
        summary: 'Stateless application servers, load balancers, DNS routing, and CDN caching.',
        estimated_minutes: 13,
        content: `### Chapter 1: Scalability Fundamentals

#### 1. Vertical vs Horizontal Scaling
- **Vertical Scaling (Scale Up)**: Adding more CPU/RAM to a single server. Limited by hardware ceiling and single point of failure (SPOF).
- **Horizontal Scaling (Scale Out)**: Adding more commodity instances behind a load balancer. True elasticity.

#### 2. The Stateless Web Tier
Store session state in a distributed cache (like Redis) or JWT client tokens rather than web server local memory. Any web server instance can handle any incoming request.`,
      },
      {
        id: 'sd-ch2',
        chapter_number: 2,
        title: 'Database Partitioning, Sharding & CAP Theorem',
        summary: 'Horizontal database sharding, consistency models, and ACID vs BASE trade-offs.',
        estimated_minutes: 14,
        content: `### Chapter 2: Database Partitioning, Sharding & CAP Theorem

#### 1. CAP Theorem
In a distributed asynchronous network, you can guarantee at most TWO out of three properties:
- **Consistency (C)**: Every read receives the most recent write or an error.
- **Availability (A)**: Every non-failing node returns a response, but not guaranteed to be the latest write.
- **Partition Tolerance (P)**: The system functions despite arbitrary network drops between nodes.

#### 2. Sharding
Splitting a monolithic database across multiple physical machines using a **Shard Key** (e.g. \`hash(user_id) % num_shards\`).`,
      },
      {
        id: 'sd-ch3',
        chapter_number: 3,
        title: 'Asynchronous Processing & Message Brokers',
        summary: 'Decoupling services with Apache Kafka and RabbitMQ, event streaming, and dead-letter queues.',
        estimated_minutes: 14,
        content: `### Chapter 3: Asynchronous Processing & Message Brokers

#### 1. Why Message Queues?
- **Decoupling**: The producer does not need to know who the consumer is.
- **Traffic Smoothing / Backpressure**: Spikes in requests are stored in the queue and processed by workers at an optimal steady rate without crashing databases.`,
      },
      {
        id: 'sd-ch4',
        chapter_number: 4,
        title: 'Real-World Case Study: URL Shortener & Rate Limiter',
        summary: 'Complete architectural walkthrough: Base62 encoding, hash collisions, distributed ID generators, and Redis.',
        estimated_minutes: 14,
        content: `### Chapter 4: Real-World Case Study: URL Shortener & Rate Limiter

#### 1. High-Level Design
1. Client sends long URL.
2. App generates a 7-character **Base62** string from a distributed 64-bit ID generator (Snowflake).
3. Writes mapping to PostgreSQL and caches hot URLs in Redis with LRU eviction.
4. On redirect \`GET /{shortCode}\`, Redis returns the long URL for a \`301/302 Redirect\`.`,
      },
    ],
  },
];
