import Foundation
import SwiftUI

public struct WelcomeView: View {
    
    @Binding
    public var navigationPath: NavigationPath
    
    // Номер телефона строймира
    private let stroymirPhoneNumber = "+74959259277"
    
    public var body: some View {
        VStack {
            
            Image("lolgoBest")
                .resizable()
                .frame(width: 243, height: 63)
                .padding(.top, 80)
            
            Image("a-lot-of-houses")
                .resizable()
                .frame(width: 243, height: 243)
                .padding(.top, 16)
            
            Text("Добро пожаловать!")
                .font(Fonts.Font_Title3)
                .padding(.top, 32)
            
            Text("Мы ремонтируем квартиры под ключ\nв Москве и области")
                .font(Fonts.Font_Callout)
                .foregroundColor(Colors.textFieldOverlayGray)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
            
            Spacer()
            
            HStack{
                Button(
                    action: {
                        navigationPath.append(Destination.costcalculation)
                    },
                    label: {
                        HStack {
                            Image("gifts")
                            Text("Рассчитать стоимость")
                                .foregroundColor(Color.white)
                                .font(Fonts.Font_Headline2)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Colors.orange)
                        .cornerRadius(16)
                    }
                )
                Button(
                    action: {
                        let phoneUrl = "tel://\(stroymirPhoneNumber)"
                        guard let url = URL(string: phoneUrl) else {
                            return
                        }
                        
                        UIApplication.shared.open(url)
                    },
                    label: {
                        ZStack {
                            Rectangle()
                                .frame(width: 56 ,height: 56)
                                .foregroundColor(Colors.orange)
                                .cornerRadius(12)
                            
                            Image("call_swg_white")
                               
                        }
                    }
                )
            }
            .padding(.top, 24)
            
            Button(
                action: {
                    navigationPath.append(Destination.phoneinput)
                },
                label: {
                    Text("Войти в аккаунт")
                        .font(Fonts.Font_Headline2)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .foregroundColor(Colors.orange)
                }
                
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Colors.orange, lineWidth: 1) // Оранжевая граница
            )
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 16)
        .navigationBarBackButtonHidden(true)
    }
}
