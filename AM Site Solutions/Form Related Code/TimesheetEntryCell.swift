//
//  TimesheetEntryCell.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 04/09/2024.
//


import UIKit


class TimesheetEntryCell: UITableViewCell {

    let dateLabel = UILabel()
    let startTimeLabel = UILabel()
    let startLocationLabel = UILabel()
    let stopTimeLabel = UILabel()
    let stopLocationLabel = UILabel()
    let hireEquipmentLabel = UILabel() // New label for hire equipment details
    let lunchBreakLabel = UILabel()    // New label for lunch break info

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // Configure labels
        configureLabel(dateLabel, fontSize: 16, isBold: true)
        configureLabel(startTimeLabel)
        configureLabel(startLocationLabel, wraps: true)
        configureLabel(stopTimeLabel)
        configureLabel(stopLocationLabel, wraps: true)
        configureLabel(hireEquipmentLabel, fontSize: 14, isBold: false, wraps: true)
        configureLabel(lunchBreakLabel, fontSize: 14, isBold: false, wraps: true)

        hireEquipmentLabel.textColor = UIColor.darkGray
        lunchBreakLabel.textColor = UIColor.darkGray

        // Create stack views for time and location
        let startStackView = UIStackView(arrangedSubviews: [startTimeLabel, startLocationLabel])
        startStackView.axis = .vertical
        startStackView.spacing = 4

        let stopStackView = UIStackView(arrangedSubviews: [stopTimeLabel, stopLocationLabel])
        stopStackView.axis = .vertical
        stopStackView.spacing = 4

        let contentStackView = UIStackView(arrangedSubviews: [startStackView, stopStackView])
        contentStackView.axis = .horizontal
        contentStackView.spacing = 16
        contentStackView.distribution = .fillEqually

        // Stack for additional rows (hire equipment & lunch break)
        let additionalInfoStackView = UIStackView(arrangedSubviews: [hireEquipmentLabel, lunchBreakLabel])
        additionalInfoStackView.axis = .vertical
        additionalInfoStackView.spacing = 4
        additionalInfoStackView.isHidden = true // Hide by default

        // Combine all stacks in the main vertical stack
        let mainStackView = UIStackView(arrangedSubviews: [dateLabel, contentStackView, additionalInfoStackView])
        mainStackView.axis = .vertical
        mainStackView.spacing = 8

        // Add padding around the main stack view
        let paddedStackView = UIView()
        paddedStackView.addSubview(mainStackView)
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: paddedStackView.topAnchor, constant: 12),
            mainStackView.bottomAnchor.constraint(equalTo: paddedStackView.bottomAnchor, constant: -12),
            mainStackView.leadingAnchor.constraint(equalTo: paddedStackView.leadingAnchor, constant: 16),
            mainStackView.trailingAnchor.constraint(equalTo: paddedStackView.trailingAnchor, constant: -16)
        ])

        contentView.addSubview(paddedStackView)
        paddedStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            paddedStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            paddedStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            paddedStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            paddedStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with entry: TimesheetEntry) {
        dateLabel.text = formatDate(entry.date)
        startTimeLabel.text = formatTime(entry.startTime)
        startLocationLabel.text = entry.startLocation ?? "N/A"
        stopTimeLabel.text = entry.stopTime != nil ? formatTime(entry.stopTime!) : "In Progress"
        stopLocationLabel.text = entry.stopLocation ?? "N/A"

        var additionalInfoVisible = false

        // Configure hire equipment info
        if entry.hireEquipmentIncluded {
            let equipment = entry.equipmentType ?? "Missing"
            let duration = (entry.stopTime != nil) ? entry.lengthOfHire ?? "Missing" : nil
            hireEquipmentLabel.text = duration != nil ? "Equipment: \(equipment) (\(duration!))" : "Equipment: \(equipment)"
            hireEquipmentLabel.isHidden = false
            additionalInfoVisible = true
        } else {
            hireEquipmentLabel.isHidden = true
        }

        // Configure lunch break info
        if let stopTime = entry.stopTime {
            lunchBreakLabel.text = (entry.hadLunchBreak ?? false) ? "Inc Lunch Break" : "Exc Lunch Break"
            lunchBreakLabel.isHidden = false
            additionalInfoVisible = true
        } else {
            lunchBreakLabel.isHidden = true
        }

        // Show additional info section only if necessary
        (hireEquipmentLabel.superview as? UIStackView)?.isHidden = !additionalInfoVisible
    }

    private func configureLabel(_ label: UILabel, fontSize: CGFloat = 14, isBold: Bool = false, wraps: Bool = false) {
        label.font = isBold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize)
        label.numberOfLines = wraps ? 0 : 1
        label.lineBreakMode = wraps ? .byWordWrapping : .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
    }

    private func formatDate(_ timestamp: TimeInterval) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: Date(timeIntervalSince1970: timestamp / 1000))
    }

    private func formatTime(_ timestamp: TimeInterval) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date(timeIntervalSince1970: timestamp / 1000))
    }
}



