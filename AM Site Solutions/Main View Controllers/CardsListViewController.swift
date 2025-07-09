//
//  CardsListViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 03/03/2025.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class CardsListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var tableView: UITableView!
    var cards: [Card] = []
    let refreshControl = UIRefreshControl()
    var createNewCardButton: CustomButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = TranslationManager.shared.getTranslation(for: "common.myCards")
        print("CardsListViewController: viewDidLoad")
        setupCreateCardButton()
        setupTableView()
        loadCards()
    }
    
    func setupCreateCardButton() {
        // Initialise the CustomButton (assumes CustomButton is already defined)
        createNewCardButton = CustomButton(type: .system)
        createNewCardButton.setTitle(TranslationManager.shared.getTranslation(for: "common.addCardButton"), for: .normal)
        createNewCardButton.addTarget(self, action: #selector(createNewCardTapped), for: .touchUpInside)
        createNewCardButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(createNewCardButton)
        
        NSLayoutConstraint.activate([
            createNewCardButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            createNewCardButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        print("CardsListViewController: Create New Card button set up")
    }

    func setupTableView() {
        tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
//        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        refreshControl.addTarget(self, action: #selector(refreshCards), for: .valueChanged)
        tableView.refreshControl = refreshControl
        view.addSubview(tableView)
        
        // Pin the table view's bottom anchor to the top anchor of the createNewCardButton
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: createNewCardButton.topAnchor, constant: -20)
        ])
        
        print("CardsListViewController: TableView set up with bottom anchored to the button")
    }
    
    @objc func createNewCardTapped() {
        print("CardsListViewController: Create New Card tapped")
        let addEditVC = AddEditCardViewController()
        addEditVC.isEditMode = false  // Ensure non-edit mode for adding a new card.
        addEditVC.completionHandler = {
            print("CardsListViewController: New card added, reloading cards")
            self.loadCards()
        }
        navigationController?.pushViewController(addEditVC, animated: true)
    }
    
    @objc func refreshCards() {
        print("CardsListViewController: Refreshing cards")
        loadCards()
    }
    
    
    func loadCards() {
        print("CardsListViewController: Loading cards from Firebase")
        guard let uid = Auth.auth().currentUser?.uid else {
            print("CardsListViewController: User not authenticated")
            self.showAlert(message: "\(TranslationManager.shared.getTranslation(for: "common.userNotAuthenticated"))")
            return
        }
        let ref = Database.database().reference().child("users").child(uid).child("userCards")
        ref.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }
            self.cards.removeAll()
            for child in snapshot.children {
                if let snap = child as? DataSnapshot, let card = Card(snapshot: snap) {
                    self.cards.append(card)
                }
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
                print("CardsListViewController: Cards loaded and table view reloaded")
            }
        } withCancel: { [weak self] error in
            guard let self = self else { return }
            print("CardsListViewController: Error loading cards: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
                self.showAlert(message: "\(TranslationManager.shared.getTranslation(for: "myCards.failedToLoadCards"))")
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
            // Create a cell with the subtitle style.
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        }
        
        // Attempt to set layout margins
        cell!.preservesSuperviewLayoutMargins = false
        cell!.layoutMargins = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        
        let card = cards[indexPath.row]
        
        cell!.textLabel?.text = card.descriptionText
        cell!.textLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        
        let sdf = DateFormatter()
        sdf.dateFormat = "dd/MM/yyyy"
        let expiryDate = Date(timeIntervalSince1970: card.expiryDate / 1000)
        cell!.detailTextLabel?.text = "\(TranslationManager.shared.getTranslation(for: "myCards.expiryDateLabel")): \(sdf.string(from: expiryDate))"
        cell!.detailTextLabel?.font = UIFont.systemFont(ofSize: 15)
        
        cell!.backgroundColor = (indexPath.row % 2 == 0) ? UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1) : UIColor.white
        
        return cell!
    }


    
    // MARK: - Swipe to Delete with Confirmation
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let card = cards[indexPath.row]
            let alert = UIAlertController(title: "\(TranslationManager.shared.getTranslation(for: "myCards.deleteCard"))", message: "\(TranslationManager.shared.getTranslation(for: "myCards.sureDeleteCard"))", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "\(TranslationManager.shared.getTranslation(for: "common.cancelButton"))", style: .cancel, handler: { _ in
                print("CardsListViewController: Deletion cancelled for card \(card.cardId ?? "")")
            }))
            alert.addAction(UIAlertAction(title: "\(TranslationManager.shared.getTranslation(for: "myCards.deleteCard"))", style: .destructive, handler: { _ in
                self.deleteCard(card: card, indexPath: indexPath)
            }))
            present(alert, animated: true, completion: nil)
        }
    }
    

    
    func deleteCard(card: Card, indexPath: IndexPath) {
        print("CardsListViewController: Deleting card \(card.cardId)")
        guard let uid = Auth.auth().currentUser?.uid, !card.cardId.isEmpty else {
            print("CardsListViewController: Cannot delete card; missing user id or card id")
            return
        }
        let ref = Database.database().reference().child("users").child(uid).child("userCards").child(card.cardId)
        ref.removeValue { error, _ in
            if let error = error {
                print("CardsListViewController: Error deleting card: \(error.localizedDescription)")
            } else {
                print("CardsListViewController: Card deleted successfully")
                self.cards.remove(at: indexPath.row)
                DispatchQueue.main.async {
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                }
            }
        }
    }
    
    // MARK: - TableView Row Selection for Editing
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let card = cards[indexPath.row]
        print("CardsListViewController: Card tapped for editing: \(card.cardId ?? "")")
        let addEditVC = AddEditCardViewController()
        addEditVC.isEditMode = true
        addEditVC.card = card
        addEditVC.completionHandler = {
            print("CardsListViewController: Card updated, reloading cards")
            self.loadCards()
        }
        navigationController?.pushViewController(addEditVC, animated: true)
    }
    
    
    func showAlert(message: String, completion: (() -> Void)? = nil) {
        print("AddEditCardViewController: showAlert - \(message)")
        let alert = UIAlertController(title: "\(TranslationManager.shared.getTranslation(for: "common.alert"))", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "\(TranslationManager.shared.getTranslation(for: "common.okButton"))", style: .default, handler: { _ in
            completion?()
        }))
        present(alert, animated: true, completion: nil)
    }
}

