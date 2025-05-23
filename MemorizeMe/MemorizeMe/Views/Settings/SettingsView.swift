import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Binding var accessGranted: Bool

    @Environment(\.colorScheme) var colorScheme
    @State private var showResetAlert = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Настройки")
                .font(.largeTitle)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top)

            // Секция доступа к календарю
            VStack(alignment: .leading, spacing: 10) {
                Text("ДОСТУП")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                VStack {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(Color("primaryColor"))
                            .frame(width: 30)
                        Text("Доступ к календарю")
                        Spacer()
                        if accessGranted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Button("Открыть настройки") {
                                viewModel.openSettings()
                            }
                            .foregroundColor(Color("primaryColor"))
                        }
                    }
                    .padding()
                }
                .background(Color("backgroundPrimary"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .padding(.horizontal)
            }

            // -------- ВНЕШНИЙ ВИД --------
            VStack(alignment: .leading, spacing: 0) {
                Text("ВНЕШНИЙ ВИД")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding([.horizontal, .top])

                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "iphone")
                            .foregroundColor(Color("primaryColor"))
                            .frame(width: 30)
                        Text("Следовать теме устройства")
                        Spacer()
                        Toggle("", isOn: $viewModel.followSystemTheme)
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: Color("primaryColor")))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal)

                    Divider()
                        .padding(.leading, 46)

                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundColor(Color("primaryColor"))
                            .frame(width: 30)
                        Text("Тема приложения")
                        Spacer()
                        Picker("", selection: viewModel.followSystemTheme
                            ? .constant(viewModel.currentTheme)
                            : $viewModel.selectedTheme
                        ) {
                            ForEach(AppTheme.allCases) { theme in
                                Text(theme.title).tag(theme)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 140)
                        .disabled(viewModel.followSystemTheme)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal)
                }
                .background(Color("backgroundPrimary"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            // -------- О ПРИЛОЖЕНИИ --------
            VStack(alignment: .leading, spacing: 10) {
                Text("О ПРИЛОЖЕНИИ")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(Color("primaryColor"))
                            .frame(width: 30)
                        Text("Версия приложения")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    .padding()
                    Divider()
                        .padding(.leading, 46)
                    NavigationLink(destination: PrivacyPolicyView()) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundColor(Color("primaryColor"))
                                .frame(width: 30)
                            Text("Политика конфиденциальности")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .foregroundColor(.primary)
                    }
                }
                .background(Color("backgroundPrimary"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .padding(.horizontal)
            }

            // -------- СБРОС --------
            Button(action: {
                showResetAlert = true
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundColor(.red)
                        .frame(width: 30)
                    Text("Сбросить все напоминания")
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding()
                .background(Color("backgroundPrimary"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .padding(.horizontal)
            }
            Spacer()
        }
        .background(Color("backgroundPrimary").edgesIgnoringSafeArea(.all))
        .alert(isPresented: $showResetAlert) {
            Alert(
                title: Text("Сбросить напоминания"),
                message: Text("Вы уверены, что хотите сбросить все настройки и напоминания? Это действие невозможно отменить."),
                primaryButton: .destructive(Text("Сбросить")) {
                    viewModel.resetAllData()
                },
                secondaryButton: .cancel(Text("Отмена"))
            )
        }
        .navigationBarHidden(true)
        .onAppear {
            Task { await viewModel.checkCalendarAccess() }
        }
        .onChange(of: colorScheme) { newScheme in
            if viewModel.followSystemTheme {
                viewModel.setSystemTheme()
            }
        }
    }
}

#Preview {
    SettingsView(
        viewModel: SettingsViewModel(isCalendarAccessGranted: true),
        accessGranted: .constant(true)
    )
}
