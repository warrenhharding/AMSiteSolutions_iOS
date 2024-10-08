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

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        // Configure labels
        configureLabel(dateLabel, fontSize: 16, isBold: true)
        configureLabel(startTimeLabel)
        configureLabel(startLocationLabel, wraps: true) // Ensure wrapping for location
        configureLabel(stopTimeLabel)
        configureLabel(stopLocationLabel, wraps: true)  // Ensure wrapping for location

        // Create vertical stack view for left and right columns
        let startStackView = UIStackView(arrangedSubviews: [startTimeLabel, startLocationLabel])
        startStackView.axis = .vertical
        startStackView.spacing = 4

        let stopStackView = UIStackView(arrangedSubviews: [stopTimeLabel, stopLocationLabel])
        stopStackView.axis = .vertical
        stopStackView.spacing = 4

        // Horizontal stack view to hold both start and stop stack views
        let contentStackView = UIStackView(arrangedSubviews: [startStackView, stopStackView])
        contentStackView.axis = .horizontal
        contentStackView.spacing = 16
        contentStackView.distribution = .fillEqually

        // Create a vertical stack view for dateLabel and contentStackView
        let mainStackView = UIStackView(arrangedSubviews: [dateLabel, contentStackView])
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
    }

    private func configureLabel(_ label: UILabel, fontSize: CGFloat = 14, isBold: Bool = false, wraps: Bool = false) {
        label.font = isBold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize)
        label.numberOfLines = wraps ? 0 : 1  // Allow wrapping for location
        label.lineBreakMode = wraps ? .byWordWrapping : .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
    }

    private func formatDate(_ timestamp: TimeInterval) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: Date(timeIntervalSince1970: timestamp / 1000)) // Convert from ms to seconds
    }

    private func formatTime(_ timestamp: TimeInterval) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date(timeIntervalSince1970: timestamp / 1000)) // Convert from ms to seconds
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
//        // Add padding around the content stack view
//        let paddedStackView = UIView()
//        paddedStackView.addSubview(contentStackView)
//        contentStackView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            contentStackView.topAnchor.constraint(equalTo: paddedStackView.topAnchor, constant: 12),
//            contentStackView.bottomAnchor.constraint(equalTo: paddedStackView.bottomAnchor, constant: -12),
//            contentStackView.leadingAnchor.constraint(equalTo: paddedStackView.leadingAnchor, constant: 16),
//            contentStackView.trailingAnchor.constraint(equalTo: paddedStackView.trailingAnchor, constant: -16)
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
//        return formatter.string(from: Date(timeIntervalSince1970: timestamp))
//    }
//
//    private func formatTime(_ timestamp: TimeInterval) -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "HH:mm"
//        return formatter.string(from: Date(timeIntervalSince1970: timestamp))
//    }
//}







