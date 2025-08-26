//
//  Machine.swift
//  
//
//  Created by Warren Harding on 06/08/2025.
//

import Foundation
import Firebase

struct Machine: Codable {
    // Core fields
    var machineId: String
    var derivedMachineId: String
    var name: String
    var type: String
    var manufacturer: String
    var model: String
    var serialNumber: String
    var plantEquipmentNumber: String
    var yearOfManufacture: String
    var safeWorkingLoad: String
    var equipParticulars: String
    var ga2ReportType: String
    var status: String
    var qrCodeId: String
    var customerId: String
    var images: [String]

    // Default initializer
    init() {
        self.machineId = ""
        self.derivedMachineId = ""
        self.name = ""
        self.type = ""
        self.manufacturer = ""
        self.model = ""
        self.serialNumber = ""
        self.plantEquipmentNumber = ""
        self.yearOfManufacture = ""
        self.safeWorkingLoad = ""
        self.equipParticulars = ""
        self.ga2ReportType = ""
        self.status = "Active"
        self.qrCodeId = ""
        self.customerId = ""
        self.images = []
    }

    // Firebase mapping initializer
    init?(snapshot: DataSnapshot) {
        guard let value = snapshot.value as? [String: Any] else { return nil }
        machineId = snapshot.key
        derivedMachineId = value["derivedMachineId"] as? String ?? ""
        name = value["name"] as? String ?? ""
        type = value["type"] as? String ?? ""
        manufacturer = value["manufacturer"] as? String ?? ""
        model = value["model"] as? String ?? ""
        serialNumber = value["serialNumber"] as? String ?? ""
        plantEquipmentNumber = value["plantEquipmentNumber"] as? String ?? ""
        yearOfManufacture = value["yearOfManufacture"] as? String ?? ""
        safeWorkingLoad = value["safeWorkingLoad"] as? String ?? ""
        equipParticulars = value["equipParticulars"] as? String ?? ""
        ga2ReportType = value["ga2ReportType"] as? String ?? ""
        status = value["status"] as? String ?? "Active"
        qrCodeId = value["qrCodeId"] as? String ?? ""
        customerId = value["customerId"] as? String ?? ""
        images = value["images"] as? [String] ?? []
    }

    func toDictionary() -> [String: Any] {
        return [
            "machineId": machineId,
            "derivedMachineId": derivedMachineId,
            "name": name,
            "type": type,
            "manufacturer": manufacturer,
            "model": model,
            "serialNumber": serialNumber,
            "plantEquipmentNumber": plantEquipmentNumber,
            "yearOfManufacture": yearOfManufacture,
            "safeWorkingLoad": safeWorkingLoad,
            "equipParticulars": equipParticulars,
            "ga2ReportType": ga2ReportType,
            "status": status,
            "qrCodeId": qrCodeId,
            "customerId": customerId,
            "images": images
        ]
    }
}






//struct Machine: Codable {
//    // Core fields
//    var machineId: String = ""
//    var derivedMachineId: String = ""
//    var name: String = ""
//    var type: String = ""
//    var manufacturer: String = ""
//    var model: String = ""
//    var serialNumber: String = ""
//    var plantEquipmentNumber: String = ""
//    var yearOfManufacture: String = ""
//    var safeWorkingLoad: String = ""
//    var equipParticulars: String = ""
//    var ga2ReportType: String = ""
//    var status: String = "Active"
//    var qrCodeId: String = ""
//    var customerId: String = ""
//    var images: [String] = [] // For photo URIs
//
//    // Firebase mapping
//    init?(snapshot: DataSnapshot) {
//        guard let value = snapshot.value as? [String: Any] else { return nil }
//        machineId = snapshot.key
//        derivedMachineId = value["derivedMachineId"] as? String ?? ""
//        name = value["name"] as? String ?? ""
//        type = value["type"] as? String ?? ""
//        manufacturer = value["manufacturer"] as? String ?? ""
//        model = value["model"] as? String ?? ""
//        serialNumber = value["serialNumber"] as? String ?? ""
//        plantEquipmentNumber = value["plantEquipmentNumber"] as? String ?? ""
//        yearOfManufacture = value["yearOfManufacture"] as? String ?? ""
//        safeWorkingLoad = value["safeWorkingLoad"] as? String ?? ""
//        equipParticulars = value["equipParticulars"] as? String ?? ""
//        ga2ReportType = value["ga2ReportType"] as? String ?? ""
//        status = value["status"] as? String ?? "Active"
//        qrCodeId = value["qrCodeId"] as? String ?? ""
//        customerId = value["customerId"] as? String ?? ""
//        images = value["images"] as? [String] ?? []
//    }
//
//    func toDictionary() -> [String: Any] {
//        return [
//            "machineId": machineId,
//            "derivedMachineId": derivedMachineId,
//            "name": name,
//            "type": type,
//            "manufacturer": manufacturer,
//            "model": model,
//            "serialNumber": serialNumber,
//            "plantEquipmentNumber": plantEquipmentNumber,
//            "yearOfManufacture": yearOfManufacture,
//            "safeWorkingLoad": safeWorkingLoad,
//            "equipParticulars": equipParticulars,
//            "ga2ReportType": ga2ReportType,
//            "status": status,
//            "qrCodeId": qrCodeId,
//            "customerId": customerId,
//            "images": images
//        ]
//    }
//}
