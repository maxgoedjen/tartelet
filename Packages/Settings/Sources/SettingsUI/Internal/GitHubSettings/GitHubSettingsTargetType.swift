import Foundation

enum GitHubSettingsTargetType: String, CaseIterable, Identifiable {
    case organization = "organization"
    case personal = "personal"

    var id: Self {
        return self
    }

    var title: String {
        switch self {
        case .organization:
            return L10n.Settings.Github.TargetType.organization
        case .personal:
            return L10n.Settings.Github.TargetType.personal
        }
    }
}
