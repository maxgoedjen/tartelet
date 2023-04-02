import Foundation

public protocol GitHubCredentialsStore: AnyObject {
    var targetType: String? { get async }
    var organizationName: String? { get async }
    var repositoryNames: String? { get async }
    var appId: String? { get async }
    var privateKey: Data? { get async }
    func setTargetType(_ targetType: String?) async
    func setOrganizationName(_ organizationName: String?) async
    func setRepositoryNames(_ repositoryNames: String?) async
    func setAppID(_ appID: String?) async
    func setPrivateKey(_ privateKeyData: Data?) async
}
