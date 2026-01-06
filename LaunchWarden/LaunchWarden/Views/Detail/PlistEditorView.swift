import SwiftUI

struct PlistEditorView: View {
    let plistURL: URL
    let isEditable: Bool
    
    @State private var plistContent: [String: Any] = [:]
    @State private var rawXML: String = ""
    @State private var isLoading = true
    @State private var error: Error?
    @State private var viewMode: ViewMode = .structured
    @State private var hasUnsavedChanges = false
    @State private var isSaving = false
    
    enum ViewMode: String, CaseIterable {
        case structured = "Structured"
        case raw = "Raw XML"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Picker("View", selection: $viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                
                Spacer()
                
                if hasUnsavedChanges && isEditable {
                    Button {
                        saveChanges()
                    } label: {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.6)
                        } else {
                            Label("Save", systemImage: "square.and.arrow.down")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSaving)
                }
                
                Button {
                    loadPlist()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Reload")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Content
            if isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = error {
                ErrorView(error: error) {
                    loadPlist()
                }
            } else {
                switch viewMode {
                case .structured:
                    structuredView
                case .raw:
                    rawXMLView
                }
            }
        }
        .onAppear {
            loadPlist()
        }
    }
    
    // MARK: - Structured View
    
    private var structuredView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 1) {
                ForEach(Array(plistContent.keys.sorted()), id: \.self) { key in
                    PlistRowView(
                        key: key,
                        value: plistContent[key],
                        level: 0
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Raw XML View
    
    private var rawXMLView: some View {
        ScrollView {
            if isEditable {
                TextEditor(text: $rawXML)
                    .font(.system(.body, design: .monospaced))
                    .onChange(of: rawXML) { _, _ in
                        hasUnsavedChanges = true
                    }
            } else {
                Text(rawXML)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
    }
    
    // MARK: - Methods
    
    private func loadPlist() {
        isLoading = true
        error = nil
        
        Task {
            do {
                plistContent = try PlistParser.readRaw(url: plistURL)
                
                // Load raw XML
                if let data = FileManager.default.contents(atPath: plistURL.path),
                   let xml = String(data: data, encoding: .utf8) {
                    rawXML = xml
                }
                
                hasUnsavedChanges = false
            } catch {
                self.error = error
            }
            isLoading = false
        }
    }
    
    private func saveChanges() {
        guard isEditable else { return }
        
        isSaving = true
        
        Task {
            do {
                // Parse the raw XML back to plist
                if let data = rawXML.data(using: .utf8),
                   let plist = try PropertyListSerialization.propertyList(
                    from: data,
                    options: .mutableContainersAndLeaves,
                    format: nil
                   ) as? [String: Any] {
                    try PlistParser.write(plist: plist, to: plistURL)
                    hasUnsavedChanges = false
                    plistContent = plist
                }
            } catch {
                self.error = error
            }
            isSaving = false
        }
    }
}

// MARK: - Plist Row View

struct PlistRowView: View {
    let key: String
    let value: Any?
    let level: Int
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                // Indentation
                ForEach(0..<level, id: \.self) { _ in
                    Color.clear.frame(width: 20)
                }
                
                // Expand button for collections
                if isCollection {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 16)
                } else {
                    Color.clear.frame(width: 16)
                }
                
                // Key
                Text(key)
                    .fontWeight(.medium)
                
                // Type badge
                Text(typeString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(3)
                
                Spacer()
                
                // Value (for primitives)
                if !isCollection {
                    Text(valueString)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.blue)
                        .lineLimit(1)
                        .textSelection(.enabled)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(level % 2 == 0 ? Color.clear : Color.secondary.opacity(0.05))
            
            // Children
            if isExpanded, let dict = value as? [String: Any] {
                ForEach(Array(dict.keys.sorted()), id: \.self) { childKey in
                    PlistRowView(
                        key: childKey,
                        value: dict[childKey],
                        level: level + 1
                    )
                }
            } else if isExpanded, let array = value as? [Any] {
                ForEach(Array(array.enumerated()), id: \.offset) { index, item in
                    PlistRowView(
                        key: "[\(index)]",
                        value: item,
                        level: level + 1
                    )
                }
            }
        }
    }
    
    private var isCollection: Bool {
        value is [String: Any] || value is [Any]
    }
    
    private var typeString: String {
        switch value {
        case is String: return "String"
        case is Int: return "Number"
        case is Double: return "Number"
        case is Bool: return "Boolean"
        case is Data: return "Data"
        case is Date: return "Date"
        case is [String: Any]: return "Dictionary"
        case is [Any]: return "Array"
        default: return "Unknown"
        }
    }
    
    private var valueString: String {
        switch value {
        case let str as String: return "\"\(str)\""
        case let num as Int: return "\(num)"
        case let num as Double: return "\(num)"
        case let bool as Bool: return bool ? "true" : "false"
        case let date as Date: return date.formatted()
        case is Data: return "(Data)"
        case let dict as [String: Any]: return "{\(dict.count) items}"
        case let arr as [Any]: return "[\(arr.count) items]"
        default: return "(null)"
        }
    }
}

#Preview {
    PlistEditorView(
        plistURL: URL(fileURLWithPath: "/Users/test/Library/LaunchAgents/test.plist"),
        isEditable: true
    )
}
