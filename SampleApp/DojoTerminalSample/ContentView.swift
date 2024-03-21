import SwiftUI
import DojoTapToPayOniPhoneSDK /// (1) import SDK

@available(iOS 16.4, *)
struct ContentView: View {
    
    var dojoSDK: DojoTapToPayOniPhone? = DojoTapToPayOniPhone() /// (2) also could be  DojoTapToPayOniPhone(env: .staging)
    @State private var showingActivationAlert = false
    @State private var showingErrorAlert = false
    @State private var terminalStatus: DojoTerminalStatus?
    @State private var errorText: String = ""
    
    let secret = "ts_prod_K2r_r1ewHS9MwlxiLx9G1x2LoiScy_Kfy4hXPAZyIxDfNpAV2SPGzZopCP4s8cRjY2xY1TrOVEEHI990ugizzdpcPat_fpP2UBEUctFpsH4" // refer to our documentation
    let paymentIntentId = "payment-intent-id" // https://docs.dojo.tech/payments/api#tag/Payment-intents/operation/PaymentIntents_CreatePaymentIntent
    
    var body: some View {
        VStack {
            switch terminalStatus {
            case .operational, .provisioned:
                viewActivated
            case .pending, .provisioning:
                viewNotActivated
            case .unknown, .failed:
                viewNotActivated
            case .none, .some(_):
                Text("Checking terminal status")
            }
            Divider()
            deviceInfo
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
                        try await dojoSDK?.startPayment(paymentIntentId: paymentIntentId, secret: secret)
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
                    await dojoSDK?.deactiveTerminal()
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
}
