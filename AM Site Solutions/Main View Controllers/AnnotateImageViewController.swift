import UIKit
import PencilKit
import os.log

/// A view controller for annotating an image using PencilKit.
/// This screen provides tools for drawing, erasing, and undoing actions on a given image.
/// On save, it returns the flattened annotated image to the caller.

enum AnnotationTool {
    case brush
    case eraser
    case text
}

class AnnotateImageViewController: UIViewController, PKCanvasViewDelegate, UITextFieldDelegate {


    // MARK: - Public API
    
    /// The image that will be annotated.
    private let sourceImage: UIImage
    private var currentTool: AnnotationTool = .brush
    
    /// A closure to be executed when the user saves the annotated image.
    /// The closure receives the new image as its parameter.
    var onSave: ((UIImage) -> Void)?
    private var textLabels: [UILabel] = []
    
    // MARK: - UI Elements
    
    private lazy var canvasView: PKCanvasView = {
        let canvas = PKCanvasView()
        canvas.translatesAutoresizingMaskIntoConstraints = false
        canvas.delegate = self
        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(.pen, color: .red, width: 5) // Default tool
        return canvas
    }()
    
    private lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.image = sourceImage
        iv.isUserInteractionEnabled = true // Enable user interaction for dragging text labels
        return iv
    }()
    
    private lazy var undoButton: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.backward"), style: .plain, target: self, action: #selector(undoTapped))
    }()
    
    private lazy var eraseButton: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(systemName: "eraser"), style: .plain, target: self, action: #selector(eraseTapped))
    }()
    
    private lazy var brushButton: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(systemName: "pencil"), style: .plain, target: self, action: #selector(brushTapped))
    }()
    
    private lazy var textButton: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(systemName: "textformat.alt"), style: .plain, target: self, action: #selector(textTapped))
    }()

    // MARK: - Logger
    private let logger = Logger(subsystem: "com.amsitesolutions.AM-Site-Solutions", category: "AnnotateImageViewController")

    // MARK: - Lifecycle
    
    init(image: UIImage) {
        self.sourceImage = image
        super.init(nibName: nil, bundle: nil)
        logger.log("AnnotateImageViewController initialised for a new session.")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateToolButtons()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Annotate Image"
        
        // -- Navigation Bar --
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
        
        // -- Toolbar --
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbarItems = [brushButton, spacer, eraseButton, spacer, textButton, spacer, undoButton]
        navigationController?.isToolbarHidden = false
        
        // -- Canvas and Image View --
        view.addSubview(imageView)
        view.addSubview(canvasView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            canvasView.topAnchor.constraint(equalTo: imageView.topAnchor),
            canvasView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            canvasView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
        ])
        
        // Make the canvas transparent to see the image underneath
        canvasView.isOpaque = false
        canvasView.backgroundColor = .clear
    }
    
    // MARK: - Actions
    
    @objc private func cancelTapped() {
        logger.log("Cancel tapped. Dismissing annotation screen without saving.")
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func saveTapped() {
        // Create a new image by rendering both the original image and the canvas drawing.
        let renderer = UIGraphicsImageRenderer(bounds: imageView.bounds)
        let annotatedImage = renderer.image { context in
            // Draw the original image first
            imageView.layer.render(in: context.cgContext)
            // Draw the canvas annotations on top
            canvasView.drawing.image(from: canvasView.bounds, scale: 1.0).draw(in: imageView.bounds)
            
            // Draw text labels on top
            for label in self.textLabels {
                label.layer.render(in: context.cgContext)
            }
        }
        
        logger.log("Save tapped. Passing new annotated image back via onSave closure.")
        onSave?(annotatedImage)
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func undoTapped() {
        logger.log("Undo tapped.")
        canvasView.undoManager?.undo()
        updateToolButtons()
    }
    
    @objc private func textTapped() {
        logger.log("Text tool selected.")
        currentTool = .text
        updateToolButtons()
        
        let alertController = UIAlertController(title: "Add Text", message: nil, preferredStyle: .alert)
        alertController.addTextField { [weak self] textField in
            textField.placeholder = "Enter text"
            textField.delegate = self
            textField.autocapitalizationType = .sentences // This helps, but we'll refine with delegate
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            if let text = alertController.textFields?.first?.text, !text.isEmpty {
                self?.addTextLabel(with: text)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            // If text input is cancelled, revert to brush tool
            self?.currentTool = .brush
            self?.updateToolButtons()
        }
        
        alertController.addAction(addAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    private func addTextLabel(with text: String) {
        let label = UILabel()
        label.text = text
        label.textColor = .red // Default text color
        label.font = UIFont.systemFont(ofSize: 30)
        label.sizeToFit()
        label.center = view.center // Initial position
        label.isUserInteractionEnabled = true
        label.translatesAutoresizingMaskIntoConstraints = true // Allow manual positioning
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleTextPan(_:)))
        label.addGestureRecognizer(panGesture)
        
        imageView.addSubview(label)
        textLabels.append(label)
    }
    
    @objc private func handleTextPan(_ gesture: UIPanGestureRecognizer) {
        guard let label = gesture.view else { return }
        let translation = gesture.translation(in: imageView)
        label.center = CGPoint(x: label.center.x + translation.x, y: label.center.y + translation.y)
        gesture.setTranslation(.zero, in: imageView)
    }
    
    @objc private func eraseTapped() {
        logger.log("Eraser tool selected.")
        canvasView.tool = PKEraserTool(.bitmap)
        currentTool = .eraser
        updateToolButtons()
    }
    
    @objc private func brushTapped() {
        logger.log("Brush tool selected.")
        canvasView.tool = PKInkingTool(.pen, color: .red, width: 5)
        currentTool = .brush
        updateToolButtons()
    }
    
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        updateToolButtons()
    }
    
    // MARK: - UITextFieldDelegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        
        let newText = (text as NSString).replacingCharacters(in: range, with: string)
        
        // If the new text is empty, allow it
        if newText.isEmpty { return true }
        
        // Check if the previous character was a sentence-ending punctuation mark
        let lastCharacterIsSentenceEnd = text.last.map { String($0).rangeOfCharacter(from: CharacterSet(charactersIn: ".!?")) != nil } ?? false
        
        // Check if the current input is the first character of the text field
        let isFirstCharacter = range.location == 0 && range.length == 0
        
        // If it's the first character or follows a sentence end, capitalize it
        if (isFirstCharacter || lastCharacterIsSentenceEnd) && !string.isEmpty {
            let capitalizedString = string.capitalized
            if capitalizedString != string {
                textField.text = (text as NSString).replacingCharacters(in: range, with: capitalizedString)
                return false // We handled the change manually
            }
        }
        
        return true
    }
    
    // MARK: - Helpers
    
    private func updateToolButtons() {
        undoButton.isEnabled = canvasView.undoManager?.canUndo ?? false
        
        // Update tool selection states and enable/disable canvas interaction
        brushButton.tintColor = (currentTool == .brush) ? .systemBlue : .label
        eraseButton.tintColor = (currentTool == .eraser) ? .systemBlue : .label
        textButton.tintColor = (currentTool == .text) ? .systemBlue : .label
        
        canvasView.isUserInteractionEnabled = (currentTool != .text)
        
        switch currentTool {
        case .brush:
            canvasView.tool = PKInkingTool(.pen, color: .red, width: 5)
        case .eraser:
            canvasView.tool = PKEraserTool(.bitmap)
        case .text:
            // When text tool is active, drawing is disabled
            break
        }
        
        // Use tint color to show selection state for toolbar buttons
        
    }
}
