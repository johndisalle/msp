import SwiftUI

// MARK: - Admin Panel (root)
//
// Entry point for admin-only tools. Tab picker switches between:
//   - Moderation: existing AdminModerationView (testimony queue)
//   - Users:      new UserManagementView (list, search, grant/revoke/delete)
//
// Visible via Settings only when AuthService.shared.isAdmin == true.

struct AdminPanelView: View {
    enum Section: String, CaseIterable, Identifiable {
        case moderation = "Moderation"
        case users = "Users"
        var id: Self { self }
    }

    @State private var section: Section = .moderation

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $section) {
                ForEach(Section.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)

            Group {
                switch section {
                case .moderation: AdminModerationView()
                case .users:      UserManagementView()
                }
            }
        }
        .navigationTitle("Admin")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { AdminPanelView() }
}
