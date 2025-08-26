// import UIKit
// import PencilKit
// import os.log

// /// A view controller for annotating an image using PencilKit.
// /// This screen provides tools for drawing, erasing, and undoing actions on a given image.
// /// On save, it returns the flattened annotated image to the caller.
// class AnnotateImageViewController: UIViewController, PKCanvasViewDelegate {

//     // MARK: - Public API
    
//     /// The image that will be annotated.
//     private let sourceImage: UIImage
    
//     /// A closure to be executed when the user saves the annotated image.
//     /// The closure receives the new image as its parameter.
//     var onSave: ((UIImage) -> Void)?
    
//     // MARK: - UI Elements
    
//     private lazy var canvasView: PKCanvasView = {
//         let canvas = PKCanvasView()
//         canvas.translatesAutoresizingMaskIntoConstraints = false
//         canvas.delegate = self
//         canvas.drawingPolicy = .anyInput
//         canvas.tool = PKInkingTool(.pen, color: .red, width: 5) // Default tool
//         return canvas
//     }()
    
//     private lazy var imageView: UIImageView = {
//         let iv = UIImageView()
//         iv.translatesAutoresizingMaskIntoConstraints = false
//         iv.contentMode = .scaleAspectFit
//         iv.image = sourceImage
//         return iv
//     }()
    
//     private lazy var undoButton: UIBarButtonItem = {
//         return UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.backward"), style: .plain, target: self, action: #selector(undoTapped))
//     }()
    
//     private lazy var eraseButton: UIBarButtonItem = {
//         return UIBarButtonItem(image: UIImage(systemName: "eraser"), style: .plain, target: self, action: #selector(eraseTapped))
//     }()
    
//     private lazy var brushButton: UIBarButtonItem = {
//         return UIBarButtonItem(image: UIImage(systemName: "pencil"), style: .plain, target: self, action: #selector(brushTapped))
//     }()

//     // MARK: - Logger
//     private let logger = Logger(subsystem: "com.amsitesolutions.AM-Site-Solutions", category: "AnnotateImageViewController")

//     // MARK: - Lifecycle
    
//     init(image: UIImage) {
//         self.sourceImage = image
//         super.init(nibName: nil, bundle: nil)
//         logger.log("AnnotateImageViewController initialised for a new session.")
//     }
    
//     required init?(coder: NSCoder) {
//         fatalError("init(coder:) has not been implemented")
//     }
    
//     override func viewDidLoad() {
//         super.viewDidLoad()
//         setupUI()
//         updateToolButtons()
//     }
    
//     // MARK: - UI Setup
    
//     private func setupUI() {
//         view.backgroundColor = .systemBackground
//         title = "Annotate Image"
        
//         // -- Navigation Bar --
//         navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped))
//         navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
        
//         // -- Toolbar --
//         let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
//         toolbarItems = [brushButton, spacer, eraseButton, spacer, undoButton]
//         navigationController?.isToolbarHidden = false
        
//         // -- Canvas and Image View --
//         view.addSubview(imageView)
//         view.addSubview(canvasView)
        
//         NSLayoutConstraint.activate([
//             imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//             imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//             imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//             imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
//             canvasView.topAnchor.constraint(equalTo: imageView.topAnchor),
//             canvasView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
//             canvasView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
//             canvasView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor)
//         ])
        
//         // Make the canvas transparent to see the image underneath
//         canvasView.isOpaque = false
//         canvasView.backgroundColor = .clear
//     }
    
//     // MARK: - Actions
    
//     @objc private func cancelTapped() {
//         logger.log("Cancel tapped. Dismissing annotation screen without saving.")
//         dismiss(animated: true, completion: nil)
//     }
    
//     @objc private func saveTapped() {
//         // Create a new image by rendering both the original image and the canvas drawing.
//         let renderer = UIGraphicsImageRenderer(bounds: imageView.bounds)
//         let annotatedImage = renderer.image { context in
//             // Draw the original image first
//             imageView.layer.render(in: context.cgContext)
//             // Draw the canvas annotations on top
//             canvasView.drawing.image(from: canvasView.bounds, scale: 1.0).draw(in: imageView.bounds)
//         }
        
//         logger.log("Save tapped. Passing new annotated image back via onSave closure.")
//         onSave?(annotatedImage)
//         dismiss(animated: true, completion: nil)
//     }
    
//     @objc private func undoTapped() {
//         logger.log("Undo tapped.")
//         canvasView.undoManager?.undo()
//         updateToolButtons()
//     }
    
//     @objc private func eraseTapped() {
//         logger.log("Eraser tool selected.")
//         canvasView.tool = PKEraserTool(.bitmap)
//         updateToolButtons()
//     }
    
//     @objc private func brushTapped() {
//         logger.log("Brush tool selected.")
//         canvasView.tool = PKInkingTool(.pen, color: .red, width: 5)
//         updateToolButtons()
//     }
    
//     func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
//         updateToolButtons()
//     }
    
//     // MARK: - Helpers
    
//     private func updateToolButtons() {
//         undoButton.isEnabled = canvasView.undoManager?.canUndo ?? false
//         eraseButton.isSelected = canvasView.tool is PKEraserTool
//         brushButton.isSelected = canvasView.tool is PKInkingTool
        
//         // Use tint color to show selection state for toolbar buttons
//         eraseButton.tintColor = (canvasView.tool is PKEraserTool) ? .systemBlue : .label
//         brushButton.tintColor = (canvasView.tool is PKInkingTool) ? .systemBlue : .label
//     }
// }
