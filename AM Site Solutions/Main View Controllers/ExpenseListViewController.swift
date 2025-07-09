 //
 //  ExpenseListViewController.swift
 //  AM Site Solutions
 //
 //  Created by Warren Harding on 23/05/2025.
 //


 import UIKit
 import FirebaseAuth
 import FirebaseDatabase
import FirebaseStorage

 // MARK: - ExpenseCell

 // MARK: - ExpenseCell

class ExpenseCell: UITableViewCell {
    
    // UI Elements
    private let thumbnailImageView = UIImageView()
    private let descriptionLabel = UILabel()
    private let amountLabel = UILabel()
    private let dateLabel = UILabel()
    private let reimbursementLabel = UILabel()
    private let deleteButton = UIButton(type: .system) // Add this line
    
    // Stack views for layout
    private let textStackView = UIStackView()
    private let mainStackView = UIStackView()
    
    // Add this line
    var onDeleteTapped: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // Configure thumbnailImageView
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        
        // Configure labels
        descriptionLabel.font = UIFont.boldSystemFont(ofSize: 16)
        descriptionLabel.textColor = .black
        descriptionLabel.numberOfLines = 1
        
        amountLabel.font = UIFont.systemFont(ofSize: 14)
        amountLabel.textColor = ColorScheme.amBlue
        
        dateLabel.font = UIFont.systemFont(ofSize: 14)
        dateLabel.textColor = .darkGray
        
        reimbursementLabel.font = UIFont.italicSystemFont(ofSize: 12)
        reimbursementLabel.textColor = .darkGray
        
        // Configure delete button - Add this block
        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.tintColor = UIColor.systemRed
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        
        // Configure stack views
        textStackView.axis = .vertical
        textStackView.spacing = 4
        textStackView.addArrangedSubview(descriptionLabel)
        textStackView.addArrangedSubview(amountLabel)
        textStackView.addArrangedSubview(dateLabel)
        textStackView.addArrangedSubview(reimbursementLabel)
        
        mainStackView.axis = .horizontal
        mainStackView.spacing = 16
        mainStackView.alignment = .center
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        mainStackView.addArrangedSubview(thumbnailImageView)
        mainStackView.addArrangedSubview(textStackView)
        mainStackView.addArrangedSubview(deleteButton) // Add this line
        
        contentView.addSubview(mainStackView)
        
