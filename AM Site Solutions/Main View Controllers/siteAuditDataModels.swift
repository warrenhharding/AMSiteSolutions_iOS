import UIKit

// A simple in-memory image cache to prevent re-downloading images
class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()

    private init() {}

    func image(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }

    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
}

// Helper extension to encode Codable structs into Dictionaries for Firebase.
extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
    }
}

// Enum to represent the report types, mirroring Android.
enum ReportType: String, CaseIterable {
    case progressReport = "Progress Report"
    case incidentReport = "Incident Report"
    case snagList = "Snag List"
    case siteSafetyAudit = "Site Safety Audit Report"

    var firebaseValue: String {
        return self.rawValue
    }
}

// Data model for the Site Audit Report, aligned with the Android source of truth.
struct SiteAuditReport: Codable {
    var reportId: String
    var reportType: String
    var reportTitle: String
    var clientId: String      // Renamed to match Android
    var clientName: String    // Renamed to match Android
    var siteId: String
    var siteName: String
    var notes: [String: SiteAuditNote]
    var signatureUrl: String?
    var status: String // "Draft" or "Finalized"
    var createdBy: String
    var createdAt: TimeInterval // Handles ms/s in custom decoder
    var finalizedAt: TimeInterval?
    var isFinalized: Bool // Handles Int/Bool in custom decoder
    var pdfGenerationRequested: Bool
    var pdfDownloadUrl: String?
    var pdfGenerationError: String?

    // CodingKeys now directly match the property names and the Firebase structure.
    enum CodingKeys: String, CodingKey {
        case reportId, reportType, reportTitle, clientId, clientName, siteId, siteName, notes, signatureUrl, status, createdBy, createdAt, finalizedAt, isFinalized, pdfGenerationRequested, pdfDownloadUrl, pdfGenerationError
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reportId = try container.decode(String.self, forKey: .reportId)
        reportType = try container.decode(String.self, forKey: .reportType)
        reportTitle = try container.decode(String.self, forKey: .reportTitle)
        clientId = try container.decode(String.self, forKey: .clientId)
        clientName = try container.decode(String.self, forKey: .clientName)
        siteId = try container.decode(String.self, forKey: .siteId)
        siteName = try container.decode(String.self, forKey: .siteName)
        notes = try container.decodeIfPresent([String: SiteAuditNote].self, forKey: .notes) ?? [:]
        signatureUrl = try container.decodeIfPresent(String.self, forKey: .signatureUrl)
        status = try container.decode(String.self, forKey: .status)
        createdBy = try container.decode(String.self, forKey: .createdBy)
        finalizedAt = try container.decodeIfPresent(TimeInterval.self, forKey: .finalizedAt)
        pdfGenerationRequested = try container.decodeIfPresent(Bool.self, forKey: .pdfGenerationRequested) ?? false
        pdfDownloadUrl = try container.decodeIfPresent(String.self, forKey: .pdfDownloadUrl)
        pdfGenerationError = try container.decodeIfPresent(String.self, forKey: .pdfGenerationError)

        // Handle timestamp conversion (Android: ms, iOS: s)
        let rawCreatedAt = try container.decode(TimeInterval.self, forKey: .createdAt)
        if rawCreatedAt > 1_000_000_000_000 { // Likely milliseconds
            createdAt = rawCreatedAt / 1000.0
        } else { // Likely seconds
            createdAt = rawCreatedAt
        }
        
