//
//  AddGroupMembersView.swift
//  SimpleX (iOS)
//
//  Created by JRoberts on 22.07.2022.
//  Copyright © 2022 SimpleX Chat. All rights reserved.
//

import SwiftUI
import SimpleXChat

struct AddGroupMembersView: View {
    @Environment(\.dismiss) var dismiss: DismissAction
    var chat: Chat
    var groupInfo: GroupInfo

    var body: some View {
        AddGroupMembersViewCommon(chat: chat, groupInfo: groupInfo, addedMembersCb: { _ in dismiss() })
    }
}

struct AddGroupMembersViewCommon: View {
    @EnvironmentObject var chatModel: ChatModel
    var chat: Chat
    @State var groupInfo: GroupInfo
    var creatingGroup: Bool = false
    var showFooterCounter: Bool = true
    var addedMembersCb: ((Set<Int64>) -> Void)
    @State private var selectedContacts = Set<Int64>()
    @State private var selectedRole: GroupMemberRole = .member
    @State private var alert: AddGroupMembersAlert?
    @State private var searchText: String = ""
    @FocusState private var searchFocussed

    private enum AddGroupMembersAlert: Identifiable {
        case prohibitedToInviteIncognito
        case error(title: LocalizedStringKey, error: LocalizedStringKey = "")

        var id: String {
            switch self {
            case .prohibitedToInviteIncognito: return "prohibitedToInviteIncognito"
            case let .error(title, _): return "error \(title)"
            }
        }
    }

    var body: some View {
        if creatingGroup {
            NavigationView {
                addGroupMembersView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button ("Skip") { addedMembersCb(selectedContacts) }
                        }
                    }
            }
        } else {
            addGroupMembersView()
        }
    }

    private func addGroupMembersView() -> some View {
        VStack {
            let membersToAdd = filterMembersToAdd(chatModel.groupMembers)
            List {
                ChatInfoToolbar(chat: chat, imageSize: 48)
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                if (membersToAdd.isEmpty) {
                    Text("No contacts to add")
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                } else {
                    let count = selectedContacts.count
                    Section {
                        if creatingGroup {
                            groupPreferencesButton($groupInfo, true)
                        }
                        rolePicker()
                        inviteMembersButton()
                            .disabled(count < 1)
                    } footer: {
                        if showFooterCounter {
                            if (count >= 1) {
                                HStack {
                                    Button { selectedContacts.removeAll() } label: { Text("Clear").font(.caption) }
                                    Spacer()
                                    Text("\(count) contact(s) selected")
                                }
                            } else {
                                Text("No contacts selected")
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                    }

                    Section {
                        searchFieldView(text: $searchText, focussed: $searchFocussed)
                            .padding(.leading, 2)
                        let s = searchText.trimmingCharacters(in: .whitespaces).localizedLowercase
                        let members = s == "" ? membersToAdd : membersToAdd.filter { $0.chatViewName.localizedLowercase.contains(s) }
                        ForEach(members) { contact in
                            contactCheckView(contact)
                        }
                    }
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .alert(item: $alert) { alert in
            switch alert {
            case .prohibitedToInviteIncognito:
                return Alert(
                    title: Text("Can't invite contact!"),
                    message: Text("You're trying to invite contact with whom you've shared an incognito profile to the group in which you're using your main profile")
                )
            case let .error(title, error):
                return Alert(title: Text(title), message: Text(error))
            }
        }
        .onChange(of: selectedContacts) { _ in
            searchFocussed = false
        }
    }

    private func inviteMembersButton() -> some View {
        Button {
            inviteMembers()
        } label: {
            HStack {
                Text("Invite to group")
                Image(systemName: "checkmark")
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func inviteMembers() {
        Task {
            do {
                for contactId in selectedContacts {
                    let member = try await apiAddMember(groupInfo.groupId, contactId, selectedRole)
                    await MainActor.run { _ = chatModel.upsertGroupMember(groupInfo, member) }
                }
                addedMembersCb(selectedContacts)
            } catch {
                let a = getErrorAlert(error, "Error adding member(s)")
                alert = .error(title: a.title, error: a.message)
            }
        }
    }

    private func rolePicker() -> some View {
        Picker("New member role", selection: $selectedRole) {
            ForEach(GroupMemberRole.allCases) { role in
                if role <= groupInfo.membership.memberRole && role != .author {
                    Text(role.text)
                }
            }
        }
        .frame(height: 36)
    }

    private func contactCheckView(_ contact: Contact) -> some View {
        let checked = selectedContacts.contains(contact.apiId)
        let prohibitedToInviteIncognito = !chat.chatInfo.incognito && contact.contactConnIncognito
        var icon: String
        var iconColor: Color
        if prohibitedToInviteIncognito {
            icon = "theatermasks.circle.fill"
            iconColor = Color(uiColor: .tertiaryLabel)
        } else {
            if checked {
                icon = "checkmark.circle.fill"
                iconColor = .accentColor
            } else {
                icon = "circle"
                iconColor = Color(uiColor: .tertiaryLabel)
            }
        }
        return Button {
            if prohibitedToInviteIncognito {
                alert = .prohibitedToInviteIncognito
            } else {
                if checked {
                    selectedContacts.remove(contact.apiId)
                } else {
                    selectedContacts.insert(contact.apiId)
                }
            }
        } label: {
            HStack{
                ProfileImage(imageStr: contact.image)
                    .frame(width: 30, height: 30)
                    .padding(.trailing, 2)
                Text(ChatInfo.direct(contact: contact).chatViewName)
                    .foregroundColor(prohibitedToInviteIncognito ? .secondary : .primary)
                    .lineLimit(1)
                Spacer()
                Image(systemName: icon)
                    .foregroundColor(iconColor)
            }
        }
    }
}

func searchFieldView(text: Binding<String>, focussed: FocusState<Bool>.Binding) -> some View {
    HStack {
        Image(systemName: "magnifyingglass")
            .resizable()
            .scaledToFit()
            .frame(height: 20)
            .padding(.trailing, 10)
        TextField("Search", text: text)
            .focused(focussed)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
        Image(systemName: "xmark.circle.fill")
            .resizable()
            .scaledToFit()
            .opacity(text.wrappedValue == "" ? 0 : 1)
            .frame(height: 20)
            .onTapGesture {
                text.wrappedValue = ""
                focussed.wrappedValue = false
            }
    }
    .foregroundColor(.secondary)
    .frame(height: 36)
}

struct AddGroupMembersView_Previews: PreviewProvider {
    static var previews: some View {
        AddGroupMembersView(chat: Chat(chatInfo: ChatInfo.sampleData.group), groupInfo: GroupInfo.sampleData)
    }
}
