import SwiftUI

struct JournalView: View {
    @StateObject private var viewModel = JournalViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Transaction Details")) {
                    TextField("Amount", text: $viewModel.amount)
                        .keyboardType(.decimalPad)
                    
                    TextField("What's this for?", text: $viewModel.memo)
                }
                
                Section(header: Text("How do you feel?")) {
                    Picker("Emotion", selection: $viewModel.selectedEmotion) {
                        Text("Select Emotion").tag(nil as Emotion?)
                        ForEach(Emotion.allCases) { emotion in
                            Text("\(emotion.rawValue) \(emotion.description)").tag(emotion as Emotion?)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Category")) {
                    Picker("Category", selection: $viewModel.selectedCategory) {
                        Text("Select Category").tag(nil as Transaction.TransactionCategory?)
                        ForEach(Transaction.TransactionCategory.allCases) { category in
                            Text(category.rawValue).tag(category as Transaction.TransactionCategory?)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    Button(action: viewModel.saveTransaction) {
                        Text("Save Transaction")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("New Entry")
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Journee"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}

struct JournalView_Previews: PreviewProvider {
    static var previews: some View {
        JournalView()
    }
}
