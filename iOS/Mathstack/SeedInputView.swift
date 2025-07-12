import SwiftUI

struct SeedInputView: View {
    @Binding var isPresented: Bool
    @State private var seedInput: String = ""
    @State private var selectedDifficulty: Difficulty = .easy
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    let onSeedSelected: (Difficulty, String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "number.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Enter Seed ID")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Play a specific level by entering its seed ID")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Difficulty Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Difficulty")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        ForEach(Difficulty.allCases, id: \.self) { difficulty in
                            Button(action: {
                                selectedDifficulty = difficulty
                            }) {
                                HStack(spacing: 8) {
                                    Text(difficulty.emoji)
                                        .font(.title3)
                                    Text(difficulty.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    backgroundForDifficulty(difficulty)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // Seed Input
                VStack(alignment: .leading, spacing: 12) {
                    Text("Seed ID")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Enter seed (e.g., E001, M042, H123)", text: $seedInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title3)
                        .autocapitalization(.allCharacters)
                        .disableAutocorrection(true)
                        .onSubmit {
                            validateAndLaunch()
                        }
                    
                    // Format hint
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Format examples:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            Text("• Easy: E001-E999")
                            Text("• Medium: M001-M999")
                            Text("• Hard: H001-H999")
                        }
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Error Message
                if showError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.red.opacity(0.1))
                    )
                }
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                    
                    Button("Play Level") {
                        validateAndLaunch()
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .disabled(seedInput.isEmpty)
                    .opacity(seedInput.isEmpty ? 0.6 : 1.0)
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
            .navigationTitle("Custom Level")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
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
                .ignoresSafeArea()
            )
        }
    }
    
    private func validateAndLaunch() {
        let trimmedSeed = seedInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // Reset error state
        showError = false
        errorMessage = ""
        
        // Basic format validation
        guard !trimmedSeed.isEmpty else {
            showError(message: "Please enter a seed ID")
            return
        }
        
        guard trimmedSeed.count >= 4 else {
            showError(message: "Seed ID must be at least 4 characters long")
            return
        }
        
        // Extract difficulty prefix
        let prefix = String(trimmedSeed.prefix(1))
        let numberPart = String(trimmedSeed.dropFirst())
        
        // Validate prefix
        guard ["E", "M", "H"].contains(prefix) else {
            showError(message: "Seed ID must start with E (Easy), M (Medium), or H (Hard)")
            return
        }
        
        // Validate number part
        guard let number = Int(numberPart), number >= 1, number <= 999 else {
            showError(message: "Seed number must be between 001 and 999")
            return
        }
        
        // Determine difficulty from prefix
        let seedDifficulty: Difficulty
        switch prefix {
        case "E": seedDifficulty = .easy
        case "M": seedDifficulty = .medium
        case "H": seedDifficulty = .hard
        default: 
            showError(message: "Invalid difficulty prefix")
            return
        }
        
        // Format seed properly
        let formattedSeed = "\(prefix)\(String(format: "%03d", number))"
        
        // Check if level exists
        if LevelDatabase.shared.getLevel(difficulty: seedDifficulty, seedID: formattedSeed) != nil {
            // Update selected difficulty to match seed
            selectedDifficulty = seedDifficulty
            onSeedSelected(seedDifficulty, formattedSeed)
            isPresented = false
        } else {
            showError(message: "Level \(formattedSeed) not found. Please check the seed ID.")
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
        
        // Auto-hide error after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showError = false
        }
    }
    
    @ViewBuilder
    private func backgroundForDifficulty(_ difficulty: Difficulty) -> some View {
        let isSelected = selectedDifficulty == difficulty
        
        if isSelected {
            RoundedRectangle(cornerRadius: 10)
                .fill(difficulty.color.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(difficulty.color, lineWidth: 2)
                )
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.clear, lineWidth: 2)
                )
        }
    }
}

#Preview {
    SeedInputView(isPresented: .constant(true)) { difficulty, seed in
        print("Selected: \(difficulty.displayName) - \(seed)")
    }
} 