        // Set constraints
        NSLayoutConstraint.activate([
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 80),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // Add this constraint
            deleteButton.widthAnchor.constraint(equalToConstant: 44),
            
            mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    // Add this method
    @objc private func deleteButtonTapped() {
        onDeleteTapped?()
    }
    
    func configure(with expense: Expense) {
        descriptionLabel.text = expense.description
        
        // Format currency
        let euroLocale = Locale(identifier: "en_IE") // Euro locale
        let currencyFormatter = NumberFormatter()
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = euroLocale
        amountLabel.text = currencyFormatter.string(from: NSNumber(value: expense.amount))
        
        // Format date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let date = Date(timeIntervalSince1970: expense.expenseDate / 1000)
        dateLabel.text = dateFormatter.string(from: date)
        
        // Set reimbursement status
        reimbursementLabel.text = expense.requestReimbursement ?
            TranslationManager.shared.getTranslation(for: "expenseList.reimbursementRequested") :
            TranslationManager.shared.getTranslation(for: "expenseList.noReimbursement")
        
        // Load thumbnail image if available
        if let firstImageUrl = expense.imageUrls.first, let url = URL(string: firstImageUrl) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.thumbnailImageView.image = image
                    }
                } else {
                    print("Failed to load image: \(error?.localizedDescription ?? "Unknown error")")
                    DispatchQueue.main.async {
                        self?.thumbnailImageView.image = UIImage(named: "ic_image_placeholder")
                    }
                }
            }.resume()
        } else {
            thumbnailImageView.image = UIImage(named: "ic_image_placeholder")
        }
    }
}


 // MARK: - ExpenseListViewController

 class ExpenseListViewController: UIViewController {
    
     // UI Elements
     private let searchBar = UISearchBar()
     private let tableView = UITableView()
     private let activityIndicator = UIActivityIndicatorView(style: .large)
     private let noExpensesLabel = UILabel()
    
     // Data
     private var allExpenses: [Expense] = []
     private var filteredExpenses: [Expense] = []
    
     // Firebase
     private let databaseRef = Database.database().reference()
    
     override func viewDidLoad() {
         super.viewDidLoad()
        
         title = TranslationManager.shared.getTranslation(for: "expenseList.title")
         view.backgroundColor = .white
        
         setupUI()
         setupTableView()
         setupSearchBar()
         loadExpenses()
     }
    
     override func viewWillAppear(_ animated: Bool) {
         super.viewWillAppear(animated)
         // Reload data when returning to this screen
         loadExpenses()
     }

     deinit {
        // Remove all observers when the view controller is deallocated
        if let userParent = UserSession.shared.userParent {
            databaseRef.child("userExpenses").child(userParent).removeAllObservers()
        }
    }

    
     // MARK: - UI Setup
    
     private func setupUI() {
         // Configure searchBar
         searchBar.translatesAutoresizingMaskIntoConstraints = false
         searchBar.placeholder = TranslationManager.shared.getTranslation(for: "expenseList.searchHint")
         searchBar.backgroundImage = UIImage() // Remove background
         searchBar.backgroundColor = UIColor.systemGray6
         searchBar.layer.cornerRadius = 10
         searchBar.clipsToBounds = true
         view.addSubview(searchBar)
        
         // Configure tableView
         tableView.translatesAutoresizingMaskIntoConstraints = false
         tableView.separatorStyle = .none
         tableView.backgroundColor = UIColor.systemGray6
         view.addSubview(tableView)
        
         // Configure activityIndicator
         activityIndicator.translatesAutoresizingMaskIntoConstraints = false
         activityIndicator.hidesWhenStopped = true
         view.addSubview(activityIndicator)
        
         // Configure noExpensesLabel
         noExpensesLabel.translatesAutoresizingMaskIntoConstraints = false
         noExpensesLabel.textAlignment = .center
         noExpensesLabel.textColor = .darkGray
         noExpensesLabel.font = UIFont.systemFont(ofSize: 16)
         noExpensesLabel.text = TranslationManager.shared.getTranslation(for: "expenseList.noExpenses")
         noExpensesLabel.isHidden = true
         view.addSubview(noExpensesLabel)
        
         // Set constraints
         NSLayoutConstraint.activate([
             searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
             searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
             searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
             tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
             tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
             tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
             tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
             activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
             activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
             noExpensesLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
             noExpensesLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
             noExpensesLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
             noExpensesLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
         ])
     }
    
     private func setupTableView() {
         tableView.delegate = self
         tableView.dataSource = self
         tableView.register(ExpenseCell.self, forCellReuseIdentifier: "ExpenseCell")
     }
    
     private func setupSearchBar() {
         searchBar.delegate = self
     }
    
     // MARK: - Data Loading
    
     private func loadExpenses() {
    showLoading(true)
    
    guard let userParent = UserSession.shared.userParent else {
        showLoading(false)
        showNoExpenses(message: "User parent not found")
        return
    }
    
    let expensesRef = databaseRef.child("userExpenses").child(userParent)
    
    expensesRef.observe(.value) { [weak self] snapshot in
        guard let self = self else { return }
        
        self.allExpenses.removeAll()
        
        for child in snapshot.children {
            guard let expenseSnapshot = child as? DataSnapshot,
                  let dataSnapshot = expenseSnapshot.childSnapshot(forPath: "data").value as? [String: Any] else {
                continue
            }
            
            var expense = Expense()
            expense.id = expenseSnapshot.key
            expense.description = dataSnapshot["description"] as? String ?? ""
            expense.amount = dataSnapshot["amount"] as? Double ?? 0.0
            expense.expenseDetails = dataSnapshot["expenseDetails"] as? String ?? ""
            expense.expenseDate = dataSnapshot["expenseDate"] as? TimeInterval ?? 0
            expense.requestReimbursement = dataSnapshot["requestReimbursement"] as? Bool ?? false
            expense.imageUrls = dataSnapshot["imageUrls"] as? [String] ?? []
            expense.createdAt = dataSnapshot["createdAt"] as? TimeInterval ?? 0
            expense.updatedAt = dataSnapshot["updatedAt"] as? TimeInterval ?? 0
            expense.createdBy = dataSnapshot["createdBy"] as? String ?? ""
            
            self.allExpenses.append(expense)
        }
        
        // Sort expenses by date (newest first)
        self.allExpenses.sort { $0.expenseDate > $1.expenseDate }
        self.filteredExpenses = self.allExpenses
        
        self.showLoading(false)
        
        if self.allExpenses.isEmpty {
            self.showNoExpenses(message: TranslationManager.shared.getTranslation(for: "expenseList.noExpenses"))
        } else {
            self.tableView.reloadData()
            self.tableView.isHidden = false
            self.noExpensesLabel.isHidden = true
        }
    } withCancel: { [weak self] error in
        self?.showLoading(false)
        self?.showNoExpenses(message: "Failed to load expenses: \(error.localizedDescription)")
        print("Error fetching expenses: \(error.localizedDescription)")
    }
}

    
     // MARK: - Helper Methods
    
     private func showLoading(_ show: Bool) {
         if show {
             activityIndicator.startAnimating()
             tableView.isHidden = true
             noExpensesLabel.isHidden = true
         } else {
             activityIndicator.stopAnimating()
         }
     }
    
     private func showNoExpenses(message: String) {
         noExpensesLabel.text = message
         noExpensesLabel.isHidden = false
         tableView.isHidden = true
     }
    
     private func filterExpenses(query: String) {
         if query.isEmpty {
             filteredExpenses = allExpenses
         } else {
             filteredExpenses = allExpenses.filter {
                 $0.expenseDetails.lowercased().contains(query.lowercased())
             }
         }
        
         if filteredExpenses.isEmpty {
             showNoExpenses(message: TranslationManager.shared.getTranslation(for: "expenseList.noExpensesFound"))
         } else {
             tableView.isHidden = false
             noExpensesLabel.isHidden = true
             tableView.reloadData()
         }
     }

     private func confirmDeleteExpense(_ expense: Expense) {
    // Get the translation string
    let translationFormat = TranslationManager.shared.getTranslation(for: "expenseList.deleteConfirmMessage")
    
    // Replace %s with %@ for Swift string formatting
    let swiftFormatString = translationFormat.replacingOccurrences(of: "%s", with: "%@")
    
    let alertController = UIAlertController(
        title: TranslationManager.shared.getTranslation(for: "expenseList.deleteConfirmTitle"),
        message: String(format: swiftFormatString, expense.description),
        preferredStyle: .alert
    )
    
    let deleteAction = UIAlertAction(
        title: TranslationManager.shared.getTranslation(for: "common.delete"),
        style: .destructive
    ) { [weak self] _ in
        self?.deleteExpense(expense)
    }
    
    let cancelAction = UIAlertAction(
        title: TranslationManager.shared.getTranslation(for: "common.cancel"),
        style: .cancel
    )
    
    alertController.addAction(deleteAction)
    alertController.addAction(cancelAction)
    
    present(alertController, animated: true)
}

private func deleteExpense(_ expense: Expense) {
    showLoading(true)
    
    guard let userParent = UserSession.shared.userParent else {
        showLoading(false)
        showAlert(
            title: TranslationManager.shared.getTranslation(for: "common.error"),
            message: "User parent not found"
        )
        return
    }
    
    let expenseRef = databaseRef.child("userExpenses").child(userParent).child(expense.id)
    
    expenseRef.removeValue { [weak self] error, _ in
        guard let self = self else { return }
        
        if let error = error {
            self.showLoading(false)
            print("Error deleting expense: \(error.localizedDescription)")
            self.showAlert(
                title: TranslationManager.shared.getTranslation(for: "common.error"),
                message: TranslationManager.shared.getTranslation(for: "expenseList.deleteError") + ": \(error.localizedDescription)"
            )
            return
        }
        
        // Show success message
        self.showLoading(false)
        self.showToast(message: TranslationManager.shared.getTranslation(for: "expenseList.deleteSuccess"))
    }
}


private func showAlert(title: String, message: String) {
    let alertController = UIAlertController(
        title: title,
        message: message,
        preferredStyle: .alert
    )
    
    let okAction = UIAlertAction(
        title: TranslationManager.shared.getTranslation(for: "common.ok"),
        style: .default
    )
    
    alertController.addAction(okAction)
    
    present(alertController, animated: true)
}

private func showToast(message: String) {
    let toastLabel = UILabel()
    toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
    toastLabel.textColor = .white
    toastLabel.textAlignment = .center
    toastLabel.font = UIFont.systemFont(ofSize: 14)
    toastLabel.text = message
    toastLabel.alpha = 0
    toastLabel.layer.cornerRadius = 10
    toastLabel.clipsToBounds = true
    toastLabel.translatesAutoresizingMaskIntoConstraints = false
    
    view.addSubview(toastLabel)
    
    NSLayoutConstraint.activate([
        toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        toastLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
        toastLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -40),
        toastLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
    ])
    
    UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
        toastLabel.alpha = 1
    }, completion: { _ in
        UIView.animate(withDuration: 0.5, delay: 2, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0
        }, completion: { _ in
            toastLabel.removeFromSuperview()
        })
    })
}


    
     private func openExpenseInEditMode(expense: Expense) {
         let editVC = AddExpenseViewController.createForEditExpense(expenseId: expense.id)
         navigationController?.pushViewController(editVC, animated: true)
     }
 }

 // MARK: - UITableViewDataSource & UITableViewDelegate

 extension ExpenseListViewController: UITableViewDataSource, UITableViewDelegate {
    
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return filteredExpenses.count
     }
    
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: "ExpenseCell", for: indexPath) as? ExpenseCell else {
        return UITableViewCell()
    }
    
    let expense = filteredExpenses[indexPath.row]
    cell.configure(with: expense)
    
    // Add this block
    cell.onDeleteTapped = { [weak self] in
        self?.confirmDeleteExpense(expense)
    }
    
    // Add card-like appearance
    cell.contentView.backgroundColor = .white
    cell.contentView.layer.cornerRadius = 8
    cell.contentView.layer.shadowColor = UIColor.black.cgColor
    cell.contentView.layer.shadowOpacity = 0.1
    cell.contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
    cell.contentView.layer.shadowRadius = 2
    
        // Add some padding around the cell
    cell.contentView.layer.masksToBounds = false
    cell.selectionStyle = .none
    
    return cell
}


    
     func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
         return UITableView.automaticDimension
     }
    
     func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
         return 120
     }
    
     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
         let expense = filteredExpenses[indexPath.row]
         openExpenseInEditMode(expense: expense)
     }
 }

 // MARK: - UISearchBarDelegate

 extension ExpenseListViewController: UISearchBarDelegate {
    
     func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
         filterExpenses(query: searchText)
     }
    
     func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
         searchBar.resignFirstResponder()
     }
    
     func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
         searchBar.text = ""
         filterExpenses(query: "")
         searchBar.resignFirstResponder()
     }
 }







