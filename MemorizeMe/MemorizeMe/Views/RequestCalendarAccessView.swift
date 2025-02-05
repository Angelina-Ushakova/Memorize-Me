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
                .foregroundColor(.pink)
                .padding()
                .background(Circle().fill(Color.pink.opacity(0.1)))

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

            VStack(spacing: 15) {
                Button(action: {
                    accessGranted = false
                }) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Отказаться")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.pink)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.pink, lineWidth: 2)
                    )
                    .cornerRadius(12)
                }

                Button(action: {
                    calendarService.requestAccess { granted in
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
                    .background(Color.pink)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                }
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }
}

#Preview {
    RequestCalendarAccessView(accessGranted: .constant(nil))
}
