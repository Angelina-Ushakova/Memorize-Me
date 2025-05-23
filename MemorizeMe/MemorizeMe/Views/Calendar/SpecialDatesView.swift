import SwiftUI
import SwiftData

struct SpecialDatesView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var significantDateViewModel: SignificantDateViewModel

    @State private var selectedSpecialDate: SignificantDate?
    @State private var showAlert = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Напоминания")
                .font(.largeTitle)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top)

            if significantDateViewModel.isAnalyzing {
                VStack(spacing: 15) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Анализируем ваш календарь...")
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if significantDateViewModel.specialDates.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("Нет значимых дат")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Добавьте события в календарь, и мы найдем для вас важные даты")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding(.horizontal)

                    Button("Обновить анализ") {
                        Task {
                            await significantDateViewModel.refreshAnalysis(modelContext: modelContext)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 15) {
                        if !significantDateViewModel.getUpcomingDates().isEmpty {
                            SectionHeaderView(title: "Ближайшие", count: significantDateViewModel.getUpcomingDates().count)

                            ForEach(significantDateViewModel.getUpcomingDates(), id: \.id) { specialDate in
                                SpecialDateCard(specialDate: specialDate)
                                    .onTapGesture {
                                        selectedSpecialDate = specialDate
                                        showAlert = true
                                    }
                                    .contextMenu {
                                        Button("Удалить", role: .destructive) {
                                            Task {
                                                await significantDateViewModel.deleteSpecialDate(specialDate, modelContext: modelContext)
                                            }
                                        }
                                    }
                            }
                        }

                        SectionHeaderView(title: "Все напоминания", count: significantDateViewModel.specialDates.count)

                        ForEach(significantDateViewModel.specialDates, id: \.id) { specialDate in
                            SpecialDateCard(specialDate: specialDate)
                                .onTapGesture {
                                    selectedSpecialDate = specialDate
                                    showAlert = true
                                }
                                .contextMenu {
                                    Button("Удалить", role: .destructive) {
                                        Task {
                                            await significantDateViewModel.deleteSpecialDate(specialDate, modelContext: modelContext)
                                        }
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            Spacer()
        }
        .background(Color("backgroundPrimary").edgesIgnoringSafeArea(.all))
        .refreshable {
            await significantDateViewModel.refreshAnalysis(modelContext: modelContext)
        }
        .overlay(
            Group {
                if showAlert, let date = selectedSpecialDate {
                    SpecialDateAlertView(
                        specialDate: date,
                        onDelete: {
                            showAlert = false
                            Task {
                                await significantDateViewModel.deleteSpecialDate(date, modelContext: modelContext)
                            }
                        },
                        onDismiss: { showAlert = false }
                    )
                }
            }
        )
    }
}

struct SectionHeaderView: View {
    let title: String
    let count: Int

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            Text("(\(count))")
                .font(.caption)
                .foregroundColor(.gray)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

struct SpecialDateCard: View {
    let specialDate: SignificantDate
    @EnvironmentObject var significantDateViewModel: SignificantDateViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: categoryIcon)
                    .foregroundColor(Color(specialDate.type.calendarColor))
                    .frame(width: 20)

                Text(specialDate.type.description)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("textPrimary"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(specialDate.type.calendarColor), lineWidth: 1.4)
                            .background(
                                Color(specialDate.type.calendarColor)
                                    .opacity(0.09)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            )
                    )
                Spacer()
                Text(significantDateViewModel.formatDate(specialDate.notificationDate))
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Text(specialDate.eventTitle)
                .font(.body)
                .fontWeight(.medium)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color("backgroundPrimary"))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private var categoryIcon: String {
        switch specialDate.type {
        case .action: return "checkmark.circle"
        case .greeting: return "gift"
        case .anniversary: return "calendar.badge.clock"
        case .prettyDate: return "sparkles"
        case .throwback: return "memories"
        case .other: return "calendar"
        }
    }
}
