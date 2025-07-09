//
//  FormCell.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 03/09/2024.
//

import UIKit
import FirebaseStorage


class FormCell: UICollectionViewCell {
    // MARK: - Public API
    var form: Form? {
        didSet {
            guard let form = form else { return }
            formLabel.text = form.name
            fetchIcon(named: form.iconName)
        }
    }

    /// flip this to adjust the heart icon
    var isFavourite: Bool = false {
        didSet { updateFavouriteIcon() }
    }

    /// called when user taps the heart
    var onFavouriteTap: (() -> Void)?

    // MARK: - Subviews

    let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let formLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 18, weight: .medium)
        lbl.textColor = .black
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    /// our heart button
    private let favouriteButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.tintColor = ColorScheme.amBlue   // or your brand colour
        return btn
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(iconImageView)
        contentView.addSubview(formLabel)
        contentView.addSubview(favouriteButton)

        // Layout
        NSLayoutConstraint.activate([
            // Icon
            iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),

            // Label
            formLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: -8),
            formLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            formLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            formLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            // Favourite heart (top-right)
            favouriteButton.widthAnchor.constraint(equalToConstant: 24),
            favouriteButton.heightAnchor.constraint(equalToConstant: 24),
            favouriteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            favouriteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4)
        ])

        // Heart tap
        favouriteButton.addTarget(self, action: #selector(favouriteTapped), for: .touchUpInside)
        updateFavouriteIcon()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    // MARK: - Icon fetching

    func fetchIcon(named iconName: String) {
        let localURL = getLocalPath(for: iconName)
        if FileManager.default.fileExists(atPath: localURL.path),
           let data = try? Data(contentsOf: localURL),
           let img = UIImage(data: data) {
            iconImageView.image = img
        } else {
            let ref = Storage.storage().reference().child("icons/\(iconName)")
            ref.getData(maxSize: 1<<20) { data, error in
                if let data = data, let img = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.iconImageView.image = img
                    }
                    try? data.write(to: localURL)
                } else {
                    print("FormCell: failed to download icon \(iconName): \(error?.localizedDescription ?? "n/a")")
                }
            }
        }
    }

    private func getLocalPath(for iconName: String) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(iconName)
    }

    // MARK: - Favourite handling

    @objc private func favouriteTapped() {
        print("FormCell: heart tapped on \(form?.id ?? "unknown")")
        onFavouriteTap?()
    }

//    private func updateFavouriteIcon() {
//        let symbol = isFavourite ? "heart.fill" : "heart"
//        favouriteButton.setImage(UIImage(systemName: symbol), for: .normal)
//    }
    private func updateFavouriteIcon() {
        let symbol = isFavourite ? "star.fill" : "star"
        print("FormCell: setting favourite icon to \(symbol) (isFavourite = \(isFavourite))")
        favouriteButton.setImage(UIImage(systemName: symbol), for: .normal)
    }
}



//class FormCell: UICollectionViewCell {
//
//    var form: Form? {
//        didSet {
//            if let form = form {
//                formLabel.text = form.name
//                iconImageView.image = UIImage(named: form.iconName)
//                fetchIcon(named: form.iconName)
//            }
//        }
//    }
//
//    let iconImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.contentMode = .scaleAspectFit
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        return imageView
//    }()
//
//    private let formLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
//        label.textColor = .black
//        label.textAlignment = .center
//        label.numberOfLines = 0
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        contentView.addSubview(iconImageView)
//        contentView.addSubview(formLabel)
//
//        NSLayoutConstraint.activate([
//            iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
//            iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
//            iconImageView.widthAnchor.constraint(equalToConstant: 80),
//            iconImageView.heightAnchor.constraint(equalToConstant: 80),
//
//            formLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: -8),
//            formLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: -8),
//            formLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 8),
//            formLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 8)
//        ])
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    func fetchIcon(named iconName: String) {
//        let localPath = getLocalPath(for: iconName)
//        if FileManager.default.fileExists(atPath: localPath.path) {
//            self.iconImageView.image = UIImage(contentsOfFile: localPath.path)
//        } else {
//            let storageRef = Storage.storage().reference().child("icons/\(iconName)")
//            storageRef.getData(maxSize: 1 * 1024 * 1024) { data, error in
//                if let error = error {
//                    print("Error downloading icon: \(error)")
//                    return
//                }
//                if let data = data, let image = UIImage(data: data) {
//                    self.iconImageView.image = image
//                    try? data.write(to: localPath)
//                }
//            }
//        }
//    }
//    
//    func getLocalPath(for iconName: String) -> URL {
//        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        return documentsDirectory.appendingPathComponent(iconName)
//    }
//}
//
//
