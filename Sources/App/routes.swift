import Routing
import Vapor

public func routes(_ router: Router) throws {
    // I always keep a status check
    router.get("status") { req in
        return "Alive and well: \(Date())"
    }

    try pennyapi(router)
}
