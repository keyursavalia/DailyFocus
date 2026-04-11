import UIKit

// MARK: - Delegate

final class LeftPanelTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        LeftPanelPresentationController(presentedViewController: presented, presenting: presenting)
    }

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        LeftPanelAnimator(isPresenting: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        LeftPanelAnimator(isPresenting: false)
    }
}

// MARK: - Presentation controller

final class LeftPanelPresentationController: UIPresentationController {

    private let dimmingView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0)
        return v
    }()

    override func presentationTransitionWillBegin() {
        guard let container = containerView else { return }
        dimmingView.frame = container.bounds
        container.insertSubview(dimmingView, at: 0)

        dimmingView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(dimmingTapped))
        )

        // Style the card: corners + shadow
        if let pv = presentedView {
            pv.layer.cornerRadius = 18
            pv.layer.cornerCurve = .continuous
            pv.clipsToBounds = false
            pv.layer.shadowColor = UIColor.black.cgColor
            pv.layer.shadowOpacity = 0.18
            pv.layer.shadowRadius = 24
            pv.layer.shadowOffset = CGSize(width: 6, height: 4)
        }

        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.28)
        })
    }

    override func dismissalTransitionWillBegin() {
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.backgroundColor = .clear
        })
    }

    /// Compact floating card positioned just below the nav bar, anchored to the left edge.
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let container = containerView else { return .zero }
        let safeTop = container.safeAreaInsets.top
        // Sits just below the custom nav bar (44pt) with a small gap
        let y = safeTop + 44 + 10
        let width: CGFloat = 256
        let height = presentedViewController.preferredContentSize.height
        return CGRect(x: 12, y: y, width: width, height: height)
    }

    @objc private func dimmingTapped() {
        presentedViewController.dismiss(animated: true)
    }
}

// MARK: - Animator

final class LeftPanelAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let isPresenting: Bool
    init(isPresenting: Bool) { self.isPresenting = isPresenting }

    func transitionDuration(using context: UIViewControllerContextTransitioning?) -> TimeInterval {
        isPresenting ? 0.36 : 0.26
    }

    func animateTransition(using context: UIViewControllerContextTransitioning) {
        if isPresenting {
            guard
                let toVC = context.viewController(forKey: .to),
                let toView = context.view(forKey: .to)
            else { return }

            context.containerView.addSubview(toView)
            let finalFrame = context.finalFrame(for: toVC)
            toView.frame = finalFrame.offsetBy(dx: -(finalFrame.width + finalFrame.minX + 20), dy: 0)
            toView.alpha = 0.6

            UIView.animate(
                withDuration: transitionDuration(using: context),
                delay: 0,
                usingSpringWithDamping: 0.82,
                initialSpringVelocity: 0.4,
                options: .curveEaseOut
            ) {
                toView.frame = finalFrame
                toView.alpha = 1
            } completion: { _ in
                context.completeTransition(!context.transitionWasCancelled)
            }
        } else {
            guard let fromView = context.view(forKey: .from) else { return }
            let target = fromView.frame.offsetBy(dx: -(fromView.frame.width + fromView.frame.minX + 20), dy: 0)

            UIView.animate(withDuration: transitionDuration(using: context), delay: 0, options: .curveEaseIn) {
                fromView.frame = target
                fromView.alpha = 0
            } completion: { _ in
                context.completeTransition(!context.transitionWasCancelled)
            }
        }
    }
}
