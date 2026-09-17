import SwiftUI

struct PhoneNumberEntryView: View {
    let personId: UUID
    @Environment(DataService.self) private var dataService
    @AppStorage("phoneEntered") private var phoneEntered: String = ""
    @State private var phoneNumber: String = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 8) {
                    Text("Your Phone Number")
                        .font(.largeTitle.weight(.bold))
                    Text("Used for team notifications and reminders")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                TextField("5551234567", text: $phoneNumber)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .onChange(of: phoneNumber) { _, newValue in
                        phoneNumber = newValue.filter { $0.isNumber }
                    }

                Button {
                    Task { await savePhone() }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Continue")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 40)
                .disabled(phoneNumber.count < 10 || isLoading)

                Button {
                    phoneEntered = "true"
                } label: {
                    Text("Skip")
                        .font(.subheadline)
                }
                .foregroundStyle(.secondary)

                Spacer()
                Spacer()
            }
            .padding()
        }
    }

    private func savePhone() async {
        isLoading = true
        defer { isLoading = false }

        let phone = phoneNumber.trimmingCharacters(in: .whitespaces)
        await dataService.updatePhone(personId: personId, phone: phone)
        phoneEntered = "true"
    }
}