//  //
//  //  ExpenseListViewController.swift
//  //  AM Site Solutions
//  //
//  //  Created by Warren Harding on 23/05/2025.
//  //


//  import UIKit
//  import FirebaseAuth
//  import FirebaseDatabase
// import FirebaseStorage

//  // MARK: - ExpenseCell

//  class ExpenseCell: UITableViewCell {
    
//      // UI Elements
//      private let thumbnailImageView = UIImageView()
//      private let descriptionLabel = UILabel()
//      private let amountLabel = UILabel()
//      private let dateLabel = UILabel()
//      private let reimbursementLabel = UILabel()
    
//      // Stack views for layout
//      private let textStackView = UIStackView()
//      private let mainStackView = UIStackView()
    
//      override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//          super.init(style: style, reuseIdentifier: reuseIdentifier)
//          setupUI()
//      }
    
//      required init?(coder: NSCoder) {
//          super.init(coder: coder)
//          setupUI()
//      }
    
//      private func setupUI() {
//          // Configure thumbnailImageView
//          thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
//          thumbnailImageView.contentMode = .scaleAspectFill
//          thumbnailImageView.clipsToBounds = true
//          thumbnailImageView.layer.cornerRadius = 8
//          thumbnailImageView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        
//          // Configure labels
//          descriptionLabel.font = UIFont.boldSystemFont(ofSize: 16)
//          descriptionLabel.textColor = .black
//          descriptionLabel.numberOfLines = 1
        