//class TimesheetEntryCell: UITableViewCell {
//
//    let dateLabel = UILabel()
//    let startTimeLabel = UILabel()
//    let startLocationLabel = UILabel()
//    let stopTimeLabel = UILabel()
//    let stopLocationLabel = UILabel()
//
//    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//
//        // Configure labels
//        configureLabel(dateLabel, fontSize: 16, isBold: true)
//        configureLabel(startTimeLabel)
//        configureLabel(startLocationLabel, wraps: true) // Ensure wrapping for location
//        configureLabel(stopTimeLabel)
//        configureLabel(stopLocationLabel, wraps: true)  // Ensure wrapping for location
//
//        // Create vertical stack view for left and right columns
//        let startStackView = UIStackView(arrangedSubviews: [startTimeLabel, startLocationLabel])
//        startStackView.axis = .vertical
//        startStackView.spacing = 4
//
//        let stopStackView = UIStackView(arrangedSubviews: [stopTimeLabel, stopLocationLabel])
//        stopStackView.axis = .vertical
//        stopStackView.spacing = 4
//
//        // Horizontal stack view to hold both start and stop stack views
//        let contentStackView = UIStackView(arrangedSubviews: [startStackView, stopStackView])
//        contentStackView.axis = .horizontal
//        contentStackView.spacing = 16
//        contentStackView.distribution = .fillEqually
//
//        // Create a vertical stack view for dateLabel and contentStackView
//        let mainStackView = UIStackView(arrangedSubviews: [dateLabel, contentStackView])
//        mainStackView.axis = .vertical
//        mainStackView.spacing = 8
//
//        // Add padding around the main stack view
//        let paddedStackView = UIView()
//        paddedStackView.addSubview(mainStackView)
//        mainStackView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            mainStackView.topAnchor.constraint(equalTo: paddedStackView.topAnchor, constant: 12),
//            mainStackView.bottomAnchor.constraint(equalTo: paddedStackView.bottomAnchor, constant: -12),
//            mainStackView.leadingAnchor.constraint(equalTo: paddedStackView.leadingAnchor, constant: 16),
//            mainStackView.trailingAnchor.constraint(equalTo: paddedStackView.trailingAnchor, constant: -16)
//        ])
//
//        contentView.addSubview(paddedStackView)
//        paddedStackView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            paddedStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
//            paddedStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
//            paddedStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//            paddedStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
//        ])
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    func configure(with entry: TimesheetEntry) {
//        dateLabel.text = formatDate(entry.date)
//        startTimeLabel.text = formatTime(entry.startTime)
//        startLocationLabel.text = entry.startLocation ?? "N/A"
//        stopTimeLabel.text = entry.stopTime != nil ? formatTime(entry.stopTime!) : "In Progress"
//        stopLocationLabel.text = entry.stopLocation ?? "N/A"
//    }
//
//    private func configureLabel(_ label: UILabel, fontSize: CGFloat = 14, isBold: Bool = false, wraps: Bool = false) {
//        label.font = isBold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize)
//        label.numberOfLines = wraps ? 0 : 1  // Allow wrapping for location
//        label.lineBreakMode = wraps ? .byWordWrapping : .byTruncatingTail
//        label.translatesAutoresizingMaskIntoConstraints = false
//    }
//
//    private func formatDate(_ timestamp: TimeInterval) -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "dd MMM yyyy"
//        return formatter.string(from: Date(timeIntervalSince1970: timestamp / 1000)) // Convert from ms to seconds
//    }
//
//    private func formatTime(_ timestamp: TimeInterval) -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "HH:mm"
//        return formatter.string(from: Date(timeIntervalSince1970: timestamp / 1000)) // Convert from ms to seconds
//    }
//}
