import SwiftUI

struct SettingsView: View {
    @Binding var languageCode: String
    @Binding var appearanceCode: String
    let language: AppLanguage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.text("settings.language", language: language)) {
                    Picker(L10n.text("settings.language", language: language), selection: $languageCode) {
                        ForEach(AppLanguage.allCases) { option in
                            Text(option.displayName).tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(L10n.text("settings.appearance", language: language)) {
                    Picker(L10n.text("settings.appearance", language: language), selection: $appearanceCode) {
                        ForEach(AppearanceMode.allCases) { option in
                            Text(title(for: option)).tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(L10n.text("privacy.title", language: language)) {
                    Text(L10n.text("privacy.body", language: language))
                }

                Section(L10n.text("review.title", language: language)) {
                    Text(L10n.text("review.body", language: language))
                }
            }
            .navigationTitle(L10n.text("settings.title", language: language))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.text("action.done", language: language)) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func title(for mode: AppearanceMode) -> String {
        switch mode {
        case .system:
            return L10n.text("appearance.system", language: language)
        case .light:
            return L10n.text("appearance.light", language: language)
        case .dark:
            return L10n.text("appearance.dark", language: language)
        }
    }
}