//          amountLabel.font = UIFont.systemFont(ofSize: 14)
//          amountLabel.textColor = ColorScheme.amBlue
        
//          dateLabel.font = UIFont.systemFont(ofSize: 14)
//          dateLabel.textColor = .darkGray
        
//          reimbursementLabel.font = UIFont.italicSystemFont(ofSize: 12)
//          reimbursementLabel.textColor = .darkGray
        
//          // Configure stack views
//          textStackView.axis = .vertical
//          textStackView.spacing = 4
//          textStackView.addArrangedSubview(descriptionLabel)
//          textStackView.addArrangedSubview(amountLabel)
//          textStackView.addArrangedSubview(dateLabel)
//          textStackView.addArrangedSubview(reimbursementLabel)
        
//          mainStackView.axis = .horizontal
//          mainStackView.spacing = 16
//          mainStackView.alignment = .center
//          mainStackView.translatesAutoresizingMaskIntoConstraints = false
//          mainStackView.addArrangedSubview(thumbnailImageView)
//          mainStackView.addArrangedSubview(textStackView)
        
//          contentView.addSubview(mainStackView)
        
//          // Set constraints
//          NSLayoutConstraint.activate([
//              thumbnailImageView.widthAnchor.constraint(equalToConstant: 80),
//              thumbnailImageView.heightAnchor.constraint(equalToConstant: 80),
            
