import UIKit
import DotLottie

/// Full-screen confetti overlay using `Resources/Confetti.lottie` via DotLottie.
final class CompletionCelebrationView: UIView {

    private var playerView: DotLottiePlayerUIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        isHidden = true
        alpha = 0
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func loadConfettiData() -> Data? {
        let bundle = Bundle.main
        if let url = bundle.url(forResource: "Confetti", withExtension: "lottie", subdirectory: "Resources"),
           let data = try? Data(contentsOf: url) {
            return data
        }
        if let url = bundle.url(forResource: "Confetti", withExtension: "lottie"),
           let data = try? Data(contentsOf: url) {
            return data
        }
        return nil
    }

    func playCelebration() {
        subviews.forEach { $0.removeFromSuperview() }
        playerView = nil

        guard let data = Self.loadConfettiData() else { return }

        let config = AnimationConfig(autoplay: false, loop: false)
        let pv = DotLottiePlayerUIView(dotLottieData: data, config: config)
        pv.loopMode = .playOnce
        pv.translatesAutoresizingMaskIntoConstraints = false
        pv.backgroundColor = .clear
        addSubview(pv)
        NSLayoutConstraint.activate([
            pv.centerXAnchor.constraint(equalTo: centerXAnchor),
            pv.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -36),
            pv.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0),
            pv.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.5)
        ])
        playerView = pv
        _ = pv.play()

        isHidden = false
        UIView.animate(withDuration: 0.28) { self.alpha = 1 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 7) { [weak self] in
            self?.fadeOut()
        }
    }

    func stopAndHide() {
        fadeOut()
    }

    private func fadeOut() {
        playerView?.pause()
        UIView.animate(withDuration: 0.55, animations: {
            self.alpha = 0
        }) { _ in
            self.isHidden = true
            self.subviews.forEach { $0.removeFromSuperview() }
            self.playerView = nil
        }
    }
}
