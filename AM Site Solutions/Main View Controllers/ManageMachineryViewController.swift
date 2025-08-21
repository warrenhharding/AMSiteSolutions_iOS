//
//  ManageMachineryViewController.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 06/08/2025.
//

import UIKit
import Firebase


class MachineTableViewCell: UITableViewCell {
    // MARK: - UI Elements
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold) // Made bold
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let detailsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        label.numberOfLines = 0 // Allow multiple lines if needed
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    private func setupUI() {
        contentView.addSubview(nameLabel)
        contentView.addSubview(detailsLabel)
        contentView.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            detailsLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            detailsLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            detailsLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            statusLabel.topAnchor.constraint(equalTo: detailsLabel.bottomAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    // MARK: - Configuration
    func configure(with machine: Machine) {
        nameLabel.text = machine.name.isEmpty ? "No Name Assigned" : machine.name // Fallback for empty names
        detailsLabel.text = formatDetails(for: machine)
        statusLabel.text = machine.status
        statusLabel.textColor = machine.status == "Active" ? .systemGreen : (machine.status == "Under Repair" ? .systemOrange : .systemRed)
    }

    // MARK: - Helper
    private func formatDetails(for machine: Machine) -> String {
        var details = [String]()
        
        if !machine.serialNumber.isEmpty {
            details.append("S/N: \(machine.serialNumber)")
        }
        if !machine.plantEquipmentNumber.isEmpty {
            details.append("Plant #: \(machine.plantEquipmentNumber)")
        }
        if !machine.type.isEmpty {
            details.append("Type: \(machine.type)")
        }
        
        return details.joined(separator: " | ") // Combines with " | " separator
    }
}





class ManageMachineryViewController: UIViewController {
    // MARK: - Properties
    private var machines: [Machine] = []
    private var filteredMachines: [Machine] = []
    private let searchController = UISearchController(searchResultsController: nil)
    private var currentFilter: String = "All Machines"
    private let addMachineButton = CustomButton(type: .system)
    

    // MARK: - UI Elements
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(MachineTableViewCell.self, forCellReuseIdentifier: "MachineCell")
        return tableView
    }()

    private let filterChipView: FilterChipView = {
        let view = FilterChipView()
        view.translatesAutoresizingMaskIntoConstraints = false
        // view.backgroundColor = .yellow // Debugging
        return view
    }()
    
    private let emptyView: UILabel = {
        let label = UILabel()
        label.text = "No machines found."
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSearchController()
        setupFilterChips()
        setupAddMachineButton()
        tableView.dataSource = self
        tableView.delegate = self
        fetchMachines()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Set up the table header view now that we have proper dimensions
        if tableView.tableHeaderView == nil {
            setupTableHeaderView()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Removed debug print statement
    }

    // MARK: - Setup
    private func setupUI() {
        title = "Manage Machinery"
        view.backgroundColor = .systemBackground

        // Add table view and empty view
        view.addSubview(tableView)
        view.addSubview(emptyView)

        // Configure table view constraints first
        NSLayoutConstraint.activate([
            // Table view constraints
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Empty view constraints
            emptyView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor)
        ])
        
        // We'll set up the table header view after the view has laid out
    }

    private func setupFilterChips() {
        filterChipView.delegate = self
    }
    
    private func setupAddMachineButton() {
        print("[ManageMachineryVC] setupAddMachineButton")
        addMachineButton.setTitle("Add Machine", for: .normal)
        addMachineButton.addTarget(self, action: #selector(addMachineButtonTapped), for: .touchUpInside)
        addMachineButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addMachineButton)
        
        NSLayoutConstraint.activate([
            // Button pinned to bottom
            addMachineButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addMachineButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addMachineButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addMachineButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Re-anchor tableView bottom to top of button
            tableView.bottomAnchor.constraint(equalTo: addMachineButton.topAnchor, constant: -16)
        ])
    }
    
    private func setupTableHeaderView() {
        // Create a container view for the filter chips with proper margins
        let headerContainer = UIView()
        headerContainer.backgroundColor = .systemBackground
        
        // Add the filter chip view to the container
        headerContainer.addSubview(filterChipView)
        
        // Set up constraints within the container
        NSLayoutConstraint.activate([
            filterChipView.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 8),
            filterChipView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 16),
            filterChipView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -16),
            filterChipView.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -8),
            filterChipView.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Calculate the required height and set the frame
        let headerHeight: CGFloat = 56 // 40 (chip height) + 8 (top) + 8 (bottom)
        let tableWidth = tableView.bounds.width > 0 ? tableView.bounds.width : view.bounds.width
        headerContainer.frame = CGRect(x: 0, y: 0, width: tableWidth, height: headerHeight)
        
        // Debug: Add a background color to make the header visible
        headerContainer.backgroundColor = .systemGray6
        filterChipView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        
        // Force layout
        headerContainer.layoutIfNeeded()
        
        // Set as table header view
        tableView.tableHeaderView = headerContainer
        
        print("Header container frame: \(headerContainer.frame)")
        print("Filter chip view frame: \(filterChipView.frame)")
    }

    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        
        // Use the standard, Apple-recommended integration
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        definesPresentationContext = true
    }


    // MARK: - Data Handling    
    private func fetchMachines() {
        guard let userParent = UserSession.shared.userParent else {
            print("ManageMachineryViewController: No userParent found")
            return
        }
        
        // Show loading state
        emptyView.isHidden = true
        // If you have a loading indicator, show it here
        
        let database = Database.database()
        let machinesRef = database.reference().child("machines")
        
        print("ManageMachineryViewController: Querying machines for userParent: \(userParent)")
        
        // Query machines for the current user's organization - this matches Android exactly
        machinesRef.queryOrdered(byChild: "appCustomerId").queryEqual(toValue: userParent)
            .observe(.value) { [weak self] snapshot in
                guard let self = self else { return }
                
                self.machines.removeAll()
                print("ManageMachineryViewController: Total machines in snapshot: \(snapshot.childrenCount)")
                
                for child in snapshot.children {
                    guard let machineSnapshot = child as? DataSnapshot else { continue }
                    let machineId = machineSnapshot.key
                    
                    if let machine = Machine(snapshot: machineSnapshot) {
                        self.machines.append(machine)
                        print("ManageMachineryViewController: Added machine: \(machine.name), ID: \(machineId)")
                    } else {
                        print("ManageMachineryViewController: Failed to parse machine with ID: \(machineId)")
                    }
                }
                
                print("ManageMachineryViewController: Total machines loaded: \(self.machines.count)")
                
                DispatchQueue.main.async {
                    // Hide loading indicator if you have one
                    
                    if self.machines.isEmpty {
                        self.emptyView.isHidden = false
                        self.tableView.isHidden = true
                        self.emptyView.text = "No machines found for your organization"
                    } else {
                        self.emptyView.isHidden = true
                        self.tableView.isHidden = false
                        self.applyFilters()
                    }
                }
            } withCancel: { [weak self] error in
                print("ManageMachineryViewController: Database error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    // Hide loading indicator if you have one
                    self?.emptyView.isHidden = false
                    self?.tableView.isHidden = true
                    self?.emptyView.text = "Error loading machines: \(error.localizedDescription)"
                }
            }
    }

    private func applyFilters(searchText: String = "", filter: String = "All Machines") {
        filteredMachines = machines.filter { machine in
            // Apply status filter
            if filter != "All Machines" && machine.status != filter {
                return false
            }
            // Apply search filter
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                return machine.name.lowercased().contains(query) ||
                       machine.serialNumber.lowercased().contains(query) ||
                       machine.type.lowercased().contains(query)
            }
            return true
        }
        tableView.reloadData()
        emptyView.isHidden = !filteredMachines.isEmpty
    }
    
    // MARK: - Actions
        @objc private func addMachineButtonTapped() {
            print("[ManageMachineryVC] addMachineButtonTapped")
            let newMachineVC = NewMachineViewController.createForNewMachine()
            present(newMachineVC, animated: true)
        }
        
        private func editMachine(_ machine: Machine) {
            print("[ManageMachineryVC] editMachine: \(machine.machineId)")
            let editVC = NewMachineViewController.createForEditMachine(machine)
            present(editVC, animated: true)
        }
}

// MARK: - FilterChipViewDelegate
extension ManageMachineryViewController: FilterChipViewDelegate {
    func didSelectFilter(_ filter: String) {
        print("Selected filter: \(filter)") // Debugging
        currentFilter = filter
        applyFilters(searchText: searchController.searchBar.text ?? "", filter: filter)
    }
}

// MARK: - UISearchResultsUpdating
extension ManageMachineryViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        applyFilters(searchText: searchController.searchBar.text ?? "", filter: currentFilter)
    }
}

// MARK: - UITableViewDelegate & DataSource
extension ManageMachineryViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredMachines.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MachineCell", for: indexPath) as! MachineTableViewCell
        cell.configure(with: filteredMachines[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            print("[ManageMachineryVC] didSelectRowAt: row \(indexPath.row)")
            tableView.deselectRow(at: indexPath, animated: true)
            let machine = filteredMachines[indexPath.row]
            editMachine(machine)
        }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                       forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                let machine = filteredMachines[indexPath.row]
                print("[ManageMachineryVC] deleting machine: \(machine.machineId)")
                let ref = Database.database().reference().child("machines").child(machine.machineId)
                ref.removeValue()
            }
        }
}