//              mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
//              mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//              mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//              mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
//          ])
//      }
    
//      func configure(with expense: Expense) {
//          descriptionLabel.text = expense.description
        
//          // Format currency
//          let euroLocale = Locale(identifier: "en_IE") // Euro locale
//          let currencyFormatter = NumberFormatter()
//          currencyFormatter.numberStyle = .currency
//          currencyFormatter.locale = euroLocale
//          amountLabel.text = currencyFormatter.string(from: NSNumber(value: expense.amount))
        
//          // Format date
//          let dateFormatter = DateFormatter()
//          dateFormatter.dateFormat = "dd/MM/yyyy"
//          let date = Date(timeIntervalSince1970: expense.expenseDate / 1000)
//          dateLabel.text = dateFormatter.string(from: date)
        
//          // Set reimbursement status
//          reimbursementLabel.text = expense.requestReimbursement ?
//              TranslationManager.shared.getTranslation(for: "expenseList.reimbursementRequested") :
//              TranslationManager.shared.getTranslation(for: "expenseList.noReimbursement")
        
//          // Load thumbnail image if available
//          if let firstImageUrl = expense.imageUrls.first, let url = URL(string: firstImageUrl) {
//              URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
//                  if let data = data, let image = UIImage(data: data) {
//                      DispatchQueue.main.async {
//                          self?.thumbnailImageView.image = image
//                      }
//                  } else {
//                      print("Failed to load image: \(error?.localizedDescription ?? "Unknown error")")
//                      DispatchQueue.main.async {
//                          self?.thumbnailImageView.image = UIImage(named: "ic_image_placeholder")
//                      }
//                  }
//              }.resume()
//          } else {
//              thumbnailImageView.image = UIImage(named: "ic_image_placeholder")
//          }
//      }
//  }

//  // MARK: - ExpenseListViewController

//  class ExpenseListViewController: UIViewController {
    
//      // UI Elements
//      private let searchBar = UISearchBar()
//      private let tableView = UITableView()
//      private let activityIndicator = UIActivityIndicatorView(style: .large)
//      private let noExpensesLabel = UILabel()
    
//      // Data
//      private var allExpenses: [Expense] = []
//      private var filteredExpenses: [Expense] = []
    
