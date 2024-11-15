import SwiftUI
import DojoTapToPayOniPhoneSDK /// (1) import SDK

@available(iOS 16.7, *)
struct ContentView: View {
    
    var dojoSDK: DojoTapToPayOniPhone? = DojoTapToPayOniPhone() /// (2) also could be  DojoTapToPayOniPhone(env: .staging)
    @State private var showingActivationAlert = false
    @State private var showingErrorAlert = false
    @State private var terminalStatus: DojoTerminalStatus?
    @State private var errorText: String = ""
    @State private var paymentIntentText: String = ""
    @State private var emailText: String = ""
    
    let secret = "secret" // refer to our documentation
    @State private var paymentIntentId = "payment-intent-id" // https://docs.dojo.tech/payments/api#tag/Payment-intents/operation/PaymentIntents_CreatePaymentIntent
    
    var body: some View {
        VStack {
            switch terminalStatus {
            case .operational:
                viewActivated
            case .pending, .provisioning, .provisioned:
                viewNotActivated
            case .unknown, .failed:
                viewNotActivated
            case .none, .some(_):
                Text("Checking terminal status")
            }
            Divider()
            viewSendReceipt
            viewCurrentEnv
        }.task {
            do {
                /// (3) check current device status
                terminalStatus = try await dojoSDK?.getTerminalActivationStatus(secret: secret)
            } catch {
                showError(error)
                terminalStatus = .unknown
            }
        }.alert("Activation in progress...", isPresented: $showingActivationAlert) {
            Button("Hide", role: .cancel) { }
        }.alert(errorText, isPresented: $showingErrorAlert) {
            Button("Hide", role: .cancel) { }
        }
    }
    
    var viewNotActivated: some View {
        VStack {
            Image(systemName:"dock.arrow.down.rectangle")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Activate device")
        }.onTapGesture {
            Task {
                do {
                    showingActivationAlert = true
                    /// (4) activate if not .operational or .provisioned
                    try await dojoSDK?.activateTerminal(secret)
                    terminalStatus = try await dojoSDK?.getTerminalActivationStatus(notifyWhenOperational: true, secret: secret)
                } catch {
                    print(error)
                    terminalStatus = .unknown
                }
                showingActivationAlert = false
            }
        }
        .padding()
    }
    
    var viewActivated: some View {
        VStack(spacing: 30) {
            VStack {
                Image(systemName:"sterlingsign.square.fill")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Take Payment")
            }.onTapGesture {
                Task {
                    do {
                        /// (5) take payments
                        
                        if let isAccountLinked = try? await dojoSDK?.isAccountLinked(secret),
                           !isAccountLinked {
                            try await dojoSDK?.linkAccount(secret)
                        }
                        
                        let result = try await dojoSDK?.startPayment(paymentIntentId: paymentIntentId, secret: secret)
                        print(result)
                    } catch {
                        showError(error)
                    }
                }
            }
            VStack {
                Image(systemName:"xmark.square.fill")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Deactivate device")
            }.onTapGesture {
                Task {
                    dojoSDK?.deactiveTerminal()
                    terminalStatus = .unknown
                }
            }
        }
        .padding()
    }
    
    var deviceInfo: some View {
        VStack {
            Text("Device name: \(DeviceHelper.deviceName)")
            Text("Model: \(DeviceHelper.deviceModel)")
            Text("Type: \(DeviceHelper.modelType)")
        }
    }
    
    func showError(_ error: Error) {
        errorText = (error as NSError).debugDescription
        showingErrorAlert = true
        terminalStatus = .unknown
    }
    
    var viewSendReceipt: some View {
        VStack {
            paymentIntentInputField
            emailInputField
            Button("Send Receipt") {
                if !paymentIntentText.isEmpty {
                    paymentIntentId = paymentIntentText
                }
                Task {
                    do {
                        try await dojoSDK?.sendReceipt(paymentIntentId: paymentIntentId, secret: secret, emails: [emailText])
                    } catch {
                        showError(error)
                    }
                }
            }
        }
    }
    
    var paymentIntentInputField: some View {
        VStack {
            TextField("Payment-intent-id", text: $paymentIntentText)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.never)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                    }
                }
                .padding()
        }
    }
    
    var viewCurrentEnv: some View {
        VStack {
            if let dojoSDK = dojoSDK {
                Text("Env: \(dojoSDK.getEnvironment())")
            }
        }
    }
    
    var emailInputField: some View {
        VStack {
            TextField("Email", text: $emailText)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.never)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                    }
                }
                .padding()
        }
    }
}
