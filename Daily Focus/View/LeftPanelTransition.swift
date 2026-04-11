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

        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        })
    }

    override func dismissalTransitionWillBegin() {
        presentedViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0)
        })
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let container = containerView else { return .zero }
        let width = min(container.bounds.width * 0.78, 320)
        return CGRect(x: 0, y: 0, width: width, height: container.bounds.height)
    }

    @objc private func dimmingTapped() {
        presentedViewController.dismiss(animated: true)
    }
}

// MARK: - Animator

final class LeftPanelAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let isPresenting: Bool
    init(isPresenting: Bool) { self.isPresenting = isPresenting }

    func transitionDuration(using context: UIViewControllerContextTransitioning?) -> TimeInterval { 0.28 }

    func animateTransition(using context: UIViewControllerContextTransitioning) {
        let duration = transitionDuration(using: context)

        if isPresenting {
            guard
                let toVC = context.viewController(forKey: .to),
                let toView = context.view(forKey: .to)
            else { return }

            context.containerView.addSubview(toView)
            let final = context.finalFrame(for: toVC)
            toView.frame = final.offsetBy(dx: -final.width, dy: 0)

            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut) {
                toView.frame = final
            } completion: { _ in
                context.completeTransition(!context.transitionWasCancelled)
            }
        } else {
            guard let fromView = context.view(forKey: .from) else { return }
            let target = fromView.frame.offsetBy(dx: -fromView.frame.width, dy: 0)

            UIView.animate(withDuration: duration, delay: 0, options: .curveEaseIn) {
                fromView.frame = target
            } completion: { _ in
                context.completeTransition(!context.transitionWasCancelled)
            }
        }
    }
}