//      // Firebase
//      private let databaseRef = Database.database().reference()
    
//      override func viewDidLoad() {
//          super.viewDidLoad()
        
//          title = TranslationManager.shared.getTranslation(for: "expenseList.title")
//          view.backgroundColor = .white
        
//          setupUI()
//          setupTableView()
//          setupSearchBar()
//          loadExpenses()
//      }
    
//      override func viewWillAppear(_ animated: Bool) {
//          super.viewWillAppear(animated)
//          // Reload data when returning to this screen
//          loadExpenses()
//      }
    
//      // MARK: - UI Setup
    
//      private func setupUI() {
//          // Configure searchBar
//          searchBar.translatesAutoresizingMaskIntoConstraints = false
//          searchBar.placeholder = TranslationManager.shared.getTranslation(for: "expenseList.searchHint")
//          searchBar.backgroundImage = UIImage() // Remove background
//          searchBar.backgroundColor = UIColor.systemGray6
//          searchBar.layer.cornerRadius = 10
//          searchBar.clipsToBounds = true
//          view.addSubview(searchBar)
        
//          // Configure tableView
//          tableView.translatesAutoresizingMaskIntoConstraints = false
//          tableView.separatorStyle = .none
//          tableView.backgroundColor = UIColor.systemGray6
//          view.addSubview(tableView)
        
//          // Configure activityIndicator
//          activityIndicator.translatesAutoresizingMaskIntoConstraints = false
//          activityIndicator.hidesWhenStopped = true
//          view.addSubview(activityIndicator)
        
//          // Configure noExpensesLabel
//          noExpensesLabel.translatesAutoresizingMaskIntoConstraints = false
//          noExpensesLabel.textAlignment = .center
//          noExpensesLabel.textColor = .darkGray
//          noExpensesLabel.font = UIFont.systemFont(ofSize: 16)
//          noExpensesLabel.text = TranslationManager.shared.getTranslation(for: "expenseList.noExpenses")
//          noExpensesLabel.isHidden = true
//          view.addSubview(noExpensesLabel)
        
//          // Set constraints
//          NSLayoutConstraint.activate([
//              searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
//              searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//              searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
//              tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
//              tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//              tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//              tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
//              activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//              activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
//              noExpensesLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//              noExpensesLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//              noExpensesLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
//              noExpensesLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
//          ])
//      }
    
//      private func setupTableView() {
//          tableView.delegate = self
//          tableView.dataSource = self
//          tableView.register(ExpenseCell.self, forCellReuseIdentifier: "ExpenseCell")
//      }
    
//      private func setupSearchBar() {
//          searchBar.delegate = self
//      }
    
//      // MARK: - Data Loading
    
//      private func loadExpenses() {
//          showLoading(true)
        
//          guard let userParent = UserSession.shared.userParent else {
//              showLoading(false)
//              showNoExpenses(message: "User parent not found")
//              return
//          }
        
//          let expensesRef = databaseRef.child("userExpenses").child(userParent)
        
//          expensesRef.observeSingleEvent(of: .value) { [weak self] snapshot in
//              guard let self = self else { return }
            
//              self.allExpenses.removeAll()
            
//              for child in snapshot.children {
//                  guard let expenseSnapshot = child as? DataSnapshot,
//                        let dataSnapshot = expenseSnapshot.childSnapshot(forPath: "data").value as? [String: Any] else {
//                      continue
//                  }
                
//                  var expense = Expense()
//                  expense.id = expenseSnapshot.key
//                  expense.description = dataSnapshot["description"] as? String ?? ""
//                  expense.amount = dataSnapshot["amount"] as? Double ?? 0.0
//                  expense.expenseDetails = dataSnapshot["expenseDetails"] as? String ?? ""
//                  expense.expenseDate = dataSnapshot["expenseDate"] as? TimeInterval ?? 0
//                  expense.requestReimbursement = dataSnapshot["requestReimbursement"] as? Bool ?? false
//                  expense.imageUrls = dataSnapshot["imageUrls"] as? [String] ?? []
//                  expense.createdAt = dataSnapshot["createdAt"] as? TimeInterval ?? 0
//                  expense.updatedAt = dataSnapshot["updatedAt"] as? TimeInterval ?? 0
//                  expense.createdBy = dataSnapshot["createdBy"] as? String ?? ""
                
