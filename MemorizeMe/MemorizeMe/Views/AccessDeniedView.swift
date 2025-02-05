import SwiftUI

struct AccessDeniedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.pink)

            Text("Доступ запрещён")
                .font(.title)
                .fontWeight(.bold)

            Text("Мы не сможем напоминать вам о событиях, если не получим доступ к вашему календарю. Вы можете разрешить доступ в настройках iPhone.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 30)

            Button(action: openSettings) {
                HStack {
                    Image(systemName: "gear")
                    Text("Открыть настройки")
                }
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.pink)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(radius: 5)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    AccessDeniedView()
}
