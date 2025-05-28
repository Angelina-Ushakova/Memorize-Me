import SwiftUI

struct RequestCalendarAccessView: View {
    @Binding var accessGranted: Bool?
    
    let calendarService = CalendarSyncService()

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "calendar.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(Color("appPrimaryColor"))
                .padding()
                .background(Circle().fill(Color("appPrimaryColor").opacity(0.1)))

            Text("Разрешите доступ к календарю")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Text("Это необходимо, чтобы мы могли напоминать вам о важных датах.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            // Кнопки действий
            VStack(spacing: 15) {
                // Кнопка отказа
                Button(action: {
                    // Устанавливаем статус доступа как отклоненный
                    accessGranted = false
                }) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Отказаться")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(Color("appPrimaryColor"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("appPrimaryColor"), lineWidth: 2)
                    )
                    .cornerRadius(12)
                }

                // Кнопка разрешения
                Button(action: {
                    // Запрашиваем доступ к календарю
                    calendarService.requestAccess { granted in
                        // Обновляем статус доступа
                        accessGranted = granted
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Разрешить доступ")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("appPrimaryColor"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                }
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .background(Color("backgroundPrimary").edgesIgnoringSafeArea(.all))
    }
}

#Preview {
    RequestCalendarAccessView(accessGranted: .constant(nil))
}
