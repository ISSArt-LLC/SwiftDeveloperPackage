#if !os(macOS)
    import UIKit

    @available(iOS 13.0, *)
    public extension UIImage {
        func resize(targetWidth: CGFloat) -> UIImage {
            let originalSize = self.size
            let targetSize = CGSize(width: targetWidth, height: targetWidth * originalSize.height / originalSize.width)
            return self.resize(targetSize: targetSize)
        }
        
        func resize(targetSize: CGSize) -> UIImage {
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            return renderer.image { _ in
                self.draw(in: CGRect(origin: .zero, size: targetSize))
            }
        }
    }
#endif


