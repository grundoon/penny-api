//import FluentSQLite
//import Vapor
import Vapor
import Foundation
import PostgreSQL
import FluentPostgreSQL

/*
 Start Postgres
 docker run --name postgres -e POSTGRES_DB=vapor   -e POSTGRES_USER=vapor -e POSTGRES_PASSWORD=password   -p 5432:5432 -d postgres
 */


/// How to merge two users

/// Slack
/// GitHub
/// Internal Reference --- how to merge back to internal user

//
/*
 coin has reference to target id, from: to:
*/
//

//struct Source {
//    static let slack = "slack"
//    static let github = "github"
//}

//enum Sources: String, CodingKey {
//    case slack, github
//    static var all: [Sources] {
//        return [
//            .slack,
//            .github,
//        ]
//    }
//}

//final class _User: Codable {
//    var id: UUID?
//    var sources: [String: String] = [:]
//
//    init(id: UUID?, sources: [String: String]) {
//
//    }
//}
//
//extension _User {
//    convenience init(from decoder: Decoder) throws {
//        enum Id: String, CodingKey {
//            case id
//        }
//        let idValues = try decoder.container(keyedBy: Id.self)
//        id = try idValues.decode(UUID.self, forKey: .id)
//
//        let values = try decoder.container(keyedBy: Sources.self)
//        try Sources.all.forEach { source in
//            sources[source.stringValue] = try values.decode(String.self, forKey: source)
//        }
//
////        let values = try decoder.container(keyedBy: CodingKeys.self)
////        id = try values.decode(String.self, forKey: .id)
////        type = try values.decode(String.self, forKey: .type)
////        number = try values.decode(Int.self, forKey: .number)
////        name = try values.decode(String.self, forKey: .name)
////
////        /* Assign Description from an inner nested container, Ex: medium description */
////        let nestedDescription = try values.nestedContainer(keyedBy: DescriptionCodingKeys.self, forKey: .description)
////        description = try nestedDescription.decode(String.self, forKey: .medium)
////
////        country = try values.decode(String.self, forKey: .country)
////        locale = try values.decode(String.self, forKey: .locale)
////        orderPrecedence = try values.decode(Int.self, forKey: .orderPrecedence)
////
////        let dateString = try values.decode(String.self, forKey: .modified)
////        let formatter = ISO8601DateFormatter()
////        formatter.formatOptions = [.withColonSeparatorInTime, .withDashSeparatorInDate, .withFullDate, .withTime]
////        modified = formatter.date(from: dateString)
//    }
//}
//
////Custom Encoder - Omits modified date since that is a backend value
//extension _User {
//    func encode(to encoder: Encoder) throws {
////        var container = encoder.container(keyedBy: CodingKeys.self)
////        try container.encode(id, forKey: .id)
////        try container.encode(type, forKey: .type)
////        try container.encode(number, forKey: .number)
////        try container.encode(name, forKey: .name)
////
////        var descriptionContainer = container.nestedContainer(keyedBy: DescriptionCodingKeys.self, forKey: .description)
////        try descriptionContainer.encode(description, forKey: .medium)
////
////        try container.encode(country, forKey: .country)
////        try container.encode(locale, forKey: .locale)
////        try container.encode(orderPrecedence, forKey: .orderPrecedence)
//    }
//}

final class User: Codable {
    struct Sauce {
        static var slack: String { return CodingKeys.slack.description }
        static var github: String { return CodingKeys.github.description }
    }

    var id: UUID?

    var slack: String?
    var github: String?
    // potentially more in future

    init(slack: String?, github: String?) {
        self.slack = slack
        self.github = github
    }

    var sources: [(source: String, id: String)] {
        var list = [(source: String, id: String)]()
        if let slack = slack {
            list.append((Sauce.slack, slack))
        }
        if let github = github {
            list.append((Sauce.github, github))
        }
        return list
    }
}

extension User {
    convenience init(_ dict: [String: String]) {
        self.init(
            slack: dict[Sauce.slack],
            github: dict[Sauce.github]
        )
    }
}

extension User: PostgreSQLUUIDModel {}
extension User: Content {}
extension User: Migration {}
extension User: Parameter {}


///

///
/*
 Get all coins for
 */
///

struct Penny {
    func createGitHub(with req: Request) -> Future<Coin> {
        let coin = Coin(source: User.Sauce.github, to: "foo-gh", from: "bar", reason: "cuz", value: 1)
        return coin.save(on: req)
    }

