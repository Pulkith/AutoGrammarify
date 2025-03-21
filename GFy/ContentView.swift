//
//  ContentView.swift
//  GFy
//
//  Created by Pulkith Paruchuri on 3/20/25.
//

import SwiftUI

// MARK: - Main ContentView
struct ContentView: View {
    @State private var isWiFiOn = true
    @State private var selectedHotspot: String? = nil
    @State private var selectedKnownNetwork: String? = nil
    @State private var selectedOtherNetwork: String? = nil
    @State private var selectedStyle: String? = "Regular"
    
    var body: some View {
        VStack(spacing: 0) {
            // 1) Title Row (Wi-Fi + Toggle)
            titleRow
            
            Divider()
            
            // 2) PERSONAL HOTSPOT SECTION
            SectionHeader("Text Style")
            optionRow(name: "Regular")
            optionRow(name: "Formal")
            optionRow(name: "Casual")
            optionRow(name: "Scholar")
            
            Divider()
                .padding(.top, 5)
            
            // 3) Wi-Fi Settings Button
            MenuButton(title: "Settings", icon: nil, action: {
                print("Settings")
            }, useBlueHover: true)
                .padding(.top, 5)
            
            // 4) Quit Button
            MenuButton(title: "Quit", icon: "xmark.circle", action: {
                print("Quit clicked")
                NSApplication.shared.terminate(nil)
            }, useRedHover: true)
            .padding(.top, 5)
            .padding(.bottom, 5)
        }
        .frame(width: 300)
        .background(VisualEffectBlur(material: .menu))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 8)
    }
    
    // MARK: - Title Row (Wi-Fi + Toggle)
    private var titleRow: some View {
        HStack {
            Text("GFy")
                .font(.system(size: 14, weight: .medium))
            Spacer()
            Toggle("", isOn: $isWiFiOn)
                .toggleStyle(SwitchToggleStyle())
                .labelsHidden()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
    
    // MARK: - Application Select Row
    // MARK: - Application Select Row
    func optionRow(name: String) -> some View {
        HStack {
            Image(systemName: "pencil")
                .foregroundColor(selectedStyle == name ? .white : .primary)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(selectedStyle == name ? Color.blue : Color(NSColor.lightGray).opacity(0.3))
                )
            Text(name)
            Spacer()
        }
        .menuRowStyle()
        .onTapGesture {
            selectedStyle = name
        }
    }
    
    // MARK: - Personal Hotspot Row
//    func hotspotRow(name: String, is5G: Bool) -> some View {
//        HStack {
//            Image(systemName: "personalhotspot")
//                .foregroundColor(selectedHotspot == name ? .blue : .primary)
//            Text(name)
//            Spacer()
//            if is5G {
//                // Example "5G" label or icon
//                Text("5G")
//                    .font(.system(size: 11, weight: .semibold))
//                    .foregroundColor(.secondary)
//            }
//        }
//        .menuRowStyle()
//        .onTapGesture {
//            selectedHotspot = name
//            selectedKnownNetwork = nil
//            selectedOtherNetwork = nil
//        }
//    }
    
    // MARK: - Known Network Row
//    func knownNetworkRow(name: String, locked: Bool) -> some View {
//        HStack {
//            // Example Wi-Fi symbol
//            Image(systemName: "wifi")
//                .foregroundColor(selectedKnownNetwork == name ? .blue : .primary)
//            Text(name)
//            Spacer()
//            // Lock icon if network is secured
//            if locked {
//                Image(systemName: "lock.fill")
//                    .foregroundColor(.secondary)
//            }
//        }
//        .menuRowStyle()
//        .onTapGesture {
//            selectedHotspot = nil
//            selectedKnownNetwork = name
//            selectedOtherNetwork = nil
//        }
//    }
    
    // MARK: - Other Network Row
//    func otherNetworkRow(name: String) -> some View {
//        HStack {
//            Image(systemName: "wifi")
//                .foregroundColor(selectedOtherNetwork == name ? .blue : .primary)
//            Text(name)
//            Spacer()
//        }
//        .menuRowStyle()
//        .onTapGesture {
//            selectedHotspot = nil
//            selectedKnownNetwork = nil
//            selectedOtherNetwork = name
//        }
//    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    
    init(_ title: String) {
        self.title = title
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

// MARK: - Row Styling Modifier
extension View {
    func menuRowStyle() -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())  // Ensures hover effect covers entire row
            .buttonStyle(.plain)
            .hoverEffect()
    }
    
    // Simple hover effect that slightly darkens the background
    func hoverEffect() -> some View {
        modifier(HoverEffectModifier())
    }
}

// MARK: - HoverEffectModifier
struct HoverEffectModifier: ViewModifier {
    @State private var isHovering = false
    
    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: 6)  // Curved corners for hover effect
                .fill(isHovering
                      ? Color(NSColor.lightGray).opacity(0.3)
                      : Color.clear)
            )
            .onHover { hover in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovering = hover
                }
            }
            .padding(.leading, 5)
            .padding(.trailing, 5)
                }
}

// MARK: - NSVisualEffectView Wrapper for Blur
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .menu
    var blendingMode: NSVisualEffectView.BlendingMode = .withinWindow
    var state: NSVisualEffectView.State = .active
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) { }
}

// MARK: - Preview (Optional)
// struct ContentView_Previews: PreviewProvider {
//     static var previews: some View {
//         ContentView()
//     }
// }

// MARK: - Menu Button
struct MenuButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var useBlueHover: Bool = false
    var useRedHover: Bool = false
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(useRedHover ? .red : .primary)
                }
                Text(title)
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering
                          ? (useRedHover ? Color.red.opacity(0.2) : 
                                useBlueHover ? Color.blue.opacity(0.5) :
                             Color(NSColor.lightGray).opacity(0.3))
                          : Color.clear)
            )
            .padding(.horizontal, 5)
        }
        .buttonStyle(.plain)
        .onHover { hover in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hover
            }
        }
    }
}
