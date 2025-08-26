import UIKit
import PencilKit
import PhotosUI

// MARK: - NoteEditorViewController

class NoteEditorViewController: UIViewController, PKCanvasViewDelegate, PHPickerViewControllerDelegate {
    
    // MARK: - Delegate Protocol

protocol NoteEditorViewControllerDelegate: AnyObject {
    func noteEditor(_ editor: NoteEditorViewController, didSave note: SiteAuditNote)
}

// MARK: - Properties

weak var delegate: NoteEditorViewControllerDelegate?
    
    private let isEditMode: Bool
    
    // MARK: - UI Elements
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private lazy var descriptionTextView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 5
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    private lazy var canvasView: PKCanvasView = {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(.pen, color: .red, width: 5)
        canvas.delegate = self
        canvas.layer.borderColor = UIColor.lightGray.cgColor
        canvas.layer.borderWidth = 1
        canvas.layer.cornerRadius = 5
        canvas.translatesAutoresizingMaskIntoConstraints = false
        return canvas
    }()
    
    private lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.isUserInteractionEnabled = false // Pass touches to the canvas
        return iv
    }()
    
    private lazy var addOrChangeImageButton: CustomButton = {
        let button = CustomButton(type: .system)
        button.setTitle("Add Image", for: .normal)
        button.addTarget(self, action: #selector(addImageTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Clear Annotations", for: .normal)
        button.addTarget(self, action: #selector(clearCanvas), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Initializers
    
    init(note: SiteAuditNote) {
        self.note = note
        self.isEditMode = true
        super.init(nibName: nil, bundle: nil)
    }
    
    init(order: Int) {
        self.note = SiteAuditNote(order: order)
        self.isEditMode = false
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = isEditMode ? "Edit Note" : "Add Note"
        setupNavigationBar()
        setupUI()
        configureView()
    }
    
    // MARK: - UI Setup
    
    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        let descriptionLabel = createLabel(with: "Description")
        let imageLabel = createLabel(with: "Image & Annotations")
        
        let stackView = UIStackView(arrangedSubviews: [
            descriptionLabel, descriptionTextView,
            imageLabel, addOrChangeImageButton,
            clearButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stackView)
        contentView.addSubview(imageView)
        contentView.addSubview(canvasView)
        
        stackView.setCustomSpacing(16, after: descriptionTextView)
        stackView.setCustomSpacing(16, after: addOrChangeImageButton)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            canvasView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 8),
            canvasView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            canvasView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            canvasView.heightAnchor.constraint(equalTo: canvasView.widthAnchor, multiplier: 4.0/3.0), // 4:3 aspect ratio
            canvasView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            imageView.topAnchor.constraint(equalTo: canvasView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: canvasView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: canvasView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: canvasView.bottomAnchor)
        ])
    }
    
    private func createLabel(with text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .darkGray
        return label
    }
    
    // MARK: - Configuration
    
    private func configureView() {
        guard let note = note else { return }
        
        descriptionTextView.text = note.description
        
        if let localImage = note.localImage {
            imageView.image = localImage
            addOrChangeImageButton.setTitle("Change Image", for: .normal)
        } else if let imageUrlString = note.imageUrl, let url = URL(string: imageUrlString) {
            loadImage(from: url) { [weak self] image in
                self?.imageView.image = image
                self?.note?.localImage = image
                self?.addOrChangeImageButton.setTitle("Change Image", for: .normal)
            }
        }
        
        if let localAnnotatedImage = note.localAnnotatedImage {
            // If we have a local annotated image, we can't easily re-import the drawing,
            // so we just display the final image. A more advanced implementation might
            // save the PKDrawing data itself.
            let annotatedImageView = UIImageView(image: localAnnotatedImage)
            annotatedImageView.contentMode = .scaleAspectFit
            annotatedImageView.frame = canvasView.bounds
            canvasView.addSubview(annotatedImageView)
        } else if let annotatedImageUrlString = note.annotatedImageUrl, let url = URL(string: annotatedImageUrlString) {
            // Similar to above, just show the final image.
            loadImage(from: url) { [weak self] image in
                guard let self = self else { return }
                let annotatedImageView = UIImageView(image: image)
                annotatedImageView.contentMode = .scaleAspectFit
                annotatedImageView.frame = self.canvasView.bounds
                self.canvasView.addSubview(annotatedImageView)
                self.note?.localAnnotatedImage = image
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func saveTapped() {
        guard var noteToSave = note else { return }
        
        noteToSave.description = descriptionTextView.text
        
        // If there's a drawing on the canvas, generate the annotated image
        if !canvasView.drawing.bounds.isEmpty {
            // Create an image of the canvas view (which includes the background image view)
            UIGraphicsBeginImageContextWithOptions(canvasView.bounds.size, false, UIScreen.main.scale)
            canvasView.drawHierarchy(in: canvasView.bounds, afterScreenUpdates: true)
            let annotatedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            noteToSave.localAnnotatedImage = annotatedImage
        }
        
        delegate?.noteEditor(self, didSave: noteToSave)
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func addImageTapped() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @objc private func clearCanvas() {
        canvasView.drawing = PKDrawing()
    }
    
    // MARK: - PHPickerViewControllerDelegate
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
            if let image = object as? UIImage {
                DispatchQueue.main.async {
                    self?.note?.localImage = image
                    self?.imageView.image = image
                    self?.addOrChangeImageButton.setTitle("Change Image", for: .normal)
                    self?.clearCanvas() // Clear annotations when a new image is set
                }
            }
        }
    }
    
    // MARK: - Image Loading
    
    private func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        // Check cache first
        if let cachedImage = ImageCache.shared.image(forKey: url.absoluteString) {
            completion(cachedImage)
            return
        }
        
        // Download image
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, let image = UIImage(data: data), error == nil else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            // Save to cache and complete
            ImageCache.shared.setImage(image, forKey: url.absoluteString)
            DispatchQueue.main.async { completion(image) }
        }.resume()
    }
}
