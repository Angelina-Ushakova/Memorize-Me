import SwiftUI

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
        .background(Color("backgroundPrimary").edgesIgnoringSafeArea(.all))
        .navigationTitle("Политика конфиденциальности")
    }
}
