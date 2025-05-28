import SwiftUI
import SwiftData

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Binding var accessGranted: Bool
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var significantDateViewModel: SignificantDateViewModel

    @Environment(\.colorScheme) var colorScheme
    @State private var showResetAlert = false
    @State private var showAnalysisTooltip = false

    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Text("Настройки")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top)

                // АНАЛИЗ КАЛЕНДАРЯ
                VStack(alignment: .leading, spacing: 10) {
                    Text("АНАЛИЗ")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        HStack {
                            Image(systemName: "brain")
                                .foregroundColor(Color("primaryColor"))
                                .frame(width: 30)
                            
                            Text("Полный анализ календаря")
                                .font(.body)
                            
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showAnalysisTooltip.toggle()
                                }
                            }) {
                                Image(systemName: "questionmark.circle")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }
                            
                            Spacer()
                            
                            if significantDateViewModel.isAnalyzing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Button("Запустить") {
                                    Task {
                                        await significantDateViewModel.fullRefreshAnalysis(modelContext: modelContext)
                                    }
                                }
                                .foregroundColor(Color("primaryColor"))
                            }
                        }
                        .padding()
                        
                        Divider()
                            .padding(.leading, 46)
                        
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(Color("primaryColor"))
                                .frame(width: 30)
                            Text("Найдено значимых дат")
                            Spacer()
                            Text("\(significantDateViewModel.specialDates.count)")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        
                        if significantDateViewModel.lastAnalysisDate != nil {
                            Divider()
                                .padding(.leading, 46)
                            
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(Color("primaryColor"))
                                    .frame(width: 30)
                                Text("Последний анализ")
                                Spacer()
                                Text(formatLastAnalysisDate())
                                    .foregroundColor(.gray)
                            }
                            .padding()
                        }
                    }
                    .background(Color("backgroundPrimary"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray5), lineWidth: 1)
                    )
                    .padding(.horizontal)
                }

                // ВНЕШНИЙ ВИД
                VStack(alignment: .leading, spacing: 10) {
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
                            Picker("", selection: $viewModel.selectedTheme) {
                                ForEach(AppTheme.allCases) { theme in
                                    Text(theme.title).tag(theme)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 140)
                            .disabled(viewModel.followSystemTheme)
                            .onChange(of: viewModel.followSystemTheme) { followSystem in
                                if followSystem {
                                    viewModel.selectedTheme = viewModel.currentTheme
                                }
                            }
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

                // О ПРИЛОЖЕНИИ
                VStack(alignment: .leading, spacing: 10) {
                    Text("О ПРИЛОЖЕНИИ")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    VStack(spacing: 0) {
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

                // СБРОС
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
                .padding(.bottom, 20)
                
                Spacer()
            }
            .background(Color("backgroundPrimary").edgesIgnoringSafeArea(.all))
            .blur(radius: showAnalysisTooltip ? 2 : 0)
            
            // Кастомный Tooltip
            if showAnalysisTooltip {
                AnalysisTooltipView {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showAnalysisTooltip = false
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 0.9).combined(with: .opacity)
                ))
            }
        }
        .alert(isPresented: $showResetAlert) {
            Alert(
                title: Text("Сбросить напоминания"),
                message: Text("Вы уверены, что хотите сбросить все настройки и напоминания? Это действие невозможно отменить."),
                primaryButton: .destructive(Text("Сбросить")) {
                    Task {
                        await resetAllData()
                    }
                },
                secondaryButton: .cancel(Text("Отмена"))
            )
        }
        .navigationBarHidden(true)
        .onChange(of: colorScheme) { newScheme in
            if viewModel.followSystemTheme {
                viewModel.setSystemTheme()
                viewModel.selectedTheme = viewModel.currentTheme
            }
        }
    }
    
    private func formatLastAnalysisDate() -> String {
        guard let date = significantDateViewModel.lastAnalysisDate else { return "Никогда" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        if Calendar.current.isDate(date, inSameDayAs: Date()) {
            formatter.timeStyle = .short
            return "Сегодня в \(formatter.string(from: date))"
        } else if Calendar.current.isDate(date, inSameDayAs: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()) {
            formatter.timeStyle = .short
            return "Вчера в \(formatter.string(from: date))"
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    private func resetAllData() async {
        do {
            try modelContext.delete(model: SignificantDate.self)
            try modelContext.save()
            let notificationService = NotificationService()
            await notificationService.cancelAllNotifications()
            await significantDateViewModel.loadSpecialDates(modelContext: modelContext)
            print("Все данные успешно сброшены")
        } catch {
            print("Ошибка сброса данных: \(error)")
        }
    }
}

struct AnalysisTooltipView: View {
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Заголовок
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(Color("primaryColor"))
                    .font(.title2)
                
                Text("Что делает полный анализ?")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Содержимое
            VStack(alignment: .leading, spacing: 12) {
                TooltipBulletPoint(
                    icon: "arrow.clockwise.circle",
                    text: "Переанализирует все события календаря"
                )
                
                TooltipBulletPoint(
                    icon: "calendar.badge.exclamationmark",
                    text: "Полностью пересоздаёт расписание напоминаний"
                )
                
                TooltipBulletPoint(
                    icon: "clock.arrow.2.circlepath",
                    text: "Может изменить время и количество уведомлений"
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Примечание
            Text("Обычно достаточно автоматических обновлений")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
        }
        .frame(width: 320)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
    }
}

struct TooltipBulletPoint: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color("primaryColor"))
                .font(.system(size: 16))
                .frame(width: 20, alignment: .center)
            
            Text(text)
                .font(.subheadline)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}
