import SwiftUI
import UIKit

// Модификатор для удаления стандартной линии TabBar
struct TabBarModifier: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                let appearance = UITabBarAppearance()
                appearance.backgroundColor = UIColor(Color("backgroundPrimary"))
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
            content
                .modifier(TabBarModifier())
                .safeAreaInset(edge: .bottom) {
                    Color.clear
                        .frame(height: 1)
                        .background(GeometryReader { geometry in
                            Color.clear.onAppear {
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
                    .padding(.bottom, tabBarHeight - 8)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}
