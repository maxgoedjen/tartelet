import Foundation
import GitHubCredentialsStore
import Keychain
import RSAPrivateKey

public final actor GitHubCredentialsStoreKeychain: GitHubCredentialsStore {
    private enum PasswordAccount {
        static let targetType = "github.credentials.targetType"
        static let organizationName = "github.credentials.organizationName"
        static let repositoryNames = "github.credentials.repositoryNames"
        static let appId = "github.credentials.appId"
    }

    private enum KeyTag {
        static let privateKey = "github.credentials.privateKey"
    }

    public var targetType: String? {
        get async {
            return await keychain.password(forAccount: PasswordAccount.targetType, belongingToService: serviceName)
        }
    }
    public var repositoryNames: String? {
        get async {
            return await keychain.password(forAccount: PasswordAccount.repositoryNames, belongingToService: serviceName)
        }
    }
    public var organizationName: String? {
        get async {
            return await keychain.password(forAccount: PasswordAccount.organizationName, belongingToService: serviceName)
        }
    }
    public var appId: String? {
        get async {
            return await keychain.password(forAccount: PasswordAccount.appId, belongingToService: serviceName)
        }
    }
    public var privateKey: Data? {
        get async {
            return await keychain.key(withTag: KeyTag.privateKey)?.data
        }
    }

    private let keychain: Keychain
    private let serviceName: String

    public init(keychain: Keychain, serviceName: String) {
        self.keychain = keychain
        self.serviceName = serviceName
    }

    public func setTargetType(_ targetType: String?) async {
        if let targetType {
            _ = await keychain.setPassword(targetType, forAccount: PasswordAccount.targetType, belongingToService: serviceName)
        } else {
            await keychain.removePassword(forAccount: PasswordAccount.targetType, belongingToService: serviceName)
        }
    }

    public func setOrganizationName(_ organizationName: String?) async {
        if let organizationName {
            _ = await keychain.setPassword(organizationName, forAccount: PasswordAccount.organizationName, belongingToService: serviceName)
        } else {
            await keychain.removePassword(forAccount: PasswordAccount.organizationName, belongingToService: serviceName)
        }
    }

    public func setRepositoryNames(_ repositoryNames: String?) async {
        if let repositoryNames {
            _ = await keychain.setPassword(repositoryNames, forAccount: PasswordAccount.repositoryNames, belongingToService: serviceName)
        } else {
            await keychain.removePassword(forAccount: PasswordAccount.repositoryNames, belongingToService: serviceName)
        }
    }

    public func setAppID(_ appID: String?) async {
        if let appID {
            _ = await keychain.setPassword(appID, forAccount: PasswordAccount.appId, belongingToService: serviceName)
        } else {
            await keychain.removePassword(forAccount: PasswordAccount.appId, belongingToService: serviceName)
        }
    }

    public func setPrivateKey(_ privateKeyData: Data?) async {
        if let privateKeyData, let key = RSAPrivateKey(privateKeyData) {
            _ = await keychain.setKey(key, withTag: KeyTag.privateKey)
        } else {
            await keychain.removeKey(withTag: KeyTag.privateKey)
        }
    }
}
