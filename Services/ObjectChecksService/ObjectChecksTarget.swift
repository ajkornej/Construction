import Foundation

enum ObjectChecksTarget {
    case getTickets
}

extension ObjectChecksTarget: NetworkTarget {
    var requestPath: String {
        switch self {
        case .getTickets:
            RequestPath.getTickets
        }
    }
}