    func createSlack(with req: Request) -> Future<Coin> {
        let coin = Coin(source: User.Sauce.slack, to: "foo-sl", from: "bar", reason: "cuz", value: 1)
        return coin.save(on: req)
    }

    func coins(with req: Request, for: String, usingSource source: String) throws -> Future<[Coin]> {
        // get user
        // WHERE \(source) == \(for)
        let user: User! = nil
        return try coins(with: req, for: user)
    }

    func coins(with req: Request, for user: User) throws -> Future<[Coin]> {
        let items = try user.sources.map(Coin.sourceFilter)
        let or = QueryFilterItem.group(.or, items)

        let query = Coin.query(on: req)
        query.addFilter(or)
        return query.all()
    }

    func give(coins: Int = 1, to: String, from: String, usingSource: String) {

    }

    func linkSources(sourceOne: String, idOne: String, sourceTwo: String, idTwo: String) {

    }
}

extension Penny {
    func findOrCreateUser(with req: Request, forSource source: String, withId id: String) throws -> Future<User> {
        return try findUser(with: req, forSource: source, withId: id).flatMap(to: User.self) { (user) -> Future<User> in
            if let user = user { return Future.map(on: req) { user } }
            else {
                // TODO: Get self out
                return self.createUser(with: req, forSource: source, withId: id) }
        }
    }

    func combineUsers(with req: Request, users: [User]) throws -> Future<User> {
        var allSources: [String: String] = [:]
        users.flatMap { $0.sources } .forEach { pair in
            // TODO: Add preventers for things like duplicate sources w/ mismatched ids
            // this shouldn't happen unless we somehow link, for example, two github accounts
            // with a single slack account.
            // checks should be elsewhere also
            allSources[pair.source] = pair.id
        }

        return users.map { $0.delete(on: req) }
            .flatten(on: req)
            .flatMap(to: User.self) { return User(allSources).save(on: req) }
    }

    private func findUser(with req: Request, forSource source: String, withId id: String) throws -> Future<User?> {
        let filter = try QueryFilter<PostgreSQLDatabase>(
            field: .init(name: source),
            type: .equals,
            value: .data(id)
        )
        let item = QueryFilterItem.single(filter)

        let query = User.query(on: req)
        query.addFilter(item)
        return query.first()
    }

    private func createUser(with req: Request, forSource source: String, withId id: String) -> Future<User> {
        let user = User([source: id])
        return user.save(on: req)
    }
}

extension Coin {
    static func sourceFilter(source: String, id: String) throws -> QueryFilterItem<PostgreSQLDatabase> {
        let sourceFilter = try QueryFilter<PostgreSQLDatabase>(
            field: "source",
            type: .equals,
            value: .data(source)
        )

        let idFilter = try QueryFilter<PostgreSQLDatabase>(
            field: "to",
            type: .equals,
            value: .data(id)
        )

        let source = QueryFilterItem.single(sourceFilter)
        let id = QueryFilterItem.single(idFilter)
        return .group(.and, [source, id])
    }
}

final class Coin: Codable {
    var id: UUID?

    /// ie: GitHub, Slack, other future sources
    var source: String
    /// ie: who should receive the coin
    /// the id here will correspond to the source
    var to: String
    /// ie: who gave the coin
    /// the id here will correspond to the source, for example, if source is GitHub, it
    /// will be a GitHub identifier
    var from: String

    /// An indication of the reason to possibly begin categorizing more
    var reason: String?

    /// The value of a given coin, for potentially allowing more coins in future
    var value: Int = 1

    init(source: String, to: String, from: String, reason: String?, value: Int) {
        self.source = source
        self.to = to
        self.from = from
        self.reason = reason
        self.value = value
    }
}

extension Coin: PostgreSQLUUIDModel {}
extension Coin: Content {}
extension Coin: Migration {}
extension Coin: Parameter {}


//final class CoinGift {
//    let source: String
//    let target: User
//}

//
///// A single entry of a Todo list.
//final class Todo: SQLiteModel {
//    /// The unique identifier for this `Todo`.
//    var id: Int?
//
//    /// A title describing what this `Todo` entails.
//    var title: String
//
//    /// Creates a new `Todo`.
//    init(id: Int? = nil, title: String) {
//        self.id = id
//        self.title = title
//    }
//}
//
///// Allows `Todo` to be used as a dynamic migration.
//extension Todo: Migration { }
//
///// Allows `Todo` to be encoded to and decoded from HTTP messages.
//extension Todo: Content { }
//
///// Allows `Todo` to be used as a dynamic parameter in route definitions.
//extension Todo: Parameter { }
