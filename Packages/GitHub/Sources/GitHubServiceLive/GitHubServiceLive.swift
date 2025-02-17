import Foundation
import GitHubCredentialsStore
import GitHubJWTTokenFactory
import GitHubService
import NetworkingService

private enum GitHubServiceLiveError: LocalizedError {
    case organizationNameUnavailable
    case appIDUnavailable
    case privateKeyUnavailable
    case appIsNotInstalled
    case downloadNotFound(os: String, architecture: String)

    var errorDescription: String? {
        switch self {
        case .organizationNameUnavailable:
            return "The organization name is not available"
        case .appIDUnavailable:
            return "The app ID is not available"
        case .privateKeyUnavailable:
            return "The private key is not available"
        case .appIsNotInstalled:
            return "The GitHub app has not been installed. Please install it from the developer settings."
        case let .downloadNotFound(os, architecture):
            return "Could not find a download for \(os) (\(architecture))"
        }
    }
}

public final class GitHubServiceLive: GitHubService {
    private let baseURL = URL(string: "https://api.github.com")!
    private let credentialsStore: GitHubCredentialsStore
    private let networkingService: NetworkingService

    public init(credentialsStore: GitHubCredentialsStore, networkingService: NetworkingService) {
        self.credentialsStore = credentialsStore
        self.networkingService = networkingService
    }

    public func getAppAccessToken() async throws -> GitHubAppAccessToken {
        let appInstallation = try await getAppInstallation()
        let installationID = String(appInstallation.id)
        let appID = String(appInstallation.appId)
        let url = baseURL.appending(path: "/app/installations/\(installationID)/access_tokens")
        guard let privateKey = await credentialsStore.privateKey else {
            throw GitHubServiceLiveError.privateKeyUnavailable
        }
        let jwtToken = try GitHubJWTTokenFactory.makeJWTToken(privateKey: privateKey, appID: appID)
        var request = URLRequest(url: url).addingBearerToken(jwtToken)
        request.httpMethod = "POST"
        return try await networkingService.load(IntermediateGitHubAppAccessToken.self, from: request).map { parameters in
            GitHubAppAccessToken(parameters.value.token)
        }
    }

    public func getRunnerDownloadURL(with appAccessToken: GitHubAppAccessToken) async throws -> URL {
        let organizationName = try await getOrganizationName()
        let url = baseURL.appending(path: "/orgs/\(organizationName)/actions/runners/downloads")
        let request = URLRequest(url: url).addingBearerToken(appAccessToken.rawValue)
        let downloads = try await networkingService.load([GitHubRunnerDownload].self, from: request).map(\.value)
        let os = "osx"
        let architecture = "arm64"
        guard let download = downloads.first(where: { $0.os == os && $0.architecture == architecture }) else {
            throw GitHubServiceLiveError.downloadNotFound(os: os, architecture: architecture)
        }
        return download.downloadURL
    }

    public func getRunnerRegistrationToken(with appAccessToken: GitHubAppAccessToken) async throws -> GitHubRunnerRegistrationToken {
        let organizationName = try await getOrganizationName()
        let url = baseURL.appending(path: "/orgs/\(organizationName)/actions/runners/registration-token")
        var request = URLRequest(url: url).addingBearerToken(appAccessToken.rawValue)
        request.httpMethod = "POST"
        return try await networkingService.load(IntermediateGitHubRunnerRegistrationToken.self, from: request).map { parameters in
            GitHubRunnerRegistrationToken(parameters.value.token)
        }
    }
}

private extension GitHubServiceLive {
    private func getAppInstallation() async throws -> GitHubAppInstallation {
        let url = baseURL.appending(path: "/app/installations")
        let token = try await getAppJWTToken()
        let request = URLRequest(url: url).addingBearerToken(token)
        let appInstallations = try await networkingService.load([GitHubAppInstallation].self, from: request).map(\.value)
        let organizationName = await credentialsStore.organizationName
        guard let appInstallation = appInstallations.first(where: { $0.account.login == organizationName }) else {
            throw GitHubServiceLiveError.appIsNotInstalled
        }
        return appInstallation
    }

    private func getOrganizationName() async throws -> String {
        guard let organizationName = await credentialsStore.organizationName else {
            throw GitHubServiceLiveError.organizationNameUnavailable
        }
        return organizationName
    }

    private func getAppJWTToken() async throws -> String {
        guard let privateKey = await credentialsStore.privateKey else {
            throw GitHubServiceLiveError.privateKeyUnavailable
        }
        guard let appID = await credentialsStore.appId else {
            throw GitHubServiceLiveError.appIDUnavailable
        }
        return try GitHubJWTTokenFactory.makeJWTToken(privateKey: privateKey, appID: appID)
    }
}

private extension URLRequest {
    func addingBearerToken(_ token: String) -> URLRequest {
        var mutableRequest = self
        mutableRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return mutableRequest
    }
}
