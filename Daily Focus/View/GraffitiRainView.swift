import UIKit

class GraffitiRainView: UIView {
    
    private let emitterLayer = CAEmitterLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupEmitter()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: -50)
        emitterLayer.emitterSize = CGSize(width: bounds.width * 2, height: 1)
    }
    
    private func setupEmitter() {
        // Graffiti-style colors: neon, spray paint palette
        let colors: [UIColor] = [
            UIColor(red: 0.0, green: 1.0, blue: 0.5, alpha: 0.9),  // neon green
            UIColor(red: 1.0, green: 0.3, blue: 0.5, alpha: 0.9),  // hot pink
            UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 0.9),  // electric blue
            UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 0.9),  // spray yellow
            UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 0.9)   // orange
        ]
        
        var cells: [CAEmitterCell] = []
        
        for color in colors {
            let cell = CAEmitterCell()
            cell.birthRate = 8
            cell.lifetime = 12
            cell.velocity = 80
            cell.velocityRange = 40
            cell.emissionLongitude = .pi / 2  // fall downward
            cell.emissionRange = .pi / 4
            cell.scale = 0.15
            cell.scaleRange = 0.1
            cell.color = color.cgColor
            cell.alphaSpeed = -0.05
            
            // Use circle (spray dot) or create custom content
            cell.contents = createGraffitiImage(color: color)?.cgImage
            cells.append(cell)
        }
        
        emitterLayer.emitterCells = cells
        emitterLayer.emitterShape = .line
        layer.addSublayer(emitterLayer)
    }
    
    private func createGraffitiImage(color: UIColor) -> UIImage? {
        let size = CGSize(width: 20, height: 20)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 2, y: 2, width: 16, height: 16))
        }
    }
    
    func startRain() {
        emitterLayer.birthRate = 1
    }
    
    func stopRain() {
        emitterLayer.birthRate = 0
    }
}
