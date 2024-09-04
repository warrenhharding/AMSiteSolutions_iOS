//
//  FormCell.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 03/09/2024.
//

import UIKit
import FirebaseStorage

class FormCell: UICollectionViewCell {

    var form: Form? {
        didSet {
            if let form = form {
                formLabel.text = form.name
                iconImageView.image = UIImage(named: form.iconName)
                fetchIcon(named: form.iconName)
            }
        }
    }

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let formLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(iconImageView)
        contentView.addSubview(formLabel)

        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),

            formLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: -8),
            formLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: -8),
            formLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 8),
            formLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 8)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func fetchIcon(named iconName: String) {
        let localPath = getLocalPath(for: iconName)
        if FileManager.default.fileExists(atPath: localPath.path) {
            self.iconImageView.image = UIImage(contentsOfFile: localPath.path)
        } else {
            let storageRef = Storage.storage().reference().child("icons/\(iconName)")
            storageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
                if let error = error {
                    print("Error downloading icon: \(error)")
                    return
                }
                if let data = data, let image = UIImage(data: data) {
                    self.iconImageView.image = image
                    try? data.write(to: localPath)
                }
            }
        }
    }
    
    func getLocalPath(for iconName: String) -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent(iconName)
    }
}


