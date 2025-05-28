import SwiftData
@preconcurrency import SwiftData

@available(*, deprecated, message: "Убрать, когда SwiftData станет Sendable")
extension ModelContext: @unchecked @retroactive Sendable {}
