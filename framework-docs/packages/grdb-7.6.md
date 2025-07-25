# GRDB

Directory Structure:

└── ./
    └── GRDB
        └── Documentation.docc
            ├── Extension
            │   ├── Configuration.md
            │   ├── DatabasePool.md
            │   ├── DatabaseQueue.md
            │   ├── DatabaseRegionObservation.md
            │   ├── DatabaseValueConvertible.md
            │   ├── Statement.md
            │   ├── TransactionObserver.md
            │   └── ValueObservation.md
            ├── Concurrency.md
            ├── DatabaseConnections.md
            ├── DatabaseObservation.md
            ├── DatabaseSchema.md
            ├── DatabaseSchemaIntegrityChecks.md
            ├── DatabaseSchemaIntrospection.md
            ├── DatabaseSchemaModifications.md
            ├── DatabaseSchemaRecommendations.md
            ├── DatabaseSharing.md
            ├── FullTextSearch.md
            ├── GRDB.md
            ├── JSON.md
            ├── Migrations.md
            ├── QueryInterface.md
            ├── RecordRecommendedPractices.md
            ├── RecordTimestamps.md
            ├── SingleRowTables.md
            ├── SQLSupport.md
            ├── SwiftConcurrency.md
            └── Transactions.md



---
File: /GRDB/Documentation.docc/Extension/Configuration.md
---

# ``GRDB/Configuration``

The configuration of a database connection.

## Overview

You create a `Configuration` before opening a database connection:

```swift
var config = Configuration()
config.readonly = true
config.maximumReaderCount = 2  // (DatabasePool only) The default is 5

let dbQueue = try DatabaseQueue( // or DatabasePool
    path: "/path/to/database.sqlite",
    configuration: config)
```

See <doc:DatabaseConnections>.

## Frequent Use Cases

#### Tracing SQL Statements

You can setup a tracing function that prints out all executed SQL requests with ``prepareDatabase(_:)`` and ``Database/trace(options:_:)``:

```swift
var config = Configuration()
config.prepareDatabase { db in
    db.trace { print("SQL> \($0)") }
}

let dbQueue = try DatabaseQueue(
    path: "/path/to/database.sqlite",
    configuration: config)

// Prints "SQL> SELECT COUNT(*) FROM player"
let playerCount = dbQueue.read { db in
    try Player.fetchCount(db)
}
```

#### Public Statement Arguments

Debugging is easier when database errors and tracing functions expose the values sent to the database. Since those values may contain sensitive information, verbose logging is disabled by default. You turn it on with ``publicStatementArguments``:   

```swift
var config = Configuration()
#if DEBUG
// Protect sensitive information by enabling
// verbose debugging in DEBUG builds only.
config.publicStatementArguments = true
#endif

let dbQueue = try DatabaseQueue(
    path: "/path/to/database.sqlite",
    configuration: config)

do {
    try dbQueue.write { db in
        user.name = ...
        user.location = ...
        user.address = ...
        user.phoneNumber = ...
        try user.save(db)
    }
} catch {
    // Prints sensitive information in debug builds only
    print(error)
}
```

> Warning: It is your responsibility to prevent sensitive information from leaking in unexpected locations, so you should not set the `publicStatementArguments` flag in release builds (think about GDPR and other privacy-related rules).

## Topics

### Creating a Configuration

- ``init()``

### Configuring SQLite Connections

- ``acceptsDoubleQuotedStringLiterals``
- ``busyMode``
- ``foreignKeysEnabled``
- ``journalMode``
- ``readonly``
- ``JournalModeConfiguration``

### Configuring GRDB Connections

- ``allowsUnsafeTransactions``
- ``label``
- ``maximumReaderCount``
- ``observesSuspensionNotifications``
- ``persistentReadOnlyConnections``
- ``prepareDatabase(_:)``
- ``publicStatementArguments``
- ``transactionClock``
- ``TransactionClock``

### Configuring the Quality of Service

- ``qos``
- ``readQoS``
- ``writeQoS``
- ``targetQueue``
- ``writeTargetQueue``



---
File: /GRDB/Documentation.docc/Extension/DatabasePool.md
---

# ``GRDB/DatabasePool``

A database connection that allows concurrent accesses to an SQLite database.

## Usage

Open a `DatabasePool` with the path to a database file:

```swift
import GRDB

let dbPool = try DatabasePool(path: "/path/to/database.sqlite")
```

SQLite creates the database file if it does not already exist. The connection is closed when the database queue gets deallocated.

**A `DatabasePool` can be used from any thread.** The ``DatabaseWriter/write(_:)-76inz`` and ``DatabaseReader/read(_:)-3806d`` methods are synchronous, and block the current thread until your database statements are executed in a protected dispatch queue:

```swift
// Modify the database:
try dbPool.write { db in
    try Player(name: "Arthur").insert(db)
}

// Read values:
try dbPool.read { db in
    let players = try Player.fetchAll(db)
    let playerCount = try Player.fetchCount(db)
}
```

Database access methods can return values:

```swift
let playerCount = try dbPool.read { db in
    try Place.fetchCount(db)
}

let newPlayerCount = try dbPool.write { db -> Int in
    try Player(name: "Arthur").insert(db)
    return try Player.fetchCount(db)
}
```

The ``DatabaseWriter/write(_:)-76inz`` method wraps your database statements in a transaction that commits if and only if no error occurs. On the first unhandled error, all changes are reverted, the whole transaction is rollbacked, and the error is rethrown.

When you don't need to modify the database, prefer the ``DatabaseReader/read(_:)-3806d`` method, because several threads can perform reads in parallel.

When precise transaction handling is required, see <doc:Transactions>.

Asynchronous database accesses are described in <doc:Concurrency>.

`DatabasePool` can take snapshots of the database: see ``DatabaseSnapshot`` and ``DatabaseSnapshotPool``.

`DatabasePool` can be configured with ``Configuration``.

## Concurrency

A `DatabasePool` creates one writer SQLite connection, and a pool of read-only SQLite connections.

