//
//  AdminUserCardsViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 03/03/2025.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class AdminUserCardsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var tableView: UITableView!
    var cards: [Card] = []
    let refreshControl = UIRefreshControl()
    var noCardsLabel: UILabel!
    
    // Passed from previous screen:
    var userId: String!  // Must be set before presenting this VC
    var userName: String = "Unknown User"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "\(TranslationManager.shared.getTranslation(for: "adminCards.adminCardListTitle")) \(userName)"  // Updated once user info loads
        print("AdminUserCardsViewController: viewDidLoad")
        
        setupNoCardsLabel()
        setupTableView()
        loadUserInfoAndCards()
    }
    
    func setupTableView() {
        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        // Do not register a cell so that we create one with the .subtitle style below
        refreshControl.addTarget(self, action: #selector(refreshCards), for: .valueChanged)
        tableView.refreshControl = refreshControl
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        print("AdminUserCardsViewController: TableView set up")
    }
    
    func setupNoCardsLabel() {
        noCardsLabel = UILabel()
        noCardsLabel.translatesAutoresizingMaskIntoConstraints = false
        noCardsLabel.text = TranslationManager.shared.getTranslation(for: "adminCards.noCards")
        noCardsLabel.textAlignment = .center
        noCardsLabel.isHidden = true
        view.addSubview(noCardsLabel)
        NSLayoutConstraint.activate([
            noCardsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noCardsLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc func refreshCards() {
        print("AdminUserCardsViewController: Refreshing cards")
        loadUserInfoAndCards()
    }
    
    func loadUserInfoAndCards() {
        guard let userId = userId, !userId.isEmpty else {
            self.showAlert(message: TranslationManager.shared.getTranslation(for: "adminCards.invalidUser")) { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            return
        }
        print("AdminUserCardsViewController: Loading info and cards for userId: \(userId)")
        
        let ref = Database.database().reference().child("users").child(userId)
        ref.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }
            self.cards.removeAll()
            // Optional: check if snapshot.exists() and log if it does not.
            if let name = snapshot.childSnapshot(forPath: "userName").value as? String {
                self.userName = name
            } else {
                print("AdminUserCardsViewController: userName not found for userId: \(userId)")
            }
            self.title = "\(TranslationManager.shared.getTranslation(for: "adminCards.adminCardListTitle")) \(self.userName)"
            let cardsSnapshot = snapshot.childSnapshot(forPath: "userCards")
            for child in cardsSnapshot.children {
                if let snap = child as? DataSnapshot, var card = Card(snapshot: snap) {
                    // Make sure cardId is mutable and then assign it:
                    card.cardId = snap.key
                    self.cards.append(card)
                } else {
                    print("AdminUserCardsViewController: Failed to parse card from snapshot.")
                }
            }
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
                self.tableView.reloadData()
                self.noCardsLabel.isHidden = !self.cards.isEmpty
                self.tableView.isHidden = self.cards.isEmpty
                print("AdminUserCardsViewController: Loaded \(self.cards.count) cards")
            }
        } withCancel: { [weak self] error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
                self.showAlert(message: TranslationManager.shared.getTranslation(for: "myCards.failedToLoadCards"))
            }
        }
    }

    

    
    // MARK: - UITableViewDataSource Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cards.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cellIdentifier = "Cell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        }
        // Set layout margins for extra padding
        cell!.preservesSuperviewLayoutMargins = false
        cell!.layoutMargins = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        
        let card = cards[indexPath.row]
        cell!.textLabel?.text = card.descriptionText
        cell!.textLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        
        let sdf = DateFormatter()
        sdf.dateFormat = "dd/MM/yyyy"
        let expiryDate = Date(timeIntervalSince1970: card.expiryDate / 1000)
        let updatedAtDate = Date(timeIntervalSince1970: card.updatedAt / 1000)
        // Show expiry and last updated on separate lines (3rd line is added)
        cell!.detailTextLabel?.text = "\(TranslationManager.shared.getTranslation(for: "myCards.expiryDateLabel")): \(sdf.string(from: expiryDate))\n\(TranslationManager.shared.getTranslation(for: "myCards.lastUpdatedLabel")): \(sdf.string(from: updatedAtDate))"
        cell!.detailTextLabel?.numberOfLines = 0
        cell!.detailTextLabel?.font = UIFont.systemFont(ofSize: 15)
        
        cell!.backgroundColor = (indexPath.row % 2 == 0) ? UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1) : UIColor.white
        
        return cell!
    }
    
    // MARK: - UITableViewDelegate Methods
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let card = cards[indexPath.row]
        print("AdminUserCardsViewController: Card tapped: \(card.cardId ?? "")")
        let detailVC = AdminViewCardDetailsViewController()
        // Pass card details to the details view controller
        detailVC.cardDescription = card.descriptionText
        detailVC.expiryDate = card.expiryDate
        detailVC.updatedAt = card.updatedAt
        detailVC.frontImageURL = card.frontImageURL
        detailVC.backImageURL = card.backImageURL
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    // MARK: - Helper: Show Alert
    
    func showAlert(message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: TranslationManager.shared.getTranslation(for: "common.alert"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: TranslationManager.shared.getTranslation(for: "common.okButton"), style: .default, handler: { _ in completion?() }))
        present(alert, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserInfoAndCards()
    }
}

