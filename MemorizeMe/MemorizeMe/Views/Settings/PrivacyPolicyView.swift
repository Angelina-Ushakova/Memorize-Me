import SwiftUI

// Представление политики конфиденциальности
struct PrivacyPolicyView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Политика конфиденциальности")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Приложение «Memorize Me» уважает вашу конфиденциальность и обрабатывает данные только локально на вашем устройстве. Мы не передаем никакие данные на сторонние серверы.")
                        .font(.body)
                    
                    Text("Доступ к календарю")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.top)
                    
                    Text("Приложение запрашивает доступ к вашему календарю исключительно для анализа событий и создания напоминаний. Все данные обрабатываются и хранятся только на вашем устройстве.")
                        .font(.body)
                    
                    Text("Уведомления")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.top)
                    
                    Text("Приложение использует системные уведомления iOS для напоминания о значимых датах. Вы можете в любой момент отключить уведомления в настройках устройства.")
                        .font(.body)
                    
                    Text("Хранение данных")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.top)
                    
                    Text("Все анализируемые данные хранятся локально на вашем устройстве с использованием технологии Swift Data. Мы не собираем, не передаем и не анализируем ваши данные на удаленных серверах.")
                        .font(.body)
                    
                    Text("Безопасность")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.top)
                    
                    Text("Приложение следует всем рекомендациям Apple по безопасности данных. Доступ к календарю предоставляется только после вашего явного согласия и может быть отозван в любой момент через настройки iOS.")
                        .font(.body)
                    
                    Text("Контакты")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.top)
                    
                    Text("Если у вас есть вопросы о нашей политике конфиденциальности, вы можете связаться с нами через App Store.")
                        .font(.body)
                    
                    Text("Последнее обновление: май 2025")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top)
                }
            }
            .padding()
        }
        .background(Color("backgroundPrimary").edgesIgnoringSafeArea(.all))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color("primaryColor"))
                        Text("Назад")
                            .foregroundColor(Color("primaryColor"))
                    }
                }
            }
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
