import SwiftUI

struct DifficultySelectionView: View {
    let onDifficultySelected: (Difficulty) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Logo placeholder (you can add actual image later)
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.3, green: 0.8, blue: 0.76), .cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.bottom, 10)
            
            Text("Math Stack")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.red, Color(red: 0.3, green: 0.8, blue: 0.76)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            VStack(spacing: 15) {
                DifficultyButton(
                    difficulty: .easy,
                    isRecommended: false
                ) {
                    onDifficultySelected(.easy)
                }
                
                DifficultyButton(
                    difficulty: .medium,
                    isRecommended: false
                ) {
                    onDifficultySelected(.medium)
                }
                
                DifficultyButton(
                    difficulty: .hard,
                    isRecommended: true
                ) {
                    onDifficultySelected(.hard)
                }
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.1, green: 0.1, blue: 0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 2)
                )
                .shadow(color: Color(red: 0.3, green: 0.8, blue: 0.76).opacity(0.1), radius: 15)
        )
        .padding(.horizontal, 20)
    }
}

struct DifficultyButton: View {
    let difficulty: Difficulty
    let isRecommended: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(difficulty.emoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(difficulty.displayName)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(difficulty.subtitle)
                        .font(.caption)
                        .opacity(0.8)
                }
                
                Spacer()
                
                if isRecommended {
                    Text("RECOMMENDED")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(red: 1.0, green: 0.85, blue: 0.59)) // #ffd89b
                        .foregroundColor(.black)
                        .cornerRadius(8)
                }
            }
            .foregroundColor(.white)
            .padding()
            .background(
                LinearGradient(
                    colors: [difficulty.color, difficulty.color.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(10)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.18),
                Color(red: 0.09, green: 0.13, blue: 0.24)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        DifficultySelectionView { difficulty in
            print("Selected: \(difficulty)")
        }
    }
} 
