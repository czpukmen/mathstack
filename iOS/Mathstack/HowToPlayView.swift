import SwiftUI

struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 10) {
                        Text("🎮")
                            .font(.system(size: 50))
                        
                        Text("How to Play Math Stack")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.red, Color(red: 0.3, green: 0.8, blue: 0.76)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 10)
                    
                    // Goal section
                    HowToSection(
                        title: "🎯 Goal",
                        content: "Collect five arithmetic sequences by color. Each sequence must go from **1 to 5/10/15** or from **15/10/5 to 1**."
                    )
                    
                    // Gameplay section
                    HowToSection(
                        title: "🎮 Gameplay",
                        content: """
                        • Tap cards to collect them in sequences
                        • Only bottom row cards are unlocked initially
                        • Collecting cards unlocks adjacent cards
                        • Use temporary slots (Stacks) for strategy
                        • Move cards to empty spaces on the field
                        """
                    )
                    
                    // Special Slots section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("💡 Special Slots")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.3, green: 0.8, blue: 0.76))
                        
                        HintCard(
                            title: "🎯 Stack 1-3:",
                            content: "These slots automatically work as stacking areas. When you place a card here, you can stack the next or previous number of the same color on top. These stacks can only be moved to collections when they fit the sequence."
                        )
                        
                        HintCard(
                            title: "🔀 Shuffle:",
                            content: "Completely reshuffles all remaining cards on the field and redistributes them. Resets the game state to bottom-row-only unlocked. Adds +2 moves to your counter."
                        )
                        
                        HintCard(
                            title: "↶ Undo:",
                            content: "Cancels the last move and adds +1 move to your counter. Can be used unlimited times to try different strategies."
                        )
                    }
                    
                    // Victory section
                    HowToSection(
                        title: "🏆 Victory",
                        content: "Complete all five color sequences to win!"
                    )
                    
                    // Tips section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("💡 Tips")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.3, green: 0.8, blue: 0.76))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            TipRow(text: "Start with cards that can begin or end sequences (1 or max number)")
                            TipRow(text: "Use temp slots to build mini-sequences before moving to collections")
                            TipRow(text: "Plan ahead - unlocking cards reveals new possibilities")
                            TipRow(text: "Don't be afraid to use undo to explore different strategies")
                        }
                    }
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.18),
                        Color(red: 0.09, green: 0.13, blue: 0.24)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 0.3, green: 0.8, blue: 0.76))
                    .fontWeight(.bold)
                }
            }
        }
    }
}

struct HowToSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color(red: 0.3, green: 0.8, blue: 0.76))
            
            Text(content)
                .font(.body)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct HintCard: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(Color(red: 0.3, green: 0.8, blue: 0.76))
            
            Text(content)
                .font(.body)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.3, green: 0.8, blue: 0.76).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 0.3, green: 0.8, blue: 0.76).opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct TipRow: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(Color(red: 0.3, green: 0.8, blue: 0.76))
                .fontWeight(.bold)
            
            Text(text)
                .font(.body)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    HowToPlayView()
} 