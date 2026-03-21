import AVKit
import SwiftUI

struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        let picker = AVRoutePickerView()
        picker.tintColor = .label
        picker.prioritizesVideoDevices = false
        picker.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(picker)
        NSLayoutConstraint.activate([
            picker.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            picker.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            picker.widthAnchor.constraint(equalToConstant: 36),
            picker.heightAnchor.constraint(equalToConstant: 36),
        ])
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
