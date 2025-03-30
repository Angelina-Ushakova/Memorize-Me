import SwiftUI
import UIKit

// Модификатор для удаления стандартной линии TabBar
struct TabBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                let appearance = UITabBarAppearance()
                appearance.backgroundColor = UIColor.systemBackground
                appearance.shadowColor = .clear
                appearance.shadowImage = UIImage()
                
                UITabBar.appearance().standardAppearance = appearance
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
    }
}

// Глобальная кастомная обертка для TabView с линией
struct TabViewWithLine<Content: View>: View {
    @ViewBuilder let content: Content
    @State private var tabBarHeight: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Оригинальный TabView
            content
                .modifier(TabBarModifier())
                .safeAreaInset(edge: .bottom) {
                    // Используем safeAreaInset для создания дополнительного пространства под контентом
                    Color.clear
                        .frame(height: 1) // Минимальная высота
                        .background(GeometryReader { geometry in
                            Color.clear.onAppear {
                                // Получаем высоту TabBar
                                tabBarHeight = geometry.safeAreaInsets.bottom + 65
                            }
                        })
                }
            
            // Общая линия для всех экранов
            VStack {
                Spacer()
                Divider()
                    .background(Color(.systemGray5))
                    .frame(height: 1)
                    .padding(.bottom, tabBarHeight - 8) // Динамическое позиционирование
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}

// Обновленная версия MainTabView
struct MainTabView: View {
    @Binding var accessGranted: Bool?
    
    var body: some View {
        TabViewWithLine {
            TabView {
                CalendarView()
                    .tabItem {
                        Label("Календарь", systemImage: "calendar")
                    }
                
                SettingsView(accessGranted: Binding<Bool>(
                    get: { self.accessGranted ?? false },
                    set: { self.accessGranted = $0 }
                ))
                    .tabItem {
                        Label("Настройки", systemImage: "gear")
                    }
                
                // Любые другие вкладки можно добавлять здесь без изменения логики линии
            }
            .accentColor(.pink)
        }
    }
}
