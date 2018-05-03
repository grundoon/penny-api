import Dispatch
import XCTest

import Vapor
import Crypto
import Random
@testable import Mint

final class PennyTests: XCTestCase {

//    func testAccount() throws {
//        let worker = Request(using: app)
//        let one = try saveExternal(source: "github", id: "932198", on: worker).wait()
//        print(one)
//        print("")
//
//        let all = try allExternals(on: worker).wait()
//        print(all)
//        print("")
//    }
//
    func testUserCrud() throws {
        // MARK: GitHub
        let ghe = MockExternalAccount.randomGitHub()
        let github = try! testUserCrud(on: ghe)
//        XCTAssertEqual(github?.github, ghe.externalId)

        // MARK: Slack
        let sle = MockExternalAccount.randomSlack()
        let slack = try testUserCrud(on: sle)
        XCTAssertEqual(slack?.slack, sle.externalId)

        var users = [Account]()
        if let slack = slack {
            users.append(slack)
        }
        if let github = github {
            users.append(github)
        }

        let mint = mockVault()

        // MARK: Fetch All, Test Delete Query
        let ids = users.compactMap { $0.id }
        XCTAssertEqual(users.count, ids.count)
        let fetch = try mint.accounts.fetchQuery(ids: ids)
        let fetched = try fetch.all().wait()
        let fetchedIds = fetched.compactMap { $0.id }
        XCTAssertEqual(ids.map({ $0.uuidString }).sorted(by: <), fetchedIds.map({ $0.uuidString }).sorted(by: <))

        // MARK: Combine
        let combined = try mint.accounts.combine(users).wait()
        XCTAssertEqual(combined.slack, sle.externalId)
        XCTAssertEqual(combined.github, ghe.externalId)

        // MARK: Ensure Originals Gone
        let originalUsers = try fetch.all().wait()
        XCTAssert(originalUsers.isEmpty)

        // MARK: Retrieve Combined
        let one = try mint.accounts.get(ghe).wait()
        let two = try mint.accounts.get(sle).wait()

        let group = [one, two, combined].compactMap { $0 }
        XCTAssert(group.count == 3)

        func assertAllEqual<T: Hashable>(_ arr: [T], _ msg: String) {
            XCTAssert(Set(arr).count == 1, msg)
        }

        let groupIds = group.compactMap { $0.id }
        XCTAssert(groupIds.count == group.count, "missing at least one penny id")
        assertAllEqual(groupIds, "penny ids didn't match")

        let ghs = group.compactMap { $0.github }
        XCTAssert(ghs.count == group.count, "missing at least one github id")
        assertAllEqual(ghs, "github ids didn't match")

        let sls = group.compactMap { $0.slack }
        XCTAssert(sls.count == group.count, "missing at least one slack id")
        assertAllEqual(sls, "slack ids didn't match")
    }

    private func testUserCrud(on external: ExternalAccount) throws -> Account? {
        let id = external.externalId
        let source = external.externalSource

        let mint = mockVault()

        // MARK: Clean
        var user = try mint.accounts
            .search(source: source, sourceId: id)
            .wait()
        // In case it exists
        if let user = user {
            let _ = mint.accounts.delete(user)
        }

        // MARK: Find - Fail
        user = try mint.accounts
            .search(source: source, sourceId: id)
            .wait()
        XCTAssert(user == nil, "found user that should NOT exist")

        // MARK: Create
        user = try mint.accounts.create(source: source, sourceId: id).wait()
        XCTAssert(user != nil, "did NOT create user")

        // MARK: Find - Success
        user = try mint.accounts
            .search(source: source, sourceId: id)
            .wait()
        XCTAssert(user != nil, "did NOT find user that SHOULD exist")

        return user
    }
//
//    func testGiveCoin() throws {
//        let penny = mockPenny()
//
//        let giver = MockExternalUser.randomGitHub()
//        let receiver = MockExternalUser.randomGitHub()
//
//        let _ = try penny.coins.give(to: receiver.externalId, from: giver.externalId, source: "github", reason: "I think you're great").wait()
//
//        let user = try penny.user.findOrCreate(receiver).wait()
//        let coins = try penny.coins.all(for: user).wait()
//        XCTAssert(coins.count == 1)
//    }
//
//    static let allTests = [
//        ("testUserCrud", testUserCrud),
//        ("testGiveCoin", testGiveCoin),
//    ]
}

func mockVault() -> Mint.Vault {
    let req = Request(using: app)
    return Mint.Vault(req)
}

func mockPenny() -> Mint.Bot {
    let response = Request(using: app)
    return Mint.Bot(response)
}

let app: Application = {
    var config = Config.default()
    var env = try! Environment.detect()
    var services = Services.default()

    let provider = MintProvider()
    try! provider.register(&services)

//    try! App.configure(&config, &env, &services)

    let app = try! Application(
        config: config,
        environment: env,
        services: services
    )

//    try! App.boot(app)

    return app
}()

struct MockExternalAccount: ExternalAccount {
    let externalId: String
    let externalSource: String

    static func randomGitHub() -> MockExternalAccount {
        let int = try! OSRandom().generate(Int.self)
        return MockExternalAccount(
            externalId: int.description,
            externalSource: "github"
        )
    }

    static func randomSlack() -> MockExternalAccount {
        let uuid = UUID().uuidString
        return MockExternalAccount(
            externalId: uuid,
            externalSource: "slack"
        )
    }
}
