//
//  SignatureDrawView.swift
//  AM Site Solutions
//
//  Created by Warren Harding on 29/01/2025.
//

import UIKit

class SignatureDrawView: UIView {

    private var path = UIBezierPath()
    private var touchPoint: CGPoint?
    private var optionalImage: UIImage?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        self.backgroundColor = UIColor.lightGray
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.darkGray.cgColor
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        touchPoint = touch.location(in: self)
        path.move(to: touchPoint!)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let touchPoint = touchPoint else { return }
        let currentPoint = touch.location(in: self)
        path.addLine(to: currentPoint)
        self.touchPoint = currentPoint
        drawSignature()
    }

    private func drawSignature() {
        UIGraphicsBeginImageContext(self.frame.size)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        optionalImage?.draw(in: self.bounds)
        
        self.layer.render(in: context)
        UIColor.black.setStroke()
        path.stroke()
        UIGraphicsEndImageContext()
        
        self.setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        optionalImage?.draw(in: rect)
        UIColor.black.setStroke()
        path.stroke()
    }

    func clear() {
        path.removeAllPoints()
        optionalImage = nil
        self.setNeedsDisplay()
    }

//    func getSignatureImage() -> UIImage? {
//        UIGraphicsBeginImageContext(self.bounds.size)
//        defer { UIGraphicsEndImageContext() }
//        guard let context = UIGraphicsGetCurrentContext() else { return nil }
//        
//        optionalImage?.draw(in: self.bounds)
//        
//        self.layer.render(in: context)
//        return UIGraphicsGetImageFromCurrentImageContext()
//    }
    
    func getSignatureImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0)
        defer { UIGraphicsEndImageContext() }
        // drawHierarchy renders the view's appearance while respecting transparency
        if self.drawHierarchy(in: self.bounds, afterScreenUpdates: true) {
            return UIGraphicsGetImageFromCurrentImageContext()
        }
        return nil
    }
    
    func setSignatureImage(_ image: UIImage) {
        self.optionalImage = image
        self.setNeedsDisplay()
    }
}

