import Foundation
import Contacts

@MainActor
class ContactManager: ObservableObject {
    static let shared = ContactManager()

    @Published var authorizationStatus: CNAuthorizationStatus = .notDetermined
    @Published var allContacts: [Contact] = []
    @Published var duplicateGroups: [DuplicateContactGroup] = []
    @Published var isLoading = false

    private let store = CNContactStore()

    private init() {
        checkAuthorizationStatus()
    }

    func checkAuthorizationStatus() {
        authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await store.requestAccess(for: .contacts)
            await MainActor.run {
                self.authorizationStatus = granted ? .authorized : .denied
            }
            return granted
        } catch {
            return false
        }
    }

    func loadContacts() async {
        guard authorizationStatus == .authorized else { return }

        await MainActor.run {
            isLoading = true
        }

        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactIdentifierKey as CNKeyDescriptor
        ]

        let request = CNContactFetchRequest(keysToFetch: keysToFetch)
        var contacts: [Contact] = []

        do {
            try store.enumerateContacts(with: request) { cnContact, _ in
                let contact = Contact(
                    id: cnContact.identifier,
                    givenName: cnContact.givenName,
                    familyName: cnContact.familyName,
                    phoneNumbers: cnContact.phoneNumbers.map { $0.value.stringValue },
                    emailAddresses: cnContact.emailAddresses.map { $0.value as String }
                )
                contacts.append(contact)
            }
        } catch {
            print("Failed to fetch contacts: \(error)")
        }

        await MainActor.run {
            self.allContacts = contacts
            self.isLoading = false
        }

        await findDuplicates()
    }

    func findDuplicates() async {
        var nameGroups: [String: [Contact]] = [:]

        for contact in allContacts {
            let normalizedName = contact.fullName.lowercased().trimmingCharacters(in: .whitespaces)
            guard !normalizedName.isEmpty else { continue }

            if nameGroups[normalizedName] != nil {
                nameGroups[normalizedName]?.append(contact)
            } else {
                nameGroups[normalizedName] = [contact]
            }
        }

        let duplicates = nameGroups.filter { $0.value.count > 1 }
            .map { DuplicateContactGroup(contacts: $0.value) }
            .sorted { $0.contacts.count > $1.contacts.count }

        await MainActor.run {
            self.duplicateGroups = duplicates
        }
    }

    func mergeContacts(group: DuplicateContactGroup, keepIndex: Int) async throws {
        guard keepIndex < group.contacts.count else { return }

        let contactsToDelete = group.contacts.enumerated()
            .filter { $0.offset != keepIndex }
            .map { $0.element }

        for contact in contactsToDelete {
            guard let cnContact = try? store.unifiedContact(
                withIdentifier: contact.id,
                keysToFetch: [CNContactIdentifierKey as CNKeyDescriptor]
            ) else { continue }

            let deleteRequest = CNSaveRequest()
            deleteRequest.delete(cnContact.mutableCopy() as! CNMutableContact)
            try store.execute(deleteRequest)
        }

        await loadContacts()
    }
}