//                  self.allExpenses.append(expense)
//              }
            
//              // Sort expenses by date (newest first)
//              self.allExpenses.sort { $0.expenseDate > $1.expenseDate }
//              self.filteredExpenses = self.allExpenses
            
//              self.showLoading(false)
            
//              if self.allExpenses.isEmpty {
//                  self.showNoExpenses(message: TranslationManager.shared.getTranslation(for: "expenseList.noExpenses"))
//              } else {
//                  self.tableView.reloadData()
//                  self.tableView.isHidden = false
//                  self.noExpensesLabel.isHidden = true
//              }
//          } withCancel: { [weak self] error in
//              self?.showLoading(false)
//              self?.showNoExpenses(message: "Failed to load expenses: \(error.localizedDescription)")
//              print("Error fetching expenses: \(error.localizedDescription)")
//          }
//      }
    
//      // MARK: - Helper Methods
    
//      private func showLoading(_ show: Bool) {
//          if show {
//              activityIndicator.startAnimating()
//              tableView.isHidden = true
//              noExpensesLabel.isHidden = true
//          } else {
//              activityIndicator.stopAnimating()
//          }
//      }
    
//      private func showNoExpenses(message: String) {
//          noExpensesLabel.text = message
//          noExpensesLabel.isHidden = false
//          tableView.isHidden = true
//      }
    
//      private func filterExpenses(query: String) {
//          if query.isEmpty {
//              filteredExpenses = allExpenses
//          } else {
//              filteredExpenses = allExpenses.filter {
//                  $0.expenseDetails.lowercased().contains(query.lowercased())
//              }
//          }
        
//          if filteredExpenses.isEmpty {
//              showNoExpenses(message: TranslationManager.shared.getTranslation(for: "expenseList.noExpensesFound"))
//          } else {
//              tableView.isHidden = false
//              noExpensesLabel.isHidden = true
//              tableView.reloadData()
//          }
//      }
    
//      private func openExpenseInEditMode(expense: Expense) {
//          let editVC = AddExpenseViewController.createForEditExpense(expenseId: expense.id)
//          navigationController?.pushViewController(editVC, animated: true)
//      }
//  }

//  // MARK: - UITableViewDataSource & UITableViewDelegate

//  extension ExpenseListViewController: UITableViewDataSource, UITableViewDelegate {
    
//      func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//          return filteredExpenses.count
//      }
    
//      func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//          guard let cell = tableView.dequeueReusableCell(withIdentifier: "ExpenseCell", for: indexPath) as? ExpenseCell else {
//              return UITableViewCell()
//          }
        
//          let expense = filteredExpenses[indexPath.row]
//          cell.configure(with: expense)
        
//          // Add card-like appearance
//          cell.contentView.backgroundColor = .white
//          cell.contentView.layer.cornerRadius = 8
//          cell.contentView.layer.shadowColor = UIColor.black.cgColor
//          cell.contentView.layer.shadowOpacity = 0.1
//          cell.contentView.layer.shadowOffset = CGSize(width: 0, height: 2)
//          cell.contentView.layer.shadowRadius = 2
        
//          // Add some padding around the cell
//          cell.contentView.layer.masksToBounds = false
//          cell.selectionStyle = .none
        
//          return cell
//      }
    
//      func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//          return UITableView.automaticDimension
//      }
    
//      func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
//          return 120
//      }
    
//      func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//          let expense = filteredExpenses[indexPath.row]
//          openExpenseInEditMode(expense: expense)
//      }
//  }

//  // MARK: - UISearchBarDelegate

//  extension ExpenseListViewController: UISearchBarDelegate {
    
//      func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//          filterExpenses(query: searchText)
//      }
    
//      func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//          searchBar.resignFirstResponder()
//      }
    
//      func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//          searchBar.text = ""
//          filterExpenses(query: "")
//          searchBar.resignFirstResponder()
//      }
//  }

