
import Foundation

// MARK: - Address
//struct Address: Codable {
//    var roadNumber: String = ""
//    var area: String = ""
//    var county: String = ""
//    var eircode: String = ""
//}

// MARK: - CustomerSite
struct CustomerSite: Codable {
    var id: String = ""
    var customerName: String = ""
    var siteName: String = ""
    var contactName: String = ""
    var contactPhone: String = ""
    var contactEmail: String = ""
    var siteAddress: Address = Address()
    var archived: Bool = false
}