//import UIKit
//
//class TimesheetEntryCell: UITableViewCell {
//
//    // Define UI elements
//    let dateLabel = UILabel()
//    
//    // Start time and location
//    let startTimeImageView = UIImageView(image: UIImage(systemName: "clock"))
//    let startTimeLabel = UILabel()
//    let startLocationImageView = UIImageView(image: UIImage(systemName: "location"))
//    let startLocationLabel = UILabel()
//    
//    // Stop time and location
//    let stopTimeImageView = UIImageView(image: UIImage(systemName: "clock"))
//    let stopTimeLabel = UILabel()
//    let stopLocationImageView = UIImageView(image: UIImage(systemName: "location"))
//    let stopLocationLabel = UILabel()
//    
//    // Initialization of the cell
//    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        setupViews()
//        setupConstraints()
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    // MARK: - Setup Views
//    private func setupViews() {
//        // Date label
//        dateLabel.font = UIFont.boldSystemFont(ofSize: 16)
//        dateLabel.textColor = UIColor.systemBlue
//        dateLabel.translatesAutoresizingMaskIntoConstraints = false
//        contentView.addSubview(dateLabel)
//        
//        // Start time
//        startTimeLabel.translatesAutoresizingMaskIntoConstraints = false
//        startTimeLabel.font = UIFont.systemFont(ofSize: 14)
//        startTimeImageView.translatesAutoresizingMaskIntoConstraints = false
//        startTimeImageView.tintColor = UIColor.systemGray
//        contentView.addSubview(startTimeLabel)
//        contentView.addSubview(startTimeImageView)
//        
//        // Start location
//        startLocationLabel.translatesAutoresizingMaskIntoConstraints = false
//        startLocationLabel.font = UIFont.systemFont(ofSize: 14)
//        startLocationImageView.translatesAutoresizingMaskIntoConstraints = false
//        startLocationImageView.tintColor = UIColor.systemGray
//        contentView.addSubview(startLocationLabel)
//        contentView.addSubview(startLocationImageView)
//        
//        // Stop time
//        stopTimeLabel.translatesAutoresizingMaskIntoConstraints = false
//        stopTimeLabel.font = UIFont.systemFont(ofSize: 14)
//        stopTimeImageView.translatesAutoresizingMaskIntoConstraints = false
//        stopTimeImageView.tintColor = UIColor.systemGray
//        contentView.addSubview(stopTimeLabel)
//        contentView.addSubview(stopTimeImageView)
//        
//        // Stop location
//        stopLocationLabel.translatesAutoresizingMaskIntoConstraints = false
//        stopLocationLabel.font = UIFont.systemFont(ofSize: 14)
//        stopLocationImageView.translatesAutoresizingMaskIntoConstraints = false
//        stopLocationImageView.tintColor = UIColor.systemGray
//        contentView.addSubview(stopLocationLabel)
//        contentView.addSubview(stopLocationImageView)
//    }
//    
//    // MARK: - Setup Constraints
//    private func setupConstraints() {
//        // Date label constraints
//        NSLayoutConstraint.activate([
//            dateLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
//            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//        ])
//        
//        // Start time and location constraints (horizontal stack)
//        NSLayoutConstraint.activate([
//            startTimeImageView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
//            startTimeImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            startTimeImageView.widthAnchor.constraint(equalToConstant: 16),
//            startTimeImageView.heightAnchor.constraint(equalToConstant: 16),
//            
//            startTimeLabel.centerYAnchor.constraint(equalTo: startTimeImageView.centerYAnchor),
//            startTimeLabel.leadingAnchor.constraint(equalTo: startTimeImageView.trailingAnchor, constant: 8),
//        ])
//        
//        NSLayoutConstraint.activate([
//            startLocationImageView.topAnchor.constraint(equalTo: startTimeImageView.bottomAnchor, constant: 8),
//            startLocationImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            startLocationImageView.widthAnchor.constraint(equalToConstant: 16),
//            startLocationImageView.heightAnchor.constraint(equalToConstant: 16),
//            
//            startLocationLabel.centerYAnchor.constraint(equalTo: startLocationImageView.centerYAnchor),
//            startLocationLabel.leadingAnchor.constraint(equalTo: startLocationImageView.trailingAnchor, constant: 8),
//        ])
//        
//        // Stop time and location constraints (horizontal stack)
//        NSLayoutConstraint.activate([
//            stopTimeImageView.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 8),
//            stopTimeImageView.leadingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 16),
//            stopTimeImageView.widthAnchor.constraint(equalToConstant: 16),
//            stopTimeImageView.heightAnchor.constraint(equalToConstant: 16),
//            
//            stopTimeLabel.centerYAnchor.constraint(equalTo: stopTimeImageView.centerYAnchor),
//            stopTimeLabel.leadingAnchor.constraint(equalTo: stopTimeImageView.trailingAnchor, constant: 8),
//        ])
//        
//        NSLayoutConstraint.activate([
//            stopLocationImageView.topAnchor.constraint(equalTo: stopTimeImageView.bottomAnchor, constant: 8),
//            stopLocationImageView.leadingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 16),
//            stopLocationImageView.widthAnchor.constraint(equalToConstant: 16),
//            stopLocationImageView.heightAnchor.constraint(equalToConstant: 16),
//            
//            stopLocationLabel.centerYAnchor.constraint(equalTo: stopLocationImageView.centerYAnchor),
//            stopLocationLabel.leadingAnchor.constraint(equalTo: stopLocationImageView.trailingAnchor, constant: 8),
//            stopLocationLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
//        ])
//    }
//    
//    // Method to configure the cell
//    func configure(with entry: TimesheetEntry) {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "dd MMM yyyy"
//        dateLabel.text = dateFormatter.string(from: Date(timeIntervalSince1970: entry.date))
//        
//        let timeFormatter = DateFormatter()
//        timeFormatter.dateFormat = "HH:mm"
//        startTimeLabel.text = timeFormatter.string(from: Date(timeIntervalSince1970: entry.startTime))
//        startLocationLabel.text = entry.startLocation ?? "N/A"
//        
//        if let stopTime = entry.stopTime {
//            stopTimeLabel.text = timeFormatter.string(from: Date(timeIntervalSince1970: stopTime))
//        } else {
//            stopTimeLabel.text = "In Progress"
//        }
//        stopLocationLabel.text = entry.stopLocation ?? "N/A"
//    }
//}
//