Unless ``Configuration/readonly``, the database is set to the [WAL mode](https://sqlite.org/wal.html). The WAL mode makes it possible for reads and writes to proceed concurrently.

All write accesses are executed in a serial **writer dispatch queue**, which means that there is never more than one thread that writes in the database.

All read accesses are executed in **reader dispatch queues** (one per read-only SQLite connection). Reads are generally non-blocking, unless the maximum number of concurrent reads has been reached. In this case, a read has to wait for another read to complete. That maximum number can be configured with ``Configuration/maximumReaderCount``.

SQLite connections are closed when the `DatabasePool` is deallocated.

`DatabasePool` inherits most of its database access methods from the ``DatabaseReader`` and ``DatabaseWriter`` protocols. It defines a few specific database access methods as well, listed below.

A `DatabasePool` needs your application to follow rules in order to deliver its safety guarantees. See <doc:Concurrency> for more information.

## Topics

### Creating a DatabasePool

- ``init(path:configuration:)``

### Accessing the Database

See ``DatabaseReader`` and ``DatabaseWriter`` for more database access methods.

- ``asyncConcurrentRead(_:)``
- ``writeInTransaction(_:_:)``

### Creating Database Snapshots

- ``makeSnapshot()``
- ``makeSnapshotPool()``

### Managing SQLite Connections

- ``invalidateReadOnlyConnections()``
- ``releaseMemory()``
- ``releaseMemoryEventually()``



---
File: /GRDB/Documentation.docc/Extension/DatabaseQueue.md
---

# ``GRDB/DatabaseQueue``

A database connection that serializes accesses to an SQLite database.

## Usage

Open a `DatabaseQueue` with the path to a database file:

```swift
import GRDB

let dbQueue = try DatabaseQueue(path: "/path/to/database.sqlite")
```

SQLite creates the database file if it does not already exist. The connection is closed when the database queue gets deallocated.

**A `DatabaseQueue` can be used from any thread.** The ``DatabaseWriter/write(_:)-76inz`` and ``DatabaseReader/read(_:)-3806d`` methods are synchronous, and block the current thread until your database statements are executed in a protected dispatch queue:

```swift
// Modify the database:
try dbQueue.write { db in
    try Player(name: "Arthur").insert(db)
}

// Read values:
try dbQueue.read { db in
    let players = try Player.fetchAll(db)
    let playerCount = try Player.fetchCount(db)
}
```

Database access methods can return values:

```swift
let playerCount = try dbQueue.read { db in
    try Place.fetchCount(db)
}

let newPlayerCount = try dbQueue.write { db -> Int in
    try Player(name: "Arthur").insert(db)
    return try Player.fetchCount(db)
}
```

The ``DatabaseWriter/write(_:)-76inz`` method wraps your database statements in a transaction that commits if and only if no error occurs. On the first unhandled error, all changes are reverted, the whole transaction is rollbacked, and the error is rethrown.

When you don't need to modify the database, prefer the ``DatabaseReader/read(_:)-3806d`` method: it prevents any modification to the database.

When precise transaction handling is required, see <doc:Transactions>.

Asynchronous database accesses are described in <doc:Concurrency>.

`DatabaseQueue` can be configured with ``Configuration``.

## In-Memory Databases

`DatabaseQueue` can open a connection to an [in-memory SQLite database](https://www.sqlite.org/inmemorydb.html).

Such connections are quite handy for tests and SwiftUI previews, since you do not have to perform any cleanup of the file system.

```swift
let dbQueue = try DatabaseQueue()
```

In order to create several connections to the same in-memory database, give this database a name:

```swift
// A shared in-memory database
let dbQueue1 = try DatabaseQueue(named: "myDatabase")

// Another connection to the same database
let dbQueue2 = try DatabaseQueue(named: "myDatabase")
```

See ``init(named:configuration:)``.

## Concurrency

A `DatabaseQueue` creates one single SQLite connection. All database accesses are executed in a serial **writer dispatch queue**, which means that there is never more than one thread that uses the database. The SQLite connection is closed when the `DatabaseQueue` is deallocated.

`DatabaseQueue` inherits most of its database access methods from the ``DatabaseReader`` and ``DatabaseWriter`` protocols. It defines a few specific database access methods as well, listed below.

A `DatabaseQueue` needs your application to follow rules in order to deliver its safety guarantees. See <doc:Concurrency> for more information.

## Topics

### Creating a DatabaseQueue

- ``init(named:configuration:)``
- ``init(path:configuration:)``
- ``inMemoryCopy(fromPath:configuration:)``
- ``temporaryCopy(fromPath:configuration:)``

### Accessing the Database

See ``DatabaseReader`` and ``DatabaseWriter`` for more database access methods.

- ``inDatabase(_:)``
- ``inTransaction(_:_:)``

### Managing the SQLite Connection

- ``releaseMemory()``



---
File: /GRDB/Documentation.docc/Extension/DatabaseRegionObservation.md
---

# ``GRDB/DatabaseRegionObservation``

`DatabaseRegionObservation` tracks changes in a database region, and notifies impactful transactions.

## Overview

`DatabaseRegionObservation` tracks insertions, updates, and deletions that impact the tracked region, whether performed with raw SQL, or <doc:QueryInterface>. This includes indirect changes triggered by [foreign keys actions](https://www.sqlite.org/foreignkeys.html#fk_actions) or [SQL triggers](https://www.sqlite.org/lang_createtrigger.html).

See <doc:GRDB/DatabaseRegionObservation#Dealing-with-Undetected-Changes> below for the list of exceptions.

`DatabaseRegionObservation` calls your application right after changes have been committed in the database, and before any other thread had any opportunity to perform further changes. *This is a pretty strong guarantee, that most applications do not really need.* Instead, most applications prefer to be notified with fresh values: make sure you check ``ValueObservation`` before using `DatabaseRegionObservation`.

## DatabaseRegionObservation Usage

Create a `DatabaseRegionObservation` with one or several requests to track:

```swift
// Tracks the full player table
let observation = DatabaseRegionObservation(tracking: Player.all())
```

Then start the observation from a ``DatabaseQueue`` or ``DatabasePool``:

```swift
let cancellable = try observation.start(in: dbQueue) { error in
    // Handle error
} onChange: { (db: Database) in
    print("Players were changed")
}
```

Enjoy the changes notifications:

```swift
try dbQueue.write { db in
    try Player(name: "Arthur").insert(db)
}
// Prints "Players were changed"
```

You stop the observation by calling the ``DatabaseCancellable/cancel()`` method on the object returned by the `start` method. Cancellation is automatic when the cancellable is deallocated:

```swift
cancellable.cancel()
```

`DatabaseRegionObservation` can also be turned into a Combine publisher, or an RxSwift observable (see the companion library [RxGRDB](https://github.com/RxSwiftCommunity/RxGRDB)):

```swift
let cancellable = observation.publisher(in: dbQueue).sink { completion in
    // Handle completion
} receiveValue: { (db: Database) in
    print("Players were changed")
}
```

You can feed `DatabaseRegionObservation` with any type that conforms to the ``DatabaseRegionConvertible`` protocol: ``FetchRequest``, ``DatabaseRegion``, ``Table``, etc. For example:

```swift
// Observe the score column of the 'player' table
let observation = DatabaseRegionObservation(
    tracking: Player.select(\.score))

// Observe the 'score' column of the 'player' table
let observation = DatabaseRegionObservation(
    tracking: SQLRequest("SELECT score FROM player"))

// Observe both the 'player' and 'team' tables
let observation = DatabaseRegionObservation(
    tracking: Table("player"), Table("team"))

// Observe the full database
let observation = DatabaseRegionObservation(
    tracking: .fullDatabase)
```

## Dealing with Undetected Changes

`DatabaseRegionObservation` will not notify impactful transactions whenever the database is modified in an undetectable way:

- Changes performed by external database connections.
- Changes performed by SQLite statements that are not compiled and executed by GRDB.
- Changes to the database schema, changes to internal system tables such as `sqlite_master`.
- Changes to [`WITHOUT ROWID`](https://www.sqlite.org/withoutrowid.html) tables.

To have observations notify such undetected changes, applications can take explicit action: call the ``Database/notifyChanges(in:)`` `Database` method from a write transaction:
    
```swift
try dbQueue.write { db in
    // Notify observations that some changes were performed in the database
    try db.notifyChanges(in: .fullDatabase)

    // Notify observations that some changes were performed in the player table
    try db.notifyChanges(in: Player.all())

    // Equivalent alternative
    try db.notifyChanges(in: Table("player"))
}
```

## Topics

### Creating DatabaseRegionObservation

- ``init(tracking:)-5ldbe``
- ``init(tracking:)-2nqjd``

### Observing Database Transactions

- ``publisher(in:)``
- ``start(in:onError:onChange:)``



---
File: /GRDB/Documentation.docc/Extension/DatabaseValueConvertible.md
---

# ``GRDB/DatabaseValueConvertible``

A type that can convert itself into and out of a database value.

## Overview

A `DatabaseValueConvertible` type supports conversion to and from database values (null, integers, doubles, strings, and blobs). `DatabaseValueConvertible` is adopted by `Bool`, `Int`, `String`, `Date`, etc.

> Note: Types that converts to and from multiple columns in a database row must not conform to the `DatabaseValueConvertible` protocol. Those types are called **record types**, and should conform to record protocols instead. See <doc:QueryInterface>.

> Note: Standard collections `Array`, `Set`, and `Dictionary` do not conform to `DatabaseValueConvertible`. To store arrays, sets, or dictionaries in individual database values, wrap them as properties of `Codable` record types. They will automatically be stored as JSON objects and arrays. See <doc:QueryInterface>.

## Conforming to the DatabaseValueConvertible Protocol

To conform to `DatabaseValueConvertible`, implement the two requirements ``fromDatabaseValue(_:)-21zzv`` and ``databaseValue-1ob9k``. Do not customize the ``fromMissingColumn()-7iamp`` requirement. If your type `MyValue` conforms, then the conformance of the optional type `MyValue?` is automatic.

The implementation of `fromDatabaseValue` must return nil if the type can not be decoded from the raw database value. This nil value will have GRDB throw a decoding error accordingly.

For example:

```swift
struct EvenInteger {
    let value: Int // Guaranteed even

    init?(_ value: Int) {
        guard value.isMultiple(of: 2) else {
            return nil // Not an even number
        }
        self.value = value
    }
}

extension EvenInteger: DatabaseValueConvertible {
    var databaseValue: DatabaseValue {
        value.databaseValue
    }

    static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Self? {
        guard let value = Int.fromDatabaseValue(dbValue) else {
            return nil // Not an integer
        }
        return EvenInteger(value) // Nil if not even
    }
}
```

### Built-in RawRepresentable support

`DatabaseValueConvertible` implementation is ready-made for `RawRepresentable` types whose raw value is itself `DatabaseValueConvertible`, such as enums:

```swift
enum Grape: String {
    case chardonnay, merlot, riesling
}

// Encodes and decodes `Grape` as a string in the database:
extension Grape: DatabaseValueConvertible { }
```

### Built-in Codable support

`DatabaseValueConvertible` is also ready-made for `Codable` types, which are automatically coded and decoded from JSON arrays and objects:

```swift
struct Color: Codable {
    var red: Double
    var green: Double
    var blue: Double
}

// Encodes and decodes `Color` as a JSON object in the database:
extension Color: DatabaseValueConvertible { }
```

By default, such codable value types are encoded and decoded with the standard [JSONEncoder](https://developer.apple.com/documentation/foundation/jsonencoder) and [JSONDecoder](https://developer.apple.com/documentation/foundation/jsondecoder). `Data` values are handled with the `.base64` strategy, `Date` with the `.millisecondsSince1970` strategy, and non conforming floats with the `.throw` strategy.

To customize the JSON format, provide an explicit implementation for the `DatabaseValueConvertible` requirements, or implement these two methods:

```swift
protocol DatabaseValueConvertible {
    static func databaseJSONDecoder() -> JSONDecoder
    static func databaseJSONEncoder() -> JSONEncoder
}
```

### Adding support for the Tagged library

[Tagged](https://github.com/pointfreeco/swift-tagged) is a popular library that makes it possible to enhance the type-safety of our programs with dedicated wrappers around basic types. For example:

```swift
import Tagged

struct Player: Identifiable {
    // Thanks to Tagged, Player.ID can not be mismatched with Team.ID or
    // Award.ID, even though they all wrap strings.
    typealias ID = Tagged<Player, String>
    var id: ID
    var name: String
    var score: Int
}
```

Applications that use both Tagged and GRDB will want to add those lines somewhere:

```swift
import GRDB
import Tagged

// Add database support to Tagged values
extension Tagged: @retroactive SQLExpressible where RawValue: SQLExpressible { }
extension Tagged: @retroactive StatementBinding where RawValue: StatementBinding { }
extension Tagged: @retroactive StatementColumnConvertible where RawValue: StatementColumnConvertible { }
extension Tagged: @retroactive DatabaseValueConvertible where RawValue: DatabaseValueConvertible { }
```

This makes it possible to use `Tagged` values in all the expected places:

```swift
let id: Player.ID = ...
let player = try Player.find(db, id: id)
```

## Optimized Values

For extra performance, custom value types can conform to both `DatabaseValueConvertible` and ``StatementColumnConvertible``. This extra protocol grants raw access to the [low-level C SQLite interface](https://www.sqlite.org/c3ref/column_blob.html) when decoding values.

For example:

```swift
extension EvenInteger: StatementColumnConvertible {
    init?(sqliteStatement: SQLiteStatement, index: CInt) {
        let int64 = sqlite3_column_int64(sqliteStatement, index)
        guard let value = Int(exactly: int64) else {
            return nil // Does not fit Int (probably a 32-bit architecture)
        }
        self.init(value) // Nil if not even
    }
}
```

This extra conformance is not required: only aim at the low-level C interface if you have identified a performance issue after profiling your application! 

## Topics

### Creating a Value

- ``fromDatabaseValue(_:)-21zzv``
- ``fromMissingColumn()-7iamp``

### Accessing the DatabaseValue

- ``databaseValue-1ob9k``

### Configuring the JSON format for the standard Decodable protocol

- ``databaseJSONDecoder()-7zou9``
- ``databaseJSONEncoder()-37sff``

### Fetching Values from Raw SQL

- ``fetchCursor(_:sql:arguments:adapter:)-6elcz``
- ``fetchAll(_:sql:arguments:adapter:)-1cqyb``
- ``fetchSet(_:sql:arguments:adapter:)-5jene``
- ``fetchOne(_:sql:arguments:adapter:)-qvqp``

### Fetching Values from a Prepared Statement

- ``fetchCursor(_:arguments:adapter:)-4l6af``
- ``fetchAll(_:arguments:adapter:)-3abuc``
- ``fetchSet(_:arguments:adapter:)-6y54n``
- ``fetchOne(_:arguments:adapter:)-3d7ax``

### Fetching Values from a Request

- ``fetchCursor(_:_:)-8q4r6``
- ``fetchAll(_:_:)-9hkqs``
- ``fetchSet(_:_:)-1foke``
- ``fetchOne(_:_:)-o6yj``

### Supporting Types

- ``DatabaseValueCursor``
- ``StatementBinding``



---
File: /GRDB/Documentation.docc/Extension/Statement.md
---

# ``GRDB/Statement``

A prepared statement.

## Overview

Prepared statements let you execute an SQL query several times, with different arguments if needed.

Reusing prepared statements is a performance optimization technique because SQLite parses and analyses the SQL query only once, when the prepared statement is created.

## Building Prepared Statements

Build a prepared statement with the ``Database/makeStatement(sql:)`` method:

```swift
try dbQueue.write { db in
    let insertStatement = try db.makeStatement(sql: """
        INSERT INTO player (name, score) VALUES (:name, :score)
        """)
    
    let selectStatement = try db.makeStatement(sql: """
        SELECT * FROM player WHERE name = ?
        """)
}
```

The `?` and colon-prefixed keys like `:name` in the SQL query are the statement arguments. Set the values for those arguments with arrays or dictionaries of database values, or ``StatementArguments`` instances:

```swift
insertStatement.arguments = ["name": "Arthur", "score": 1000]
selectStatement.arguments = ["Arthur"]
```

Alternatively, the ``Database/makeStatement(literal:)`` method creates prepared statements with support for [SQL Interpolation]:

```swift
let insertStatement = try db.makeStatement(literal: "INSERT ...")
let selectStatement = try db.makeStatement(literal: "SELECT ...")
//                                         ~~~~~~~
```

The `makeStatement` methods throw an error of code `SQLITE_MISUSE` (21) if the SQL query contains multiple statements joined with a semicolon. See <doc:GRDB/Statement#Parsing-Multiple-Prepared-Statements-from-a-Single-SQL-String> below.

## Executing Prepared Statements and Fetching Values

Prepared statements can be executed:

```swift
try insertStatement.execute()
```

To fetch rows and values from a prepared statement, use a fetching method of ``Row``, ``DatabaseValueConvertible``, or ``FetchableRecord``:

```swift
let players = try Player.fetchCursor(selectStatement) // A Cursor of Player
let players = try Player.fetchAll(selectStatement)    // [Player]
let players = try Player.fetchSet(selectStatement)    // Set<Player>
let player =  try Player.fetchOne(selectStatement)     // Player?
//                ~~~~~~ or Row, Int, String, Date, etc.
```

Arguments can be set at the moment of the statement execution:

```swift
try insertStatement.execute(arguments: ["name": "Arthur", "score": 1000])
let player = try Player.fetchOne(selectStatement, arguments: ["Arthur"])
```

> Note: A prepared statement that has failed with an error can not be recovered. Create a new instance, or use a cached statement as described below.

> Tip: When you look after the best performance, take care about a difference between setting the arguments before execution, and setting the arguments at the moment of execution:
>
> ```swift
> // First option
> try statement.setArguments(...)
> try statement.execute()
>
> // Second option
> try statement.execute(arguments: ...)
> ```
>
> Both perform exactly the same action, and most applications should not care about the difference. Yet:
>
> - ``setArguments(_:)`` performs a copy of string and blob arguments. It uses the low-level [`SQLITE_TRANSIENT`](https://www.sqlite.org/c3ref/c_static.html) option, and fits well the reuse of a given statement with the same arguments.
> - ``execute(arguments:)`` avoids a temporary allocation for string and blob arguments if the number of arguments is small. Instead of `SQLITE_TRANSIENT`, it uses the low-level [`SQLITE_STATIC`](https://www.sqlite.org/c3ref/c_static.html) option. This fits well the reuse of a given statement with various arguments.
>
> Don't make a blind choice, and monitor your app performance if it really matters!

## Caching Prepared Statements

When the same query will be used several times in the lifetime of an application, one may feel a natural desire to cache prepared statements.

Don't cache statements yourself.

> Note: This is because an application lacks the necessary tools. Statements are tied to specific SQLite connections and dispatch queues which are not managed by the application, especially with a ``DatabasePool`` connection. A change in the database schema [may, or may not](https://www.sqlite.org/compile.html#max_schema_retry) invalidate a statement.

Instead, use the ``Database/cachedStatement(sql:)`` method. GRDB does all the hard caching and memory management:

```swift
let statement = try db.cachedStatement(sql: "INSERT ...")
```

The variant ``Database/cachedStatement(literal:)`` supports [SQL Interpolation]:

```swift
let statement = try db.cachedStatement(literal: "INSERT ...")
```

Should a cached prepared statement throw an error, don't reuse it. Instead, reload one from the cache.

## Parsing Multiple Prepared Statements from a Single SQL String

To build multiple statements joined with a semicolon, use ``Database/allStatements(sql:arguments:)``:

```swift
let statements = try db.allStatements(sql: """
    INSERT INTO player (name, score) VALUES (?, ?);
    INSERT INTO player (name, score) VALUES (?, ?);
    """, arguments: ["Arthur", 100, "O'Brien", 1000])
while let statement = try statements.next() {
    try statement.execute()
}
```

The variant ``Database/allStatements(literal:)`` supports [SQL Interpolation]:

```swift
let statements = try db.allStatements(literal: """
    INSERT INTO player (name, score) VALUES (\("Arthur"), \(100));
    INSERT INTO player (name, score) VALUES (\("O'Brien"), \(1000));
    """)
// An alternative way to iterate all statements
try statements.forEach { statement in
    try statement.execute()
}
```

> Tip: When you intend to run all statements in an SQL string but don't care about individual ones, don't bother iterating individual statement instances! Skip this documentation section and just use ``Database/execute(sql:arguments:)``:
>
> ```swift
> try db.execute(sql: """
>     CREATE TABLE player ...; 
>     INSERT INTO player ...;
>     """)
> ```

The results of multiple `SELECT` statements can be joined into a single ``Cursor``. This is the GRDB version of the [`sqlite3_exec()`](https://www.sqlite.org/c3ref/exec.html) function:

```swift
let statements = try db.allStatements(sql: """
    SELECT ...; 
    SELECT ...; 
    """)
let players = try statements.flatMap { statement in
    try Player.fetchCursor(statement)
}
for let player = try players.next() { 
    print(player.name)
}
```

The ``SQLStatementCursor`` returned from `allStatements` can be turned into a regular Swift array, but in this case make sure all individual statements can compile even if the previous ones were not executed:

```swift
// OK: Array of statements
let statements = try Array(db.allStatements(sql: """
    INSERT ...; 
    UPDATE ...; 
    """))

// FAILURE: Can't build an array of statements since the INSERT won't
// compile until CREATE TABLE is executed.
let statements = try Array(db.allStatements(sql: """
    CREATE TABLE player ...; 
    INSERT INTO player ...;
    """))
```

## Topics

### Executing a Prepared Statement

- ``execute(arguments:)``

### Arguments

- ``arguments``
- ``setArguments(_:)``
- ``setUncheckedArguments(_:)``
- ``validateArguments(_:)``
- ``StatementArguments``

### Statement Informations

- ``columnCount``
- ``columnNames``
- ``databaseRegion``
- ``index(ofColumn:)``
- ``isReadonly``
- ``sql``
- ``sqliteStatement``
- ``SQLiteStatement``


[SQL Interpolation]: https://github.com/groue/GRDB.swift/blob/master/Documentation/SQLInterpolation.md



---
File: /GRDB/Documentation.docc/Extension/TransactionObserver.md
---

# ``GRDB/TransactionObserver``

A type that tracks database changes and transactions performed in a database.

## Overview

`TransactionObserver` is the low-level protocol that supports all <doc:DatabaseObservation> features.

A transaction observer is notified of individual changes (inserts, updates and deletes), before they are committed to disk, as well as transaction commits and rollbacks.

## Activate a Transaction Observer

An observer starts receiving change notifications after it has been added to a database connection with the ``DatabaseWriter/add(transactionObserver:extent:)`` `DatabaseWriter` method, or the ``Database/add(transactionObserver:extent:)`` `Database` method:

```swift
let observer = MyObserver()
dbQueue.add(transactionObserver: observer)
```

By default, database holds weak references to its transaction observers: they are not retained, and stop getting notifications after they are deallocated. See <doc:TransactionObserver#Observation-Extent> for more options.

## Database Changes And Transactions

Database changes are notified to the ``databaseDidChange(with:)`` callback. This includes indirect changes triggered by `ON DELETE` and `ON UPDATE` actions associated to [foreign keys](https://www.sqlite.org/foreignkeys.html#fk_actions), and [SQL triggers](https://www.sqlite.org/lang_createtrigger.html).

Transaction completions are notified to the ``databaseWillCommit()-7mksu``, ``databaseDidCommit(_:)`` and ``databaseDidRollback(_:)`` callbacks.

> Important: Some changes and transactions are not automatically notified. See <doc:GRDB/TransactionObserver#Dealing-with-Undetected-Changes> below.

Notified changes are not actually written to disk until the transaction commits, and the `databaseDidCommit` callback is called. On the other side, `databaseDidRollback` confirms their invalidation:

```swift
try dbQueue.write { db in
    try db.execute(sql: "INSERT ...") // 1. didChange
    try db.execute(sql: "UPDATE ...") // 2. didChange
}                                     // 3. willCommit, 4. didCommit

try dbQueue.inTransaction { db in
    try db.execute(sql: "INSERT ...") // 1. didChange
    try db.execute(sql: "UPDATE ...") // 2. didChange
    return .rollback                  // 3. didRollback
}

try dbQueue.write { db in
    try db.execute(sql: "INSERT ...") // 1. didChange
    throw SomeError()
}                                     // 2. didRollback
```

Database statements that are executed outside of any explicit transaction do not drop off the radar:

```swift
try dbQueue.writeWithoutTransaction { db in
    try db.execute(sql: "INSERT ...") // 1. didChange, 2. willCommit, 3. didCommit
    try db.execute(sql: "UPDATE ...") // 4. didChange, 5. willCommit, 6. didCommit
}
```

Changes that are on hold because of a [savepoint](https://www.sqlite.org/lang_savepoint.html) are only notified after the savepoint has been released. This makes sure that notified events are only those that have an opportunity to be committed:

```swift
try dbQueue.inTransaction { db in
    try db.execute(sql: "INSERT ...")            // 1. didChange

    try db.execute(sql: "SAVEPOINT foo")
    try db.execute(sql: "UPDATE ...")            // delayed
    try db.execute(sql: "UPDATE ...")            // delayed
    try db.execute(sql: "RELEASE SAVEPOINT foo") // 2. didChange, 3. didChange

    try db.execute(sql: "SAVEPOINT bar")
    try db.execute(sql: "UPDATE ...")            // not notified
    try db.execute(sql: "ROLLBACK TO SAVEPOINT bar")
    try db.execute(sql: "RELEASE SAVEPOINT bar")

    return .commit                               // 4. willCommit, 5. didCommit
}
```

Eventual errors thrown from `databaseWillCommit` are exposed to the application code:

```swift
do {
    try dbQueue.inTransaction { db in
        ...
        return .commit // 1. willCommit (throws), 2. didRollback
    }
} catch {
    // 3. The error thrown by the transaction observer.
}
```

- Note: All callbacks are called in the writer dispatch queue, and serialized with all database updates.

- Note: The `databaseDidChange` and `databaseWillCommit` callbacks must not access the observed writer database connection in any way. This limitation does not apply to `databaseDidCommit` and `databaseDidRollback` which can use their database argument.

## Filtering Database Events

**Transaction observers can choose the database changes they are interested in.**

The ``observes(eventsOfKind:)`` method filters events that are notified to ``databaseDidChange(with:)``. It is the most efficient and recommended change filtering technique, because it is only called once before a database query is executed, and can completely disable change tracking:

```swift
// Calls `observes(eventsOfKind:)` once.
// Calls `databaseDidChange(with:)` for every updated row, or not at all.
try db.execute(sql: "UPDATE player SET score = score + 1")
```

The ``DatabaseEventKind`` argument of `observes(eventsOfKind:)` can distinguish insertions from deletions and updates, and is also able to tell the columns that are about to be changed.

For example, an observer can focus on the changes that happen on the "player" database table only:

```swift
class PlayerObserver: TransactionObserver {
    func observes(eventsOfKind eventKind: DatabaseEventKind) -> Bool {
        // Only observe changes to the "player" table.
        eventKind.tableName == "player"
    }

    func databaseDidChange(with event: DatabaseEvent) {
        // This method is only called for changes that happen to
        // the "player" table.
    }
}
```

When the `observes(eventsOfKind:)` method returns false for all event kinds, the observer is still notified of transactions.

## Observation Extent

**You can specify how long an observer is notified of database changes and transactions.**

The `remove(transactionObserver:)` method explicitly stops notifications, at any time:

```swift
// From a database queue or pool:
dbQueue.remove(transactionObserver: observer)

// From a database connection:
dbQueue.inDatabase { db in
    db.remove(transactionObserver: observer)
}
```

Alternatively, use the `extent` parameter of the `add(transactionObserver:extent:)` method:

```swift
let observer = MyObserver()

// On a database queue or pool:
dbQueue.add(transactionObserver: observer) // default extent
dbQueue.add(transactionObserver: observer, extent: .observerLifetime)
dbQueue.add(transactionObserver: observer, extent: .nextTransaction)
dbQueue.add(transactionObserver: observer, extent: .databaseLifetime)

// On a database connection:
dbQueue.inDatabase { db in
    db.add(transactionObserver: ...)
}
```

- The default extent is `.observerLifetime`: the database holds a weak reference to the observer, and the observation automatically ends when the observer is deallocated. Meanwhile, the observer is notified of all changes and transactions.

- `.nextTransaction` activates the observer until the current or next transaction completes. The database keeps a strong reference to the observer until its `databaseDidCommit` or `databaseDidRollback` callback is called. Hereafter the observer won't get any further notification.

- `.databaseLifetime` has the database retain and notify the observer until the database connection is closed.

Finally, an observer can avoid processing database changes until the end of the current transaction. After ``stopObservingDatabaseChangesUntilNextTransaction()``, the `databaseDidChange` callback will not be called until the current transaction completes:

```swift
class PlayerObserver: TransactionObserver {
    var playerTableWasModified = false

    func observes(eventsOfKind eventKind: DatabaseEventKind) -> Bool {
        eventKind.tableName == "player"
    }

    func databaseDidChange(with event: DatabaseEvent) {
        playerTableWasModified = true

        // It is pointless to keep on tracking further changes:
        stopObservingDatabaseChangesUntilNextTransaction()
    }
}
```

## Support for SQLite Pre-Update Hooks

When SQLite is built with the `SQLITE_ENABLE_PREUPDATE_HOOK` option, `TransactionObserver` gets an extra callback which lets you observe individual column values in the rows modified by a transaction:

```swift
protocol TransactionObserver: AnyObject {
    #if SQLITE_ENABLE_PREUPDATE_HOOK
    /// Notifies before a database change (insert, update, or delete)
    /// with change information (initial / final values for the row's
    /// columns).
    ///
    /// The event is only valid for the duration of this method call. If you
    /// need to keep it longer, store a copy: event.copy().
    func databaseWillChange(with event: DatabasePreUpdateEvent)
    #endif
}
```

This extra API can be activated in two ways:

1. Use the GRDB.swift CocoaPod with a custom compilation option, as below.

    ```ruby
    pod 'GRDB.swift'

    post_install do |installer|
      installer.pods_project.targets.select { |target| target.name == "GRDB.swift" }.each do |target|
        target.build_configurations.each do |config|
          # Enable extra GRDB APIs
          config.build_settings['OTHER_SWIFT_FLAGS'] = "$(inherited) -D SQLITE_ENABLE_PREUPDATE_HOOK"
          # Enable extra SQLite APIs
          config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = "$(inherited) GRDB_SQLITE_ENABLE_PREUPDATE_HOOK=1"
        end
      end
    end
    ```

    **Warning**: make sure you use the right platform version! You will get runtime errors on devices with a lower version.

    **Note**: the `GRDB_SQLITE_ENABLE_PREUPDATE_HOOK=1` option in `GCC_PREPROCESSOR_DEFINITIONS` defines some C function prototypes that are lacking from the system `<sqlite3.h>` header. When Xcode eventually ships with an SDK that includes a complete header, you may get a compiler error about duplicate function definitions. When this happens, just remove this `GRDB_SQLITE_ENABLE_PREUPDATE_HOOK=1` option.

2. Use a [custom SQLite build](http://github.com/groue/GRDB.swift/blob/master/Documentation/CustomSQLiteBuilds.md) and activate the `SQLITE_ENABLE_PREUPDATE_HOOK` compilation option.

## Dealing with Undetected Changes

The changes and transactions that are not automatically notified to transaction observers are:

- Read-only transactions.
- Changes and transactions performed by external database connections.
- Changes performed by SQLite statements that are not both compiled and executed through GRDB APIs.
- Changes to the database schema, changes to internal system tables such as `sqlite_master`.
- Changes to [`WITHOUT ROWID`](https://www.sqlite.org/withoutrowid.html) tables.
- The deletion of duplicate rows triggered by [`ON CONFLICT REPLACE`](https://www.sqlite.org/lang_conflict.html) clauses (this last exception might change in a future release of SQLite).

To notify undetected changes to transaction observers, perform an explicit call to the ``Database/notifyChanges(in:)`` `Database` method. The ``databaseDidChange()-7olv7`` callback will be called accordingly. For example:

```swift
try dbQueue.write { db in
    // Notify observers that some changes were performed in the database
    try db.notifyChanges(in: .fullDatabase)

    // Notify observers that some changes were performed in the player table
    try db.notifyChanges(in: Player.all())

    // Equivalent alternative
    try db.notifyChanges(in: Table("player"))
}
```

To notify a change in the database schema, notify a change to the `sqlite_master` table:

```swift
try dbQueue.write { db in
    // Notify all observers of the sqlite_master table
    try db.notifyChanges(in: Table("sqlite_master"))
}
```

## Topics

### Filtering Database Changes

- ``observes(eventsOfKind:)``
- ``DatabaseEventKind``

### Handling Database Changes

- ``databaseDidChange()-7olv7``
- ``databaseDidChange(with:)``
- ``stopObservingDatabaseChangesUntilNextTransaction()``
- ``DatabaseEvent``

### Handling Transactions

- ``databaseWillCommit()-7mksu``
- ``databaseDidCommit(_:)``
- ``databaseDidRollback(_:)``



---
File: /GRDB/Documentation.docc/Extension/ValueObservation.md
---

# ``GRDB/ValueObservation``

`ValueObservation` tracks changes in the results of database requests, and notifies fresh values whenever the database changes.

## Overview

`ValueObservation` tracks insertions, updates, and deletions that impact the tracked value, whether performed with raw SQL, or <doc:QueryInterface>. This includes indirect changes triggered by [foreign keys actions](https://www.sqlite.org/foreignkeys.html#fk_actions) or [SQL triggers](https://www.sqlite.org/lang_createtrigger.html).

See <doc:GRDB/ValueObservation#Dealing-with-Undetected-Changes> below for the list of exceptions.

## ValueObservation Usage

1. Make sure that a unique database connection, ``DatabaseQueue`` or ``DatabasePool``, is kept open during the whole duration of the observation.

2. Create a `ValueObservation` with a closure that fetches the observed value:

    ```swift
    let observation = ValueObservation.tracking { db in
        // Fetch and return the observed value
    }

    // For example, an observation of [Player], which tracks all players:
    let observation = ValueObservation.tracking { db in
        try Player.fetchAll(db)
    }

    // The same observation, using shorthand notation:
    let observation = ValueObservation.tracking(Player.fetchAll)
    ```

    There is no limit on the values that can be observed. An observation can perform multiple requests, from multiple database tables, and use raw SQL. See ``tracking(_:)`` for some examples.

3. Start the observation in order to be notified of changes:

    ```swift
    let cancellable = observation.start(in: dbQueue) { error in
        // Handle error
    } onChange: { (players: [Player]) in
        print("Fresh players", players)
    }
    ```

4. Stop the observation by calling the ``DatabaseCancellable/cancel()`` method on the object returned by the `start` method. Cancellation is automatic when the cancellable is deallocated:

    ```swift
    cancellable.cancel()
    ```

`ValueObservation` can also be turned into an async sequence, a Combine publisher, or an RxSwift observable (see the companion library [RxGRDB](https://github.com/RxSwiftCommunity/RxGRDB)):

- Async sequence:

    ```swift
    do {
        for try await players in observation.values(in: dbQueue) {
            print("Fresh players", players)
        }
    } catch {
        // Handle error
    }
    ```

- Combine Publisher:

    ```swift
    let cancellable = observation.publisher(in: dbQueue).sink { completion in
        // Handle completion
    } receiveValue: { (players: [Player]) in
        print("Fresh players", players)
    }
    ```

## ValueObservation Behavior

`ValueObservation` notifies an initial value before the eventual changes.

`ValueObservation` only notifies changes committed to disk.

By default, `ValueObservation` notifies a fresh value whenever any component of its fetched value is modified (any fetched column, row, etc.). This can be configured: see <doc:ValueObservation#Specifying-the-Tracked-Region>.

By default, `ValueObservation` notifies the initial value, as well as eventual changes and errors, on the main actor, asynchronously. This can be configured: see <doc:ValueObservation#ValueObservation-Scheduling>.

By default, `ValueObservation` fetches a fresh value immediately after a change is committed in the database. In particular, modifying the database on the main thread triggers a fetch on the main thread as well. This behavior can be configured: see <doc:ValueObservation#ValueObservation-Scheduling>.

`ValueObservation` may coalesce subsequent changes into a single notification.

`ValueObservation` may notify consecutive identical values. You can filter out the undesired duplicates with the ``removeDuplicates()`` method.

Starting an observation retains the database connection, until it is stopped. As long as the observation is active, the database connection won't be deallocated.

The database observation stops when the cancellable returned by the `start` method is cancelled or deallocated, or if an error occurs.

> Important: Take care that there are use cases that `ValueObservation` is unfit for.
>
> For example, an application may need to process absolutely all changes, and avoid any coalescing. An application may also need to process changes before any further modifications could be performed in the database file. In those cases, the application needs to track *individual transactions*, not values: use ``DatabaseRegionObservation``.
>
> If you need to process changes before they are committed to disk, use ``TransactionObserver``.

## ValueObservation Scheduling

By default, `ValueObservation` notifies the initial value, as well as eventual changes and errors, on the main actor, asynchronously:

```swift
// The default scheduling
let cancellable = observation.start(in: dbQueue) { error in
    // This closure is MainActor-isolated.
} onChange: { value in
    // This closure is MainActor-isolated.
    print("Fresh value", value)
}
```

You can change this behavior by adding a `scheduling` argument to the `start()` method.

For example, the ``ValueObservationMainActorScheduler/immediate`` scheduler notifies all values on the main actor, and notifies the first one immediately when the observation starts.

It is very useful in graphic applications, because you can configure views right away, without waiting for the initial value to be fetched eventually. You don't have to implement any empty or loading screen, or to prevent some undesired initial animation. Take care that the user interface is not responsive during the fetch of the first value, so only use the `immediate` scheduling for very fast database requests!

```swift
// Immediate scheduling notifies
// the initial value right on subscription.
let cancellable = observation
    .start(in: dbQueue, scheduling: .immediate) { error in
        // Called on the main actor
    } onChange: { value in
        // Called on the main actor
        print("Fresh value", value)
    }
// <- Here "Fresh value" has already been printed.
```

The ``ValueObservationScheduler/async(onQueue:)`` scheduler asynchronously schedules values and errors on the dispatch queue of your choice. Make sure you provide a serial dispatch queue, because a concurrent one such as `DispachQueue.global(qos: .default)` would mess with the ordering of fresh value notifications:

```swift
// Async scheduling notifies all values
// on the specified dispatch queue.
let myQueue: DispatchQueue
let cancellable = observation
    .start(in: dbQueue, scheduling: .async(myQueue)) { error in
        // Called asynchronously on myQueue
    } onChange: { value in
        // Called asynchronously on myQueue
        print("Fresh value", value)
    }
```

The ``ValueObservationScheduler/task`` scheduler asynchronously schedules values and errors on the cooperative thread pool. It is implicitly used when you turn a ValueObservation into an async sequence. You can specify it explicitly when you intend to consume a shared observation as an async sequence: 

```swift
do {
    for try await players in observation.values(in: dbQueue) {
        // Called on the cooperative thread pool
        print("Fresh players", players)
    }
} catch {
    // Handle error
}

let sharedObservation = observation.shared(in: dbQueue, scheduling: .task)
do {
    for try await players in sharedObservation.values() {
        // Called on the cooperative thread pool
        print("Fresh players", players)
    }
} catch {
    // Handle error
}

```

As described above, the `scheduling` argument controls the execution of the change and error callbacks. You also have some control on the execution of the database fetch:

- With the `.immediate` scheduling, the initial fetch is always performed synchronously, on the main actor, when the observation starts, so that the initial value can be notified immediately.

- With the default `.async` scheduling, the initial fetch is always performed asynchronouly. It never blocks the main thread.

- By default, fresh values are fetched immediately after the database was changed. In particular, modifying the database on the main thread triggers a fetch on the main thread as well.

    To change this behavior, and guarantee that fresh values are never fetched from the main thread, you need a ``DatabasePool`` and an optimized observation created with the ``tracking(regions:fetch:)`` or ``trackingConstantRegion(_:)`` methods. Make sure you read the documentation of those methods, or you might write an observation that misses some database changes.

    It is possible to use a ``DatabasePool`` in the application, and an in-memory ``DatabaseQueue`` in tests and Xcode previews, with the common protocol ``DatabaseWriter``.


## ValueObservation Sharing

Sharing a `ValueObservation` spares database resources. When a database change happens, a fresh value is fetched only once, and then notified to all clients of the shared observation.

You build a shared observation with ``shared(in:scheduling:extent:)``:

```swift
// SharedValueObservation<[Player]>
let sharedObservation = ValueObservation
    .tracking { db in try Player.fetchAll(db) }
    .shared(in: dbQueue)
```

`ValueObservation` and `SharedValueObservation` are nearly identical, but the latter has no operator such as `map`. As a replacement, you may for example use Combine apis:

```swift
let cancellable = try sharedObservation
    .publisher() // Turn shared observation into a Combine Publisher
    .map { ... } // The map operator from Combine
    .sink(...)
```


## Specifying the Tracked Region

While the standard ``tracking(_:)`` method lets you track changes to a fetched value and receive any changes to it, sometimes your use case might require more granular control.

Consider a scenario where you'd like to get a specific Player's row, but only when their `score` column changes. You can use ``tracking(region:_:fetch:)`` to do just that:

```swift
let observation = ValueObservation.tracking(
    // Define the tracked database region
    // (the score column of the player with id 1)
    region: Player.select(\.score).filter(id: 1),
    // Define what to fetch upon such change to the tracked region
    // (the player with id 1)
    fetch: { db in try Player.fetchOne(db, id: 1) }
)
```

This ``tracking(region:_:fetch:)`` method lets you entirely separate the **observed region(s)** from the **fetched value** itself, for maximum flexibility. See ``DatabaseRegionConvertible`` for more information about the regions that can be tracked.

## Dealing with Undetected Changes

`ValueObservation` will not fetch and notify a fresh value whenever the database is modified in an undetectable way:

- Changes performed by external database connections.
- Changes performed by SQLite statements that are not compiled and executed by GRDB.
- Changes to the database schema, changes to internal system tables such as `sqlite_master`.
- Changes to [`WITHOUT ROWID`](https://www.sqlite.org/withoutrowid.html) tables.

To have observations notify a fresh values after such an undetected change was performed, applications can take explicit action. For example, cancel and restart observations. Alternatively, call the ``Database/notifyChanges(in:)`` `Database` method from a write transaction:
    
```swift
try dbQueue.write { db in
    // Notify observations that some changes were performed in the database
    try db.notifyChanges(in: .fullDatabase)

    // Notify observations that some changes were performed in the player table
    try db.notifyChanges(in: Player.all())

    // Equivalent alternative
    try db.notifyChanges(in: Table("player"))
}
```

## ValueObservation Performance

This section further describes runtime aspects of `ValueObservation`, and provides some optimization tips for demanding applications.

**`ValueObservation` is triggered by database transactions that may modify the tracked value.**

Precisely speaking, `ValueObservation` tracks changes in a ``DatabaseRegion``, not changes in values.

For example, if you track the maximum score of players, all transactions that impact the `score` column of the `player` database table (any update, insertion, or deletion) trigger the observation, even if the maximum score itself is not changed.

You can filter out undesired duplicate notifications with the ``removeDuplicates()`` method.

**ValueObservation can create database contention.** In other words, active observations take a toll on the constrained database resources. When triggered by impactful transactions, observations fetch fresh values, and can delay read and write database accesses of other application components.

When needed, you can help GRDB optimize observations and reduce database contention:

> Important: **Keep your number of observations bounded.**
>
> In particular, do not observe independently all elements in a list. Instead, observe the whole list in a single observation.

> Tip: Stop observations when possible.
>
> For example, if a `UIViewController` needs to display database values, it can start the observation in `viewWillAppear`, and stop it in `viewWillDisappear`.
>
> In a SwiftUI application, you can profit from the [GRDBQuery](https://github.com/groue/GRDBQuery) companion library, and its [`View.queryObservation(_:)`](https://swiftpackageindex.com/groue/grdbquery/documentation/grdbquery/queryobservation) method.

> Tip: Share observations when possible.
>
> Each call to `ValueObservation.start` method triggers independent values refreshes. When several components of your app are interested in the same value, consider sharing the observation with ``shared(in:scheduling:extent:)``.

> Tip: When the observation processes some raw fetched values, use the ``map(_:)`` operator:
>
> ```swift
> // Plain observation
> let observation = ValueObservation.tracking { db -> MyValue in
>     let players = try Player.fetchAll(db)
>     return computeMyValue(players)
> }
>
> // Optimized observation
> let observation = ValueObservation
>     .tracking { db try Player.fetchAll(db) }
>     .map { players in computeMyValue(players) }
> ```
>
> The `map` operator performs its job without blocking database accesses, and without blocking the main thread.

> Tip: When the observation tracks a constant database region, create an optimized observation with the ``tracking(regions:fetch:)`` or ``trackingConstantRegion(_:)`` methods. Make sure you read the documentation of those methods, or you might write an observation that misses some database changes.

**Truncating WAL checkpoints impact ValueObservation.** Such checkpoints are performed with ``Database/checkpoint(_:on:)`` or [`PRAGMA wal_checkpoint`](https://www.sqlite.org/pragma.html#pragma_wal_checkpoint). When an observation is started on a ``DatabasePool``, from a database that has a missing or empty [wal file](https://www.sqlite.org/tempfiles.html#write_ahead_log_wal_files), the observation will always notify two values when it starts, even if the database content is not changed. This is a consequence of the impossibility to create the [wal snapshot](https://www.sqlite.org/c3ref/snapshot_get.html) needed for detecting that no changes were performed during the observation startup. If your application performs truncating checkpoints, you will avoid this behavior if you recreate a non-empty wal file before starting observations. To do so, perform any kind of no-op transaction (such a creating and dropping a dummy table).


## Topics

### Creating a ValueObservation

- ``tracking(_:)``
- ``trackingConstantRegion(_:)``
- ``tracking(region:_:fetch:)``
- ``tracking(regions:fetch:)``

### Creating a Shared Observation

- ``shared(in:scheduling:extent:)``
- ``SharedValueObservationExtent``

### Accessing Observed Values

- ``start(in:scheduling:onError:onChange:)-t62r``
- ``start(in:scheduling:onError:onChange:)-4mqbs``
- ``publisher(in:scheduling:)``
- ``values(in:scheduling:bufferingPolicy:)``
- ``DatabaseCancellable``
- ``ValueObservationScheduler``
- ``ValueObservationMainActorScheduler``

### Mapping Values

- ``map(_:)``

### Filtering Values

- ``removeDuplicates()``
- ``removeDuplicates(by:)``

### Requiring Write Access

- ``requiresWriteAccess``

### Debugging

- ``handleEvents(willStart:willFetch:willTrackRegion:databaseDidChange:didReceiveValue:didFail:didCancel:)``
- ``print(_:to:)``

### Supporting Types

- ``ValueReducer``



---
File: /GRDB/Documentation.docc/Concurrency.md
---

# Concurrency

GRDB helps your app deal with Swift and SQLite concurrency.

## Overview

If your app moves slow database jobs off the main thread, so that the user interface remains responsive, then this guide is for you. In the case of apps that share a database with other processes, such as an iOS app and its extensions, don't miss the dedicated <doc:DatabaseSharing> guide after this one.

**In all cases, and first and foremost, follow the <doc:Concurrency#Concurrency-Rules> right from the start.**

The other chapters cover, with more details, the fundamentals of SQLite concurrency, and how GRDB makes it manageable from your Swift code.

## Concurrency Rules

**The two concurrency rules are strongly recommended practices.** They are all about SQLite, a robust and reliable database that takes great care of your data: don't miss an opportunity to put it on your side!

#### Rule 1: Connect to any database file only once

Open one single ``DatabaseQueue`` or ``DatabasePool`` per database file, for the whole duration of your use of the database. Not for the duration of _each_ database access, but really for the duration of _all_ database accesses to this file.

- *Why does this rule exist?* - Since SQLite does not support parallel writes, each `DatabaseQueue` and `DatabasePool` makes sure application threads perform writes one by one, without overlap.

- *Practical advice* - An app that uses a single database will connect only once. A document-based app will connect each time a document is opened, and disconnect when the document is closed. See the [demo apps] in order to see how to setup a UIKit or SwiftUI application for a single database.

- *What if you do not follow this rule?*
    
    - You will not be able to use the <doc:DatabaseObservation> features.
    - You will see SQLite errors ([`SQLITE_BUSY`]).

#### Rule 2: Mind your transactions

Database operations that are grouped in a transaction are guaranteed to be either fully saved on disk, or not at all. Read-only transactions guarantee a stable and immutable view of the database, and do not see changes performed by eventual concurrent writes.

In other words, transactions are the one and single tool that helps you enforce and rely on the invariants of your database (such as "all authors must have at least one book").

**You are responsible**, in your Swift code, for delimiting transactions. You do so by grouping database accesses inside a pair of `{ db in ... }` brackets:

```swift
try dbQueue.write { db in
    // Inside a transaction
}

try dbQueue.read { db
    // Inside a transaction
}
```

Alternatively, you can open an explicit transaction or savepoint: see <doc:Transactions>.

- *Why does this rule exist?* - Because GRDB and SQLite can not guess where to insert the transaction boundaries that protect the invariants of your database. This is your task. Transactions also avoid concurrency problems, as described in the <doc:Concurrency#Safe-and-Unsafe-Database-Accesses> section below. 

- *Practical advice* - Take the time to identify the invariants of your database. Some of them can be enforced in the database schema itself, such as "all books must have a non-empty title", or "all books must have an author" (see <doc:DatabaseSchema>). Some invariants can only be enforced by transactions, such as "all account credits must have a matching debit", or "all authors must have at least one book".

- *What if you do not follow this rule?* - You will see broken database invariants, at runtime, or when your apps wakes up after a crash. These bugs corrupt user data, and are very difficult to fix.


## Synchronous and Asynchronous Database Accesses

**You can access the database from any thread, in a synchronous or asynchronous way.**

➡️ **A sync access blocks the current thread** until the database operations are completed:

```swift
let playerCount = try dbQueue.read { db in
    try Player.fetchCount(db)
}

let newPlayerCount = try dbQueue.write { db -> Int in
    try Player(name: "Arthur").insert(db)
    return try Player.fetchCount(db)
}
```

See ``DatabaseReader/read(_:)-3806d`` and ``DatabaseWriter/write(_:)-76inz``.

It is a programmer error to perform a sync access from any other database access (this restriction can be lifted: see <doc:Concurrency#Safe-and-Unsafe-Database-Accesses>):

```swift
try dbQueue.write { db in
    // Fatal Error: Database methods are not reentrant.
    try dbQueue.write { db in ... }
}
```

🔀 **An async access does not block the current thread.** Instead, it notifies you when the database operations are completed. There are four ways to access the database asynchronously:

- **Swift concurrency** (async/await)
    
    ```swift
    let playerCount = try await dbQueue.read { db in
        try Player.fetchCount(db)
    }
    
    let newPlayerCount = try await dbQueue.write { db -> Int in
        try Player(name: "Arthur").insert(db)
        return try Player.fetchCount(db)
    }
    ```

    See ``DatabaseReader/read(_:)-5mfwu`` and ``DatabaseWriter/write(_:)-4gnqx``.
    
    Note the identical method names: `read`, `write`. The async version is only available in async Swift functions.
    
    The async database access methods honor task cancellation. Once an async Task is cancelled, reads and writes throw `CancellationError`, and any transaction is rollbacked.
    
    See <doc:SwiftConcurrency> for more information about GRDB and Swift 6.

- **Combine publishers**
    
    For example:
    
    ```swift
    let playerCountPublisher = dbQueue.readPublisher { db in
        try Player.fetchCount(db)
    }
    
    let newPlayerCountPublisher = dbQueue.writePublisher { db -> Int in
        try Player(name: "Arthur").insert(db)
        return try Player.fetchCount(db)
    }
    ```
    
    See ``DatabaseReader/readPublisher(receiveOn:value:)``, and ``DatabaseWriter/writePublisher(receiveOn:updates:)``.
    
    Those publishers do not access the database until they are subscribed. They complete on the main dispatch queue by default.

- **RxSwift observables**
    
    See the companion library [RxGRDB].

- **Completion blocks**

    See ``DatabaseReader/asyncRead(_:)`` and ``DatabaseWriter/asyncWrite(_:completion:)``.

During one async access, all individual database operations grouped inside (fetch, insert, etc.) are synchronous:

```swift
// One asynchronous access...
try await dbQueue.write { db in
    // ... always performs synchronous database operations:
    try Player(...).insert(db)
    try Player(...).insert(db)
    let players = try Player.fetchAll(db)
}
```

This is true for all async techniques.

This prevents the database operations from various concurrent accesses from being interleaved. For example, one access must not be able to issue a `COMMIT` statement in the middle of an unfinished concurrent write!

## Safe and Unsafe Database Accesses

**You will generally use the safe database access methods `read` and `write`.** In this context, "safe" means that a database access is concurrency-friendly, because GRDB provides the following guarantees:

#### Serialized Writes

**All writes performed by one ``DatabaseQueue`` or ``DatabasePool`` instance are serialized.**

This guarantee prevents [`SQLITE_BUSY`] errors during concurrent writes.

#### Write Transactions

**All writes are wrapped in a transaction.**

Concurrent reads can not see partial database updates (even reads performed by other processes).

#### Isolated Reads

**All reads are wrapped in a transaction.**

An isolated read sees a stable and immutable state of the database, and does not see changes performed by eventual concurrent writes (even writes performed by other processes). See [Isolation In SQLite](https://www.sqlite.org/isolation.html) for more information.

#### Forbidden Writes

**Inside a read access, all attempts to write raise an error.**

This enforces the immutability of the database during a read.

#### Non-Reentrancy

**Database accesses methods are not reentrant.**

This reduces the opportunities for deadlocks, and fosters the clear transaction boundaries of <doc:Concurrency#Rule-2:-Mind-your-transactions>.

### Unsafe Database Accesses

Some applications need to relax this safety net, in order to achieve specific SQLite operations. In this case, replace `read` and `write` with one of the methods below:

- **Write outside of any transaction** (Lifted guarantee: <doc:Concurrency#Write-Transactions>)
    
    See all ``DatabaseWriter`` methods with `WithoutTransaction` in their names.
    
- **Reentrant write, outside of any transaction** (Lifted guarantees: <doc:Concurrency#Write-Transactions>, <doc:Concurrency#Non-Reentrancy>)
    
    See ``DatabaseWriter/unsafeReentrantWrite(_:)``.
    
- **Read outside of any transaction** (Lifted guarantees: <doc:Concurrency#Isolated-Reads>, <doc:Concurrency#Forbidden-Writes>)
    
    See all ``DatabaseReader`` methods with `unsafe` in their names.

- **Reentrant read, outside of any transaction** (Lifted guarantees: <doc:Concurrency#Isolated-Reads>, <doc:Concurrency#Forbidden-Writes>, <doc:Concurrency#Non-Reentrancy>)
    
    See ``DatabaseReader/unsafeReentrantRead(_:)``.

> Important: By using one of the methods above, you become responsible of the thread-safety of your application. Please understand the consequences of lifting each concurrency guarantee.

Some concurrency guarantees can be restored at your convenience:

- The <doc:Concurrency#Write-Transactions> and <doc:Concurrency#Isolated-Reads> guarantees can be restored at any point, with an explicit transaction or savepoint. For example:
    
    ```swift
    try dbQueue.writeWithoutTransaction { db in
        try db.inTransaction { ... }
    }
    ```
    
- The <doc:Concurrency#Forbidden-Writes> guarantee can only be lifted with ``DatabaseQueue``. It can be restored with [`PRAGMA query_only`](https://www.sqlite.org/pragma.html#pragma_query_only).

## Differences between Database Queues and Pools

Despite the common guarantees and rules shared by database queues and pools, those two database accessors don't have the same behavior.

``DatabaseQueue`` opens a single database connection, and serializes all database accesses, reads, and writes. There is never more than one thread that uses the database. In the image below, we see how three threads can see the database as time passes:

![DatabaseQueue Scheduling](DatabaseQueueScheduling.png)

``DatabasePool`` manages a pool of several database connections, and allows concurrent reads and writes thanks to the [WAL mode](https://www.sqlite.org/wal.html). A database pool serializes all writes (the <doc:Concurrency#Serialized-Writes> guarantee). Reads are isolated so that they don't see changes performed by other threads (the <doc:Concurrency#Isolated-Reads> guarantee). This gives a very different picture:

![DatabasePool Scheduling](DatabasePoolScheduling.png)

See how, with database pools, two reads can see different database states at the same time. This may look scary! Please see the next chapter below for a relief.

## Concurrent Thinking

Despite the <doc:Concurrency#Differences-between-Database-Queues-and-Pools>, you can write robust code that works equally well with both `DatabaseQueue` and `DatabasePool`.

This allows your app to switch between queues and pools, at your convenience:

- The [demo applications] share the same database code for the on-disk pool that feeds the app, and the in-memory queue that feeds tests and SwiftUI previews. This makes sure tests and previews run fast, without any temporary file, with the same behavior as the app.

- Applications that perform slow write transactions (when saving a lot of data from a remote server, for example) may want to replace their queue with a pool so that the reads that feed their user interface can run in parallel.

All you need is a little "concurrent thinking", based on those two basic facts:

- You are sure, when you perform a write access, that you deal with the latest database state on disk. This is enforced by SQLite, which simply can't perform parallel writes, and by the <doc:Concurrency#Serialized-Writes> guarantee. Writes performed by other processes can trigger an [`SQLITE_BUSY`] ``DatabaseError`` that you can handle.

- Whenever you extract some data from a database access, immediately consider it as _stale_. It is stale, whether you use a `DatabaseQueue` or `DatabasePool`. It is stale because nothing prevents other application threads or processes from overwriting the value you have just fetched:
    
    ```swift
    // or dbQueue.write, for that matter
    let cookieCount = dbPool.read { db in
        try Cookie.fetchCount(db)
    }
    
    // At this point, the number of cookies on disk
    // may have already changed.
    print("We have \(cookieCount) cookies left")
    ```
    
    Does this mean you can't rely on anything? Of course not:
    
    - If you intend to display some database value on screen, use ``ValueObservation``: it always eventually notifies the latest state of the database. Your application won't display stale values for a long time: after the database has been changed on disk, the fresh value if fetched, and soon notified on the main thread where the screen can be updated.
    
    - As said above, the moment of truth is the next write access!

## Advanced DatabasePool

``DatabasePool`` is very concurrent, since all reads can run in parallel, and can even run during write operations. But writes are still serialized: at any given point in time, there is no more than a single thread that is writing into the database.

When your application modifies the database, and then reads some value that depends on those modifications, you may want to avoid blocking concurrent writes longer than necessary - especially when the read is slow:

```swift
let newPlayerCount = try dbPool.write { db in
    // Increment the number of players
    try Player(...).insert(db)
    
    // Read the number of players. Concurrent writes are blocked :-(
    return try Player.fetchCount(db)
}
```

🔀 The solution is ``DatabasePool/asyncConcurrentRead(_:)``. It must be called from within a write access, outside of any transaction:

```swift
try dbPool.writeWithoutTransaction { db in
    // Increment the number of players
    try db.inTransaction {
        try Player(...).insert(db)
        return .commit
    }
    
    // <- Not in a transaction here
    dbPool.asyncConcurrentRead { dbResult in
        do {
            // Handle the new player count - guaranteed greater than zero
            let db = try dbResult.get()
            let newPlayerCount = try Player.fetchCount(db)
        } catch {
            // Handle error
        }
    }
}
```

The ``DatabasePool/asyncConcurrentRead(_:)`` method blocks until it can guarantee its closure argument an isolated access to the database, in the exact state left by the last transaction. It then asynchronously executes the closure.

In the illustration below, the striped band shows the delay needed for the reading thread to acquire isolation. Until then, no other thread can write:

![DatabasePool Concurrent Read](DatabasePoolConcurrentRead.png)

Types that conform to ``TransactionObserver`` can also use those methods in their ``TransactionObserver/databaseDidCommit(_:)`` method, in order to process database changes without blocking other threads that want to write into the database.

## Topics

### Database Connections with Concurrency Guarantees

- ``DatabaseWriter``
- ``DatabaseReader``
- ``DatabaseSnapshotReader``

### Going Further

- <doc:SwiftConcurrency>
- <doc:DatabaseSharing>


[demo apps]: https://github.com/groue/GRDB.swift/tree/master/Documentation/DemoApps
[`SQLITE_BUSY`]: https://www.sqlite.org/rescode.html#busy
[RxGRDB]: https://github.com/RxSwiftCommunity/RxGRDB
[demo applications]: https://github.com/groue/GRDB.swift/tree/master/Documentation/DemoApps



---
File: /GRDB/Documentation.docc/DatabaseConnections.md
---

# Database Connections

Open database connections to SQLite databases. 

## Overview

GRDB provides two classes for accessing SQLite databases: ``DatabaseQueue`` and ``DatabasePool``:

```swift
import GRDB

// Pick one:
let dbQueue = try DatabaseQueue(path: "/path/to/database.sqlite")
let dbPool = try DatabasePool(path: "/path/to/database.sqlite")
```

The differences are:

- `DatabasePool` allows concurrent database accesses (this can improve the performance of multithreaded applications).
- `DatabasePool` opens your SQLite database in the [WAL mode](https://www.sqlite.org/wal.html).
- `DatabaseQueue` supports <doc:DatabaseQueue#In-Memory-Databases>.

**If you are not sure, choose `DatabaseQueue`.** You will always be able to switch to `DatabasePool` later.

## Opening a Connection

You need a path to a database file in order to open a database connection.

**When the SQLite file is ready-made, and you do not intend to modify its content**, then add the database file as a [resource of your Xcode project or Swift package](https://developer.apple.com/documentation/xcode), and open a read-only database connection:

```swift
// HOW TO open a read-only connection to a database resource

// Get the path to the database resource.
// Replace `Bundle.main` with `Bundle.module` when you write a Swift Package.
if let dbPath = Bundle.main.path(forResource: "db", ofType: "sqlite")

if let dbPath {
    // If the resource exists, open a read-only connection.
    // Writes are disallowed because resources can not be modified. 
    var config = Configuration()
    config.readonly = true
    let dbQueue = try DatabaseQueue(path: dbPath, configuration: config)
} else {
    // The database resource can not be found.
    // Fix your setup, or report the problem to the user. 
}
```

**If the application creates or writes in the database**, then first choose a proper location for the database file. Document-based applications will let the user pick a location. Apps that use the database as a global storage will prefer the Application Support directory.

> Tip: Regardless of the database location, it is recommended that you wrap the database file inside a dedicated directory. This directory will bundle the main database file and its related [SQLite temporary files](https://www.sqlite.org/tempfiles.html) together.
>
> The dedicated directory helps moving or deleting the whole database when needed: just move or delete the directory.
>
> On iOS, the directory can be encrypted with [data protection](https://developer.apple.com/documentation/uikit/protecting_the_user_s_privacy/encrypting_your_app_s_files), in order to help securing all database files in one shot. When a database is protected, an application that runs in the background on a locked device won't be able to read or write from it. Instead, it will catch ``DatabaseError`` with code [`SQLITE_IOERR`](https://www.sqlite.org/rescode.html#ioerr) (10) "disk I/O error", or [`SQLITE_AUTH`](https://www.sqlite.org/rescode.html#auth) (23) "not authorized".

The sample code below creates or opens a database file inside its dedicated directory. On the first run, a new empty database file is created. On subsequent runs, the directory and database file already exist, so it just opens a connection:

```swift
// HOW TO create an empty database, or open an existing database file

// Create the "Application Support/MyDatabase" directory if needed
let fileManager = FileManager.default
let appSupportURL = try fileManager.url(
    for: .applicationSupportDirectory, in: .userDomainMask,
    appropriateFor: nil, create: true) 
let directoryURL = appSupportURL.appendingPathComponent("MyDatabase", isDirectory: true)
try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

// Open or create the database
let databaseURL = directoryURL.appendingPathComponent("db.sqlite")
let dbQueue = try DatabaseQueue(path: databaseURL.path)
```

## Closing Connections

Database connections are automatically closed when ``DatabaseQueue`` or ``DatabasePool`` instances are deinitialized.

If the correct execution of your program depends on precise database closing, perform an explicit call to ``DatabaseReader/close()``. This method may fail and create zombie connections, so please check its detailed documentation.


## Next Steps

Once connected to the database, your next steps are probably:

- Define the structure of newly created databases: see <doc:Migrations>.
- If you intend to write SQL, see <doc:SQLSupport>. Otherwise, see <doc:QueryInterface>.

Even if you plan to keep your project mundane and simple, take the time to read the <doc:Concurrency> guide eventually.

## Topics

### Configuring database connections

- ``Configuration``

### Connections for read and write accesses

- ``DatabaseQueue``
- ``DatabasePool``

### Read-only connections on an unchanging database content

- ``DatabaseSnapshot``
- ``DatabaseSnapshotPool``

### Using database connections

- ``Database``
- ``DatabaseError``



---
File: /GRDB/Documentation.docc/DatabaseObservation.md
---

# Database Observation

Observe database changes and transactions.

## Overview

**SQLite notifies its host application of changes performed to the database, as well of transaction commits and rollbacks.**

GRDB puts this SQLite feature to some good use, and lets you observe the database in various ways:

- ``ValueObservation``: Get notified when database values change.
- ``DatabaseRegionObservation``: Get notified when a transaction impacts a database region.
- ``Database/afterNextTransaction(onCommit:onRollback:)``: Handle transactions commits or rollbacks, one by one.
- ``TransactionObserver``: The low-level protocol that supports all database observation features.

## Topics

### Observing Database Values

- ``ValueObservation``
- ``SharedValueObservation``
- ``AsyncValueObservation``
- ``Database/registerAccess(to:)``

### Observing Database Transactions

- ``DatabaseRegionObservation``
- ``Database/afterNextTransaction(onCommit:onRollback:)``

### Low-Level Transaction Observers

- ``TransactionObserver``
- ``Database/add(transactionObserver:extent:)``
- ``Database/remove(transactionObserver:)``
- ``DatabaseWriter/add(transactionObserver:extent:)``
- ``DatabaseWriter/remove(transactionObserver:)``
- ``Database/TransactionObservationExtent``

### Database Regions

- ``DatabaseRegion``
- ``DatabaseRegionConvertible``



---
File: /GRDB/Documentation.docc/DatabaseSchema.md
---

# The Database Schema

Define or query the database schema.

## Overview

**GRDB supports all database schemas, and has no requirement.** Any existing SQLite database can be opened, and you are free to structure your new databases as you wish.

You perform modifications to the database schema with methods such as ``Database/create(table:options:body:)``, listed in <doc:DatabaseSchemaModifications>. For example:

```swift
try db.create(table: "player") { t in
    t.autoIncrementedPrimaryKey("id")
    t.column("name", .text).notNull()
    t.column("score", .integer).notNull()
}
```

Most applications modify the database schema as new versions ship: it is recommended to wrap all schema changes in <doc:Migrations>.

## Topics

### Define the database schema

- <doc:DatabaseSchemaModifications>
- <doc:DatabaseSchemaRecommendations>

### Introspect the database schema

- <doc:DatabaseSchemaIntrospection>

### Check the database schema

- <doc:DatabaseSchemaIntegrityChecks>



---
File: /GRDB/Documentation.docc/DatabaseSchemaIntegrityChecks.md
---

# Integrity Checks

Perform integrity checks of the database content

## Topics

### Integrity Checks

- ``Database/checkForeignKeys()``
- ``Database/checkForeignKeys(in:in:)``
- ``Database/foreignKeyViolations()``
- ``Database/foreignKeyViolations(in:in:)``
- ``ForeignKeyViolation``



---
File: /GRDB/Documentation.docc/DatabaseSchemaIntrospection.md
---

# Database Schema Introspection

Get information about schema objects such as tables, columns, indexes, foreign keys, etc.

## Topics

### Querying the Schema Version

- ``Database/schemaVersion()``

### Existence Checks

- ``Database/tableExists(_:in:)``
- ``Database/triggerExists(_:in:)``
- ``Database/viewExists(_:in:)``

### Table Structure

- ``Database/columns(in:in:)``
- ``Database/foreignKeys(on:in:)``
- ``Database/indexes(on:in:)``
- ``Database/primaryKey(_:in:)``
- ``Database/table(_:hasUniqueKey:)``

### Reserved Tables

- ``Database/isGRDBInternalTable(_:)``
- ``Database/isSQLiteInternalTable(_:)``

### Supporting Types

- ``ColumnInfo``
- ``ForeignKeyInfo``
- ``IndexInfo``
- ``PrimaryKeyInfo``



---
File: /GRDB/Documentation.docc/DatabaseSchemaModifications.md
---

# Modifying the Database Schema

How to modify the database schema

## Overview

For modifying the database schema, prefer Swift methods over raw SQL queries. They allow the compiler to check if a schema change is available on the target operating system. Only use a raw SQL query when no Swift method exist (when creating triggers, for example).

When a schema change is not directly supported by SQLite, or not available on the target operating system, database tables have to be recreated. See <doc:Migrations> for the detailed procedure.

## Create Tables

The ``Database/create(table:options:body:)`` method covers nearly all SQLite table creation features. For virtual tables, see [Full-Text Search](https://github.com/groue/GRDB.swift/blob/master/Documentation/FullTextSearch.md), or use raw SQL.

```swift
// CREATE TABLE place (
//   id INTEGER PRIMARY KEY AUTOINCREMENT,
//   title TEXT,
//   favorite BOOLEAN NOT NULL DEFAULT 0,
//   latitude DOUBLE NOT NULL,
//   longitude DOUBLE NOT NULL
// )
try db.create(table: "place") { t in
    t.autoIncrementedPrimaryKey("id")
    t.column("title", .text)
    t.column("favorite", .boolean).notNull().defaults(to: false)
    t.column("longitude", .double).notNull()
    t.column("latitude", .double).notNull()
}
```

**Configure table creation**

```swift
// CREATE TABLE player ( ... )
try db.create(table: "player") { t in ... }
    
// CREATE TEMPORARY TABLE player IF NOT EXISTS (
try db.create(table: "player", options: [.temporary, .ifNotExists]) { t in ... }
```

Reference: ``TableOptions``

**Add regular columns** with their name and eventual type (`text`, `integer`, `double`, `real`, `numeric`, `boolean`, `blob`, `date`, `datetime`, `any`, and `json`) - see [SQLite data types](https://www.sqlite.org/datatype3.html) and <doc:JSON>:

```swift
// CREATE TABLE player (
//   score,
//   name TEXT,
//   creationDate DATETIME,
//   address TEXT,
try db.create(table: "player") { t in
    t.column("score")
    t.column("name", .text)
    t.column("creationDate", .datetime)
    t.column("address", .json)
```

Reference: ``TableDefinition/column(_:_:)``

Define **not null** columns, and set **default values**:

```swift
    // email TEXT NOT NULL,
    t.column("email", .text).notNull()
    
    // name TEXT NOT NULL DEFAULT 'Anonymous',
    t.column("name", .text).notNull().defaults(to: "Anonymous")
```

Reference: ``ColumnDefinition``

**Define primary, unique, or foreign keys**. When defining a foreign key, the referenced column is the primary key of the referenced table (unless you specify otherwise):

```swift
    // id INTEGER PRIMARY KEY AUTOINCREMENT,
    t.autoIncrementedPrimaryKey("id")

    // uuid TEXT PRIMARY KEY NOT NULL,
    t.primaryKey("uuid", .text)

    // teamName TEXT NOT NULL,
    // position INTEGER NOT NULL,
    // PRIMARY KEY (teamName, position),
    t.primaryKey {
        t.column("teamName", .text)
        t.column("position", .integer)
    }

    // email TEXT UNIQUE,
    t.column("email", .text).unique()

    // teamId TEXT REFERENCES team(id) ON DELETE CASCADE,
    // countryCode TEXT REFERENCES country(code) NOT NULL,
    t.belongsTo("team", onDelete: .cascade)
    t.belongsTo("country").notNull()
```

Reference: ``TableDefinition``, ``ColumnDefinition/unique(onConflict:)``

**Create an index** on a column

```swift
    t.column("score", .integer).indexed()
```

Reference: ``ColumnDefinition``

For extra index options, see <doc:DatabaseSchemaModifications#Create-Indexes> below.

**Perform integrity checks** on individual columns, and SQLite will only let conforming rows in. In the example below, the `$0` closure variable is a column which lets you build any SQL expression.

```swift
    // name TEXT CHECK (LENGTH(name) > 0)
    // score INTEGER CHECK (score > 0)
    t.column("name", .text).check { length($0) > 0 }
    t.column("score", .integer).check(sql: "score > 0")
```

Reference: ``ColumnDefinition``

Columns can also be defined with a raw sql String, or an [SQL literal](https://github.com/groue/GRDB.swift/blob/master/Documentation/SQLInterpolation.md#sql-literal) in which you can safely embed raw values without any risk of syntax errors or SQL injection:

```swift
    t.column(sql: "name TEXT")
    
    let defaultName: String = ...
    t.column(literal: "name TEXT DEFAULT \(defaultName)")
```

Reference: ``TableDefinition``

Other **table constraints** can involve several columns:

```swift
    // PRIMARY KEY (a, b),
    t.primaryKey(["a", "b"])
    
    // UNIQUE (a, b) ON CONFLICT REPLACE,
    t.uniqueKey(["a", "b"], onConflict: .replace)
    
    // FOREIGN KEY (a, b) REFERENCES parents(c, d),
    t.foreignKey(["a", "b"], references: "parents")
    
    // CHECK (a + b < 10),
    t.check(Column("a") + Column("b") < 10)
    
    // CHECK (a + b < 10)
    t.check(sql: "a + b < 10")
    
    // Raw SQL constraints
    t.constraint(sql: "CHECK (a + b < 10)")
    t.constraint(literal: "CHECK (a + b < \(10))")
```

Reference: ``TableDefinition``

**Generated columns**:

```swift
    t.column("totalScore", .integer).generatedAs(sql: "score + bonus")
    t.column("totalScore", .integer).generatedAs(Column("score") + Column("bonus"))
}
```

Reference: ``ColumnDefinition``

## Modify Tables

SQLite lets you modify existing tables:

```swift
// ALTER TABLE referer RENAME TO referrer
try db.rename(table: "referer", to: "referrer")

// ALTER TABLE player ADD COLUMN hasBonus BOOLEAN
// ALTER TABLE player RENAME COLUMN url TO homeURL
// ALTER TABLE player DROP COLUMN score
try db.alter(table: "player") { t in
    t.add(column: "hasBonus", .boolean)
    t.rename(column: "url", to: "homeURL")
    t.drop(column: "score")
}
```

Reference: ``TableAlteration``

> Note: SQLite restricts the possible table alterations, and may require you to recreate dependent triggers or views. See <doc:Migrations#Defining-the-Database-Schema-from-a-Migration> for more information.

## Drop Tables

Drop tables with the ``Database/drop(table:)`` method:

```swift
try db.drop(table: "obsolete")
```

## Create Indexes

Create an index on a column:

```swift
try db.create(table: "player") { t in
    t.column("email", .text).unique()
    t.column("score", .integer).indexed()
}
```

Create indexes on an existing table:

```swift
// CREATE INDEX index_player_on_email ON player(email)
try db.create(indexOn: "player", columns: ["email"])

// CREATE UNIQUE INDEX index_player_on_email ON player(email)
try db.create(indexOn: "player", columns: ["email"], options: .unique)
```

Create indexes with a specific collation:

```swift
// CREATE INDEX index_player_on_email ON player(email COLLATE NOCASE)
try db.create(
    index: "index_player_on_email",
    on: "player",
    expressions: [Column("email").collating(.nocase)])
```

Create indexes on expressions:

```swift
// CREATE INDEX index_player_on_total_score ON player(score+bonus)
try db.create(
    index: "index_player_on_total_score",
    on: "player",
    expressions: [Column("score") + Column("bonus")])

// CREATE INDEX index_player_on_country ON player(address ->> 'country')
try db.create(
    index: "index_player_on_country",
    on: "player",
    expressions: [
        JSONColumn("address")["country"],
    ])
```

Unique constraints and unique indexes are somewhat different: don't miss the tip in <doc:DatabaseSchemaRecommendations/Unique-keys-should-be-supported-by-unique-indexes> below.

## Topics

### Database Tables

- ``Database/alter(table:body:)``
- ``Database/create(table:options:body:)``
- ``Database/create(virtualTable:options:using:)``
- ``Database/create(virtualTable:options:using:_:)``
- ``Database/drop(table:)``
- ``Database/dropFTS4SynchronizationTriggers(forTable:)``
- ``Database/dropFTS5SynchronizationTriggers(forTable:)``
- ``Database/rename(table:to:)``
- ``Database/ColumnType``
- ``Database/ConflictResolution``
- ``Database/ForeignKeyAction``
- ``TableAlteration``
- ``TableDefinition``
- ``TableOptions``
- ``VirtualTableModule``
- ``VirtualTableOptions``

### Database Views

- ``Database/create(view:options:columns:as:)``
- ``Database/create(view:options:columns:asLiteral:)``
- ``Database/drop(view:)``
- ``ViewOptions``

### Database Indexes

- ``Database/create(indexOn:columns:options:condition:)``
- ``Database/create(index:on:columns:options:condition:)``
- ``Database/create(index:on:expressions:options:condition:)``
- ``Database/drop(indexOn:columns:)``
- ``Database/drop(index:)``
- ``IndexOptions``

### Sunsetted Methods

Those are legacy interfaces that are preserved for backwards compatibility. Their use is not recommended.

- ``Database/create(index:on:columns:unique:ifNotExists:condition:)``
- ``Database/create(table:temporary:ifNotExists:withoutRowID:body:)``
- ``Database/create(virtualTable:ifNotExists:using:)``
- ``Database/create(virtualTable:ifNotExists:using:_:)``



---
File: /GRDB/Documentation.docc/DatabaseSchemaRecommendations.md
---

# Database Schema Recommendations

Recommendations for an ideal integration of the database schema with GRDB

## Overview

Even though all schema are supported, some features of the library and of the Swift language are easier to use when the schema follows a few conventions described below.

When those conventions are not applied, or not applicable, you will have to perform extra configurations.

For recommendations specific to JSON columns, see <doc:JSON>.

## Table names should be English, singular, and camelCased

Make them look like singular Swift identifiers: `player`, `team`, `postalAddress`:

```swift
// RECOMMENDED
try db.create(table: "player") { t in
    // table columns and constraints
}

// REQUIRES EXTRA CONFIGURATION
try db.create(table: "players") { t in
    // table columns and constraints
}
```

☝️ **If table names follow a different naming convention**, record types (see <doc:QueryInterface>) will need explicit table names:

```swift
extension Player: TableRecord {
    // Required because table name is not 'player'
    static let databaseTableName = "players"
}

extension PostalAddress: TableRecord {
    // Required because table name is not 'postalAddress'
    static let databaseTableName = "postal_address"
}

extension Award: TableRecord {
    // Required because table name is not 'award'
    static let databaseTableName = "Auszeichnung"
}
```

[Associations](https://github.com/groue/GRDB.swift/blob/master/Documentation/AssociationsBasics.md) will need explicit keys as well:

```swift
extension Player: TableRecord {
    // Explicit association key because the table name is not 'postalAddress'   
    static let postalAddress = belongsTo(PostalAddress.self, key: "postalAddress")

    // Explicit association key because the table name is not 'award'
    static let awards = hasMany(Award.self, key: "awards")
}
```

As in the above example, make sure to-one associations use singular keys, and to-many associations use plural keys.

## Column names should be camelCased

Again, make them look like Swift identifiers: `fullName`, `score`, `creationDate`:

```swift
// RECOMMENDED
try db.create(table: "player") { t in
    t.autoIncrementedPrimaryKey("id")
    t.column("fullName", .text).notNull()
    t.column("score", .integer).notNull()
    t.column("creationDate", .datetime).notNull()
}

// REQUIRES EXTRA CONFIGURATION
try db.create(table: "player") { t in
    t.autoIncrementedPrimaryKey("id")
    t.column("full_name", .text).notNull()
    t.column("score", .integer).notNull()
    t.column("creation_date", .datetime).notNull()
}
```

☝️ **If the column names follow a different naming convention**, `Codable` record types will need an explicit `CodingKeys` enum:

```swift
struct Player: Decodable, FetchableRecord {
    var id: Int64
    var fullName: String
    var score: Int
    var creationDate: Date

    // Required CodingKeys customization because 
    // columns are not named like Swift properties
    enum CodingKeys: String, CodingKey {
        case id, fullName = "full_name", score, creationDate = "creation_date"
    }
}
```

## Tables should have explicit primary keys

A primary key uniquely identifies a row in a table. It is defined on one or several columns:

```swift
// RECOMMENDED
try db.create(table: "player") { t in
    // Auto-incremented primary key
    t.autoIncrementedPrimaryKey("id")
    t.column("name", .text).notNull()
}

try db.create(table: "team") { t in
    // Single-column primary key
    t.primaryKey("id", .text)
    t.column("name", .text).notNull()
}

try db.create(table: "membership") { t in
    // Composite primary key
    t.primaryKey {
        t.belongsTo("player")
        t.belongsTo("team")
    }
    t.column("role", .text).notNull()
}
```

Primary keys support record fetching methods such as ``FetchableRecord/fetchOne(_:id:)``, and persistence methods such as ``MutablePersistableRecord/update(_:onConflict:)`` or ``MutablePersistableRecord/delete(_:)``.

See <doc:SingleRowTables> when you need to define a table that contains a single row.

☝️ **If the database table does not define any explicit primary key**, identifying specific rows in this table needs explicit support for the [hidden `rowid` column](https://www.sqlite.org/rowidtable.html) in the matching record types:

```swift
// A table without any explicit primary key
try db.create(table: "player") { t in
    t.column("name", .text).notNull()
    t.column("score", .integer).notNull()
}

// The record type for the 'player' table'
struct Player: Codable {
    // Uniquely identifies a player.
    var rowid: Int64?
    var name: String
    var score: Int
}

extension Player: FetchableRecord, MutablePersistableRecord {
    // Required because the primary key
    // is the hidden rowid column.
    static var databaseSelection: [any SQLSelectable] {
        [.allColumns, .rowID]
    }

    // Update id upon successful insertion
    mutating func didInsert(_ inserted: InsertionSuccess) {
        rowid = inserted.rowID
    }
}

try dbQueue.read { db in
    // SELECT *, rowid FROM player WHERE rowid = 1
    if let player = try Player.fetchOne(db, id: 1) {
        // DELETE FROM player WHERE rowid = 1
        let deleted = try player.delete(db)
        print(deleted) // true
    }
}
```

## Single-column primary keys should be named 'id'

This helps record types play well with the standard `Identifiable` protocol.

```swift
// RECOMMENDED
try db.create(table: "player") { t in
    t.primaryKey("id", .text)
    t.column("name", .text).notNull()
}

// REQUIRES EXTRA CONFIGURATION
try db.create(table: "player") { t in
    t.primaryKey("uuid", .text)
    t.column("name", .text).notNull()
}
```
☝️ **If the primary key follows a different naming convention**, `Identifiable` record types will need a custom `CodingKeys` enum, or an extra property:

```swift
// Custom coding keys
struct Player: Codable, Identifiable {
    var id: String
    var name: String

    // Required CodingKeys customization because 
    // columns are not named like Swift properties
    enum CodingKeys: String, CodingKey {
        case id = "uuid", name
    }
}

// Extra property
struct Player: Identifiable {
    var uuid: String
    var name: String
    
    // Required because the primary key column is not 'id'
    var id: String { uuid }
}
```

## Unique keys should be supported by unique indexes

Unique indexes makes sure SQLite prevents the insertion of conflicting rows:

```swift
// RECOMMENDED
try db.create(table: "player") { t in
    t.autoIncrementedPrimaryKey("id")
    t.belongsTo("team").notNull()
    t.column("position", .integer).notNull()
    // Players must have distinct names
    t.column("name", .text).unique()
}

// One single player at any given position in a team
try db.create(
    indexOn: "player",
    columns: ["teamId", "position"],
    options: .unique)
```

> Tip: SQLite does not support deferred unique indexes, and this creates undesired churn when you need to temporarily break them. This may happen, for example, when you want to reorder player positions in our above example.
>
> There exist several workarounds; one of them involves dropping and recreating the unique index after the temporary violations have been fixed. If you plan to use this technique, take care that only actual indexes can be dropped. Unique constraints created inside the table body can not:
>
> ```swift
> // Unique constraint on player(name) can not be dropped.
> try db.create(table: "player") { t in
>     t.column("name", .text).unique()
> }
>
> // Unique index on team(name) can be dropped.
> try db.create(table: "team") { t in
>     t.column("name", .text)
> }
> try db.create(indexOn: "team", columns: ["name"], options: .unique)
> ```
>
> If you want to turn an undroppable constraint into a droppable index, you'll need to recreate the database table. See <doc:Migrations> for the detailed procedure.

☝️ **If a table misses unique indexes**, some record methods such as ``FetchableRecord/fetchOne(_:key:)-92b9m`` and ``TableRecord/deleteOne(_:key:)-5pdh5`` will raise a fatal error:

```swift
try dbQueue.write { db in
    // Fatal error: table player has no unique index on columns ...
    let player = try Player.fetchOne(db, key: ["teamId": 42, "position": 1])
    try Player.deleteOne(db, key: ["name": "Arthur"])
    
    // Use instead:
    let player = try Player
        .filter { $0.teamId == 42 && $0.position == 1 }
        .fetchOne(db)

    try Player
        .filter { $0.name == "Arthur" }
        .deleteAll(db)
}
```

## Relations between tables should be supported by foreign keys

[Foreign Keys](https://www.sqlite.org/foreignkeys.html) have SQLite enforce valid relationships between tables:

```swift
try db.create(table: "team") { t in
    t.autoIncrementedPrimaryKey("id")
    t.column("color", .text).notNull()
}

// RECOMMENDED
try db.create(table: "player") { t in
    t.autoIncrementedPrimaryKey("id")
    t.column("name", .text).notNull()
    // A player must refer to an existing team
    t.belongsTo("team").notNull()
}

// REQUIRES EXTRA CONFIGURATION
try db.create(table: "player") { t in
    t.autoIncrementedPrimaryKey("id")
    t.column("name", .text).notNull()
    // No foreign key
    t.column("teamId", .integer).notNull()
}
```

See ``TableDefinition/belongsTo(_:inTable:onDelete:onUpdate:deferred:indexed:)`` for more information about the creation of foreign keys.

GRDB [Associations](https://github.com/groue/GRDB.swift/blob/master/Documentation/AssociationsBasics.md) are automatically configured from foreign keys declared in the database schema:

```swift
extension Player: TableRecord {
    static let team = belongsTo(Team.self)
}

extension Team: TableRecord {
    static let players = hasMany(Player.self)
}
```

See [Associations and the Database Schema](https://github.com/groue/GRDB.swift/blob/master/Documentation/AssociationsBasics.md#associations-and-the-database-schema) for more precise recommendations.

☝️ **If a foreign key is not declared in the schema**, you will need to explicitly configure related associations:

```swift
extension Player: TableRecord {
    // Required configuration because the database does
    // not declare any foreign key from players to their team.
    static let teamForeignKey = ForeignKey(["teamId"])
    static let team = belongsTo(Team.self,
                                using: teamForeignKey)
}

extension Team: TableRecord {
    // Required configuration because the database does
    // not declare any foreign key from players to their team.
    static let players = hasMany(Player.self,
                                 using: Player.teamForeignKey)
}
```



---
File: /GRDB/Documentation.docc/DatabaseSharing.md
---

# Sharing a Database

How to share an SQLite database between multiple processes • Recommendations for App Group containers, App Extensions, App Sandbox, and file coordination.

## Overview

**This guide describes a recommended setup that applies as soon as several processes want to access the same SQLite database.** It complements the <doc:Concurrency> guide, that you should read first.

On iOS for example, you can share database files between multiple processes by storing them in an [App Group Container](https://developer.apple.com/documentation/foundation/nsfilemanager/1412643-containerurlforsecurityapplicati). On macOS, several processes may want to open the same database, according to their particular sandboxing contexts.

Accessing a shared database from several SQLite connections, from several processes, creates challenges at various levels:

1. **Database setup** may be attempted by multiple processes, concurrently, with possible conflicts.
2. **SQLite** may throw [`SQLITE_BUSY`] errors, "database is locked".
3. **iOS** may kill your application with a [`0xDEAD10CC`] exception.
4. **GRDB** <doc:DatabaseObservation> does not detect changes performed by external processes.

We'll address all of those challenges below.

> Important: Preventing errors that may happen due to database sharing is difficult. It is extremely difficult on iOS. And it is almost impossible to test.
>
> Always consider sharing plain files, or any other inter-process communication technique, before sharing an SQLite database.

## Use the WAL mode

In order to access a shared database, use a ``DatabasePool``. It opens the database in the [WAL mode], which helps sharing a database because it allows multiple processes to access the database concurrently.

It is also possible to use a ``DatabaseQueue``, with the `.wal` ``Configuration/journalMode``.

Since several processes may open the database at the same time, protect the creation of the database connection with an [NSFileCoordinator].

- In a process that can create and write in the database, use this sample code:
    
    ```swift
    /// Returns an initialized database pool at the shared location databaseURL
    func openSharedDatabase(at databaseURL: URL) throws -> DatabasePool {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinatorError: NSError?
        var dbPool: DatabasePool?
        var dbError: Error?
        coordinator.coordinate(writingItemAt: databaseURL, options: .forMerging, error: &coordinatorError) { url in
            do {
                dbPool = try openDatabase(at: url)
            } catch {
                dbError = error
            }
        }
        if let error = dbError ?? coordinatorError {
            throw error
        }
        return dbPool!
    }
    
    private func openDatabase(at databaseURL: URL) throws -> DatabasePool {
        var configuration = Configuration()
        configuration.prepareDatabase { db in
            // Activate the persistent WAL mode so that
            // read-only processes can access the database.
            //
            // See https://www.sqlite.org/walformat.html#operations_that_require_locks_and_which_locks_those_operations_use
            // and https://www.sqlite.org/c3ref/c_fcntl_begin_atomic_write.html#sqlitefcntlpersistwal
            if db.configuration.readonly == false {
                var flag: CInt = 1
                let code = withUnsafeMutablePointer(to: &flag) { flagP in
                    sqlite3_file_control(db.sqliteConnection, nil, SQLITE_FCNTL_PERSIST_WAL, flagP)
                }
                guard code == SQLITE_OK else {
                    throw DatabaseError(resultCode: ResultCode(rawValue: code))
                }
            }
        }
        let dbPool = try DatabasePool(path: databaseURL.path, configuration: configuration)
        
        // Perform here other database setups, such as defining
        // the database schema with a DatabaseMigrator, and 
        // checking if the application can open the file:
        try migrator.migrate(dbPool)
        if try dbPool.read(migrator.hasBeenSuperseded) {
            // Database is too recent
            throw /* some error */
        }
        
        return dbPool
    }
    ```

- In a process that only reads in the database, use this sample code:
    
    ```swift
    /// Returns an initialized database pool at the shared location databaseURL,
    /// or nil if the database is not created yet, or does not have the required
    /// schema version.
    func openSharedReadOnlyDatabase(at databaseURL: URL) throws -> DatabasePool? {
        let coordinator = NSFileCoordinator(filePresenter: nil)
        var coordinatorError: NSError?
        var dbPool: DatabasePool?
        var dbError: Error?
        coordinator.coordinate(readingItemAt: databaseURL, options: .withoutChanges, error: &coordinatorError) { url in
            do {
                dbPool = try openReadOnlyDatabase(at: url)
            } catch {
                dbError = error
            }
        }
        if let error = dbError ?? coordinatorError {
            throw error
        }
        return dbPool
    }
    
    private func openReadOnlyDatabase(at databaseURL: URL) throws -> DatabasePool? {
        do {
            var configuration = Configuration()
            configuration.readonly = true
            let dbPool = try DatabasePool(path: databaseURL.path, configuration: configuration)
            
            // Check here if the database schema is the expected one,
            // for example with a DatabaseMigrator:
            return try dbPool.read { db in
                if try migrator.hasBeenSuperseded(db) {
                    // Database is too recent
                    return nil
                } else if try migrator.hasCompletedMigrations(db) == false {
                    // Database is too old
                    return nil
                }
                return dbPool
            }
        } catch {
            if FileManager.default.fileExists(atPath: databaseURL.path) {
                throw error
            } else {
                return nil
            }
        }
    }
    ```


#### The Specific Case of Read-Only Connections

Read-only connections will fail unless two extra files ending in `-shm` and `-wal` are present next to the database file ([source](https://www.sqlite.org/walformat.html#operations_that_require_locks_and_which_locks_those_operations_use)). Those files are regular companions of databases in the [WAL mode]. But they are deleted, under regular operations, when database connections are closed. Precisely speaking, they *may* be deleted: it depends on the SQLite and the operating system versions ([source](https://github.com/groue/GRDB.swift/issues/739#issuecomment-604363998)). And when they are deleted, read-only connections fail.

The solution is to enable the "persistent WAL mode", as shown in the sample code above, by setting the [SQLITE_FCNTL_PERSIST_WAL](https://www.sqlite.org/c3ref/c_fcntl_begin_atomic_write.html#sqlitefcntlpersistwal) flag. This mode makes sure the `-shm` and `-wal` files are never deleted, and guarantees a database access to read-only connections.


## How to limit the SQLITE_BUSY error

> SQLite Documentation: The [`SQLITE_BUSY`] result code indicates that the database file could not be written (or in some cases read) because of concurrent activity by some other database connection, usually a database connection in a separate process.

If several processes want to write in the database, configure the database pool of each process that wants to write:

```swift
var configuration = Configuration()
configuration.busyMode = .timeout(/* a TimeInterval */)
let dbPool = try DatabasePool(path: ..., configuration: configuration)
```

The busy timeout has write transactions wait, instead of throwing `SQLITE_BUSY`, whenever another process is writing. GRDB automatically opens all write transactions with the IMMEDIATE kind, preventing write transactions from overlapping.

With such a setup, you will still get `SQLITE_BUSY` errors if the database remains locked by another process for longer than the specified timeout. You can catch those errors:

```swift
do {
    try dbPool.write { db in ... }
} catch DatabaseError.SQLITE_BUSY {
    // Another process won't let you write. Deal with it.
}
```

## How to limit the 0xDEAD10CC exception

> Apple documentation: [`0xDEAD10CC`] (pronounced “dead lock”): the operating system terminated the app because it held on to a file lock or SQLite database lock during suspension.

#### If you use SQLCipher

Use SQLCipher 4+, and configure the database from ``Configuration/prepareDatabase(_:)``:

```swift
var configuration = Configuration()
configuration.prepareDatabase { (db: Database) in
    try db.usePassphrase("secret")
    try db.execute(sql: "PRAGMA cipher_plaintext_header_size = 32")
}
let dbPool = try DatabasePool(path: ..., configuration: configuration)
```

Applications become responsible for managing the salt themselves: see [instructions](https://www.zetetic.net/sqlcipher/sqlcipher-api/#cipher_plaintext_header_size). See also <https://github.com/sqlcipher/sqlcipher/issues/255> for more context and information.

#### In all cases

The technique described below is based on [this discussion](https://developer.apple.com/forums/thread/126438) on the Apple Developer Forums. It is [**🔥 EXPERIMENTAL**](https://github.com/groue/GRDB.swift/blob/master/README.md#what-are-experimental-features).

In each process that writes in the database, set the ``Configuration/observesSuspensionNotifications`` configuration flag:

```swift
var configuration = Configuration()
configuration.observesSuspensionNotifications = true
let dbPool = try DatabasePool(path: ..., configuration: configuration)
```

Post ``Database/suspendNotification`` when the application is about to be [suspended](https://developer.apple.com/documentation/uikit/app_and_environment/managing_your_app_s_life_cycle). You can for example post this notification from `UIApplicationDelegate.applicationDidEnterBackground(_:)`, or in the expiration handler of a [background task](https://forums.developer.apple.com/thread/85066):

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    func applicationDidEnterBackground(_ application: UIApplication) {
        NotificationCenter.default.post(name: Database.suspendNotification, object: self)
    }
}
```

Once suspended, a database won't acquire any new lock that could cause the `0xDEAD10CC` exception.

In exchange, you will get `SQLITE_INTERRUPT` (code 9) or `SQLITE_ABORT` (code 4) errors, with messages "Database is suspended", "Transaction was aborted", or "interrupted". You can catch those errors:

```swift
do {
    try dbPool.write { db in ... }
} catch DatabaseError.SQLITE_INTERRUPT, DatabaseError.SQLITE_ABORT {
    // Oops, the database is suspended.
    // Maybe try again after database is resumed?
}
```

Post ``Database/resumeNotification`` in order to resume suspended databases. You can safely post this notification when the app comes back to foreground.

In applications that use the background modes supported by iOS, post `resumeNotification` method from each and every background mode callback that may use the database, and don't forget to post `suspendNotification` again before the app turns suspended.

## How to perform cross-process database observation

<doc:DatabaseObservation> features are not able to detect database changes performed by other processes.

Whenever you need to notify other processes that the database has been changed, you will have to use a cross-process notification mechanism such as [NSFileCoordinator] or [CFNotificationCenterGetDarwinNotifyCenter]. You can trigger those notifications automatically with ``DatabaseRegionObservation``:

```swift
// Notify all changes made to the database
let observation = DatabaseRegionObservation(tracking: .fullDatabase)
let observer = try observation.start(in: dbPool) { db in
    // Notify other processes
}

// Notify changes made to the "player" and "team" tables only
let observation = DatabaseRegionObservation(tracking: Player.all(), Team.all())
let observer = try observation.start(in: dbPool) { db in
    // Notify other processes
}
```

The processes that observe the database can catch those notifications, and deal with the notified changes. See <doc:GRDB/TransactionObserver#Dealing-with-Undetected-Changes> for some related techniques.

[NSFileCoordinator]: https://developer.apple.com/documentation/foundation/nsfilecoordinator
[CFNotificationCenterGetDarwinNotifyCenter]: https://developer.apple.com/documentation/corefoundation/1542572-cfnotificationcentergetdarwinnot
[WAL mode]: https://www.sqlite.org/wal.html
[`SQLITE_BUSY`]: https://www.sqlite.org/rescode.html#busy
[`0xDEAD10CC`]: https://developer.apple.com/documentation/xcode/understanding-the-exception-types-in-a-crash-report



---
File: /GRDB/Documentation.docc/FullTextSearch.md
---

# Full-Text Search

Search a corpus of textual documents.

## Overview

Please refer to the [Full-Text Search](https://github.com/groue/GRDB.swift/blob/master/Documentation/FullTextSearch.md) guide. It also describes how to enable support for the FTS5 engine.

## Topics

### Full-Text Engines

- ``FTS3``
- ``FTS4``
- ``FTS5``



---
File: /GRDB/Documentation.docc/GRDB.md
---

# ``GRDB``

A toolkit for SQLite databases, with a focus on application development

##

![GRDB Logo](GRDBLogo.png)

## Overview

Use this library to save your application’s permanent data into SQLite databases. It comes with built-in tools that address common needs:

- **SQL Generation**
    
    Enhance your application models with persistence and fetching methods, so that you don't have to deal with SQL and raw database rows when you don't want to.

- **Database Observation**
    
    Get notifications when database values are modified. 

- **Robust Concurrency**
    
    Multi-threaded applications can efficiently use their databases, including WAL databases that support concurrent reads and writes. 

- **Migrations**
    
    Evolve the schema of your database as you ship new versions of your application.
    
- **Leverage your SQLite skills**

    Not all developers need advanced SQLite features. But when you do, GRDB is as sharp as you want it to be. Come with your SQL and SQLite skills, or learn new ones as you go!

## Usage

Start using the database in four steps:

```swift
import GRDB

// 1. Open a database connection
let dbQueue = try DatabaseQueue(path: "/path/to/database.sqlite")

// 2. Define the database schema
try dbQueue.write { db in
    try db.create(table: "player") { t in
        t.primaryKey("id", .text)
        t.column("name", .text).notNull()
        t.column("score", .integer).notNull()
    }
}

// 3. Define a record type
struct Player: Codable, FetchableRecord, PersistableRecord {
    var id: String
    var name: String
    var score: Int
}

// 4. Write and read in the database
try dbQueue.write { db in
    try Player(id: "1", name: "Arthur", score: 100).insert(db)
    try Player(id: "2", name: "Barbara", score: 1000).insert(db)
}

let players: [Player] = try dbQueue.read { db in
    try Player.fetchAll(db)
}
```

## Links and Companion Libraries

- [GitHub Repository](http://github.com/groue/GRDB.swift)
- [Installation Instructions, encryption with SQLCipher, custom SQLite builds](https://github.com/groue/GRDB.swift#installation)
- [GRDBQuery](https://github.com/groue/GRDBQuery): the SwiftUI companion for GRDB.
- [GRDBSnapshotTesting](https://github.com/groue/GRDBSnapshotTesting): Test your database.

## Topics

### Fundamentals

- <doc:DatabaseConnections>
- <doc:SQLSupport>
- <doc:Concurrency>
- <doc:Transactions>

### Migrations and The Database Schema

- <doc:DatabaseSchema>
- <doc:Migrations>

### Records and the Query Interface

- <doc:QueryInterface>
- <doc:RecordRecommendedPractices>
- <doc:RecordTimestamps>
- <doc:SingleRowTables>

### Application Tools

- <doc:DatabaseObservation>
- <doc:FullTextSearch>
- <doc:JSON>
- ``DatabasePublishers``



---
File: /GRDB/Documentation.docc/JSON.md
---

# JSON Support

Store and use JSON values in SQLite databases.

## Overview

SQLite and GRDB can store and fetch JSON values in database columns. Starting iOS 16+, macOS 10.15+, tvOS 17+, and watchOS 9+, JSON values can be manipulated at the database level.

## Store and fetch JSON values

### JSON columns in the database schema

It is recommended to store JSON values in text columns. In the example below, we create a ``Database/ColumnType/jsonText`` column with ``Database/create(table:options:body:)``:

```swift
try db.create(table: "player") { t in
    t.primaryKey("id", .text)
    t.column("name", .text).notNull()
    t.column("address", .jsonText).notNull() // A JSON column
}
```

> Note: `.jsonText` and `.text` are equivalent, because both build a TEXT column in SQL. Yet the former better describes the intent of the column.
>
> Note: SQLite JSON functions and operators are [documented](https://www.sqlite.org/json1.html#interface_overview) to throw errors if any of their arguments are binary blobs. That's the reason why it is recommended to store JSON as text.

> Tip: When an application performs queries on values embedded inside JSON columns, indexes can help performance:
>
> ```swift
> // CREATE INDEX player_on_country 
> // ON player(address ->> 'country')
> try db.create(
>     index: "player_on_country",
>     on: "player",
>     expressions: [
>         JSONColumn("address")["country"],
>     ])
>
> struct Player: FetchableRecord, TableRecord {
>     enum Columns {
>         static let address = JSONColumn("address") 
>     }
> }
>
> // SELECT * FROM player
> // WHERE address ->> 'country' = 'DE'
> let germanPlayers = try Player
>     .filter { $0.address["country"] == "DE" }
>     .fetchAll(db)
> ```

### Strict and flexible JSON schemas

[Codable Records](https://github.com/groue/GRDB.swift/blob/master/README.md#codable-records) handle both strict and flexible JSON schemas.

**For strict schemas**, use `Codable` properties. They will be stored as JSON strings in the database:

```swift
struct Address: Codable {
    var street: String
    var city: String
    var country: String
}

struct Player: Codable {
    var id: String
    var name: String

    // Stored as a JSON string
    // {"street": "...", "city": "...",  "country": "..."} 
    var address: Address
}

extension Player: FetchableRecord, PersistableRecord { }
```

**For flexible schemas**, use `String` or `Data` properties.

In the specific case of `Data` properties, it is recommended to store them as text in the database, because SQLite JSON functions and operators are [documented](https://www.sqlite.org/json1.html#interface_overview) to throw errors if any of their arguments are binary blobs. This encoding is automatic with ``DatabaseDataEncodingStrategy/text``:

```swift
// JSON String property
struct Player: Codable {
    var id: String
    var name: String
    var address: String // JSON string
}

extension Player: FetchableRecord, PersistableRecord { }

// JSON Data property, saved as text in the database
struct Team: Codable {
    var id: String
    var color: String
    var info: Data // JSON UTF8 data
}

extension Team: FetchableRecord, PersistableRecord {
    // Support SQLite JSON functions and operators
    // by storing JSON data as database text:
    static func databaseDataEncodingStrategy(for column: String) -> DatabaseDataEncodingStrategy {
        .text
    }
}
```

> Tip: Conform your `Codable` property to `DatabaseValueConvertible` if you want to be able to filter on specific values of it:
>
> ```swift
> struct Address: Codable { ... }
> extension Address: DatabaseValueConvertible {}
>
> struct Player: FetchableRecord, TableRecord {
>     enum Columns {
>         static let address = JSONColumn("address") 
>     }
> }
>
> // SELECT * FROM player
> // WHERE address = '{"street": "...", "city": "...", "country": "..."}'
> let players = try Player
>     .filter { $0.address == Address(...) }
>     .fetchAll(db)
> ```
>
> Take care that SQLite will compare strings, not JSON objects: white-space and key ordering matter. For this comparison to succeed, make sure that the database contains values that are formatted exactly like a serialized `Address`.

## Manipulate JSON values at the database level

[SQLite JSON functions and operators](https://www.sqlite.org/json1.html) are available starting iOS 16+, macOS 10.15+, tvOS 17+, and watchOS 9+.

Functions such as `JSON`, `JSON_EXTRACT`, `JSON_PATCH` and others are available as static methods on `Database`: ``Database/json(_:)``, ``Database/jsonExtract(_:atPath:)``, ``Database/jsonPatch(_:with:)``, etc.

See the full list below.

## JSON table-valued functions

The JSON table-valued functions `json_each` and `json_tree` are not supported.

## Topics

### JSON Values

- ``SQLJSONExpressible``
- ``JSONColumn``

### Access JSON subcomponents, and query JSON values, at the SQL level

The `->` and `->>` SQL operators are available on the ``SQLJSONExpressible`` protocol.

- ``Database/jsonArrayLength(_:)``
- ``Database/jsonArrayLength(_:atPath:)``
- ``Database/jsonExtract(_:atPath:)``
- ``Database/jsonExtract(_:atPaths:)``
- ``Database/jsonType(_:)``
- ``Database/jsonType(_:atPath:)``

### Build new JSON values at the SQL level

- ``Database/json(_:)``
- ``Database/jsonArray(_:)-8p2p8``
- ``Database/jsonArray(_:)-469db``
- ``Database/jsonObject(_:)``
- ``Database/jsonQuote(_:)``
- ``Database/jsonGroupArray(_:filter:)``
- ``Database/jsonGroupObject(key:value:filter:)``

### Modify JSON values at the SQL level

- ``Database/jsonInsert(_:_:)``
- ``Database/jsonPatch(_:with:)``
- ``Database/jsonReplace(_:_:)``
- ``Database/jsonRemove(_:atPath:)``
- ``Database/jsonRemove(_:atPaths:)``
- ``Database/jsonSet(_:_:)``

### Validate JSON values at the SQL level

- ``Database/jsonIsValid(_:)``



---
File: /GRDB/Documentation.docc/Migrations.md
---

# Migrations

Migrations allow you to evolve your database schema over time.

## Overview

You can think of migrations as being 'versions' of the database. A database schema starts off in an empty state, and each migration adds or removes tables, columns, or entries.

GRDB can update the database schema along this timeline, bringing it from whatever point it is in the history to the latest version. When a user upgrades your application, only non-applied migrations are run.

You setup migrations in a ``DatabaseMigrator`` instance. For example:

```swift
var migrator = DatabaseMigrator()

// 1st migration
migrator.registerMigration("Create authors") { db in
    try db.create(table: "author") { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("creationDate", .datetime)
        t.column("name", .text)
    }
}

// 2nd migration
migrator.registerMigration("Add books and author.birthYear") { db in
    try db.create(table: "book") { t in
        t.autoIncrementedPrimaryKey("id")
        t.belongsTo("author").notNull()
        t.column("title", .text).notNull()
    }

    try db.alter(table: "author") { t in
        t.add(column: "birthYear", .integer)
    }
}
```

To migrate a database, open a connection (see <doc:DatabaseConnections>), and call the ``DatabaseMigrator/migrate(_:)`` method:

```swift
let dbQueue = try DatabaseQueue(path: "/path/to/database.sqlite")

// Migrate the database up to the latest version
try migrator.migrate(dbQueue)
```

You can also migrate a database up to a specific version (useful for testing):

```swift
try migrator.migrate(dbQueue, upTo: "v2")

// Migrations can only run forward:
try migrator.migrate(dbQueue, upTo: "v2")
try migrator.migrate(dbQueue, upTo: "v1")
// ^ fatal error: database is already migrated beyond migration "v1"
```

When several versions of your app are deployed in the wild, you may want to perform extra checks:

```swift
try dbQueue.read { db in
    // Read-only apps or extensions may want to check if the database
    // lacks expected migrations:
    if try migrator.hasCompletedMigrations(db) == false {
        // database too old
    }
    
    // Some apps may want to check if the database
    // contains unknown (future) migrations:
    if try migrator.hasBeenSuperseded(db) {
        // database too new
    }
}
```

**Each migration runs in a separate transaction.** Should one throw an error, its transaction is rollbacked, subsequent migrations do not run, and the error is eventually thrown by ``DatabaseMigrator/migrate(_:)``.

**Migrations run with deferred foreign key checks.** This means that eventual foreign key violations are only checked at the end of the migration (and they make the migration fail). See <doc:Migrations#Foreign-Key-Checks> below for more information.

**The memory of applied migrations is stored in the database itself** (in a reserved table).

## Defining the Database Schema from a Migration

See <doc:DatabaseSchema> for the methods that define the database schema. For example:

```swift
migrator.registerMigration("Create authors") { db in
    try db.create(table: "author") { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("creationDate", .datetime)
        t.column("name", .text)
    }
}
```

#### How to Rename a Foreign Key

When a migration **renames a foreign key**, make sure the migration runs with `.immediate` foreign key checks, in order to avoid database integrity problems:

```swift
// IMPORTANT: rename foreign keys with immediate foreign key checks.
migrator.registerMigration("Guilds", foreignKeyChecks: .immediate) { db in
    try db.rename(table: "team", to: "guild")
    
    try db.alter(table: "player") { t in
        // Rename a foreign key
        t.rename(column: "teamId", to: "guildId")
    }
}
```

Note: migrations that run with `.immediate` foreign key checks can not be used to recreated database tables, as described below. When needed, define two migrations instead of one.

#### How to Recreate a Database Table 

When you need to modify a table in a way that is not directly supported by SQLite, or not available on your target operating system, you will need to recreate the database table.

For example:

```swift
migrator.registerMigration("Add NOT NULL check on author.name") { db in
    try db.create(table: "new_author") { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("creationDate", .datetime)
        t.column("name", .text).notNull()
    }
    try db.execute(sql: "INSERT INTO new_author SELECT * FROM author")
    try db.drop(table: "author")
    try db.rename(table: "new_author", to: "author")
}
```

The detailed sequence of operations for recreating a database table from a migration is:

1. When relevant, remember the format of all indexes, triggers, and views associated with table `X`. This information will be needed in steps 6 below. One way to do this is to run the following statement and examine the output in the console:

    ```swift
    try db.dumpSQL("SELECT type, sql FROM sqlite_schema WHERE tbl_name='X'")
    ```

2. Construct a new table `new_X` that is in the desired revised format of table `X`. Make sure that the name `new_X` does not collide with any existing table name, of course.

    ```swift
    try db.create(table: "new_X") { t in ... }
    ```

3. Transfer content from `X` into `new_X` using a statement like:

    ```swift
    try db.execute(sql: "INSERT INTO new_X SELECT ... FROM X")
    ```

4. Drop the old table `X`:
    
    ```swift
    try db.drop(table: "X")
    ```

5. Change the name of `new_X` to `X` using:

    ```swift
    try db.rename(table: "new_X", to: "X")
    ```

6. When relevant, reconstruct indexes, triggers, and views associated with table `X`.

7. If any views refer to table `X` in a way that is affected by the schema change, then drop those views using `DROP VIEW` and recreate them with whatever changes are necessary to accommodate the schema change using `CREATE VIEW`.

> Important: When recreating a table, be sure to follow the above procedure exactly, in the given order, or you might corrupt triggers, views, and foreign key constraints.
>
> When you want to recreate a table _outside of a migration_, check the full procedure detailed in the [Making Other Kinds Of Table Schema Changes](https://www.sqlite.org/lang_altertable.html#making_other_kinds_of_table_schema_changes) section of the SQLite documentation.

## Good Practices for Defining Migrations

**A good migration is a migration that is never modified once it has shipped.**

It is much easier to control the schema of all databases deployed on users' devices when migrations define a stable timeline of schema versions. For this reason, it is recommended that migrations define the database schema with **strings**:

```swift
migrator.registerMigration("Create authors") { db in
    // RECOMMENDED
    try db.create(table: "author") { t in
        t.autoIncrementedPrimaryKey("id")
        ...
    }

    // NOT RECOMMENDED
    try db.create(table: Author.databaseTableName) { t in
        t.autoIncrementedPrimaryKey(Author.Columns.id.name)
        ...
    }
}
```

In other words, migrations should talk to the database, only to the database, and use the database language. This makes sure the Swift code of any given migrations will never have to change in the future.

Migrations and the rest of the application code do not live at the same "moment". Migrations describe the past states of the database, while the rest of the application code targets the latest one only. This difference is the reason why **migrations should not depend on application types.**

## The eraseDatabaseOnSchemaChange Option

A `DatabaseMigrator` can automatically wipe out the full database content, and recreate the whole database from scratch, if it detects that migrations have changed their definition.

Setting ``DatabaseMigrator/eraseDatabaseOnSchemaChange`` is useful during application development, as you are still designing migrations, and the schema changes often:

- A migration is removed, or renamed.
- A schema change is detected: any difference in the `sqlite_master` table, which contains the SQL used to create database tables, indexes, triggers, and views.

> Warning: This option can destroy your precious users' data!

It is recommended that this option does not ship in the released application: hide it behind `#if DEBUG` as below.

```swift
var migrator = DatabaseMigrator()
#if DEBUG
// Speed up development by nuking the database when migrations change
migrator.eraseDatabaseOnSchemaChange = true
#endif
```

## Foreign Key Checks

By default, each migration temporarily disables foreign keys, and performs a full check of all foreign keys in the database before it is committed on disk.

When the database becomes very big, those checks may have a noticeable impact on migration performances. You'll know this by profiling migrations, and looking for the time spent in the `checkForeignKeys` method.

You can make those migrations faster, but this requires a little care.

**Your first mitigation technique is immediate foreign key checks.**

When you register a migration with `.immediate` foreign key checks, the migration does not temporarily disable foreign keys, and does not need to perform a deferred full check of all foreign keys in the database:

```swift
migrator.registerMigration("Fast migration", foreignKeyChecks: .immediate) { db in ... }
```

Such a migration is faster, and it still guarantees database integrity. But it must only execute schema alterations directly supported by SQLite. Migrations that recreate tables as described in <doc:Migrations#Defining-the-Database-Schema-from-a-Migration> **must not** run with immediate foreign keys checks. You'll need to use the second mitigation technique:

**Your second mitigation technique is to disable deferred foreign key checks.**

You can ask the migrator to stop performing foreign key checks for all newly registered migrations:

```swift
migrator = migrator.disablingDeferredForeignKeyChecks()
```

Migrations become unchecked by default, and run faster. But your app becomes responsible for preventing foreign key violations from being committed to disk:

```swift
migrator = migrator.disablingDeferredForeignKeyChecks()
migrator.registerMigration("Fast but unchecked migration") { db in ... }
```

To prevent a migration from committing foreign key violations on disk, you can:

- Register the migration with immediate foreign key checks, as long as it does not recreate tables as described in <doc:Migrations#Defining-the-Database-Schema-from-a-Migration>:

    ```swift
    migrator = migrator.disablingDeferredForeignKeyChecks()
    migrator.registerMigration("Fast and checked migration", foreignKeyChecks: .immediate) { db in ... }
    ```

- Perform foreign key checks on some tables only, before the migration is committed on disk:

    ```swift
    migrator = migrator.disablingDeferredForeignKeyChecks()
    migrator.registerMigration("Partially checked") { db in
        ...
        
        // Throws an error and stops migrations if there exists a
        // foreign key violation in the 'book' table.
        try db.checkForeignKeys(in: "book")
    }
    ```

As in the above example, check for foreign key violations with the ``Database/checkForeignKeys()`` and ``Database/checkForeignKeys(in:in:)`` methods. They throw a nicely detailed ``DatabaseError`` that contains a lot of debugging information:

```swift
// SQLite error 19: FOREIGN KEY constraint violation - from book(authorId) to author(id),
// in [id:1 authorId:2 name:"Moby-Dick"]
try db.checkForeignKeys(in: "book")
```

Alternatively, you can deal with each individual violation by iterating a cursor of ``ForeignKeyViolation``.

## Topics

### DatabaseMigrator

- ``DatabaseMigrator``



---
File: /GRDB/Documentation.docc/QueryInterface.md
---

# Records and the Query Interface

Record types and the query interface build SQL queries for you.

## Overview

For an overview, see [Records](https://github.com/groue/GRDB.swift/blob/master/README.md#records), and [The Query Interface](https://github.com/groue/GRDB.swift/blob/master/README.md#the-query-interface).

## Topics

### Records Protocols

- ``EncodableRecord``
- ``FetchableRecord``
- ``MutablePersistableRecord``
- ``PersistableRecord``
- ``TableRecord``

### Expressions

- ``Column``
- ``JSONColumn``
- ``SQLExpression``

### Requests

- ``CommonTableExpression``
- ``QueryInterfaceRequest``
- ``Table``

### Associations

- ``Association``

### Errors

- ``RecordError``
- ``PersistenceError``

### Supporting Types

- ``ColumnExpression``
- ``DerivableRequest``
- ``SQLExpressible``
- ``SQLJSONExpressible``
- ``SQLSpecificExpressible``
- ``SQLSubqueryable``
- ``SQLOrderingTerm``
- ``SQLSelectable``

### Legacy Types

- ``Record``



---
File: /GRDB/Documentation.docc/RecordRecommendedPractices.md
---

# Recommended Practices for Designing Record Types

Leverage the best of record types and associations. 

## Overview

GRDB sits right between low-level SQLite wrappers, and high-level ORMs like [Core Data], so you may face questions when designing the model layer of your application.

This is the topic of this article. Examples will be illustrated with a simple library database made of books and their authors.

## Trust SQLite More Than Yourself

Let's put things in the right order. An SQLite database stored on a user's device is more important than the Swift code that accesses it. When a user installs a new version of an application, only the database stored on the user's device remains the same. But all the Swift code may have changed.

This is why it is recommended to define a **robust database schema** even before playing with record types.

This is important because SQLite is very robust, whereas we developers write bugs. The more responsibility we give to SQLite, the less code we have to write, and the fewer defects we will ship on our users' devices, affecting their precious data.

For example, if we were to define <doc:Migrations> that configure a database made of books and their authors, we could write:

```swift
var migrator = DatabaseMigrator()

migrator.registerMigration("createLibrary") { db in
    try db.create(table: "author") { t in             // (1)
        t.autoIncrementedPrimaryKey("id")             // (2)
        t.column("name", .text).notNull()             // (3)
        t.column("countryCode", .text)                // (4)
    }
    
    try db.create(table: "book") { t in
        t.autoIncrementedPrimaryKey("id")
        t.column("title", .text).notNull()            // (5)
        t.belongsTo("author", onDelete: .cascade)     // (6)
            .notNull()                                // (7)
    }
}

try migrator.migrate(dbQueue)
```

1. Our database tables follow the <doc:DatabaseSchemaRecommendations>: table names are English, singular, and camelCased. They look like Swift identifiers: `author`, `book`, `postalAddress`, `httpRequest`.
2. Each author has a unique id.
3. An author must have a name.
4. The country of an author is not always known.
5. A book must have a title.
6. The `book.authorId` column is used to link a book to the author it belongs to. This column is indexed in order to ease the selection of an author's books. A foreign key is defined from `book.authorId` column to `authors.id`, so that SQLite guarantees that no book refers to a missing author. The `onDelete: .cascade` option has SQLite automatically delete all of an author's books when that author is deleted. See [Foreign Key Actions](https://sqlite.org/foreignkeys.html#fk_actions) for more information.
7. The `book.authorId` column is not null so that SQLite guarantees that all books have an author.

Thanks to this database schema, the application will always process *consistent data*, no matter how wrong the Swift code can get. Even after a hard crash, all books will have an author, a non-nil title, etc.

> Tip: **A local SQLite database is not a JSON payload loaded from a remote server.**
>
> The JSON format and content can not be controlled, and an application must defend itself against wacky servers. But a local database is under your full control. It is trustable. A relational database such as SQLite guarantees the quality of users data, as long as enough energy is put in the proper definition of the database schema.

> Tip: **Plan early for future versions of your application**: use <doc:Migrations>.

## Record Types

### Persistable Record Types are Responsible for Their Tables

**Define one record type per database table.** This record type will be responsible for writing in this table.

**Let's start from regular structs** whose properties match the columns in their database table. They conform to the standard [`Codable`] protocol so that we don't have to write the methods that convert to and from raw database rows.

```swift
struct Author: Codable {
    var id: Int64?
    var name: String
    var countryCode: String?
}

struct Book: Codable {
    var id: Int64?
    var authorId: Int64
    var title: String
}
```

**We add database powers to our types with record protocols.** 

The `author` and `book` tables have an auto-incremented id. We want inserted records to learn about their id after a successful insertion. That's why we have them conform to the ``MutablePersistableRecord`` protocol, and implement ``MutablePersistableRecord/didInsert(_:)-109jm``. Other kinds of record types would just use ``PersistableRecord``, and ignore `didInsert`.

On the reading side, we use ``FetchableRecord``, the protocol that can decode database rows.

This gives:

```swift
// Add Database access
extension Author: FetchableRecord, MutablePersistableRecord {
    // Update auto-incremented id upon successful insertion
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

extension Book: FetchableRecord, MutablePersistableRecord {
    // Update auto-incremented id upon successful insertion
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
```

That's it. The `Author` type can read and write in the `author` database table. `Book` as well, in `book`:

```swift
try dbQueue.write { db in
    // Insert and set author's id
    var author = Author(name: "Herman Melville", countryCode: "US")
    try author.insert(db)

    // Insert and set book's id
    var book = Book(authorId: author.id!, title: "Moby-Dick")
    try book.insert(db)
}

let books = try dbQueue.read { db in
    try Book.fetchAll(db)
}
```

> Tip: When a column of a database table can't be NULL, define a non-optional property in the record type. On the other side, when the database may contain NULL, define an optional property. Compare:
>
> ```swift
> try db.create(table: "author") { t in
>     t.autoIncrementedPrimaryKey("id")
>     t.column("name", .text).notNull() // Can't be NULL
>     t.column("countryCode", .text)    // Can be NULL
> }
>
> struct Author: Codable {
>     var id: Int64?
>     var name: String         // Not optional
>     var countryCode: String? // Optional
> }
> ```
>
> There are exceptions to this rule.
>
> For example, the `id` column is never NULL in the database. And yet, `Author` as an optional `id` property. That is because we want to create instances of `Author` before they could be inserted in the database, and be assigned an auto-incremented id. If the `id` property was not optional, the `Author` type could not profit from auto-incremented ids!
>
> Another exception to this rule is described in <doc:RecordTimestamps>, where the creation date of a record is never NULL in the database, but optional in the Swift type.

> Tip: When the database table has a single-column primary key, have the record type adopt the standard [`Identifiable`] protocol. This allows GRDB to define extra methods based on record ids:
>
> ```swift
> let authorID: Int64 = 42
> let author: Author = try dbQueue.read { db in
>     try Author.find(db, id: authorID)
> }
> ```
>
> Take care that **`Identifiable` is not a good fit for optional ids**. You will frequently meet optional ids for records with auto-incremented ids:
>
> ```swift
> struct Player: Codable {
>     var id: Int64? // Optional ids are not suitable for Identifiable
>     var name: String
>     var score: Int
> }
> 
> extension Player: FetchableRecord, MutablePersistableRecord {
>     // Update auto-incremented id upon successful insertion
>     mutating func didInsert(_ inserted: InsertionSuccess) {
>         id = inserted.rowID
>     }
> }
> ```
>
> For more details about auto-incremented ids and `Identifiable`, see [issue #1435](https://github.com/groue/GRDB.swift/issues/1435#issuecomment-1740857712).

### Record Types Hide Intimate Database Details

In the previous sample codes, the `Book` and `Author` structs have one property per database column, and their types are natively supported by SQLite (`String`, `Int`, etc.)

But it happens that raw database column names, or raw column types, are not a very good fit for the application.

When this happens, it's time to **distinguish the Swift and database representations**. Record types are the dedicated place where raw database values can be transformed into Swift types that are well-suited for the rest of the application.

Let's look at three examples.

#### First Example: Enums

Authors write books, and more specifically novels, poems, essays, or theatre plays. Let's add a `kind` column in the database. We decide that a book kind is represented as a string ("novel", "essay", etc.) in the database:

```swift
try db.create(table: "book") { t in
    ...
    t.column("kind", .text).notNull()
}
```

In Swift, it is not a good practice to use `String` for the type of the `kind` property. We prefer an enum instead:

```swift
struct Book: Codable {
    enum Kind: String, Codable {
        case essay, novel, poetry, theater
    }
    var id: Int64?
    var authorId: Int64
    var title: String
    var kind: Kind
}
```

Thanks to its enum property, the `Book` record prevents invalid book kinds from being stored into the database.

In order to use `Book.Kind` in database requests for books (see <doc:RecordRecommendedPractices#Record-Requests> below), we add the ``DatabaseValueConvertible`` conformance to `Book.Kind`:

```swift
extension Book.Kind: DatabaseValueConvertible { }

// Fetch all novels
let novels = try dbQueue.read { db in
    try Book.filter { $0.kind == Book.Kind.novel }.fetchAll(db)
}
```

#### Second Example: GPS Coordinates

GPS coordinates can be stored in two distinct `latitude` and `longitude` columns. But the standard way to deal with such coordinate is a single `CLLocationCoordinate2D` struct.

When this happens, keep column properties private, and provide sensible accessors instead:

```swift
try db.create(table: "place") { t in
    t.autoIncrementedPrimaryKey("id")
    t.column("name", .text).notNull()
    t.column("latitude", .double).notNull()
    t.column("longitude", .double).notNull()
}

struct Place: Codable {
    var id: Int64?
    var name: String
    private var latitude: CLLocationDegrees
    private var longitude: CLLocationDegrees
    
    var coordinate: CLLocationCoordinate2D {
        get {
            CLLocationCoordinate2D(
                latitude: latitude, 
                longitude: longitude)
        }
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }
}
```

Generally speaking, private properties make it possible to hide raw columns from the rest of the application. The next example shows another application of this technique.

#### Third Example: Money Amounts

Before storing money amounts in an SQLite database, take care that [floating-point numbers are never a good fit](https://stackoverflow.com/questions/3730019/why-not-use-double-or-float-to-represent-currency).

SQLite only supports two kinds of numbers: integers and doubles, so we'll store amounts as integers. $12.00 will be represented by 1200, a quantity of cents. This allows SQLite to compute exact sums of price, for example.

On the other side, an amount of cents is not very practical for the rest of the Swift application. The [`Decimal`] type looks like a better fit.

That's why the `Product` record type has a `price: Decimal` property, backed by a `priceCents` integer column:
    
```swift
try db.create(table: "product") { t in
    t.autoIncrementedPrimaryKey("id")
    t.column("name", .text).notNull()
    t.column("priceCents", .integer).notNull()
}

struct Product: Codable {
    var id: Int64?
    var name: String
    private var priceCents: Int
    
    var price: Decimal {
        get {
            Decimal(priceCents) / 100
        }
        set {
            priceCents = Self.cents(for: newValue)
        }
    }

    private static func cents(for value: Decimal) -> Int {
        Int(Double(truncating: NSDecimalNumber(decimal: value * 100)))
    }
}
```

## Record Requests

Once we have record types that are able to read and write in the database, we'd like to perform database requests of such records. 

### Columns 

Requests that filter or sort records are defined with **columns**, defined in a dedicated enumeration, with the name `Columns`, nested inside the record type. When the record type conforms to [`Codable`], columns can be derived from the `CodingKeys` enum:

```swift
// HOW TO define columns for a Codable record
extension Author {
    enum Columns {
        static let id = Column(CodingKeys.id)
        static let name = Column(CodingKeys.name)
        static let countryCode = Column(CodingKeys.countryCode)
    }
}
```

For non-Codable record types, declare columns with their names:

```swift
// HOW TO define columns for a non-Codable record
extension Author {
    enum Columns {
        static let id = Column("id")
        static let name = Column("name")
        static let countryCode = Column("countryCode")
    }
}
```

From those columns it is possible to define requests of type ``QueryInterfaceRequest``:

```swift
try dbQueue.read { db in
    // Fetch all authors, ordered by name,
    // in a localized case-insensitive fashion
    let sortedAuthors: [Author] = try Author.all()
        .order { $0.name.collating(.localizedCaseInsensitiveCompare) }
        .fetchAll(db)
    
    // Count French authors
    let frenchAuthorCount: Int = try Author.all()
        .filter { $0.countryCode == "FR" }
        .fetchCount(db)
}
```

### Turn Commonly-Used Requests into Methods 

An application can define reusable request methods that extend the built-in GRDB apis. Those methods avoid code repetition, ease refactoring, and foster testability.

Define those methods in extensions of the ``DerivableRequest`` protocol, as below:

```swift
// Author requests
extension DerivableRequest<Author> {
    /// Order authors by name, in a localized case-insensitive fashion
    func orderByName() -> Self {
        order { $0.name.collating(.localizedCaseInsensitiveCompare) }
    }
    
    /// Filters authors from a country
    func filter(countryCode: String) -> Self {
        filter { $0.countryCode == countryCode }
    }
}

// Book requests
extension DerivableRequest<Book> {
    /// Order books by title, in a localized case-insensitive fashion
    func orderByTitle() -> Self {
        order { $0.title.collating(.localizedCaseInsensitiveCompare) }
    }
    
    /// Filters books by kind
    func filter(kind: Book.Kind) -> Self {
        filter { $0.kind == kind }
    }
}
```

Those methods define a fluent and legible api that encapsulates intimate database details:

```swift
try dbQueue.read { db in
    let sortedSpanishAuthors: [Author] = try Author.all()
        .filter(countryCode: "ES")
        .orderByName()
        .fetchAll(db)
    
    let novelCount: Int = try Book.all()
        .filter(kind: .novel)
        .fetchCount(db)
}
```

Extensions to the `DerivableRequest` protocol can not change the type of requests. They remain requests of the base record. To define requests of another type, use an extension to ``QueryInterfaceRequest``, as in the example below:

```swift
extension QueryInterfaceRequest<Author> {
    // Selects authors' name
    func selectName() -> QueryInterfaceRequest<String> {
        select(\.name)
    }
}

// The names of Japanese authors
let names: Set<String> = try Author.all()
    .filter(countryCode: "JP")
    .selectName()
    .fetchSet(db)
```

## Associations

[Associations] help navigating from authors to their books and vice versa. Because the `book` table has an `authorId` column, we say that each book **belongs to** its author, and each author **has many** books:

```swift
extension Book {
    static let author = belongsTo(Author.self)
}

extension Author {
    static let books = hasMany(Book.self)
}
```

With associations, you can fetch a book's author, or an author's books:

```swift
// Fetch all novels from an author
try dbQueue.read { db in
    let author: Author = ...
    let novels: [Book] = try author.request(for: Author.books)
        .filter(kind: .novel)
        .orderByTitle()
        .fetchAll(db)
}
```

Associations also make it possible to define more convenience request methods:

```swift
extension DerivableRequest<Book> {
    /// Filters books from a country
    func filter(authorCountryCode countryCode: String) -> Self {
        // Books do not have any country column. But their author has one!
        // Return books that can be joined to an author from this country:
        joining(required: Book.author.filter(countryCode: countryCode))
    }
}

// Fetch all Italian novels
try dbQueue.read { db in
    let italianNovels: [Book] = try Book.all()
        .filter(kind: .novel)
        .filter(authorCountryCode: "IT")
        .fetchAll(db)
}
```

With associations, you can also process graphs of authors and books, as described in the next section. 

### How to Model Graphs of Objects

Since the beginning of this article, the `Book` and `Author` are independent structs that don't know each other. The only "meeting point" is the `Book.authorId` property.

Record types don't know each other on purpose: one does not need to know the author of a book when it's time to update the title of a book, for example.

When an application wants to process authors and books together, it defines dedicated types that model the desired view on the graph of related objects. For example:

```swift
// Fetch all authors along with their number of books
struct AuthorInfo: Decodable, FetchableRecord {
    var author: Author
    var bookCount: Int
}
let authorInfos: [AuthorInfo] = try dbQueue.read { db in
    try Author
        .annotated(with: Author.books.count)
        .asRequest(of: AuthorInfo.self)
        .fetchAll(db)
}
```

```swift
// Fetch the literary careers of German authors, sorted by name
struct LiteraryCareer: Codable, FetchableRecord {
    var author: Author
    var books: [Book]
}
let careers: [LiteraryCareer] = try dbQueue.read { db in
    try Author
        .filter(countryCode: "DE")
        .orderByName()
        .including(all: Author.books)
        .asRequest(of: LiteraryCareer.self)
        .fetchAll(db)
}
```

```swift
// Fetch all Colombian books and their authors
struct Authorship: Decodable, FetchableRecord {
    var book: Book
    var author: Author
}
let authorships: [Authorship] = try dbQueue.read { db in
    try Book.all()
        .including(required: Book.author.filter(countryCode: "CO"))
        .asRequest(of: Authorship.self)
        .fetchAll(db)
    
    // Equivalent alternative
    try Book.all()
        .filter(authorCountryCode: "CO")
        .including(required: Book.author)
        .asRequest(of: Authorship.self)
        .fetchAll(db)
}
```

In the above sample codes, requests that fetch values from several tables are decoded into additional record types: `AuthorInfo`, `LiteraryCareer`, and `Authorship`.

Those record type conform to both [`Decodable`] and ``FetchableRecord``, so that they can feed from database rows. They do not provide any persistence methods, though. **All database writes are performed from persistable record instances** (of type `Author` or `Book`).

For more information about associations, see the [Associations] guide.

### Lazy and Eager Loading: Comparison with Other Database Libraries

The additional record types described in the previous section may look superfluous. Some other database libraries are able to navigate in graphs of records without additional types.

For example, [Core Data] and Ruby's [Active Record] use **lazy loading**. This means that relationships are lazily fetched on demand:

```ruby
# Lazy loading with Active Record
author = Author.first       # Fetch first author
puts author.name
author.books.each do |book| # Lazily fetch books on demand
  puts book.title
end
```

**GRDB does not perform lazy loading.** In a GUI application, lazy loading can not be achieved without record management (as in [Core Data]), which in turn comes with non-trivial pain points for developers regarding concurrency. Instead of lazy loading, the library provides the tooling needed to fetch data, even complex graphs, in an [isolated] fashion, so that fetched values accurately represent the database content, and all database invariants are preserved. See the <doc:Concurrency> guide for more information.

Vapor [Fluent] uses **eager loading**, which means that relationships are only fetched if explicitly requested:

```swift
// Eager loading with Fluent
let query = Author.query(on: db)
    .with(\.$books) // <- Explicit request for books
    .first()

// Fetch first author and its books in one stroke
if let author = query.get() {
    print(author.name)
    for book in author.books { print(book.title) } 
}
```

One must take care of fetching relationships, though, or Fluent raises a fatal error: 

```swift
// Oops, the books relation is not explicitly requested
let query = Author.query(on: db).first()
if let author = query.get() {
    // fatal error: Children relation not eager loaded.
    for book in author.books { print(book.title) } 
}
```

**GRDB supports eager loading**. The difference with Fluent is that the relationships are modelled in a dedicated record type that provides runtime safety:

```swift
// Eager loading with GRDB
struct LiteraryCareer: Codable, FetchableRecord {
    var author: Author
    var books: [Book]
}

let request = Author.all()
    .including(all: Author.books) // <- Explicit request for books
    .asRequest(of: LiteraryCareer.self)

// Fetch first author and its books in one stroke
if let career = try request.fetchOne(db) {
    print(career.author.name)
    for book in career.books { print(book.title) } 
}
```

[Active Record]: http://guides.rubyonrails.org/active_record_basics.html
[`Codable`]: https://developer.apple.com/documentation/swift/Codable
[Core Data]: https://developer.apple.com/documentation/coredata
[`Decimal`]: https://developer.apple.com/documentation/foundation/decimal
[`Decodable`]: https://developer.apple.com/documentation/swift/Decodable
[Django]: https://docs.djangoproject.com/en/4.2/topics/db/
[Fluent]: https://docs.vapor.codes/fluent/overview/
[`Identifiable`]: https://developer.apple.com/documentation/swift/identifiable
[isolated]: https://en.wikipedia.org/wiki/Isolation_(database_systems)
[Associations]: https://github.com/groue/GRDB.swift/blob/master/Documentation/AssociationsBasics.md



---
File: /GRDB/Documentation.docc/RecordTimestamps.md
---

# Record Timestamps and Transaction Date

Learn how applications can save creation and modification dates of records.

## Overview

Some applications want to record creation and modification dates of database records. This article provides some advice and sample code that you can adapt for your specific needs.

> Note: Creation and modification dates can be automatically handled by [SQLite triggers](https://www.sqlite.org/lang_createtrigger.html). We'll explore a different technique, though.
>
> This is not an advice against triggers, and you won't feel hindered in any way if you prefer to use triggers. Still, consider:
>
> - A trigger does not suffer any exception, when some applications eventually want to fine-tune timestamps, or to perform migrations without touching timestamps.
> - The current time, according to SQLite, is not guaranteed to be constant in a given transaction. This may create undesired timestamp variations. We'll see below how GRDB provides a date that is constant at any point during a transaction.
> - The current time, according to SQLite, can't be controlled in tests and previews.

We'll start from this table and record type:

```swift
try db.create(table: "player") { t in
    t.autoIncrementedPrimaryKey("id")
    t.column("creationDate", .datetime).notNull()
    t.column("modificationDate", .datetime).notNull()
    t.column("name", .text).notNull()
    t.column("score", .integer).notNull()
}

struct Player {
    var id: Int64?
    var creationDate: Date?
    var modificationDate: Date?
    var name: String
    var score: Int
}
```

See how the table has non-null dates, while the record has optional dates.

This is because we intend, in this article, to timestamp actual database operations. The `creationDate` property is the date of database insertion, and `modificationDate` is the date of last modification in the database. A new `Player` instance has no meaningful timestamp until it is saved, and this absence of information is represented with `nil`:

```swift
// A new player has no timestamps.
var player = Player(id: nil, name: "Arthur", score: 1000)
player.id               // nil, because never saved
player.creationDate     // nil, because never saved
player.modificationDate // nil, because never saved

// After insertion, the player has timestamps.
try dbQueue.write { db in
    try player.insert(db)
}
player.id               // not nil
player.creationDate     // not nil
player.modificationDate // not nil
```

In the rest of the article, we'll address insertion first, then updates, and see a way to avoid those optional timestamps. The article ends with a sample protocol that your app may adapt and reuse.

- <doc:RecordTimestamps#Insertion-Timestamp>
- <doc:RecordTimestamps#Modification-Timestamp>
- <doc:RecordTimestamps#Dealing-with-Optional-Timestamps>
- <doc:RecordTimestamps#Sample-code-TimestampedRecord>

## Insertion Timestamp

On insertion, the `Player` record should get fresh `creationDate` and `modificationDate`. The ``MutablePersistableRecord`` protocol provides the necessary tooling, with the ``MutablePersistableRecord/willInsert(_:)-1xfwo`` persistence callback. Before insertion, the record sets both its `creationDate` and `modificationDate`:

```swift
extension Player: Encodable, MutablePersistableRecord {
    /// Sets both `creationDate` and `modificationDate` to the
    /// transaction date, if they are not set yet.
    mutating func willInsert(_ db: Database) throws {
        if creationDate == nil {
            creationDate = try db.transactionDate
        }
        if modificationDate == nil {
            modificationDate = try db.transactionDate
        }
    }
    
    /// Update auto-incremented id upon successful insertion
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

try dbQueue.write { db in
    // An inserted record has both a creation and a modification date.
    var player = Player(name: "Arthur", score: 1000)
    try player.insert(db)
    player.creationDate     // not nil
    player.modificationDate // not nil
}
```

The `willInsert` callback uses the ``Database/transactionDate`` instead of `Date()`. This has two advantages:

- Within a write transaction, all inserted players get the same timestamp:
    
    ```swift
    // All players have the same timestamp.
    try dbQueue.write { db in
        for var player in players {
            try player.insert(db)
        }
    }
    ```
    
- The transaction date can be configured with ``Configuration/transactionClock``, so that your tests and previews can control the date.

## Modification Timestamp

Let's now deal with updates. The `update` persistence method won't automatically bump the timestamp as the `insert` method does. We have to explicitly deal with the modification date:

```swift
// Increment the player score (two different ways).
try dbQueue.write { db in
    var player: Player
    
    // Update all columns
    player.score += 1
    player.modificationDate = try db.transactionDate
    try player.update(db)

    // Alternatively, update only the modified columns
    try player.updateChanges(db) {
         $0.score += 1
         $0.modificationDate = try db.transactionDate
    }
}
```

Again, we use ``Database/transactionDate``, so that all modified players get the same timestamp within a given write transaction.

> Note: The insertion case could profit from automatic initialization of the creation date with the ``MutablePersistableRecord/willInsert(_:)-1xfwo`` persistence callback, but the modification date is not handled with ``MutablePersistableRecord/willUpdate(_:columns:)-3oko4``. Instead, the above sample code explicitly modifies the modification date.
>
> This may look like an inconvenience, but there are several reasons for this:
>
> 1. The persistence methods that update are not mutating methods. `willUpdate` can not modify the modification date.
>
> 2. Automatic changes to the modification date from the general `update` method create problems.
>
>     Developers are seduced by this convenient-looking feature, but they also eventually want to disable automatic timestamp updates in specific circumstances. That's because application requirements happen to change, and developers happen to overlook some corner cases.
>
>     This need is well acknowledged by existing database libraries: to disable automatic timestamp updates, [ActiveRecord](https://stackoverflow.com/questions/861448/is-there-a-way-to-avoid-automatically-updating-rails-timestamp-fields) uses globals (not thread-safe in a Swift application), [Django ORM](https://stackoverflow.com/questions/7499767/temporarily-disable-auto-now-auto-now-add) does not make it easy, and [Fluent](https://github.com/vapor/fluent-kit/issues/355) simply does not allow it.
>
>     None of those solutions or lack thereof are seducing.
>
> 3. Not all applications need one modification timestamp. For example, some need one timestamp per property, or per group of properties.
>
> By not providing automatic timestamp updates, all GRDB-powered applications are treated equally: they explicitly bump their modification timestamps when needed. Apps can help themselves by introducing protocols dedicated to their particular handling of updates. For an example of such a protocol, see <doc:RecordTimestamps#Sample-code-TimestampedRecord> below.

## Dealing with Optional Timestamps

When you fetch timestamped records from the database, it may be inconvenient to deal with optional dates, even though the database columns are guaranteed to be not null:

```swift
let player = try dbQueue.read { db 
    try Player.find(db, key: 1)
}
player.creationDate     // optional 😕
player.modificationDate // optional 😕
```

A possible technique is to define two record types: one that deals with players in general (optional timestamps), and one that only deals with persisted players (non-optional dates): 

```swift
/// `Player` deals with unsaved players
struct Player {
    var id: Int64?              // optional
    var creationDate: Date?     // optional
    var modificationDate: Date? // optional
    var name: String
    var score: Int
}

extension Player: Encodable, MutablePersistableRecord {
    /// Updates auto-incremented id upon successful insertion
    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
    
    /// Sets both `creationDate` and `modificationDate` to the
    /// transaction date, if they are not set yet.
    mutating func willInsert(_ db: Database) throws {
        if creationDate == nil {
            creationDate = try db.transactionDate
        }
        if modificationDate == nil {
            modificationDate = try db.transactionDate
        }
    }
}

/// `PersistedPlayer` deals with persisted players
struct PersistedPlayer: Identifiable {
    let id: Int64              // not optional
    let creationDate: Date     // not optional
    var modificationDate: Date // not optional
    var name: String
    var score: Int
}

extension PersistedPlayer: Codable, FetchableRecord, PersistableRecord {
    static var databaseTableName: String { "player" }
}
```

Usage:

```swift
// Fetch
try dbQueue.read { db 
    let persistedPlayer = try PersistedPlayer.find(db, id: 1)
    persistedPlayer.creationDate     // not optional
    persistedPlayer.modificationDate // not optional
}

// Insert
try dbQueue.write { db in
    var player = Player(id: nil, name: "Arthur", score: 1000)
    player.id               // nil
    player.creationDate     // nil
    player.modificationDate // nil
    
    let persistedPlayer = try player.insertAndFetch(db, as: PersistedPlayer.self)
    persistedPlayer.id               // not optional
    persistedPlayer.creationDate     // not optional
    persistedPlayer.modificationDate // not optional
}
```

See ``MutablePersistableRecord/insertAndFetch(_:onConflict:as:)`` and related methods for more information.

## Sample code: TimestampedRecord

This section provides a sample protocol for records that track their creation and modification dates.

You can copy it in your application, or use it as an inspiration. Not all apps have the same needs regarding timestamps!

`TimestampedRecord` provides the following features and methods:

- Use it as a replacement for `MutablePersistableRecord` (even if your record does not use an auto-incremented primary key):

    ```swift
    // The base Player type
    struct Player {
        var id: Int64?
        var creationDate: Date?
        var modificationDate: Date?
        var name: String
        var score: Int
    }

    // Add database powers (read, write, timestamps)
    extension Player: Codable, TimestampedRecord, FetchableRecord {
        /// Update auto-incremented id upon successful insertion
        mutating func didInsert(_ inserted: InsertionSuccess) {
            id = inserted.rowID
        }
    }
    ```

- Timestamps are set on insertion:

    ```swift
    try dbQueue.write { db in
        // An inserted record has both a creation and a modification date.
        var player = Player(name: "Arthur", score: 1000)
        try player.insert(db)
        player.creationDate     // not nil
        player.modificationDate // not nil
    }
    ```

- `updateWithTimestamp()` behaves like ``MutablePersistableRecord/update(_:onConflict:)``, but it also bumps the modification date.
    
    ```swift
    // Bump the modification date and update all columns in the database.
    player.score += 1
    try player.updateWithTimestamp(db)
    ```

- `updateChangesWithTimestamp()` behaves like ``MutablePersistableRecord/updateChanges(_:onConflict:modify:)``, but it also bumps the modification date if the record is modified.

    ```swift
    // Only bump the modification date if record is changed, and only
    // update the changed columns.
    try player.updateChangesWithTimestamp(db) {
        $0.score = 1000
    }

    // Prefer updateChanges() if the modification date should always be
    // updated, even if other columns are not changed.
    try player.updateChanges(db) {
        $0.score = 1000
        $0.modificationDate = try db.transactionDate
    }
    ```

- `touch()` only updates the modification date in the database, just like the `touch` unix command.
    
    ```swift
    // Only update the modification date in the database.
    try player.touch(db)
    ```

- There is no `TimestampedRecord.saveWithTimestamp()` method that would insert or update, like ``MutablePersistableRecord/save(_:onConflict:)``. You are encouraged to write instead (and maybe extend your version of `TimestampedRecord` so that it supports this pattern):
    
    ```swift
    extension Player {
        /// If the player has a non-nil primary key and a matching row in
        /// the database, the player is updated. Otherwise, it is inserted.
        mutating func saveWithTimestamp(_ db: Database) throws {
            // Test the presence of id first, so that we don't perform an
            // update that would surely throw RecordError.recordNotFound.
            if id == nil {
                try insert(db)
            } else {
                do {
                    try updateWithTimestamp(db)
                } catch RecordError.recordNotFound {
                    // Primary key is set, but no row was updated.
                    try insert(db)
                }
            }
        }
    }
    ```

The full implementation of `TimestampedRecord` follows:

```swift
/// A record type that tracks its creation and modification dates. See
/// <https://swiftpackageindex.com/groue/GRDB.swift/documentation/grdb/recordtimestamps>
protocol TimestampedRecord: MutablePersistableRecord {
    var creationDate: Date? { get set }
    var modificationDate: Date? { get set }
}

extension TimestampedRecord {
    /// By default, `TimestampedRecord` types set `creationDate` and
    /// `modificationDate` to the transaction date, if they are nil,
    /// before insertion.
    ///
    /// `TimestampedRecord` types that customize the `willInsert`
    /// persistence callback should call `initializeTimestamps` from
    /// their implementation.
    mutating func willInsert(_ db: Database) throws {
        try initializeTimestamps(db)
    }
    
    /// Sets `creationDate` and `modificationDate` to the transaction date,
    /// if they are nil.
    ///
    /// It is called automatically before insertion, if your type does not
    /// customize the `willInsert` persistence callback. If you customize
    /// this callback, call `initializeTimestamps` from your implementation.
    mutating func initializeTimestamps(_ db: Database) throws {
        if creationDate == nil {
            creationDate = try db.transactionDate
        }
        if modificationDate == nil {
            modificationDate = try db.transactionDate
        }
    }
    
    /// Sets `modificationDate`, and executes an `UPDATE` statement
    /// on all columns.
    ///
    /// - parameter modificationDate: The modification date. If nil, the
    ///   transaction date is used.
    mutating func updateWithTimestamp(_ db: Database, modificationDate: Date? = nil) throws {
        self.modificationDate = try modificationDate ?? db.transactionDate
        try update(db)
    }
    
    /// Modifies the record according to the provided `modify` closure, and,
    /// if and only if the record was modified, sets `modificationDate` and
    /// executes an `UPDATE` statement that updates the modified columns.
    ///
    /// For example:
    ///
    /// ```swift
    /// try dbQueue.write { db in
    ///     var player = Player.find(db, id: 1)
    ///     let modified = try player.updateChangesWithTimestamp(db) {
    ///         $0.score = 1000
    ///     }
    ///     if modified {
    ///         print("player was modified")
    ///     } else {
    ///         print("player was not modified")
    ///     }
    /// }
    /// ```
    ///
    /// - parameters:
    ///     - db: A database connection.
    ///     - modificationDate: The modification date. If nil, the
    ///       transaction date is used.
    ///     - modify: A closure that modifies the record.
    /// - returns: Whether the record was changed and updated.
    @discardableResult
    mutating func updateChangesWithTimestamp(
        _ db: Database,
        modificationDate: Date? = nil,
        modify: (inout Self) -> Void)
    throws -> Bool
    {
        // Grab the changes performed by `modify`
        let initialChanges = try databaseChanges(modify: modify)
        if initialChanges.isEmpty {
            return false
        }
        
        // Update modification date and grab its column name
        let dateChanges = try databaseChanges(modify: {
            $0.modificationDate = try modificationDate ?? db.transactionDate
        })
        
        // Update the modified columns
        let modifiedColumns = Set(initialChanges.keys).union(dateChanges.keys)
        try update(db, columns: modifiedColumns)
        return true
    }
    
    /// Sets `modificationDate`, and executes an `UPDATE` statement that
    /// updates the `modificationDate` column, if and only if the record
    /// was modified.
    ///
    /// - parameter modificationDate: The modification date. If nil, the
    ///   transaction date is used.
    mutating func touch(_ db: Database, modificationDate: Date? = nil) throws {
        try updateChanges(db) {
            $0.modificationDate = try modificationDate ?? db.transactionDate
        }
    }
}
```



---
File: /GRDB/Documentation.docc/SingleRowTables.md
---

# Single-Row Tables

The setup for database tables that should contain a single row.

## Overview

Database tables that contain a single row can store configuration values, user preferences, and generally some global application state.

They are a suitable alternative to `UserDefaults` in some applications, especially when configuration refers to values found in other database tables, and database integrity is a concern.

A possible way to store such configuration is a table of key-value pairs: two columns, and one row for each configuration value. This technique works, but it has a few drawbacks: one has to deal with the various types of configuration values (strings, integers, dates, etc), and it is not possible to define foreign keys. This is why we won't explore key-value tables.

In this guide, we'll implement a single-row table, with recommendations on the database schema, migrations, and the design of a Swift API for accessing the configuration values. The schema will define one column for each configuration value, because we aim at being able to deal with foreign keys and references to other tables. You may prefer storing configuration values in a single JSON column. In this case, take inspiration from this guide, as well as <doc:JSON>.

We will also aim at providing a default value for a given configuration, even when it is not stored on disk yet. This is a feature similar to [`UserDefaults.register(defaults:)`](https://developer.apple.com/documentation/foundation/userdefaults/1417065-register).

## The Single-Row Table

As always with SQLite, everything starts at the level of the database schema. When we put the database engine on our side, we have to write less code, and this helps shipping less bugs.

We want to instruct SQLite that our table must never contain more than one row. We will never have to wonder what to do if we were unlucky enough to find two rows with conflicting values in this table.

SQLite is not able to guarantee that the table is never empty, so we have to deal with two cases: either the table is empty, or it contains one row.

Those two cases can create a nagging question for the application. By default, inserts fail when the row already exists, and updates fail when the table is empty. In order to avoid those errors, we will have the app deal with updates in the <doc:SingleRowTables#The-Single-Row-Record> section below. Right now, we instruct SQLite to just replace the eventual existing row in case of conflicting inserts.

```swift
migrator.registerMigration("appConfiguration") { db in
    // CREATE TABLE appConfiguration (
    //   id INTEGER PRIMARY KEY ON CONFLICT REPLACE CHECK (id = 1),
    //   storedFlag BOOLEAN,
    //   ...)
    try db.create(table: "appConfiguration") { t in
        // Single row guarantee: have inserts replace the existing row,
        // and make sure the id column is always 1.
        t.primaryKey("id", .integer, onConflict: .replace)
            .check { $0 == 1 }
        
        // The configuration columns
        t.column("storedFlag", .boolean)
        // ... other columns
    }
}
```

Note how the database table is defined in a migration. That's because most apps evolve, and need to add other configuration columns eventually. See <doc:Migrations> for more information.

We have defined a `storedFlag` column that can be NULL. That may be surprising, because optional booleans are usually a bad idea! But we can deal with this NULL at runtime, and nullable columns have a few advantages:

- NULL means that the application user had not made a choice yet. When `storedFlag` is NULL, the app can use a default value, such as `true`.
- As application evolves, application will need to add new configuration columns. It is not always possible to provide a sensible default value for these new columns, at the moment the table is modified. On the other side, it is generally possible to deal with those NULL values at runtime.

Despite those arguments, some apps absolutely require a value. In this case, don't weaken the application logic and make sure the database can't store a NULL value:

```swift
// DO NOT hesitate requiring NOT NULL columns when the app requires it.
migrator.registerMigration("appConfiguration") { db in
    try db.create(table: "appConfiguration") { t in
        t.primaryKey("id", .integer, onConflict: .replace).check { $0 == 1 }
        
        t.column("flag", .boolean).notNull() // required
    }
}
```


## The Single-Row Record

Now that the database schema has been defined, we can define the record type that will help the application access the single row:

```swift
struct AppConfiguration: Codable {
    // Support for the single row guarantee
    private var id = 1
    
    // The stored properties
    private var storedFlag: Bool?
    // ... other properties
}
```

The `storedFlag` property is private, because we want to expose a nice `flag` property that has a default value when `storedFlag` is nil:

```swift
// Support for default values
extension AppConfiguration {
    var flag: Bool {
        get { storedFlag ?? true /* the default value */ }
        set { storedFlag = newValue }
    }

    mutating func resetFlag() {
        storedFlag = nil
    }
}
```

This ceremony is not needed when the column can not be null:

```swift
// The simplified setup for non-nullable columns
struct AppConfiguration: Codable {
    // Support for the single row guarantee
    private var id = 1
    
    // The stored properties
    var flag: Bool
    // ... other properties
}
```

In case the database table would be empty, we need a default configuration:

```swift
extension AppConfiguration {
    /// The default configuration
    static let `default` = AppConfiguration(flag: nil)
}
```

We make our record able to access the database:

```swift
extension AppConfiguration: FetchableRecord, PersistableRecord {
```

We have seen in the <doc:SingleRowTables#The-Single-Row-Table> section that by default, updates throw an error if the database table is empty. To avoid this error, we instruct GRDB to insert the missing default configuration before attempting to update (see ``MutablePersistableRecord/willSave(_:)-6jitc`` for more information):

```swift
    // Customize the default PersistableRecord behavior
    func willUpdate(_ db: Database, columns: Set<String>) throws {
        // Insert the default configuration if it does not exist yet.
        if try !exists(db) {
            try AppConfiguration.default.insert(db)
        }
    }
```

The standard GRDB method ``FetchableRecord/fetchOne(_:)`` returns an optional which is nil when the database table is empty. As a convenience, let's define a method that returns a non-optional (replacing the missing row with `default`):

```swift
    /// Returns the persisted configuration, or the default one if the
    /// database table is empty.
    static func find(_ db: Database) throws -> AppConfiguration {
        try fetchOne(db) ?? .default
    }
}
```

And that's it! Now we can use our singleton record:

```swift
// READ
let config = try dbQueue.read { db in
    try AppConfiguration.find(db)
}
if config.flag {
    // ...
}

// WRITE
try dbQueue.write { db in
    // Update the config in the database
    var config = try AppConfiguration.find(db)
    try config.updateChanges(db) {
        $0.flag = true
    }
    
    // Other possible ways to save the config:
    var config = try AppConfiguration.find(db)
    config.flag = true
    try config.save(db)   // all the same
    try config.update(db) // all the same
    try config.insert(db) // all the same
    try config.upsert(db) // all the same
}
```

See ``MutablePersistableRecord`` for more information about persistence methods.


## Wrap-Up

We all love to copy and paste, don't we? Just customize the template code below:

```swift
// Table creation
try db.create(table: "appConfiguration") { t in
    // Single row guarantee: have inserts replace the existing row,
    // and make sure the id column is always 1.
    t.primaryKey("id", .integer, onConflict: .replace)
        .check { $0 == 1 }
    
    // The configuration columns
    t.column("storedFlag", .boolean)
    // ... other columns
}
```

```swift
//
// AppConfiguration.swift
//

import GRDB

struct AppConfiguration: Codable {
    // Support for the single row guarantee
    private var id = 1
    
    // The stored properties
    private var storedFlag: Bool?
    // ... other properties
}

// Support for default values
extension AppConfiguration {
    var flag: Bool {
        get { storedFlag ?? true /* the default value */ }
        set { storedFlag = newValue }
    }

    mutating func resetFlag() {
        storedFlag = nil
    }
}

extension AppConfiguration {
    /// The default configuration
    static let `default` = AppConfiguration(storedFlag: nil)
}

// Database Access
extension AppConfiguration: FetchableRecord, PersistableRecord {
    // Customize the default PersistableRecord behavior
    func willUpdate(_ db: Database, columns: Set<String>) throws {
        // Insert the default configuration if it does not exist yet.
        if try !exists(db) {
            try AppConfiguration.default.insert(db)
        }
    }
    
    /// Returns the persisted configuration, or the default one if the
    /// database table is empty.
    static func find(_ db: Database) throws -> AppConfiguration {
        try fetchOne(db) ?? .default
    }
}
```



---
File: /GRDB/Documentation.docc/SQLSupport.md
---

# SQL, Prepared Statements, Rows, and Values

SQL is the fundamental language for accessing SQLite databases.

## Overview

This section of the documentation focuses on low-level SQLite concepts: the SQL language, prepared statements, database rows and values.

If SQL is not your cup of tea, jump to <doc:QueryInterface> 🙂

## SQL Support

GRDB has a wide support for SQL.

Once connected with one of the <doc:DatabaseConnections>, you can execute raw SQL statements:

```swift
try dbQueue.write { db in
    try db.execute(sql: """
        INSERT INTO player (name, score) VALUES (?, ?);
        INSERT INTO player (name, score) VALUES (?, ?);
        """, arguments: ["Arthur", 500, "Barbara", 1000])
}
```

Build a prepared ``Statement`` and lazily iterate a ``DatabaseCursor`` of ``Row``:

```swift
try dbQueue.read { db in
    let sql = "SELECT id, score FROM player WHERE name = ?"  
    let statement = try db.makeStatement(sql: sql)
    let rows = try Row.fetchCursor(statement, arguments: ["O'Brien"])
    while let row = try rows.next() {
        let id: Int64 = row[0]
        let score: Int = row[1]
    }
}
```

Leverage ``SQLRequest`` and ``FetchableRecord`` for defining streamlined apis with powerful SQL interpolation features:

```swift
struct Player: Decodable {
    var id: Int64
    var name: String
    var score: Int
}

extension Player: FetchableRecord {
    static func filter(name: String) -> SQLRequest<Player> {
        "SELECT * FROM player WHERE name = \(name)"
    }

    static func maximumScore() -> SQLRequest<Int> {
        "SELECT MAX(score) FROM player"
    }
}

try dbQueue.read { db in
    let players = try Player.filter(name: "O'Reilly").fetchAll(db) // [Player]
    let maxScore = try Player.maximumScore().fetchOne(db)          // Int?
}
```

For a more detailed overview, see [SQLite API](https://github.com/groue/GRDB.swift/blob/master/README.md#sqlite-api).

## Topics

### Fundamental Database Types

- ``Statement``
- ``Row``
- ``DatabaseValue``
- ``DatabaseCursor``

### SQL Literals and Requests

- ``SQL``
- ``SQLRequest``
- ``databaseQuestionMarks(count:)``

### Database Values

- ``DatabaseDateComponents``
- ``DatabaseValueConvertible``
- ``StatementColumnConvertible``

### Supporting Types

- ``Cursor``
- ``FetchRequest``



---
File: /GRDB/Documentation.docc/SwiftConcurrency.md
---

# Swift Concurrency and GRDB

How to best integrate GRDB and Swift Concurrency 

## Overview

GRDB’s primary goal is to leverage SQLite’s concurrency features for the benefit of application developers. Swift 6 makes it possible to achieve this goal while ensuring data-race safety.

For example, the ``DatabasePool`` connection allows applications to fetch and display database values on screen, even while a background task is writing the results of a network request to disk.

Application previews and tests prefer to use an in-memory ``DatabaseQueue`` connection.

Both connection types provide the same database access methods:

```swift
// Read
let playerCount = try await writer.read { db in
    try Player.fetchCount(db)
}

// Write
let newPlayerCount = try await writer.write { db in
    try Player(name: "Arthur").insert(db)
    return try Player.fetchCount(db)
}

// Observe database changes
let observation = ValueObservation.tracking { db in
    try Player.fetchAll(db)
}
for try await players in observation.values(in: writer) {
    print("Fresh players", players)
}
```

`DatabaseQueue` serializes all database accesses, when `DatabasePool` allows parallel reads and writes. The common ``DatabaseWriter`` protocol provides the [SQLite isolation guarantees](https://www.sqlite.org/isolation.html) that abstract away the differences between the two connection types, without sacrificing data integrity. See the <doc:Concurrency> guide for more information.

All safety guarantees of Swift 6 are enforced during database accesses. They are controlled by the language mode and level of concurrency checkings used by your application, as described in [Migrating to Swift 6] on swift.org. 

The following sections describe, with more details, how GRDB interacts with Swift Concurrency.

- <doc:SwiftConcurrency#Shorthand-Closure-Notation>
- <doc:SwiftConcurrency#Non-Sendable-Configuration-of-Record-Types>
- <doc:SwiftConcurrency#Non-Sendable-Record-Types>
- <doc:SwiftConcurrency#Choosing-between-Synchronous-and-Asynchronous-Database-Accesses>

### Shorthand Closure Notation

In the Swift 5 language mode, the compiler emits a warning when a database access is written with the shorthand closure notation:

```swift
// Standard closure:
let count = try await writer.read { db in
    try Player.fetchCount(db)
}

// Shorthand notation:
// ⚠️ Converting non-sendable function value to '@Sendable (Database) 
// throws -> Int' may introduce data races.
let count = try await writer.read(Player.fetchCount)
```

**You can remove this warning** by enabling [SE-0418: Inferring `Sendable` for methods and key path literals](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0418-inferring-sendable-for-methods.md), as below:

- **Using Xcode**

    Set `SWIFT_UPCOMING_FEATURE_INFER_SENDABLE_FROM_CAPTURES` to `YES` in the build settings of your target.

- **In a SwiftPM package manifest**

    Enable the `InferSendableFromCaptures` upcoming feature: 
    
    ```swift
    .target(
        name: "MyTarget",
        swiftSettings: [
            .enableUpcomingFeature("InferSendableFromCaptures")
        ]
    )
    ```

This language feature is not enabled by default, because it can potentially [affect source compatibility](https://www.swift.org/migration/documentation/swift-6-concurrency-migration-guide/sourcecompatibility#Inferring-Sendable-for-methods-and-key-path-literals).

### Non-Sendable Configuration of Record Types

In the Swift 6 language mode, and in the Swift 5 language mode with strict concurrency checkings, the compiler emits an error or a warning when a record type specifies which columns it fetches from the database, with the ``TableRecord/databaseSelection-7iphs`` static property:

```swift
extension Player: FetchableRecord, PersistableRecord {
    // ❌ Static property 'databaseSelection' is not concurrency-safe
    // because non-'Sendable' type '[any SQLSelectable]'
    // may have shared mutable state
    static let databaseSelection: [any SQLSelectable] = [
        Columns.id, Columns.name, Columns.score
    ]

    enum Columns {
        static let id = Column("id")
        static let name = Column("name")
        static let score = Column("score")
    }
}
```

**To fix this error**, replace the stored property with a computed property:

```swift
extension Player: FetchableRecord, PersistableRecord {
    static var databaseSelection: [any SQLSelectable] {
        [Columns.id, Columns.name, Columns.score]
    }
}
```

### Non-Sendable Record Types

In the Swift 6 language mode, and in the Swift 5 language mode with strict concurrency checkings, the compiler emits an error or a warning when the application reads, writes, or observes a non-[`Sendable`](https://developer.apple.com/documentation/swift/sendable) type.

By default, Swift classes are not Sendable. They are not thread-safe. With GRDB, record classes will typically trigger compiler diagnostics:

```swift
// A non-Sendable record type
final class Player: Codable, Identifiable {
    var id: Int64
    var name: String
    var score: Int
}

extension Player: FetchableRecord, PersistableRecord { }

// ❌ Type 'Player' does not conform to the 'Sendable' protocol
let player = try await writer.read { db in
    try Player.fetchOne(db, id: 42)
}

// ❌ Capture of 'player' with non-sendable type 'Player' in a `@Sendable` closure
let player: Player
try await writer.read { db in
    try player.insert(db)
}

// ❌ Type 'Player' does not conform to the 'Sendable' protocol
let observation = ValueObservation.tracking { db in
    try Player.fetchAll(db)
}
```

#### The solution

The solution is to have the record type conform to `Sendable`.

Since classes are difficult to make `Sendable`, the easiest way to is to replace classes with structs composed of `Sendable` properties:

```swift
// This struct is Sendable
struct Player: Codable, Identifiable {
    var id: Int64
    var name: String
    var score: Int
}

extension Player: FetchableRecord, PersistableRecord { }
```

You do not need to perform this refactoring right away: you can compile your application in the Swift 5 language mode, with minimal concurrency checkings. Take your time, and only when your application is ready, enable strict concurrency checkings or the Swift 6 language mode.

#### FAQ: My application defines record classes, because…

- **Question: My record types are subclasses of the built-in GRDB `Record` class.**
    
    Consider refactoring them as structs. The ``Record`` class was present in GRDB 1.0, in 2017. It has served its purpose. It is not `Sendable`, and its use is actively discouraged since GRDB 7.

- **Question: I need a hierarchy of record classes because I use inheritance.**
    
    It should be possible to refactor the class hiearchy with Swift protocols. See <doc:RecordTimestamps> for a practical example. Protocols make it possible to define records as structs.

- **Question: I use the `@Observable` macro for my record types, and this macro requires a class.**

    A possible solution is to define two types: an `@Observable` class that drives your SwiftUI views, and a plain record struct for database work. An indirect advantage is that you will be able to make them evolve independently.

- **Question: I use classes instead of structs because I monitored my application and classes have a lower CPU/memory footprint.**
    
    Now that's tricky. Please do not think the `Sendable` requirement is a whim: see the following questions.

#### FAQ: How to make classes Sendable?

- **Question: Can I mark my record classes as `@unchecked Sendable`?**

    Take care that all humans and machines who will read your code will think that the class is thread-safe, so make sure it really is. See the following questions.

- **Question: I can use locks to make my class safely Sendable.**

    You can indeed put a lock on the whole instance, or on each individual property, or on multiple subgroups of properties, as needed by your application. Remember that structs are simpler, because they do not need locks and the compiler does all the hard work for you.

- **Question: Can I make my record classes immutable?**

    Yes. Classes that can not be modified, made of constant `let` properties, are Sendable. Those immutable classes will not make it easy to modify the database, though.

### Choosing between Synchronous and Asynchronous Database Accesses

GRDB connections provide two versions of `read` and `write`, one that is synchronous, and one that is asynchronous. It might not be clear how to choose one or the other.

```swift
// Synchronous database access
try writer.write { ... }

// Asynchronous database access
await try writer.write { ... }
```

Synchronous database accesses are handy. They avoid undesired delays, flashes of missing content in the user interface, or `async` functions. Many apps access the database synchronously, even from the main thread, because SQLite is very fast. Of course, it is still possible to run slow queries: in this case, asynchronous accesses should be preferred. They are guaranteed to never block the main thread.

Performing synchronous accesses from Swift Concurrency tasks is not incorrect.

Some people recommend to avoid performing long blocking jobs on the cooperative thread pool, so you might want to follow this advice, and prefer to always `await` for the database in Swift tasks. In many occasions, the compiler will help you. For example, in the sample code below, the compiler requires the `await` keyword:

```swift
func fetchPlayers() async throws -> [Player] {
    try await writer.read(Player.fetchAll)
}
```

But there are some scenarios where the compiler misses opportunities to use `await`, such as inside closures ([swiftlang/swift#74459](https://github.com/swiftlang/swift/issues/74459)):

```swift
Task {
    // The compiler does not spot the missing `await`
    let players = try writer.read(Player.fetchAll)
}
```

[demo apps]: https://github.com/groue/GRDB.swift/tree/master/Documentation/DemoApps
[Migrating to Swift 6]: https://www.swift.org/migration/documentation/migrationguide/



---
File: /GRDB/Documentation.docc/Transactions.md
---

# Transactions and Savepoints

Precise transaction handling.

## Transactions and Safety

**A transaction is a fundamental tool of SQLite** that guarantees [data consistency](https://www.sqlite.org/transactional.html) as well as [proper isolation](https://sqlite.org/isolation.html) between application threads and database connections. It is at the core of GRDB <doc:Concurrency> guarantees.

To profit from database transactions, all you have to do is group related database statements in a single database access method such as ``DatabaseWriter/write(_:)-76inz`` or ``DatabaseReader/read(_:)-3806d``:

```swift
// BEGIN TRANSACTION
// INSERT INTO credit ...
// INSERT INTO debit ...
// COMMIT
try dbQueue.write { db in
    try Credit(destinationAccount, amount).insert(db)
    try Debit(sourceAccount, amount).insert(db)
}

// BEGIN TRANSACTION
// SELECT * FROM credit
// SELECT * FROM debit
// COMMIT
let (credits, debits) = try dbQueue.read { db in
    let credits = try Credit.fetchAll(db)
    let debits = try Debit.fetchAll(db)
    return (credits, debits)
}
```

In the following sections we'll explore how you can avoid transactions, and how to perform explicit transactions and savepoints. 

## Database Accesses without Transactions

When needed, you can write outside of any transaction with ``DatabaseWriter/writeWithoutTransaction(_:)-4qh1w`` (also named `inDatabase(_:)`, for `DatabaseQueue`):

```swift
// INSERT INTO credit ...
// INSERT INTO debit ...
try dbQueue.writeWithoutTransaction { db in
    try Credit(destinationAccount, amount).insert(db)
    try Debit(sourceAccount, amount).insert(db)
}
```

For reads, use ``DatabaseReader/unsafeRead(_:)-5i7tf``:

```swift
// SELECT * FROM credit
// SELECT * FROM debit
let (credits, debits) = try dbPool.unsafeRead { db in
    let credits = try Credit.fetchAll(db)
    let debits = try Debit.fetchAll(db)
    return (credits, debits)
}
```

Those method names, `writeWithoutTransaction` and `unsafeRead`, are longer and "scarier" than the regular `write` and `read` in order to draw your attention to the dangers of those unisolated accesses.

In our credit/debit example, a credit may be successfully inserted, but the debit insertion may fail, ending up with unbalanced accounts (oops).

```swift
// UNSAFE DATABASE INTEGRITY
try dbQueue.writeWithoutTransaction { db in // or dbPool.writeWithoutTransaction
    try Credit(destinationAccount, amount).insert(db)
    // 😬 May fail after credit was successfully written to disk:
    try Debit(sourceAccount, amount).insert(db)       
}
```

Transactions avoid this kind of bug.
    
``DatabasePool`` concurrent reads can see an inconsistent state of the database:

```swift
// UNSAFE CONCURRENCY
try dbPool.writeWithoutTransaction { db in
    try Credit(destinationAccount, amount).insert(db)
    // <- 😬 Here a concurrent read sees a partial db update (unbalanced accounts)
    try Debit(sourceAccount, amount).insert(db)
}
```

Transactions avoid this kind of bug, too.

Finally, reads performed outside of any transaction are not isolated from concurrent writes. It is possible to see unbalanced accounts, even though the invariant is never broken on disk:

```swift
// UNSAFE CONCURRENCY
let (credits, debits) = try dbPool.unsafeRead { db in
    let credits = try Credit.fetchAll(db)
    // <- 😬 Here a concurrent write can modify the balance before debits are fetched
    let debits = try Debit.fetchAll(db)
    return (credits, debits)
}
```

Yes, transactions also avoid this kind of bug.

## Explicit Transactions

To open explicit transactions, use `inTransaction()` or `writeInTransaction()`:

```swift
// BEGIN TRANSACTION
// INSERT INTO credit ...
// INSERT INTO debit ...
// COMMIT
try dbQueue.inTransaction { db in // or dbPool.writeInTransaction
    try Credit(destinationAccount, amount).insert(db)
    try Debit(sourceAccount, amount).insert(db)
    return .commit
}

// BEGIN TRANSACTION
// INSERT INTO credit ...
// INSERT INTO debit ...
// COMMIT
try dbQueue.writeWithoutTransaction { db in
    try db.inTransaction {
        try Credit(destinationAccount, amount).insert(db)
        try Debit(sourceAccount, amount).insert(db)
        return .commit
    }
}
```

If an error is thrown from the transaction block, the transaction is rollbacked and the error is rethrown by the transaction method. If the transaction closure returns `.rollback` instead of `.commit`, the transaction is also rollbacked, but no error is thrown.

Full manual transaction management is also possible: 

```swift
try dbQueue.writeWithoutTransaction { db
    try db.beginTransaction()
    ...
    try db.commit()
    
    try db.execute(sql: "BEGIN TRANSACTION")
    ...
    try db.execute(sql: "ROLLBACK")
}
```

Make sure all transactions opened from a database access are committed or rollbacked from that same database access, because it is a programmer error to leave an opened transaction:

```swift
// fatal error: A transaction has been left
// opened at the end of a database access.
try dbQueue.writeWithoutTransaction { db in
    try db.execute(sql: "BEGIN TRANSACTION")
    // <- no commit or rollback
}
```

In particular, since commits may throw an error, make sure you perform a rollback when a commit fails.

This restriction can be left with the ``Configuration/allowsUnsafeTransactions`` configuration flag.

It is possible to ask if a transaction is currently opened:

```swift
func myCriticalMethod(_ db: Database) throws {
    precondition(db.isInsideTransaction, "This method requires a transaction")
    try ...
}
```

Yet, there is a better option than checking for transactions. Critical database sections should use savepoints, described below:

```swift
func myCriticalMethod(_ db: Database) throws {
    try db.inSavepoint {
        // Here the database is guaranteed to be inside a transaction.
        try ...
    }
}
```

## Savepoints

**Statements grouped in a savepoint can be rollbacked without invalidating a whole transaction:**

```swift
try dbQueue.write { db in
    // Makes sure both inserts succeed, or none:
    try db.inSavepoint {
        try Credit(destinationAccount, amount).insert(db)
        try Debit(sourceAccount, amount).insert(db)
        return .commit
    }
    
    // Other savepoints, etc...
}
```

If an error is thrown from the savepoint block, the savepoint is rollbacked and the error is rethrown by the `inSavepoint` method. If the savepoint closure returns `.rollback` instead of `.commit`, the savepoint is also rollbacked, but no error is thrown.

**Unlike transactions, savepoints can be nested.** They implicitly open a transaction if no one was opened when the savepoint begins. As such, they behave just like nested transactions. Yet the database changes are only written to disk when the outermost transaction is committed:

```swift
try dbQueue.writeWithoutTransaction { db in
    try db.inSavepoint {
        ...
        try db.inSavepoint {
            ...
            return .commit
        }
        ...
        return .commit // Writes changes to disk
    }
}
```

SQLite savepoints are more than nested transactions, though. For advanced uses, use [SQLite savepoint documentation](https://www.sqlite.org/lang_savepoint.html).


## Transaction Kinds

SQLite supports [three kinds of transactions](https://www.sqlite.org/lang_transaction.html): deferred (the default), immediate, and exclusive.

By default, GRDB opens DEFERRED transaction for reads, and IMMEDIATE transactions for writes.

The transaction kind can be chosen for individual transaction:

```swift
let dbQueue = try DatabaseQueue(path: "/path/to/database.sqlite")

// BEGIN EXCLUSIVE TRANSACTION ...
try dbQueue.inTransaction(.exclusive) { db in ... }
```
