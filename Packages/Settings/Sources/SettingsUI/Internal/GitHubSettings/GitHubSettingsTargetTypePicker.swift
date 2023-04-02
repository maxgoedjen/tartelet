import SwiftUI

struct GitHubSettingsTargetTypePicker: View {
    @Binding var selection: GitHubSettingsTargetType

    var body: some View {
        Picker(L10n.Settings.Github.targetType, selection: $selection) {
            ForEach(GitHubSettingsTargetType.allCases) { type in
                Text(type.title).tag(type.rawValue)
            }
        }.pickerStyle(.segmented)
    }
}