        // Handle boolean for isFinalized (Android can send 0/1)
        do {
            isFinalized = try container.decode(Bool.self, forKey: .isFinalized)
        } catch {
            let intValue = try container.decode(Int.self, forKey: .isFinalized)
            isFinalized = (intValue != 0)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(reportId, forKey: .reportId)
        try container.encode(reportType, forKey: .reportType)
        try container.encode(reportTitle, forKey: .reportTitle)
        try container.encode(clientId, forKey: .clientId)
        try container.encode(clientName, forKey: .clientName)
        try container.encode(siteId, forKey: .siteId)
        try container.encode(siteName, forKey: .siteName)
        try container.encode(notes, forKey: .notes)
        try container.encodeIfPresent(signatureUrl, forKey: .signatureUrl)
        try container.encode(status, forKey: .status)
        try container.encode(createdBy, forKey: .createdBy)
        try container.encodeIfPresent(finalizedAt, forKey: .finalizedAt)
        try container.encode(pdfGenerationRequested, forKey: .pdfGenerationRequested)
        try container.encodeIfPresent(pdfDownloadUrl, forKey: .pdfDownloadUrl)
        try container.encodeIfPresent(pdfGenerationError, forKey: .pdfGenerationError)
        try container.encode(isFinalized, forKey: .isFinalized)

        // Always encode timestamp in milliseconds for consistency
        let createdAtInMilliseconds = Int64(createdAt * 1000)
        try container.encode(createdAtInMilliseconds, forKey: .createdAt)
    }
    
    // Custom initializer for creating a new report, ensuring all required fields are set.
    init(reportId: String, reportType: String, reportTitle: String, clientId: String, clientName: String, siteId: String, siteName: String, createdBy: String, isFinalised: Bool) {
        self.reportId = reportId
        self.reportType = reportType
        self.reportTitle = reportTitle
        self.clientId = clientId
        self.clientName = clientName
        self.siteId = siteId
        self.siteName = siteName
        self.createdBy = createdBy
        self.isFinalized = isFinalised
        
        self.notes = [:]
        self.signatureUrl = nil
        self.status = isFinalised ? "Finalized" : "Draft"
        self.createdAt = Date().timeIntervalSince1970
        self.finalizedAt = isFinalised ? Date().timeIntervalSince1970 : nil
        self.pdfGenerationRequested = false
        self.pdfDownloadUrl = nil
        self.pdfGenerationError = nil
    }
}

// Data model for a single note, identical to the Android source of truth.
struct SiteAuditNote: Codable, Equatable {
    var noteId: String
    var description: String?
    var imageUrl: String?
    var annotatedImageUrl: String?
    var order: Int
    var timestamp: TimeInterval
    
    // Helper properties not encoded into JSON
    var localImage: UIImage?
    var localAnnotatedImage: UIImage?

    enum CodingKeys: String, CodingKey {
        case noteId, description, imageUrl, annotatedImageUrl, order, timestamp
    }
    
    // Custom decoder to handle data inconsistencies from Firebase
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        noteId = try container.decodeIfPresent(String.self, forKey: .noteId) ?? UUID().uuidString
        description = try container.decodeIfPresent(String.self, forKey: .description)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        annotatedImageUrl = try container.decodeIfPresent(String.self, forKey: .annotatedImageUrl)
        order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0

        // Handle timestamp conversion (Android: ms, iOS: s)
        let rawTimestamp = try container.decodeIfPresent(TimeInterval.self, forKey: .timestamp) ?? Date().timeIntervalSince1970 * 1000
        if rawTimestamp > 1_000_000_000_000 { // Likely milliseconds
            timestamp = rawTimestamp / 1000.0
        } else { // Likely seconds
            timestamp = rawTimestamp
        }
    }

    // Custom encoder to ensure data is written in the Android-compatible format
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(noteId, forKey: .noteId)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(annotatedImageUrl, forKey: .annotatedImageUrl)
        try container.encode(order, forKey: .order)
        
        // Always encode timestamp in milliseconds for consistency
        let timestampInMilliseconds = Int64(timestamp * 1000)
        try container.encode(timestampInMilliseconds, forKey: .timestamp)
    }

    // Custom initializer for creating a new note within the iOS app
    init(order: Int, description: String? = nil, localImage: UIImage? = nil) {
        self.noteId = UUID().uuidString
        self.order = order
        self.description = description
        self.localImage = localImage
        self.timestamp = Date().timeIntervalSince1970
        self.imageUrl = nil
        self.annotatedImageUrl = nil
    }
    
    static func == (lhs: SiteAuditNote, rhs: SiteAuditNote) -> Bool {
        return lhs.noteId == rhs.noteId
    }
}
