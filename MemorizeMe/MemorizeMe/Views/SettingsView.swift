import SwiftUI

struct SettingsView: View {
    @Binding var accessGranted: Bool
    @State private var isDarkMode = false
    @State private var showResetAlert = false
    @Environment(\.colorScheme) var colorScheme
    
    let calendarService = CalendarSyncService()
    
    var body: some View {
        VStack(spacing: 20) {
            // Заголовок посередине
            Text("Настройки")
                .font(.largeTitle)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top)
            
            // Секция доступа
            VStack(alignment: .leading, spacing: 10) {
                Text("ДОСТУП")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                VStack {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.pink)
                            .frame(width: 30)
                        
                        Text("Доступ к календарю")
                        
                        Spacer()
                        
                        if accessGranted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Button("Открыть настройки") {
                                openSettings()
                            }
                            .foregroundColor(.pink)
                        }
                    }
                    .padding()
                }
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .padding(.horizontal)
            }
            
            // Секция внешнего вида
            VStack(alignment: .leading, spacing: 10) {
                Text("ВНЕШНИЙ ВИД")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                VStack {
                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundColor(.pink)
                            .frame(width: 30)
                        
                        Text("Темная тема")
                        
                        Spacer()
                        
                        Toggle("", isOn: $isDarkMode)
                            .labelsHidden()
                    }
                    .padding()
                }
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .padding(.horizontal)
            }
            
            // Секция о приложении
            VStack(alignment: .leading, spacing: 10) {
                Text("О ПРИЛОЖЕНИИ")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.pink)
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
                                .foregroundColor(.pink)
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
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .padding(.horizontal)
            }
            
            // Кнопка сброса
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
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray5), lineWidth: 1)
                )
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
        .alert(isPresented: $showResetAlert) {
            Alert(
                title: Text("Сбросить напоминания"),
                message: Text("Вы уверены, что хотите сбросить все настройки и напоминания? Это действие невозможно отменить."),
                primaryButton: .destructive(Text("Сбросить")) {
                    // Здесь будет код для сброса напоминаний
                },
                secondaryButton: .cancel(Text("Отмена"))
            )
        }
        .navigationBarHidden(true)
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// Представление политики конфиденциальности
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Политика конфиденциальности")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Приложение «Memorize Me» уважает вашу конфиденциальность и обрабатывает данные только локально на вашем устройстве. Мы не передаем никакие данные на сторонние серверы.")
                
                Text("Доступ к календарю")
                    .font(.headline)
                
                Text("Приложение запрашивает доступ к вашему календарю исключительно для анализа событий и создания напоминаний. Все данные обрабатываются и хранятся только на вашем устройстве.")
            }
            .padding()
        }
        .navigationTitle("Политика конфиденциальности")
    }
}

#Preview {
    SettingsView(accessGranted: .constant(true))
}
