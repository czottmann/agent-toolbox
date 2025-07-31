# Networking

Concise networking code leveraging async-await, Decodable & Generics. Networking
brings together `URLSession`, `async`-`await` (or `Combine` ), `Decodable` and
`Generics` to simplify connecting to a JSON api.

For building concise APIs. Automatically map your models. Uses latest Apple's
[Combine](https://developer.apple.com/documentation/combine) / `async/await`.
Compatible with native `Decodable` and any JSON Parser. Embarks a built-in
network logger.

https://github.com/freshOS/Networking

## Requirements

- Swift 5+
- iOS 13+

## Usage

### Create a Client

```swift
let client = NetworkingClient(baseURL: "https://jsonplaceholder.typicode.com")
```

### Make your first call

Use `get`, `post`, `put`, `patch` & `delete` methods on the client to make
calls.

```swift
let data: Data = try await client.get("/posts/1")
```

All the apis are also available in Combine:

```swift
client.get("/posts/1").sink(receiveCompletion: { _ in }) { (data:Data) in
    // data
}.store(in: &cancellables)
```

### Get the type you want back

`Networking` recognizes the type you want back via type inference. Types
supported are `Void`, `Data`, `Any`(JSON), `Decodable`(Your Model) &
`NetworkingJSONDecodable`

This enables keeping a simple api while supporting many types :

```swift
let voidPublisher: AnyPublisher<Void, Error> = client.get("")
let dataPublisher: AnyPublisher<Data, Error> = client.get("")
let jsonPublisher: AnyPublisher<Any, Error> = client.get("")
let postPublisher: AnyPublisher<Post, Error> = client.get("")
let postsPublisher: AnyPublisher<[Post], Error> = client.get("")
```

### Pass params

Simply pass a `[String: CustomStringConvertible]` dictionary to the `params`
parameter.

```swift
let response: Data = try await client.posts("/posts/1", params: ["optin" : true ])
```

Parameters are `.urlEncoded` by default
(`Content-Type: application/x-www-form-urlencoded`), to encode them as json
(`Content-Type: application/json`), you need to set the client's
`parameterEncoding` to `.json` as follows:

```swift
client.parameterEncoding = .json
```

### Upload multipart data

For multipart calls (post/put), just pass a `MultipartData` struct to the
`multipartData` parameter.

```swift
let params: [String: CustomStringConvertible] = [ "type_resource_id": 1, "title": photo.title]
let multipartData = MultipartData(name: "file", fileData: photo.data, fileName: "photo.jpg", mimeType: "image/jpeg")
client.post("/photos/upload",
            params: params,
            multipartData: multipartData).sink(receiveCompletion: { _ in }) { (data:Data?, progress: Progress) in
              if let data = data {
                print("upload is complete : \(data)")
              } else {
                print("progress: \(progress)")
              }
}.store(in: &cancellables)
```

### Add Headers

Headers are added via the `headers` property on the client.

```swift
client.headers["Authorization"] = "[mytoken]"
```

### Add Timeout

Timeout (TimeInterval in seconds) is added via the optional `timeout` property
on the client.

```swift
let client = NetworkingClient(baseURL: "https://jsonplaceholder.typicode.com", timeout: 15)
```

Alternatively,

```swift
client.timeout = 15
```

### Cancel a request

Since `Networking` uses the Combine framework. You just have to cancel the
`AnyCancellable` returned by the `sink` call.

```swift
var cancellable = client.get("/posts/1").sink(receiveCompletion: { _ in }) { (json:Any) in
  print(json)
}
```

Later ...

```swift
cancellable.cancel()
```

### Log Network calls

3 log levels are supported: `off`, `info`, `debug`

```swift
client.logLevel = .debug
```

### Handling errors

Errors can be handled on a Publisher, such as:

```swift
client.get("/posts/1").sink(receiveCompletion: { completion in
  switch completion {
  case .finished:
    break
  case .failure(let error):
    switch error {
    case let decodingError DecodingError:
      // handle JSON decoding errors
    case let networkingError NetworkingError:
        // handle NetworkingError
      // print(networkingError.status)
      // print(networkingError.code)
    default:
      // handle other error types
      print("\(error.localizedDescription)")
    }
  }   
}) { (response: Post) in
  // handle the response
}.store(in: &cancellables)
```

### Support JSON-to-Model parsing.

For a model to be parsable by `Networking`, it only needs to conform to the
`Decodable` protocol.

If you are using a custom JSON parser, then you'll have to conform to
`NetworkingJSONDecodable`.\
For example if you are using [Arrow](https://github.com/freshOS/Arrow) for JSON
Parsing. Supporting a `Post` model will look like this:

```swift
extension Post: NetworkingJSONDecodable {
  static func decode(_ json: Any) throws -> Post {
    var t = Post()
    if let arrowJSON = JSON(json) {
      t.deserialize(arrowJSON)
    }
    return t
  }
}
```

Instead of doing it every models, you can actually do it once for all with a
clever extension 🤓.

```swift
extension ArrowParsable where Self: NetworkingJSONDecodable {
  public static func decode(_ json: Any) throws -> Self {
    var t: Self = Self()
    if let arrowJSON = JSON(json) {
      t.deserialize(arrowJSON)
    }
    return t
  }
}

extension User: NetworkingJSONDecodable { }
extension Photo: NetworkingJSONDecodable { }
extension Video: NetworkingJSONDecodable { }
// etc.
```

### Design a clean api

In order to write a concise api, Networking provides the `NetworkingService`
protocol. This will forward your calls to the underlying client so that your
only have to write `get("/route")` instead of `network.get("/route")`, while
this is overkill for tiny apis, it definitely keep things concise when working
with massive apis.

Given an `Article` model

```swift
struct Article: DeCodable {
  let id: String
  let title: String
  let content: String
}
```

Here is what a typical CRUD api would look like :

```swift
struct CRUDApi: NetworkingService {
  var network = NetworkingClient(baseURL: "https://my-api.com")

  // Create
  func create(article a: Article) async throws -> Article {
      try await post("/articles", params: ["title" : a.title, "content" : a.content])
  }

  // Read
  func fetch(article a: Article) async throws -> Article {
      try await get("/articles/\(a.id)")
  }

  // Update
  func update(article a: Article) async throws -> Article {
      try await put("/articles/\(a.id)", params: ["title" : a.title, "content" : a.content])
  }

  // Delete
  func delete(article a: Article) async throws {
      return try await delete("/articles/\(a.id)")
  }

  // List
  func articles() async throws -> [Article] {
      try await get("/articles")
  }
}
```

The Combine equivalent would look like this:

```swift
struct CRUDApi: NetworkingService {
  var network = NetworkingClient(baseURL: "https://my-api.com")

  // Create
  func create(article a: Article) -> AnyPublisher<Article, Error> {
      post("/articles", params: ["title" : a.title, "content" : a.content])
  }

  // Read
  func fetch(article a: Article) -> AnyPublisher<Article, Error> {
      get("/articles/\(a.id)")
  }

  // Update
  func update(article a: Article) -> AnyPublisher<Article, Error> {
      put("/articles/\(a.id)", params: ["title" : a.title, "content" : a.content])
  }

  // Delete
  func delete(article a: Article) -> AnyPublisher<Void, Error> {
      delete("/articles/\(a.id)")
  }

  // List
  func articles() -> AnyPublisher<[Article], Error> {
      get("/articles")
  }
}
```

## Examples

Networking turns this:

```swift
let config = URLSessionConfiguration.default
let urlSession = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
var urlRequest = URLRequest(url: URL(string: "https://jsonplaceholder.typicode.com/users")!)
urlRequest.httpMethod = "POST"
urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
urlRequest.httpBody = "firstname=Alan&lastname=Turing".data(using: .utf8)
let (data, _) = try await urlSession.data(for: urlRequest)
let decoder = JSONDecoder()
let user = try decoder.decode(User.self, from: data)
```

into:

```swift
let network = NetworkingClient(baseURL: "https://jsonplaceholder.typicode.com")
let user: User = try await network.post("/users", params: ["firstname" : "Alan", "lastname" : "Turing"])
```
