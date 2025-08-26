
import Foundation

// MARK: - Customer
struct Customer: Codable {
    var id: String = ""
    var companyName: String = ""
    var contactName: String = ""
    var email: String = ""
    var phone: String = ""
    var address: Address = Address()
    var appUser: Bool = false
    var archived: Bool = false
    var linkedCustomerId: String?
    var linkedCustomerName: String?

    var formattedAddress: String {
        let components = [address.roadNumber, address.area, address.county, address.eircode]
            .filter { !($0.isEmpty) }
        return components.joined(separator: ", ")
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case companyName
        case contactName
        case email
        case phone
        case address
        case appUser
        case archived
        case linkedCustomerId
        case linkedCustomerName
    }
}

// MARK: - Address
struct Address: Codable {
    var roadNumber: String = ""
    var area: String = ""
    var county: String = ""
    var eircode: String = ""
    
    enum CodingKeys: String, CodingKey {
        case roadNumber
        case area
        case county
        case eircode
    }
}
